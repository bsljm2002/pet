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
  /// [customPrompt]: 사용자 커스텀 프롬프트 (우선순위 최상)
  Future<String> generateEmoticonFromImage({
    required String imageUrl,
    required String petName,
    String? petType,
    String? style,
    String? emotion,
    String? action,
    String? customPrompt,
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
        customPrompt: customPrompt,
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
    String? customPrompt,
  }) {
    // 기본 타입 설정
    final typeStr = petType ?? 'cute pet animal';

    // 감정 매핑 (한국어 감정을 영어로 변환)
    final emotionMap = {
      'joy': 'joyful and laughing with big smile',
      'happy': 'happy with bright smile',
      'love': 'loving with heart eyes',
      'surprised': 'surprised with wide open eyes and mouth',
      'angry': 'angry with furrowed brows',
      'flustered': 'flustered and confused',
      'shy': 'shy and blushing',
      'sleepy': 'sleepy with droopy eyes',
      'bored': 'bored with tired expression',
      'grumpy': 'grumpy and cranky',
      'cool': 'cool and confident',
      'cheering': 'cheering enthusiastically',
      'thankful': 'thankful and grateful',
      'curious': 'curious with questioning look',
      'playful': 'playful and mischievous',
      'excited': 'excited with sparkling eyes',
      'shocked': 'shocked and alarmed',
      'disappointed': 'disappointed and sad',
      'impressed': 'impressed and amazed',
      'moved': 'moved to tears emotionally',
      'neutral': 'neutral with blank expression',
      'deflated': 'deflated and defeated',
      'nervous': 'nervous and anxious',
      'serious': 'serious and focused',
      'funny': 'funny and silly',
      'trembling': 'trembling with intense emotion',
      'anticipating': 'anticipating with sparkling excitement',
      'dazed': 'dazed and dizzy',
    };

    final emotionStr = emotion != null
        ? emotionMap[emotion] ?? emotion
        : 'happy';

    // 커스텀 프롬프트가 있으면 추가 설명으로 활용
    final customDescription = customPrompt != null && customPrompt.isNotEmpty
        ? ' $customPrompt.'
        : '';

    return 'Create a KakaoTalk style animal emoticon sticker of a $typeStr. '
        'IMPORTANT: Only create emoticons of ANIMALS (pets like dogs, cats, birds, rabbits, etc.). '
        'Main emotion: The animal should be $emotionStr.$customDescription '
        'Design requirements: '
        '- Kawaii/chibi art style with oversized head (60% of body) and big expressive eyes '
        '- Bold black outlines for clarity and cuteness '
        '- Bright, vibrant, flat colors with slight gradients '
        '- Simple white or very light background '
        '- Centered composition, facing forward '
        '- EXAGGERATE the emotion - make it very clear and recognizable '
        '- Similar to popular Korean messaging app stickers (LINE Friends, KakaoTalk characters) '
        '- Friendly, adorable, and highly expressive '
        '- Square format, suitable for 360x360px display '
        '- MUST BE AN ANIMAL CHARACTER ONLY';
  }

  /// API 키 확인
  bool get hasApiKey => _apiKey.isNotEmpty;
}
