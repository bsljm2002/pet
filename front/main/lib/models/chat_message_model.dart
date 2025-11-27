class ChatMessageModel {
  final String id;
  final int chatRoomId;
  final int senderId;
  final String senderType; // 'USER' or 'PARTNER'
  final String message;
  final String messageType; // 'TEXT' or 'IMAGE'
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final DateTime? readAt;

  ChatMessageModel({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.senderType,
    required this.message,
    this.messageType = 'TEXT',
    this.imageUrl,
    required this.createdAt,
    this.isRead = false,
    this.readAt,
  });

  // Firebase에서 데이터 가져올 때
  factory ChatMessageModel.fromFirebase(String id, Map<dynamic, dynamic> data) {
    return ChatMessageModel(
      id: id,
      chatRoomId: data['chatRoomId'] as int,
      senderId: data['senderId'] as int,
      senderType: data['senderType'] as String,
      message: data['message'] as String,
      messageType: data['messageType'] as String? ?? 'TEXT',
      imageUrl: data['imageUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int),
      isRead: data['isRead'] as bool? ?? false,
      readAt: data['readAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(data['readAt'] as int)
          : null,
    );
  }

  // Firebase에 저장할 때
  Map<String, dynamic> toFirebase() {
    return {
      'chatRoomId': chatRoomId,
      'senderId': senderId,
      'senderType': senderType,
      'message': message,
      'messageType': messageType,
      'imageUrl': imageUrl,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isRead': isRead,
      'readAt': readAt?.millisecondsSinceEpoch,
    };
  }

  // 읽음 처리를 위한 copyWith
  ChatMessageModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return ChatMessageModel(
      id: id,
      chatRoomId: chatRoomId,
      senderId: senderId,
      senderType: senderType,
      message: message,
      messageType: messageType,
      imageUrl: imageUrl,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  // 내가 보낸 메시지인지 확인
  bool isMine(int currentUserId) {
    return senderId == currentUserId;
  }
}
