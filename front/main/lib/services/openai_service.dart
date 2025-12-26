import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class OpenAIService {
  static final OpenAIService _instance = OpenAIService._internal();
  factory OpenAIService() => _instance;
  OpenAIService._internal();

  bool _initialized = false;

  // OpenAI 초기화
  void initialize() {
    if (_initialized) return;
    
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API Key not found in .env file');
    }
    
    OpenAI.apiKey = apiKey;
    _initialized = true;
    print('✅ OpenAI Service initialized');
  }

  // 스트리밍 없이 한 번에 응답받기
  Future<String> sendMessage({
    required String message,
    List<Map<String, String>>? conversationHistory,
  }) async {
    try {
      if (!_initialized) initialize();

      // 대화 히스토리 구성
      List<OpenAIChatCompletionChoiceMessageModel> messages = [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(
              '''당신은 반려동물 케어 전문 AI 어시스턴트입니다.
사용자의 반려동물(강아지, 고양이 등)에 관한 질문에 친절하고 전문적으로 답변해주세요.

답변 가이드라인:
1. 따뜻하고 친근한 말투로 답변하세요
2. 전문적이면서도 이해하기 쉽게 설명하세요
3. 필요한 경우 구체적인 예시를 들어주세요
4. 응급 상황이나 심각한 증상인 경우 반드시 동물병원 방문을 권유하세요
5. 한국어로 답변하세요
6. 답변은 간결하게 3-4문장 정도로 작성하세요''',
            ),
          ],
          role: OpenAIChatMessageRole.system,
        ),
      ];

      // 이전 대화 히스토리 추가
      if (conversationHistory != null) {
        for (var msg in conversationHistory) {
          messages.add(
            OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  msg['content'] ?? '',
                ),
              ],
              role: msg['role'] == 'user' 
                  ? OpenAIChatMessageRole.user 
                  : OpenAIChatMessageRole.assistant,
            ),
          );
        }
      }

      // 현재 메시지 추가
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
          ],
          role: OpenAIChatMessageRole.user,
        ),
      );

      // OpenAI API 호출
      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.7,
        maxTokens: 500,
      );

      final response = chatCompletion.choices.first.message.content?.first.text ?? 
          '죄송합니다. 응답을 생성할 수 없습니다.';

      return response;
    } catch (e) {
      print('❌ OpenAI API Error: $e');
      return '죄송합니다. 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }

  // 스트리밍으로 응답받기 (타이핑 효과)
  Stream<String> sendMessageStream({
    required String message,
    List<Map<String, String>>? conversationHistory,
    String? petContext,
  }) async* {
    try {
      if (!_initialized) initialize();

      // 시스템 프롬프트 구성
      String systemPrompt = '''당신은 반려동물 케어 전문 AI 어시스턴트입니다.
사용자의 반려동물(강아지, 고양이 등)에 관한 질문에 친절하고 전문적으로 답변해주세요.

답변 가이드라인:
1. 따뜻하고 친근한 말투로 답변하세요
2. 전문적이면서도 이해하기 쉽게 설명하세요
3. 필요한 경우 구체적인 예시를 들어주세요
4. 응급 상황이나 심각한 증상인 경우 반드시 동물병원 방문을 권유하세요
5. 한국어로 답변하세요
6. 답변은 간결하게 3-4문장 정도로 작성하세요''';

      // 반려동물 정보가 있으면 추가
      if (petContext != null && petContext.isNotEmpty) {
        systemPrompt += '\n\n$petContext';
      }

      // 대화 히스토리 구성
      List<OpenAIChatCompletionChoiceMessageModel> messages = [
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt),
          ],
          role: OpenAIChatMessageRole.system,
        ),
      ];

      // 이전 대화 히스토리 추가
      if (conversationHistory != null) {
        for (var msg in conversationHistory) {
          messages.add(
            OpenAIChatCompletionChoiceMessageModel(
              content: [
                OpenAIChatCompletionChoiceMessageContentItemModel.text(
                  msg['content'] ?? '',
                ),
              ],
              role: msg['role'] == 'user' 
                  ? OpenAIChatMessageRole.user 
                  : OpenAIChatMessageRole.assistant,
            ),
          );
        }
      }

      // 현재 메시지 추가
      messages.add(
        OpenAIChatCompletionChoiceMessageModel(
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(message),
          ],
          role: OpenAIChatMessageRole.user,
        ),
      );

      // OpenAI API 스트리밍 호출
      final stream = OpenAI.instance.chat.createStream(
        model: 'gpt-4o-mini',
        messages: messages,
        temperature: 0.7,
        maxTokens: 500,
      );

      await for (final event in stream) {
        final content = event.choices.first.delta.content;
        if (content != null && content.isNotEmpty) {
          for (var item in content) {
            if (item?.text != null) {
              yield item!.text!;
            }
          }
        }
      }
    } catch (e) {
      print('❌ OpenAI Streaming Error: $e');
      yield '죄송합니다. 일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
    }
  }
}
