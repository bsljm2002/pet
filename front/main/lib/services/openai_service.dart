import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// OpenAI API 서비스 (DALL-E 이미지 생성)
class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  static const String baseUrl = 'https://api.openai.com/v1';
  late String _apiKey;

  /// API 키 초기화
  void initialize() {
    // .env 파일에서 API 키 가져오기
    _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

    if (_apiKey.isEmpty) {
      print('⚠️ OPENAI_API_KEY가 .env 파일에 설정되지 않았습니다.');
    } else {
      print('✅ OpenAI API 키 로드 완료');
    }
  }

  /// DALL-E로 반려동물 이모티콘 생성
  ///
  /// [petName]: 반려동물 이름
  /// [petType]: 반려동물 종류 (강아지/고양이)
  /// [style]: 스타일 (cute, cartoon, realistic 등)
  /// [emotion]: 감정 (happy, sad, excited 등)
  /// [action]: 동작 (playing, sleeping, eating 등)
  ///
  /// Returns: 생성된 이미지 URL
  Future<String> generatePetEmoticon({
    required String petName,
    required String petType,
    String style = 'cute',
    String emotion = 'happy',
    String action = 'playing',
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenAI API 키가 설정되지 않았습니다.');
      }

      // 프롬프트 생성
      final prompt = _buildKakaoStylePrompt(
        petName: petName,
        petType: petType,
        style: style,
        emotion: emotion,
        action: action,
      );

      print('🎨 DALL-E 이미지 생성 중...');
      print('📝 프롬프트: $prompt');

      final response = await http.post(
        Uri.parse('$baseUrl/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
          'response_format': 'url',
        }),
      );

      print('📥 응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data'][0]['url'] as String;

        print('✅ 이미지 생성 성공: $imageUrl');
        return imageUrl;
      } else {
        final errorBody = response.body;
        print('❌ 이미지 생성 실패: ${response.statusCode} - $errorBody');
        throw Exception('이미지 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ OpenAI API 오류: $e');
      rethrow;
    }
  }

  /// 업로드된 이미지를 기반으로 이모티콘 생성
  ///
  /// [imageUrl]: 원본 이미지 URL
  /// [petName]: 반려동물 이름
  /// [petType]: 반려동물 종류
  /// [style]: 변환할 스타일
  /// [emotion]: 감정 표현
  /// [action]: 행동
  Future<String> generateEmoticonFromImage({
    required String imageUrl,
    required String petName,
    String? petType,
    String? style,
    String? emotion,
    String? action,
  }) async {
    try {
      if (_apiKey.isEmpty) {
        throw Exception('OpenAI API 키가 설정되지 않았습니다.');
      }

      // 이미지 기반 프롬프트 생성 (카카오 스타일)
      final prompt = _buildKakaoStylePrompt(
        petName: petName,
        petType: petType,
        style: style ?? 'cute',
        emotion: emotion,
        action: action,
      );

      print('🎨 이미지 기반 이모티콘 생성 중...');
      print('📝 프롬프트: $prompt');

      // Note: DALL-E 3는 이미지 편집을 지원하지 않으므로,
      // 텍스트 설명으로 유사한 이모티콘을 생성합니다.
      final response = await http.post(
        Uri.parse('$baseUrl/images/generations'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'dall-e-3',
          'prompt': prompt,
          'n': 1,
          'size': '1024x1024',
          'quality': 'standard',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['data'][0]['url'] as String;

        print('✅ 이모티콘 생성 성공: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('이미지 생성 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ OpenAI API 오류: $e');
      rethrow;
    }
  }

  /// 카카오톡 스타일 이모티콘 프롬프트 생성
  String _buildKakaoStylePrompt({
    required String petName,
    String? petType,
    required String style,
    String? emotion,
    String? action,
  }) {
    final typeStr = petType ?? 'pet';
    final emotionStr = emotion ?? 'happy';
    final actionStr = action ?? 'looking at camera';

    return 'Create a KakaoTalk style emoticon sticker of a $typeStr. '
        'Style: Cute, oversized head with big expressive eyes, simple rounded body proportions. '
        'Emotion: $emotionStr expression while $actionStr. '
        'Design requirements: '
        '- Kawaii/chibi art style with exaggerated facial features '
        '- Bold black outlines for clarity '
        '- Bright, vibrant, flat colors with slight gradients '
        '- Simple background or transparent-looking (use white/very light gray) '
        '- Centered composition, facing forward '
        '- Clear, easily recognizable emotion '
        '- Similar to popular Korean messaging app stickers (LINE Friends, KakaoTalk characters) '
        '- Friendly, adorable, and highly expressive '
        '- Square format, suitable for 360x360px display';
  }

  /// API 키 확인
  bool get hasApiKey => _apiKey.isNotEmpty;
}
