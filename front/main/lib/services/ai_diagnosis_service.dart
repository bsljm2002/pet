// AI 진단 서비스
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/ai_diagnosis.dart';

/// 진단 모델 타입
enum DiagnosisModelType { dogEyes, dogSkin, catEyes, catSkin }

class AIDiagnosisService {
  static final AIDiagnosisService _instance = AIDiagnosisService._internal();
  factory AIDiagnosisService() => _instance;
  AIDiagnosisService._internal();

  static const MethodChannel _pytorchChannel = MethodChannel('ai_care/pytorch');

  final List<AIDiagnosis> _diagnoses = [];

  /// 사용 가능한 모델인지 확인
  static bool isModelAvailable(DiagnosisModelType modelType) {
    // 모든 모델 사용 가능
    return true;
  }

  /// 모델 타입에 따른 파일명 반환
  static (String modelFile, String metadataFile) getModelFiles(
    DiagnosisModelType modelType,
  ) {
    switch (modelType) {
      case DiagnosisModelType.dogEyes:
        return ('dog_eyes_best.ptl', 'dog_eyes_best_metadata.json');
      case DiagnosisModelType.dogSkin:
        return ('dog_skin_best.ptl', 'dog_skin_best_metadata.json');
      case DiagnosisModelType.catEyes:
        return ('cat_eyes_best.ptl', 'cat_eyes_best_metadata.json');
      case DiagnosisModelType.catSkin:
        return ('cat_skin_best.ptl', 'cat_skin_best_metadata.json');
    }
  }

  /// 모델 타입 이름 (한국어)
  static String getModelTypeName(DiagnosisModelType modelType) {
    switch (modelType) {
      case DiagnosisModelType.dogEyes:
        return '강아지 눈 질환';
      case DiagnosisModelType.dogSkin:
        return '강아지 피부 질환';
      case DiagnosisModelType.catEyes:
        return '고양이 눈 질환';
      case DiagnosisModelType.catSkin:
        return '고양이 피부 질환';
    }
  }

  // 모든 진단 결과 가져오기
  Future<List<AIDiagnosis>> getAllDiagnoses() async {
    return List.from(_diagnoses);
  }

  // 특정 반려동물의 진단 결과 가져오기
  Future<List<AIDiagnosis>> getDiagnosesByPet(String petId) async {
    final allDiagnoses = await getAllDiagnoses();
    return allDiagnoses.where((d) => d.petId == petId).toList();
  }

  // AI 진단 수행 (디바이스 내 PyTorch 모델 호출)
  Future<AIDiagnosis> performDiagnosis({
    required String imagePath,
    required String petName,
    String? petId,
    DiagnosisModelType modelType = DiagnosisModelType.dogEyes,
  }) async {
    if (!isModelAvailable(modelType)) {
      throw PlatformException(
        code: 'MODEL_NOT_AVAILABLE',
        message: '${getModelTypeName(modelType)} 모델이 아직 준비되지 않았습니다.',
      );
    }

    final inference = await _runClassification(imagePath, modelType);
    final diagnosis = _buildDiagnosisFromInference(
      inference,
      imagePath,
      petName,
      petId,
      modelType,
    );

    await saveDiagnosis(diagnosis);
    return diagnosis;
  }

  Future<Map<String, dynamic>> _runClassification(
    String imagePath,
    DiagnosisModelType modelType,
  ) async {
    final (modelFile, metadataFile) = getModelFiles(modelType);

    final result = await _pytorchChannel.invokeMapMethod<String, dynamic>(
      'runClassification',
      {
        'imagePath': imagePath,
        'modelFile': modelFile,
        'metadataFile': metadataFile,
      },
    );

    if (result == null) {
      throw PlatformException(
        code: 'EMPTY_RESULT',
        message: 'AI 모델이 결과를 반환하지 않았습니다.',
      );
    }

    // 디버그 로그: 모델 추론 결과 확인
    debugPrint('=== AI Model Inference Result ===');
    debugPrint('Model: $modelFile');
    debugPrint('Raw Label: ${result['label']}');
    debugPrint('Confidence: ${result['confidence']}');
    debugPrint('Class Index: ${result['index']}');
    debugPrint('Num Classes: ${result['numClasses']}');
    debugPrint('=================================');

    return result;
  }

