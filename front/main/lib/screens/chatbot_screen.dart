import 'package:flutter/material.dart';
import '../services/openai_service.dart';

/// AI 챗봇 화면
class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAIService = OpenAIService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // OpenAI 서비스 초기화
    try {
      _openAIService.initialize();
    } catch (e) {
      print('OpenAI 초기화 실패: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // 대화 히스토리 구성 (최근 10개만)
      List<Map<String, String>> conversationHistory = [];
      int startIndex = _messages.length > 10 ? _messages.length - 10 : 0;

      for (int i = startIndex; i < _messages.length - 1; i++) {
        conversationHistory.add({
          'role': _messages[i].isUser ? 'user' : 'assistant',
          'content': _messages[i].text,
        });
      }

      // OpenAI API 호출 (스트리밍)
      String aiResponse = '';
      int aiMessageIndex = _messages.length;

      // AI 메시지 추가 (빈 메시지로 시작)
      setState(() {
        _messages.add(ChatMessage(
          text: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      await for (final chunk in _openAIService.sendMessageStream(
        message: userMessage,
        conversationHistory: conversationHistory,
      )) {
        if (mounted) {
          setState(() {
            aiResponse += chunk;
            _messages[aiMessageIndex] = ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            );
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: "죄송합니다. 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
            isUser: false,
            timestamp: DateTime.now(),
          ));
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 246, 240),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        foregroundColor: const Color.fromARGB(255, 0, 108, 82),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 0, 120, 89),
                    Color.fromARGB(255, 0, 108, 82),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI 펫케어 챗봇',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      color: Color.fromARGB(255, 0, 200, 150),
                      size: 6,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '온라인',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [
          // 메시지 리스트
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      margin: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 230, 249, 230),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: Color.fromARGB(255, 0, 108, 82),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            '반려동물에 대해 궁금한 점을 물어보세요!',
                            style: TextStyle(
                              color: Color.fromARGB(255, 0, 108, 82),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '건강, 훈련, 영양 등 무엇이든 물어보세요',
                            style: TextStyle(
                              color: Color.fromARGB(153, 0, 108, 82),
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      return _buildMessageBubble(_messages[index]);
                    },
                  ),
          ),

          // 로딩 인디케이터
          if (_isLoading && _messages.isNotEmpty && _messages.last.text.isEmpty)
            _buildLoadingIndicator(),

          // 메시지 입력창
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(13, 0, 0, 0),
                  blurRadius: 10,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: '메시지를 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 0, 108, 82),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 200, 200, 200),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: const BorderSide(
                          color: Color.fromARGB(255, 0, 108, 82),
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 0, 108, 82),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            const CircleAvatar(
              backgroundColor: Color.fromARGB(255, 0, 108, 82),
              radius: 16,
              child: Icon(
                Icons.pets,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color.fromARGB(255, 0, 108, 82)
                    : Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromARGB(13, 0, 0, 0),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Colors.black87,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color.fromARGB(255, 0, 108, 82),
              radius: 16,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color.fromARGB(255, 0, 108, 82),
            radius: 16,
            child: Icon(
              Icons.pets,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromARGB(13, 0, 0, 0),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 0, 108, 82),
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '답변 생성 중...',
                  style: TextStyle(
                    color: Color.fromARGB(178, 0, 108, 82),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
