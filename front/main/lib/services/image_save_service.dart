import 'dart:io';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// 이미지 갤러리 저장 서비스
class ImageSaveService {
  static final ImageSaveService _instance = ImageSaveService._internal();
  factory ImageSaveService() => _instance;
  ImageSaveService._internal();

  final Dio _dio = Dio();

  /// URL에서 이미지 다운로드 후 갤러리에 저장
  ///
  /// [imageUrl]: 다운로드할 이미지 URL
  ///
  /// Returns: 저장 성공 여부
  Future<bool> saveImageFromUrl({required String imageUrl}) async {
    try {
      print('📥 이미지 저장 시작: $imageUrl');

      // 1. 권한 확인 및 요청
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        print('⚠️ 갤러리 접근 권한 요청 중...');
        final granted = await Gal.requestAccess();
        if (!granted) {
          print('❌ 갤러리 접근 권한이 거부되었습니다.');
          throw Exception('갤러리 접근 권한이 필요합니다.');
        }
      }

      // 2. 임시 디렉토리에 이미지 다운로드
      print('⬇️ 이미지 다운로드 중...');
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/emoticon_$timestamp.png';

      await _dio.download(
        imageUrl,
        filePath,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
        ),
      );

      print('✅ 이미지 다운로드 완료');

      // 3. 갤러리에 저장
      print('💾 갤러리에 저장 중...');
      await Gal.putImage(filePath);

      // 4. 임시 파일 삭제
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      print('✅ 갤러리 저장 성공!');
      return true;
    } catch (e) {
      print('❌ 이미지 저장 오류: $e');
      return false;
    }
  }
}
