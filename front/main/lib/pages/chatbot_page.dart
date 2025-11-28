import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import '../services/openai_service.dart';

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAIService = OpenAIService();
  late VideoPlayerController _videoController;
  late WebViewController _webViewController;
  bool _showIntro = true;
  bool _isVideoReady = false;
  bool _isWebViewReady = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _initializeWebView();
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset('assets/videos/intro.mp4')
      ..initialize().then((_) {
        setState(() {
          _isVideoReady = true;
        });
        _videoController.play();
        _videoController.setLooping(false);
        
        // 비디오가 끝나면 자동으로 채팅 화면으로 전환
        _videoController.addListener(() {
          if (_videoController.value.position >= _videoController.value.duration) {
            setState(() {
              _showIntro = false;
            });
          }
        });
      }).catchError((error) {
        print('Video initialization error: $error');
        // 비디오 로드 실패 시 바로 채팅 화면으로
        setState(() {
          _showIntro = false;
        });
      });
  }

  Future<void> _initializeWebView() async {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000));

    // HTML 파일 로드
    String htmlContent = await rootBundle.loadString('assets/html/star_animation.html');
    await _webViewController.loadHtmlString(htmlContent);
    
    setState(() {
      _isWebViewReady = true;
    });
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

    // 스크롤을 아래로
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
  void dispose() {
    _messageController.dispose();
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntro) {
      return _buildIntroScreen();
    }
    return _buildChatScreen();
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _isVideoReady
                ? AspectRatio(
                    aspectRatio: _videoController.value.aspectRatio,
                    child: VideoPlayer(_videoController),
                  )
                : const CircularProgressIndicator(
                    color: Colors.white,
                  ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _showIntro = false;
                });
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    return Scaffold(
      body: Stack(
        children: [
          // 배경 별 애니메이션
          if (_isWebViewReady)
            Positioned.fill(
              child: WebViewWidget(controller: _webViewController),
            ),

          // 채팅 UI (반투명 배경)
          Column(
            children: [
              // 챗봇 헤더
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Color.fromARGB(255, 250, 255, 250),
                      Colors.white,
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 8,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 0, 70, 51),
                            Color.fromARGB(255, 0, 56, 41),
                            Color.fromARGB(255, 0, 45, 33),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI 펫케어 챗봇',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 56, 41),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              color: Color.fromARGB(255, 0, 200, 150),
                              size: 8,
                            ),
                            SizedBox(width: 6),
                            Text(
                              '온라인',
                              style: TextStyle(
                                color: Color.fromARGB(255, 0, 120, 89),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 메시지 리스트
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.9),
                                Color.fromARGB(255, 250, 255, 250).withOpacity(0.8),
                                Colors.white.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.15),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                              BoxShadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 10,
                                offset: const Offset(0, -2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(255, 230, 249, 230),
                                      Color.fromARGB(255, 240, 255, 240),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.7),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '반려동물에 대해 궁금한 점을 물어보세요!',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 56, 41),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '건강, 훈련, 영양 등 무엇이든 물어보세요',
                                style: TextStyle(
                                  color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.6),
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
                        itemCount: _messages.length + (_isLoading && _messages.last.text.isEmpty ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index < _messages.length) {
                            return _buildMessageBubble(_messages[index]);
                          } else {
                            return _buildLoadingIndicator();
                          }
                        },
                      ),
              ),

              // 메시지 입력 필드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.95),
                      Color.fromARGB(255, 250, 255, 250).withOpacity(0.98),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 8,
                      offset: const Offset(0, -1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color.fromARGB(255, 240, 255, 240),
                              Color.fromARGB(255, 230, 249, 230),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.2),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: const TextStyle(
                            color: Color.fromARGB(255, 0, 56, 41),
                            fontSize: 15,
                          ),
                          decoration: InputDecoration(
                            hintText: '메시지를 입력하세요...',
                            hintStyle: TextStyle(
                              color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.5),
                              fontSize: 15,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 0, 70, 51),
                            Color.fromARGB(255, 0, 56, 41),
                            Color.fromARGB(255, 0, 45, 33),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                          BoxShadow(
                            color: Color.fromARGB(255, 0, 200, 150).withOpacity(0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: _isLoading 
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                        onPressed: _isLoading ? null : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 240, 255, 240),
                    Color.fromARGB(255, 230, 249, 230),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.pets, color: Color.fromARGB(255, 0, 56, 41), size: 20),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: message.isUser
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.fromARGB(255, 0, 70, 51),
                          Color.fromARGB(255, 0, 56, 41),
                          Color.fromARGB(255, 0, 45, 33),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Color.fromARGB(255, 252, 255, 252),
                        ],
                      ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: message.isUser 
                    ? Colors.transparent
                    : Color.fromARGB(255, 0, 56, 41).withOpacity(0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isUser
                        ? Color.fromARGB(255, 0, 56, 41).withOpacity(0.3)
                        : Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                  if (message.isUser)
                    BoxShadow(
                      color: Color.fromARGB(255, 0, 200, 150).withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  color: message.isUser ? Colors.white : Color.fromARGB(255, 0, 56, 41),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.4,
                ),
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 240, 255, 240),
                    Color.fromARGB(255, 230, 249, 230),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.person, color: Color.fromARGB(255, 0, 56, 41), size: 20),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromARGB(255, 240, 255, 240),
                  Color.fromARGB(255, 230, 249, 230),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.pets, color: Color.fromARGB(255, 0, 56, 41), size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Color.fromARGB(255, 252, 255, 252),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 0, 56, 41),
                    strokeWidth: 2,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '답변 생성 중...',
                  style: TextStyle(
                    color: Color.fromARGB(255, 0, 56, 41).withOpacity(0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
