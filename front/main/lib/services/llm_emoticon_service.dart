import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/llm_emoticon_request.dart';
import '../models/llm_emoticon_status.dart';
import 'openai_service.dart';

/// LLM 이모티콘 생성 서비스
class LlmEmoticonService {
  static final LlmEmoticonService _instance = LlmEmoticonService._internal();
  factory LlmEmoticonService() => _instance;
  LlmEmoticonService._internal();

  static const String baseUrl = 'http://223.130.130.225:9075';
  final OpenAIService _openAI = OpenAIService();

  /// 이모티콘 생성 요청 (비동기)
  ///
  /// 즉시 202 Accepted 응답을 받고, 백그라운드에서 LLM이 이미지를 생성합니다.
  /// 이후 [getRequestStatus]로 진행 상태를 확인해야 합니다.
  ///
  /// [userId]: 사용자 ID
  /// [petId]: 펫 ID (선택)
  /// [imageUrl]: 업로드된 원본 이미지 URL
  /// [promptMeta]: 프롬프트 메타데이터 (스타일, 감정 등)
  ///
  /// Returns: 생성된 요청 정보
  /// Throws: Exception on failure
  Future<LlmEmoticonRequest> createEmoticon({
    required int userId,
    int? petId,
    required String imageUrl,
    Map<String, dynamic>? promptMeta,
  }) async {
    try {
      print('🎨 이모티콘 생성 요청 중...');

      // OpenAI 초기화 및 이미지 생성
      _openAI.initialize();

      // 프롬프트 메타데이터에서 정보 추출
      final petName = promptMeta?['petName'] as String?;
      final petType = promptMeta?['petType'] as String?;
      final style = promptMeta?['style'] as String?;
      final emotion = promptMeta?['emotion'] as String?;
      final action = promptMeta?['action'] as String?;
      final customPrompt = promptMeta?['customPrompt'] as String?;

      print('📤 OpenAI DALL-E로 이미지 생성 시작...');
      if (customPrompt != null && customPrompt.isNotEmpty) {
        print('🎨 사용자 커스텀 프롬프트: $customPrompt');
      }

      final generatedImageUrl = await _openAI.generateEmoticonFromImage(
        imageUrl: imageUrl,
        petName: petName ?? '반려동물',
        petType: petType,
        style: style,
        emotion: emotion,
        action: action,
        customPrompt: customPrompt,
      );

      print('✅ OpenAI 이미지 생성 완료: $generatedImageUrl');

      final request = LlmEmoticonRequest(
        id: DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        petId: petId,
        imageUrl: imageUrl,
        promptMeta: promptMeta ?? {'style': 'cute', 'mood': 'happy'},
        status: EmoticonStatus.succeeded,
        generatedImageUrl: generatedImageUrl,
        createdAt: DateTime.now(),
      );

      print('✅ 이모티콘 생성 요청 성공 (ID: ${request.id})');
      return request;

      /* TODO: 백엔드 API 구현 후 아래 코드 활성화
      final requestBody = {
        'userId': userId,
        'petId': petId,
        'imageUrl': imageUrl,
        'promptMeta': promptMeta ?? {'style': 'cute', 'mood': 'happy'},
      };

      print('📤 요청 데이터: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/api/llm/emoticons/async'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 응답 코드: ${response.statusCode}');
      print('📥 응답 본문: ${response.body}');

      if (response.statusCode == 202 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final request = LlmEmoticonRequest.fromJson(data);
        print('✅ 이모티콘 생성 요청 성공 (ID: ${request.id})');
        return request;
      } else {
        final errorBody = response.body;
        print('❌ 이모티콘 생성 요청 실패: ${response.statusCode} - $errorBody');
        throw Exception('이모티콘 생성 요청 실패: ${response.statusCode}');
      }
      */
    } catch (e) {
      print('❌ 이모티콘 생성 오류: $e');
      rethrow;
    }
  }

  /// 이모티콘 생성 상태 조회 (폴링용)
  ///
  /// [requestId]: 조회할 요청 ID
  ///
  /// Returns: 최신 상태의 요청 정보
  /// Throws: Exception on failure
  Future<LlmEmoticonRequest> getRequestStatus(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/llm/emoticons/$requestId/status'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final request = LlmEmoticonRequest.fromJson(data);
        print(
          '📊 상태 조회 성공 (ID: $requestId, 상태: ${request.status.displayName})',
        );
        return request;
      } else {
        print('❌ 상태 조회 실패: ${response.statusCode}');
        throw Exception('상태 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 상태 조회 오류: $e');
      rethrow;
    }
  }

  /// 특정 이모티콘 요청 상세 조회
  ///
  /// [requestId]: 조회할 요청 ID
  Future<LlmEmoticonRequest> getRequest(int requestId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/llm/emoticons/$requestId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LlmEmoticonRequest.fromJson(data);
      } else {
        throw Exception('요청 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 요청 조회 오류: $e');
      rethrow;
    }
  }

  /// 사용자의 이모티콘 목록 조회
  ///
  /// [userId]: 사용자 ID
  /// [limit]: 최대 조회 개수 (기본 20개)
  ///
  /// Returns: 이모티콘 요청 목록
  Future<List<LlmEmoticonRequest>> getUserEmoticons({
    required int userId,
    int limit = 20,
  }) async {
    try {
      print('📋 사용자 이모티콘 목록 조회 중... (userId: $userId)');

      final response = await http.get(
        Uri.parse('$baseUrl/api/llm/emoticons/users/$userId?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final emoticons = data
            .map((json) => LlmEmoticonRequest.fromJson(json))
            .toList();
        print('✅ 이모티콘 목록 조회 성공 (${emoticons.length}개)');
        return emoticons;
      } else {
        print('❌ 목록 조회 실패: ${response.statusCode}');
        throw Exception('목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 목록 조회 오류: $e');
      rethrow;
    }
  }

  /// 펫의 이모티콘 목록 조회
  ///
  /// [petId]: 펫 ID
  ///
  /// Returns: 해당 펫의 이모티콘 요청 목록
  Future<List<LlmEmoticonRequest>> getPetEmoticons({required int petId}) async {
    try {
      print('📋 펫 이모티콘 목록 조회 중... (petId: $petId)');

      final response = await http.get(
        Uri.parse('$baseUrl/api/llm/emoticons/pets/$petId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final emoticons = data
            .map((json) => LlmEmoticonRequest.fromJson(json))
            .toList();
        print('✅ 펫 이모티콘 목록 조회 성공 (${emoticons.length}개)');
        return emoticons;
      } else {
        print('❌ 펫 목록 조회 실패: ${response.statusCode}');
        throw Exception('펫 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 펫 목록 조회 오류: $e');
      rethrow;
    }
  }

  /// 모든 이모티콘 목록 조회 (관리자용)
  ///
  /// [limit]: 최대 조회 개수
  Future<List<LlmEmoticonRequest>> getAllEmoticons({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/llm/emoticons?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LlmEmoticonRequest.fromJson(json)).toList();
      } else {
        throw Exception('전체 목록 조회 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 전체 목록 조회 오류: $e');
      rethrow;
    }
  }
}