  AIDiagnosis _buildDiagnosisFromInference(
    Map<String, dynamic> inference,
    String imagePath,
    String petName,
    String? petId,
    DiagnosisModelType modelType,
  ) {
    final rawLabel = inference['label'] as String? ?? '알 수 없음';
    final confidence = (inference['confidence'] as num?)?.toDouble() ?? 0.0;

    // 모델 타입에 따른 질병명 매핑
    final diseaseNameMap = _getDiseaseNameMap(modelType);
    final koreanDisease = diseaseNameMap[rawLabel] ?? rawLabel;
    final severity = _confidenceToSeverity(confidence);

    final modelTypeName = getModelTypeName(modelType);

    // 정상/건강 여부 확인
    final isHealthy = _isHealthyResult(rawLabel, modelType);

    // 설명 문구 생성
    String description;
    if (isHealthy) {
      description = '검사 결과, 현재 특별한 이상 소견이 발견되지 않았습니다.';
    } else {
      description =
          '검사 결과, \'$koreanDisease\' 증상이 의심됩니다. 정확한 진단을 위해 수의사와 상담하시기 바랍니다.';
    }

    // Disease-specific symptoms and recommendations
    final symptoms = _getSymptomsForDisease(rawLabel, modelType);
    final recommendations = _getRecommendationsForDisease(rawLabel, modelType);

    return AIDiagnosis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      diagnosisDate: DateTime.now(),
      petName: petName,
      petId: petId,
      diagnosis: koreanDisease,
      description: description,
      severity: isHealthy ? 'none' : severity,
      symptoms: symptoms,
      recommendations: recommendations,
      confidence: confidence,
      diseaseStatus: isHealthy ? '정상' : '질병 의심',
    );
  }

  Map<String, String> _getDiseaseNameMap(DiagnosisModelType modelType) {
    switch (modelType) {
      case DiagnosisModelType.dogEyes:
        return {
          'Pigmented_keratitis': '색소침착성각막염',
          'blepharitis': '안검염',
          'entropion': '안검내반증',
          'eyelid_tumor': '안검종양',
          'mastopathy': '유방병증',
        };
      case DiagnosisModelType.dogSkin:
        return {
          'bacterial dermatosis': '세균성 피부염',
          'fungal infection': '곰팡이 감염',
          'healthy': '정상',
          'hypersensitivity dermatitis': '과민성 피부염',
        };
      case DiagnosisModelType.catSkin:
        return {
          'Alopecia': '탈모증',
          'Eosinophilic Plague': '호산구성 플라크',
          'Flea_Allergy': '벼룩 알레르기',
          'Health': '정상',
          'Miliary Dermatitis': '좁쌀 피부염',
          'Ringworm': '백선 (링웜)',
          'Scabies': '옴',
        };
      case DiagnosisModelType.catEyes:
        return {
          'Blepharitis': '안검염',
          'Conjunctivitis': '결막염',
          'Corneal Sequestrum': '각막부골편',
          'Corneal Ulcer': '각막궤양',
          'Health': '정상',
          'Non-ulcerative': '비궤양성 각막질환',
        };
    }
  }

  List<String> _getSymptomsForDisease(
    String disease,
    DiagnosisModelType modelType,
  ) {
    // 강아지 눈 질환
    if (modelType == DiagnosisModelType.dogEyes) {
      switch (disease) {
        case 'Pigmented_keratitis':
          return ['각막에 갈색 또는 검은색 색소 침착', '눈물 분비 증가', '눈 주변 털의 변색', '시력 저하 가능성'];
        case 'blepharitis':
          return ['눈꺼풀 부종', '눈꺼풀 발적', '눈곱 증가', '눈 주변 가려움'];
        case 'entropion':
          return ['눈꺼풀이 안쪽으로 말림', '속눈썹이 각막 자극', '눈물 과다 분비', '각막 손상 가능성'];
        case 'eyelid_tumor':
          return ['눈꺼풀에 종괴 발견', '종괴 주변 부종', '눈물 분비 증가', '눈 깜빡임 이상'];
        case 'mastopathy':
          return ['유선 조직 비대', '유선 주변 종괴', '피부 변색 가능', '통증 또는 불편감'];
      }
    }

    // 강아지 피부 질환
    if (modelType == DiagnosisModelType.dogSkin) {
      switch (disease) {
        case 'bacterial dermatosis':
          return ['피부 발적', '농포 형성', '비듬 증가', '가려움증'];
        case 'fungal infection':
          return ['원형 탈모 부위', '피부 각질', '비듬', '가려움'];
        case 'healthy':
          return ['정상적인 피부 상태', '건강한 털 상태'];
        case 'hypersensitivity dermatitis':
          return ['심한 가려움', '피부 발적', '긁는 행동', '피부 손상'];
      }
    }

    // 고양이 피부 질환
    if (modelType == DiagnosisModelType.catSkin) {
      switch (disease) {
        case 'Alopecia':
          return ['탈모 부위 발생', '피부 노출', '과도한 그루밍', '스트레스 징후'];
        case 'Eosinophilic Plague':
          return ['붉은 융기 병변', '피부 궤양', '가려움', '털 빠짐'];
        case 'Flea_Allergy':
          return ['심한 가려움', '과도한 긁기', '탈모', '피부 발진'];
        case 'Health':
          return ['정상적인 피부 상태', '건강한 털 상태'];
        case 'Miliary Dermatitis':
          return ['작은 딱지 형성', '피부 돌기', '가려움', '털 빠짐'];
        case 'Ringworm':
          return ['원형 탈모', '비늘 형성', '피부 발적', '전염 가능성'];
        case 'Scabies':
          return ['심한 가려움', '피부 두꺼워짐', '딱지 형성', '탈모'];
      }
    }

    // 고양이 눈 질환
    if (modelType == DiagnosisModelType.catEyes) {
      switch (disease) {
        case 'Blepharitis':
          return ['눈꺼풀 부종', '눈꺼풀 발적', '눈곱 증가', '눈 주변 가려움'];
        case 'Conjunctivitis':
          return ['눈 충혈', '눈물 과다 분비', '눈곱 증가', '눈 부종'];
        case 'Corneal Sequestrum':
          return ['각막에 갈색/검은색 반점', '눈물 흘림', '눈 깜빡임 증가', '눈 불편감'];
        case 'Corneal Ulcer':
          return ['각막 혼탁', '눈물 과다', '눈 통증', '빛에 민감'];
        case 'Health':
          return ['정상적인 눈 상태', '건강한 눈'];
        case 'Non-ulcerative':
          return ['각막 표면 이상', '눈 불편감', '눈물 분비 변화', '가벼운 충혈'];
      }
    }

    return ['관찰된 이상 소견'];
  }

  List<String> _getRecommendationsForDisease(
    String disease,
    DiagnosisModelType modelType,
  ) {
    // 강아지 눈 질환
    if (modelType == DiagnosisModelType.dogEyes) {
      switch (disease) {
        case 'Pigmented_keratitis':
          return [
            '즉시 동물병원 방문하여 정밀 검사 받기',
            '눈 주변을 청결하게 유지',
            '눈물 분비 개선을 위한 안약 처방 필요',
            '정기적인 안과 검진 권장',
          ];
        case 'blepharitis':
          return [
            '동물병원에서 항생제 또는 항염증제 처방 받기',
            '눈 주변 청결 유지',
            '온찜질로 증상 완화',
            '알레르기 원인 파악 및 제거',
          ];
        case 'entropion':
          return [
            '즉시 수의사 상담 필요 (수술 필요할 수 있음)',
            '각막 손상 방지를 위한 안약 사용',
            '눈 비비는 행동 방지',
            '엘리자베스 칼라 착용 고려',
          ];
        case 'eyelid_tumor':
          return [
            '즉시 동물병원 방문하여 조직검사',
            '종양의 양성/악성 여부 확인 필요',
            '수술적 제거 고려',
            '정기적인 모니터링',
          ];
        case 'mastopathy':
          return [
            '동물병원 방문하여 정밀 검사',
            '호르몬 검사 필요',
            '중성화 수술 고려',
            '종양 가능성 배제를 위한 조직검사',
          ];
      }
    }

    // 강아지 피부 질환
    if (modelType == DiagnosisModelType.dogSkin) {
      switch (disease) {
        case 'bacterial dermatosis':
          return [
            '동물병원에서 항생제 처방 받기',
            '피부 청결 유지',
            '정기적인 목욕 및 그루밍',
            '감염 부위 긁지 않도록 주의',
          ];
        case 'fungal infection':
          return ['항진균제 처방 받기', '감염 부위 청결 유지', '다른 동물과의 접촉 피하기', '환경 소독 필요'];
        case 'healthy':
          return ['현재 피부 상태가 건강합니다', '정기적인 건강 검진 유지', '균형 잡힌 식단 유지'];
        case 'hypersensitivity dermatitis':
          return [
            '알레르기 원인 파악 필요',
            '항히스타민제 또는 스테로이드 처방 고려',
            '저알레르기 식단 시도',
            '환경 알레르겐 제거',
          ];
      }
    }

    // 고양이 피부 질환
    if (modelType == DiagnosisModelType.catSkin) {
      switch (disease) {
        case 'Alopecia':
          return [
            '스트레스 요인 파악 및 제거',
            '수의사 상담으로 원인 진단',
            '환경 개선 및 안정감 제공',
            '필요시 호르몬 검사',
          ];
        case 'Eosinophilic Plague':
          return [
            '즉시 수의사 진료 필요',
            '스테로이드 또는 면역조절제 처방 필요',
            '알레르기 원인 파악',
            '정기적인 추적 관찰',
          ];
        case 'Flea_Allergy':
          return ['벼룩 구제 프로그램 시작', '환경 벼룩 제거', '예방약 정기 투여', '가려움 완화를 위한 처방약'];
        case 'Health':
          return ['현재 피부 상태가 건강합니다', '정기적인 건강 검진 유지', '균형 잡힌 식단 유지'];
        case 'Miliary Dermatitis':
          return ['원인 파악을 위한 수의사 상담', '알레르기 검사 권장', '벼룩 예방 확인', '식이 알레르기 검사'];
        case 'Ringworm':
          return ['항진균제 처방 받기', '다른 동물/사람과 격리 필요', '환경 철저한 소독', '완치까지 치료 지속'];
        case 'Scabies':
          return ['즉시 수의사 진료 필요', '처방된 살충제 사용', '다른 동물과 격리', '환경 소독 필수'];
      }
    }

    // 고양이 눈 질환
    if (modelType == DiagnosisModelType.catEyes) {
      switch (disease) {
        case 'Blepharitis':
          return [
            '동물병원에서 항생제 또는 항염증제 처방 받기',
            '눈 주변 청결 유지',
            '온찜질로 증상 완화',
            '알레르기 원인 파악 및 제거',
          ];
        case 'Conjunctivitis':
          return [
            '동물병원 방문하여 원인 진단',
            '항생제 또는 항바이러스 안약 처방',
            '눈 주변 청결 유지',
            '다른 고양이와 접촉 제한',
          ];
        case 'Corneal Sequestrum':
          return [
            '즉시 안과 전문 수의사 진료 필요',
            '수술적 제거가 필요할 수 있음',
            '통증 관리를 위한 처방',
            '정기적인 추적 관찰',
          ];
        case 'Corneal Ulcer':
          return [
            '즉시 동물병원 방문 필요 (응급)',
            '항생제 안약 처방',
            '엘리자베스 칼라 착용',
            '눈 비비지 않도록 주의',
          ];
        case 'Health':
          return ['현재 눈 상태가 건강합니다', '정기적인 건강 검진 유지', '눈 주변 청결 유지'];
        case 'Non-ulcerative':
          return [
            '수의사 상담 권장',
            '인공눈물 사용 고려',
            '눈 자극 요인 제거',
            '정기적인 관찰',
          ];
      }
    }

    return ['가까운 동물병원 방문 권장', '정기적인 건강 검진'];
  }

  String _confidenceToSeverity(double confidence) {
    if (confidence >= 0.75) {
      return 'high';
    }
    if (confidence >= 0.5) {
      return 'medium';
    }
    return 'low';
  }

  /// 정상/건강 결과인지 확인
  bool _isHealthyResult(String rawLabel, DiagnosisModelType modelType) {
    // 각 모델별 정상 라벨
    final healthyLabels = {
      DiagnosisModelType.dogSkin: ['healthy'],
      DiagnosisModelType.catSkin: ['Health'],
      DiagnosisModelType.catEyes: ['Health'],
      // 강아지 눈 모델은 정상 라벨이 없음 (모든 결과가 질병)
      DiagnosisModelType.dogEyes: <String>[],
    };

    return healthyLabels[modelType]?.contains(rawLabel) ?? false;
  }

  // 진단 결과 저장
  Future<void> saveDiagnosis(AIDiagnosis diagnosis) async {
    _diagnoses.insert(0, diagnosis); // 최신 항목을 앞에 추가
  }

  // 진단 결과 삭제
  Future<void> deleteDiagnosis(String id) async {
    _diagnoses.removeWhere((d) => d.id == id);
  }
}
