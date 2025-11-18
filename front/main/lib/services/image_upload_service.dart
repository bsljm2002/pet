import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';

/// 이미지 업로드 서비스
class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  static const String baseUrl = 'http://223.130.130.225:9075';

  /// 이미지 업로드
  ///
  /// [imageFile]: 업로드할 이미지 파일
  /// [userId]: 사용자 ID (ownerId로 사용)
  ///
  /// Returns: 업로드된 이미지의 전체 URL
  /// Throws: Exception on failure
  Future<String> uploadImage({
    required File imageFile,
    required int userId,
  }) async {
    try {
      // 1. 이미지 검증
      validateImage(imageFile);

      // 2. Multipart 요청 생성 (기존 Pet 이미지 업로드 API 사용)
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/v1/pets/image?ownerId=$userId'),
      );

      // 3. 파일 타입 결정
      String extension = imageFile.path.split('.').last.toLowerCase();
      MediaType contentType;

      switch (extension) {
        case 'jpg':
        case 'jpeg':
          contentType = MediaType('image', 'jpeg');
          break;
        case 'png':
          contentType = MediaType('image', 'png');
          break;
        case 'webp':
          contentType = MediaType('image', 'webp');
          break;
        default:
          contentType = MediaType('image', 'jpeg');
      }

      // 4. 파일 추가
      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: contentType,
      );
      request.files.add(multipartFile);

      // 5. 요청 전송
      print('📤 이미지 업로드 중: ${imageFile.path}');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // 6. 응답 처리
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['imageUrl'] as String;

        // 상대 URL을 절대 URL로 변환
        final fullUrl = imageUrl.startsWith('http')
            ? imageUrl
            : '$baseUrl$imageUrl';

        print('✅ 이미지 업로드 성공: $fullUrl');
        return fullUrl;
      } else {
        final errorBody = response.body;
        print('❌ 이미지 업로드 실패: ${response.statusCode} - $errorBody');
        throw Exception('이미지 업로드 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 이미지 업로드 오류: $e');
      rethrow;
    }
  }

  /// 이미지 파일 검증
  ///
  /// 최대 크기: 10MB
  /// 허용 형식: jpg, jpeg, png, webp
  ///
  /// Throws: Exception if validation fails
  void validateImage(File imageFile) {
    // 1. 파일 존재 확인
    if (!imageFile.existsSync()) {
      throw Exception('파일이 존재하지 않습니다');
    }

    // 2. 파일 크기 체크 (10MB = 10 * 1024 * 1024 bytes)
    final fileSize = imageFile.lengthSync();
    const maxSize = 10 * 1024 * 1024;

    if (fileSize > maxSize) {
      final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
      throw Exception('파일 크기가 너무 큽니다 (현재: ${sizeMB}MB, 최대: 10MB)');
    }

    // 3. 파일 확장자 체크
    final extension = imageFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

    if (!allowedExtensions.contains(extension)) {
      throw Exception(
        '지원하지 않는 파일 형식입니다\n'
        '지원 형식: JPEG, PNG, WebP',
      );
    }

    print(
      '✅ 이미지 검증 통과: ${extension.toUpperCase()}, ${(fileSize / 1024).toStringAsFixed(2)}KB',
    );
  }

  /// 이미지 삭제 (선택)
  ///
  /// [imageUrl]: 삭제할 이미지 URL
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // URL에서 경로 추출 (예: /uploads/emoticons/xxx.jpg)
      final uri = Uri.parse(imageUrl);
      final path = uri.path;

      final response = await http.delete(
        Uri.parse('$baseUrl/api/images$path'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        print('✅ 이미지 삭제 성공: $imageUrl');
        return true;
      } else {
        print('❌ 이미지 삭제 실패: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ 이미지 삭제 오류: $e');
      return false;
    }
  }

  /// 이미지 존재 여부 확인
  Future<bool> imageExists(String imageUrl) async {
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.path;

      final response = await http.get(
        Uri.parse('$baseUrl/api/images/exists$path'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['exists'] == true;
      }
      return false;
    } catch (e) {
      print('❌ 이미지 존재 확인 오류: $e');
      return false;
    }
  }
}
