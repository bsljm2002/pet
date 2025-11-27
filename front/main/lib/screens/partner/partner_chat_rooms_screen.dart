import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../services/auth_service.dart';
import '../../services/partner_service.dart';
import '../../models/chat_room_model.dart';
import '../../pages/chat_detail_page.dart';
import 'package:intl/intl.dart';

/// 파트너용 채팅방 목록 화면
class PartnerChatRoomsScreen extends StatefulWidget {
  const PartnerChatRoomsScreen({super.key});

  @override
  State<PartnerChatRoomsScreen> createState() => _PartnerChatRoomsScreenState();
}

class _PartnerChatRoomsScreenState extends State<PartnerChatRoomsScreen> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();
  final PartnerService _partnerService = PartnerService();
  List<ChatRoomModel> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final userId = int.parse(currentUser.id);
      print('📡 파트너 채팅방 목록 조회 시작 - User ID: $userId');

      // 파트너 프로필 가져오기 (존재 여부 확인용)
      final partners = await _partnerService.getMyPartners(userId);
      print('🔍 조회된 파트너 수: ${partners.length}');

      if (partners.isEmpty) {
        print('⚠️ 등록된 파트너 프로필이 없습니다');
        setState(() {
          _chatRooms = [];
          _isLoading = false;
        });
        return;
      }

      // 채팅방은 User ID로 조회 (ChatRoom.partnerId는 User ID를 저장함)
      print('🔍 채팅방 조회에 사용할 User ID: $userId');
      final chatRooms = await _chatService.getChatRooms(userId, isPartner: true);

      setState(() {
        _chatRooms = chatRooms;
        _isLoading = false;
      });

      print('✅ 채팅방 ${chatRooms.length}개 로드됨');
    } catch (e) {
      print('❌ 채팅방 목록 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('M월 d일').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _chatRooms.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '아직 채팅방이 없습니다',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '예약이 확정되면 자동으로 채팅방이 생성됩니다',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadChatRooms,
                  child: ListView.separated(
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (context, index) {
                      final chatRoom = _chatRooms[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: chatRoom.partnerImageUrl != null
                                  ? NetworkImage(chatRoom.partnerImageUrl!)
                                  : null,
                              child: chatRoom.partnerImageUrl == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 28,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                            if (chatRoom.unreadCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    chatRoom.unreadCount > 99
                                        ? '99+'
                                        : '${chatRoom.unreadCount}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
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
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: chatRoom.serviceType == 'HOSPITAL'
                                    ? Colors.blue[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                chatRoom.serviceTypeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: chatRoom.serviceType == 'HOSPITAL'
                                      ? Colors.blue[700]
                                      : Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              chatRoom.lastMessage ?? '채팅을 시작해보세요',
                              style: TextStyle(
                                fontSize: 14,
                                color: chatRoom.lastMessage == null
                                    ? Colors.grey[500]
                                    : Colors.grey[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: Text(
                          _formatTime(chatRoom.lastMessageTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailPage(
                                chatRoom: chatRoom,
                              ),
                            ),
                          );
                          // 채팅방에서 돌아오면 목록 새로고침
                          _loadChatRooms();
                        },
                      );
                    },
                  ),
                ),
    );
  }
}
