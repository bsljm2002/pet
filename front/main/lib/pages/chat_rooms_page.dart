import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_room_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import 'chat_detail_page.dart';

/// 채팅방 목록 페이지
/// 확정된 예약에 대한 채팅방 목록 표시
class ChatRoomsPage extends StatefulWidget {
  const ChatRoomsPage({super.key});

  @override
  State<ChatRoomsPage> createState() => _ChatRoomsPageState();
}

class _ChatRoomsPageState extends State<ChatRoomsPage> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  List<ChatRoomModel> _chatRooms = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final userId = int.parse(currentUser.id);
      final chatRooms = await _chatService.getChatRooms(userId);

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '채팅방 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _ErrorView(
                  message: _errorMessage!,
                  onRetry: _loadChatRooms,
                )
              : _chatRooms.isEmpty
                  ? _EmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadChatRooms,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _chatRooms.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final chatRoom = _chatRooms[index];
                          return _ChatRoomTile(
                            chatRoom: chatRoom,
                            onTap: () async {
                              // 채팅 상세 페이지로 이동
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChatDetailPage(
                                    chatRoom: chatRoom,
                                  ),
                                ),
                              );
                              // 돌아왔을 때 목록 새로고침
                              _loadChatRooms();
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

/// 채팅방 타일
class _ChatRoomTile extends StatelessWidget {
  final ChatRoomModel chatRoom;
  final VoidCallback onTap;

  const _ChatRoomTile({
    required this.chatRoom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF4FC59E).withOpacity(0.2),
              backgroundImage: chatRoom.partnerImageUrl != null
                  ? NetworkImage(chatRoom.partnerImageUrl!)
                  : null,
              child: chatRoom.partnerImageUrl == null
                  ? Icon(
                      chatRoom.serviceType == 'HOSPITAL'
                          ? Icons.local_hospital
                          : Icons.pets,
                      color: const Color(0xFF4FC59E),
                      size: 28,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // 채팅방 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chatRoom.partnerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chatRoom.lastMessageTime != null)
                        Text(
                          _formatTime(chatRoom.lastMessageTime!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: chatRoom.serviceType == 'HOSPITAL'
                              ? Colors.blue.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          chatRoom.serviceTypeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: chatRoom.serviceType == 'HOSPITAL'
                                ? Colors.blue.shade700
                                : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          chatRoom.lastMessage ?? '채팅을 시작해보세요',
                          style: TextStyle(
                            fontSize: 14,
                            color: chatRoom.lastMessage != null
                                ? Colors.grey.shade700
                                : Colors.grey.shade400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 읽지 않은 메시지 배지
            if (chatRoom.unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  chatRoom.unreadCount > 99 ? '99+' : '${chatRoom.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      // 오늘: 시간만 표시
      return DateFormat('HH:mm').format(time);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM/dd').format(time);
    }
  }
}

/// 빈 화면
class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 18),
            const Text(
              '채팅방이 없습니다',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '예약이 확정되면 파트너와 채팅할 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 오류 화면
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC59E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
