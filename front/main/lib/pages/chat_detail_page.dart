import 'package:flutter/material.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class ChatDetailPage extends StatefulWidget {
  final ChatRoomModel chatRoom;

  const ChatDetailPage({
    super.key,
    required this.chatRoom,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  int? _currentUserId;
  String _currentUserType = 'USER';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = int.parse(user.id);
        // 파트너 사용자인지 확인
        // 파트너는 partnerId와 userId가 같고, chatRoom의 partnerId와 일치
        if (_currentUserId == widget.chatRoom.partnerId) {
          _currentUserType = 'PARTNER';
        } else {
          _currentUserType = 'USER';
        }
      });

      // 메시지 읽음 처리
      await _chatService.markMessagesAsRead(
        widget.chatRoom.id,
        _currentUserType,
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      print('🔥 메시지 전송 시작: chatRoomId=${widget.chatRoom.id}, senderId=$_currentUserId');

      await _chatService.sendMessage(
        chatRoomId: widget.chatRoom.id,
        senderId: _currentUserId!,
        senderType: _currentUserType,
        message: message,
      );

      print('✅ 메시지 전송 성공');
      _scrollToBottom();
    } catch (e, stackTrace) {
      print('❌ 메시지 전송 실패: $e');
      print('스택 트레이스: $stackTrace');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('메시지 전송 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // 메시지 복구
      _messageController.text = message;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.chatRoom.partnerName,
              style: const TextStyle(fontSize: 18),
            ),
            Text(
              widget.chatRoom.serviceTypeLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 메시지 목록
          Expanded(
            child: StreamBuilder<List<ChatMessageModel>>(
              stream: _chatService.getMessagesStream(widget.chatRoom.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('오류: ${snapshot.error}'),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      '메시지가 없습니다.\n첫 메시지를 보내보세요!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                // 메시지 로드 후 스크롤
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = _currentUserId != null &&
                        message.senderId == _currentUserId;

                    return _buildMessageBubble(message, isMine);
                  },
                );
              },
            ),
          ),

          // 메시지 입력 영역
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SafeArea(
              child: Row(
                children: [
                  // 텍스트 입력 필드
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: '메시지를 입력하세요',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // 전송 버튼
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessageModel message, bool isMine) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            // 상대방 프로필 이미지
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              backgroundImage: widget.chatRoom.partnerImageUrl != null
                  ? NetworkImage(widget.chatRoom.partnerImageUrl!)
                  : null,
              child: widget.chatRoom.partnerImageUrl == null
                  ? const Icon(Icons.person, size: 16)
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          // 메시지 내용
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isMine ? const Color(0xFF4CAF50) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: isMine ? Colors.white : Colors.black87,
                      fontSize: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (isMine && !message.isRead) ...[
                      const SizedBox(width: 4),
                      Text(
                        '1',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red[400],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isMine) const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      // 오늘: 시간만 표시
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      // 어제
      return '어제 ${DateFormat('HH:mm').format(dateTime)}';
    } else if (difference.inDays < 7) {
      // 일주일 이내: 요일 표시
      final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
      final weekday = weekdays[dateTime.weekday - 1];
      return '$weekday요일 ${DateFormat('HH:mm').format(dateTime)}';
    } else {
      // 그 외: 전체 날짜
      return DateFormat('M월 d일 HH:mm').format(dateTime);
    }
  }
}
