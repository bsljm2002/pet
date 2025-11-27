import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_database/firebase_database.dart';
import '../models/chat_room_model.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';

/// 채팅 서비스
class ChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  /// 사용자의 채팅방 목록 조회
  Future<List<ChatRoomModel>> getChatRooms(int userId, {bool isPartner = false}) async {
    try {
      final queryParam = isPartner ? 'partnerId=$userId' : 'userId=$userId';
      final url = Uri.parse(
        '${ApiService.baseUrl}/chat-rooms?$queryParam',
      );

      print('📡 [DEBUG] 채팅방 목록 조회 API 호출: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 [DEBUG] 응답 상태 코드: ${response.statusCode}');
      print('📡 [DEBUG] 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> chatRoomsList = jsonData['data'];
          return chatRoomsList.map((item) {
            return ChatRoomModel.fromJson(item);
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ 채팅방 목록 조회 오류: $e');
      return [];
    }
  }

  /// 채팅방의 메시지 스트림 가져오기 (실시간)
  Stream<List<ChatMessageModel>> getMessagesStream(int chatRoomId) {
    print('🔥 Firebase 스트림 시작: chat_rooms/$chatRoomId/messages');

    return _database
        .child('chat_rooms')
        .child(chatRoomId.toString())
        .child('messages')
        .onValue
        .map((event) {
      print('📨 Firebase 데이터 수신: ${event.snapshot.value}');

      final data = event.snapshot.value;
      if (data == null) {
        print('📭 메시지 없음');
        return <ChatMessageModel>[];
      }

      final messagesMap = data as Map<dynamic, dynamic>;
      final messages = messagesMap.entries.map((entry) {
        return ChatMessageModel.fromFirebase(
          entry.key.toString(),
          entry.value as Map<dynamic, dynamic>,
        );
      }).toList();

      // 시간순 정렬
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      print('✅ 메시지 ${messages.length}개 로드됨');
      return messages;
    }).handleError((error) {
      print('❌ Firebase 스트림 에러: $error');
      return Stream.value(<ChatMessageModel>[]);
    });
  }

  /// 메시지 전송
  Future<void> sendMessage({
    required int chatRoomId,
    required int senderId,
    required String senderType,
    required String message,
    String messageType = 'TEXT',
    String? imageUrl,
  }) async {
    try {
      final messageRef = _database
          .child('chat_rooms')
          .child(chatRoomId.toString())
          .child('messages')
          .push();

      final chatMessage = ChatMessageModel(
        id: messageRef.key!,
        chatRoomId: chatRoomId,
        senderId: senderId,
        senderType: senderType,
        message: message,
        messageType: messageType,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await messageRef.set(chatMessage.toFirebase());

      // 채팅방의 마지막 메시지 업데이트
      await _database.child('chat_rooms').child(chatRoomId.toString()).update({
        'lastMessage': message,
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ 메시지 전송 완료');
    } catch (e) {
      print('❌ 메시지 전송 오류: $e');
      rethrow;
    }
  }

  /// 메시지 읽음 처리
  Future<void> markMessagesAsRead(
    int chatRoomId,
    String senderType,
  ) async {
    try {
      final messagesSnapshot = await _database
          .child('chat_rooms')
          .child(chatRoomId.toString())
          .child('messages')
          .get();

      if (!messagesSnapshot.exists) return;

      final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>;
      final updates = <String, dynamic>{};

      messagesMap.forEach((key, value) {
        final messageData = value as Map<dynamic, dynamic>;
        // 상대방이 보낸 메시지만 읽음 처리
        if (messageData['senderType'] != senderType &&
            messageData['isRead'] == false) {
          updates['chat_rooms/$chatRoomId/messages/$key/isRead'] = true;
          updates['chat_rooms/$chatRoomId/messages/$key/readAt'] =
              DateTime.now().millisecondsSinceEpoch;
        }
      });

      if (updates.isNotEmpty) {
        await _database.update(updates);
        print('✅ 메시지 읽음 처리 완료: ${updates.length ~/ 2}개');
      }
    } catch (e) {
      print('❌ 메시지 읽음 처리 오류: $e');
    }
  }

  /// 읽지 않은 메시지 수 가져오기
  Future<int> getUnreadCount(int chatRoomId, String senderType) async {
    try {
      final messagesSnapshot = await _database
          .child('chat_rooms')
          .child(chatRoomId.toString())
          .child('messages')
          .get();

      if (!messagesSnapshot.exists) return 0;

      final messagesMap = messagesSnapshot.value as Map<dynamic, dynamic>;
      int unreadCount = 0;

      messagesMap.forEach((key, value) {
        final messageData = value as Map<dynamic, dynamic>;
        // 상대방이 보낸 메시지 중 읽지 않은 것만 카운트
        if (messageData['senderType'] != senderType &&
            messageData['isRead'] == false) {
          unreadCount++;
        }
      });

      return unreadCount;
    } catch (e) {
      print('❌ 읽지 않은 메시지 수 조회 오류: $e');
      return 0;
    }
  }
}
