import 'package:flutter/material.dart';
import '../services/openai_service.dart';
import '../services/chat_history_service.dart';
import '../services/auth_service.dart';
import '../services/pet_service.dart';
import '../services/medical_record_service.dart';
import '../models/pet_profile.dart';
import '../models/medical_record.dart';
import 'chat_history_screen.dart';

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
  final ChatHistoryService _chatHistoryService = ChatHistoryService();
  final AuthService _authService = AuthService();
  final PetService _petService = PetService();
  final MedicalRecordService _medicalRecordService = MedicalRecordService();
  bool _isLoading = false;
  String? _currentSessionId;
  String? _petContext; // 반려동물 정보 컨텍스트

  @override
  void initState() {
    super.initState();
    // OpenAI 서비스 초기화
    try {
      _openAIService.initialize();
    } catch (e) {
      print('OpenAI 초기화 실패: $e');
    }
    // 사용자 ID 설정 및 세션 생성
    _initializeChatSession();
  }

  Future<void> _initializeChatSession() async {
    // 로그인한 사용자 ID를 ChatHistoryService에 설정
    if (_authService.currentUser != null) {
      final userId = int.tryParse(_authService.currentUser!.id);
      _chatHistoryService.setUserId(userId);
      print('✅ ChatHistoryService - 사용자 ID 설정: $userId');

      // 반려동물 정보 및 진료 기록 로드
      await _loadPetContext(userId!);
    } else {
      print('⚠️ ChatHistoryService - 로그인되지 않음, 로컬 저장 모드');
    }

    // 1. 먼저 저장된 세션 목록 확인
    final sessions = await _chatHistoryService.getAllSessions();

    if (sessions.isNotEmpty) {
      // 가장 최근 세션의 ID만 설정 (화면에는 표시 안 함)
      final latestSession = sessions.first;
      setState(() {
        _currentSessionId = latestSession.id;
        // _messages는 비워둠 - 깨끗한 UI
      });
      print('✅ 기존 세션 연결: ${latestSession.title} (ID: ${latestSession.id})');
      print('💡 화면은 비어있지만 AI는 이전 대화를 기억합니다');
      return;
    }

    // 2. 기존 세션이 없으면 새 세션 생성
    print('🆕 새 세션 생성 중...');
    final session = await _chatHistoryService.createSession();
    setState(() {
      _currentSessionId = session.id;
    });
    print('✅ 새 챗봇 세션 생성: ${session.id}');
  }

  /// 반려동물 정보 및 진료 기록 로드
  Future<void> _loadPetContext(int userId) async {
    try {
      // 1. 사용자의 반려동물 목록 조회
      final petResult = await _petService.getPetsByOwner(userId.toString());

      if (petResult['success'] != true || petResult['pets'] == null) {
        print('⚠️ 등록된 반려동물이 없습니다');
        return;
      }

      final List<dynamic> petsData = petResult['pets'];
      if (petsData.isEmpty) {
        print('⚠️ 반려동물 목록이 비어있습니다');
        return;
      }

      // 2. 모든 반려동물 정보 가져오기
      StringBuffer allPetsContext = StringBuffer();

      for (int i = 0; i < petsData.length; i++) {
        final PetProfile pet = PetProfile.fromJson(petsData[i]);

        // 3. 해당 반려동물의 진료 기록 조회
        final List<MedicalRecord> medicalRecords =
            await _medicalRecordService.getPetMedicalRecords(pet.id!);

        // 4. 각 반려동물의 컨텍스트 문자열 생성
        String petContext = _buildPetContextString(pet, medicalRecords, i + 1);
        allPetsContext.write(petContext);

        // 마지막이 아니면 구분선 추가
        if (i < petsData.length - 1) {
          allPetsContext.write('\n${'=' * 50}\n\n');
        }

        print('✅ 반려동물 정보 로드 완료 ${i + 1}: ${pet.name}');
        print('📋 진료 기록: ${medicalRecords.length}건');
      }

      setState(() {
        _petContext = allPetsContext.toString();
      });

      print('✅ 총 ${petsData.length}마리의 반려동물 정보 로드 완료');
    } catch (e) {
      print('❌ 반려동물 정보 로드 실패: $e');
    }
  }

  /// 반려동물 정보를 AI가 이해할 수 있는 텍스트로 변환
  String _buildPetContextString(PetProfile pet, List<MedicalRecord> medicalRecords, [int? petNumber]) {
    StringBuffer context = StringBuffer();

    if (petNumber != null) {
      context.writeln('=== 반려동물 #$petNumber 정보 ===');
    } else {
      context.writeln('=== 사용자의 반려동물 정보 ===');
    }
    context.writeln('이름: ${pet.name}');
    context.writeln('종: ${pet.species == "DOG" ? "강아지" : "고양이"}');
    if (pet.speciesDetail != null && pet.speciesDetail!.isNotEmpty) {
      context.writeln('품종: ${pet.speciesDetail}');
    }
    if (pet.age != null) {
      context.writeln('나이: ${pet.age}살');
    }
    context.writeln('생일: ${pet.birthdate}');
    context.writeln('성별: ${pet.gender == "MALE" ? "수컷" : "암컷"}');
    context.writeln('몸무게: ${pet.weight}kg');
    if (pet.disease != null && pet.disease!.isNotEmpty) {
      context.writeln('질병/특이사항: ${pet.disease}');
    }

    // 진료 기록 추가 (최근 3개만)
    if (medicalRecords.isNotEmpty) {
      context.writeln('\n=== 최근 진료 기록 ===');
      final recentRecords = medicalRecords.take(3).toList();

      for (int i = 0; i < recentRecords.length; i++) {
        final record = recentRecords[i];
        context.writeln('${i + 1}. ${record.createdAt.toString().substring(0, 10)} - ${record.partnerName}');

        if (record.diagnosis != null && record.diagnosis!.isNotEmpty) {
          context.writeln('   진단: ${record.diagnosis}');
        }
        if (record.prescription != null && record.prescription!.isNotEmpty) {
          context.writeln('   처방약: ${record.prescription}');
        }
        if (record.dosageSchedule != null && record.dosageDays != null) {
          context.writeln('   복용: ${record.dosageScheduleFormatted} / ${record.dosageDaysFormatted}');
        }
      }
    }

    context.writeln('\n위 정보를 참고하여 ${pet.name}에 대한 개인화된 조언을 제공해주세요.');

    return context.toString();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isLoading || _currentSessionId == null) return;

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

    // DB에 사용자 메시지 저장
    try {
      print('💾 메시지 저장 시도 - 세션: $_currentSessionId, 사용자ID: ${_chatHistoryService.currentUserId}');
      await _chatHistoryService.addMessage(
        _currentSessionId!,
        ChatMessageData(
          text: userMessage,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      print('✅ 사용자 메시지 저장 완료');
    } catch (e) {
      print('❌ 사용자 메시지 저장 실패: $e');
    }

    _scrollToBottom();

    try {
      // DB에서 현재 세션의 전체 대화 히스토리 가져오기
      List<Map<String, String>> conversationHistory = [];

      final session = await _chatHistoryService.getSession(_currentSessionId!);
      if (session != null && session.messages.isNotEmpty) {
        // DB에서 가져온 메시지를 OpenAI 형식으로 변환 (최근 20개만)
        final recentMessages = session.messages.length > 20
            ? session.messages.sublist(session.messages.length - 20)
            : session.messages;

        conversationHistory = recentMessages.map((msg) => {
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.text,
        }).toList();

        print('💬 DB에서 불러온 대화 히스토리: ${conversationHistory.length}개');
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
        petContext: _petContext, // 반려동물 정보 전달
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

      // AI 응답 완료 후 DB에 저장
      if (aiResponse.isNotEmpty) {
        try {
          await _chatHistoryService.addMessage(
            _currentSessionId!,
            ChatMessageData(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
        } catch (e) {
          print('AI 응답 저장 실패: $e');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
            },
            tooltip: '대화 기록',
          ),
        ],
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
