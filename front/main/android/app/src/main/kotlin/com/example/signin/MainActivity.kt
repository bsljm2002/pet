package com.example.signin

import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.exp
import org.json.JSONObject
import org.pytorch.IValue
import org.pytorch.Module
import org.pytorch.Tensor
import org.pytorch.torchvision.TensorImageUtils
import java.io.File
import java.io.FileOutputStream
import java.io.InputStream
import java.util.Locale

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "ai_care/pytorch"
        private const val TAG = "AiCarePytorch"
    }

    // 모델 캐시 (모델 파일 경로 -> Module)
    private val moduleCache = mutableMapOf<String, Module>()
    private val metadataCache = mutableMapOf<String, JSONObject>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "runClassification" -> {
                    val imagePath = call.argument<String>("imagePath")
                    val modelFile = call.argument<String>("modelFile")
                    val metadataFile = call.argument<String>("metadataFile")
                    
                    if (imagePath.isNullOrEmpty() || modelFile.isNullOrEmpty() || metadataFile.isNullOrEmpty()) {
                        result.error("INVALID_INPUT", "imagePath, modelFile, and metadataFile are required", null)
                        return@setMethodCallHandler
                    }
                    
                    thread {
                        try {
                            val inference = runClassification(imagePath, modelFile, metadataFile)
                            runOnUiThread { result.success(inference) }
                        } catch (e: Exception) {
                            Log.e(TAG, "Classification error", e)
                            runOnUiThread {
                                result.error("CLASSIFICATION_ERROR", e.localizedMessage ?: "Unknown error", null)
                            }
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun runClassification(imagePath: String, modelFile: String, metadataFile: String): HashMap<String, Any?> {
        val module = getOrLoadModule(modelFile)
        val metadata = getOrLoadMetadata(metadataFile)
        
        // Classification 모델은 일반적으로 224x224 입력
        val trainingConfig = metadata.optJSONObject("training_config")
        val imageSize = trainingConfig?.optInt("image_size", 224) ?: 224
        
        Log.d(TAG, "Running classification with imageSize=$imageSize, model=$modelFile")
        
        // YOLO 모델 정규화: 0~1 범위 (mean=0, std=1)
        // YOLO는 ImageNet 정규화를 사용하지 않음
        val mean = floatArrayOf(0.0f, 0.0f, 0.0f)
        val std = floatArrayOf(1.0f, 1.0f, 1.0f)

        val bitmap = BitmapFactory.decodeFile(imagePath)
            ?: throw IllegalArgumentException("이미지를 불러올 수 없습니다: $imagePath")
        val resized = Bitmap.createScaledBitmap(bitmap, imageSize, imageSize, true)
        if (bitmap != resized) {
            bitmap.recycle()
        }

        val inputTensor: Tensor = TensorImageUtils.bitmapToFloat32Tensor(resized, mean, std)
        resized.recycle()
        
        val outputTensor = module.forward(IValue.from(inputTensor)).toTensor()
        val scores = outputTensor.dataAsFloatArray
        
        Log.d(TAG, "Model output size: ${scores.size}")
        
        val probabilities = softmax(scores)

        // 가장 높은 확률의 클래스 찾기
        var bestIndex = 0
        var bestValue = if (probabilities.isNotEmpty()) probabilities[0] else 0f
        for (i in 1 until probabilities.size) {
            val value = probabilities[i]
            if (value > bestValue) {
                bestValue = value
                bestIndex = i
            }
        }
        
        val confidence = probabilities[bestIndex].toDouble()
        val classNames = metadata.optJSONObject("class_names")
        val label = classNames?.optString(bestIndex.toString()) ?: "class_$bestIndex"

        // 상위 3개 예측 결과 로깅
        val topPredictions = probabilities
            .mapIndexed { index, probability ->
                val name = classNames?.optString(index.toString()) ?: "class_$index"
                name to probability
            }
            .sortedByDescending { it.second }
            .take(3)
            .joinToString(", ") { (name, prob) ->
                "$name=${String.format(Locale.US, "%.3f", prob)}"
            }

        Log.d(TAG, "Classification result: label=$label confidence=${String.format("%.4f", confidence)} index=$bestIndex")
        Log.d(TAG, "Top 3 predictions: $topPredictions")

        return hashMapOf(
            "label" to label,
            "confidence" to confidence,
            "index" to bestIndex,
            "numClasses" to probabilities.size,
        )
    }

    private fun getOrLoadModule(modelFile: String): Module {
        return moduleCache.getOrPut(modelFile) {
            val path = assetFilePath("assets/models/$modelFile")
            Log.d(TAG, "Loading model from: $path")
            Module.load(path)
        }
    }

    private fun getOrLoadMetadata(metadataFile: String): JSONObject {
        return metadataCache.getOrPut(metadataFile) {
            val json = openFlutterAsset("assets/models/$metadataFile").bufferedReader().use { it.readText() }
            Log.d(TAG, "Loaded metadata: $metadataFile")
            JSONObject(json)
        }
    }

    private fun softmax(scores: FloatArray): FloatArray {
        val maxScore = scores.maxOrNull() ?: 0f
        val expScores = FloatArray(scores.size)
        var sum = 0.0
        for (i in scores.indices) {
            val value = exp((scores[i] - maxScore).toDouble())
            expScores[i] = value.toFloat()
            sum += value
        }
        for (i in expScores.indices) {
            expScores[i] = (expScores[i] / sum).toFloat()
        }
        return expScores
    }

    private fun assetFilePath(assetName: String): String {
        val outFile = File(filesDir, assetName)
        if (outFile.exists() && outFile.length() > 0) {
            Log.d(TAG, "Using cached file: ${outFile.absolutePath}")
            return outFile.absolutePath
        }
        outFile.parentFile?.let { parent ->
            if (!parent.exists()) {
                parent.mkdirs()
            }
        }
        openFlutterAsset(assetName).use { input ->
            FileOutputStream(outFile).use { output ->
                input.copyTo(output)
            }
        }
        Log.d(TAG, "Copied asset to: ${outFile.absolutePath}")
        return outFile.absolutePath
    }

    private fun openFlutterAsset(assetPath: String): InputStream {
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        val lookupKey = flutterLoader.getLookupKeyForAsset(assetPath)
        Log.d(TAG, "Looking for asset: $assetPath with lookupKey: $lookupKey")
        return try {
            assets.open(lookupKey)
        } catch (e: Exception) {
            Log.w(TAG, "Failed to open with lookupKey: ${e.message}")
            try {
                assets.open(assetPath)
            } catch (e2: Exception) {
                Log.e(TAG, "Failed to open asset $assetPath: ${e2.message}")
                throw e2
            }
        }
    }
}
