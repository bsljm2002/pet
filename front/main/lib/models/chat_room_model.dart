/// 채팅방 모델
class ChatRoomModel {
  final int id;
  final int reservationId; // 연결된 예약 ID
  final int userId; // 사용자 ID
  final int partnerId; // 파트너 ID
  final String partnerName; // 파트너 이름
  final String? partnerImageUrl; // 파트너 프로필 이미지
  final String? lastMessage; // 마지막 메시지
  final DateTime? lastMessageTime; // 마지막 메시지 시간
  final int unreadCount; // 읽지 않은 메시지 수
  final String serviceType; // HOSPITAL or SITTER
  final DateTime createdAt; // 채팅방 생성 시간
  final String? reservationStatus; // 예약 상태 (CONFIRMED, ACCEPTED, COMPLETED 등)

  ChatRoomModel({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.partnerId,
    required this.partnerName,
    this.partnerImageUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.serviceType,
    required this.createdAt,
    this.reservationStatus,
  });

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      id: json['id'] ?? 0,
      reservationId: json['reservationId'] ?? 0,
      userId: json['userId'] ?? 0,
      partnerId: json['partnerId'] ?? 0,
      partnerName: json['partnerName'] ?? '',
      partnerImageUrl: json['partnerImageUrl'],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      serviceType: json['serviceType'] ?? 'SITTER',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      reservationStatus: json['reservationStatus'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservationId': reservationId,
      'userId': userId,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'partnerImageUrl': partnerImageUrl,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'unreadCount': unreadCount,
      'serviceType': serviceType,
      'createdAt': createdAt.toIso8601String(),
      'reservationStatus': reservationStatus,
    };
  }

  /// 서비스 타입 한글 표시
  String get serviceTypeLabel {
    switch (serviceType) {
      case 'HOSPITAL':
        return '병원';
      case 'SITTER':
        return '펫시터';
      default:
        return serviceType;
    }
  }
}
