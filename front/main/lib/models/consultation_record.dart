/// 상담 내역 데이터 모델 (간편 상담)
class ConsultationRecord {
  final int id;
  final int userId;
  final String userName;
  final int partnerId;
  final String partnerName;
  final int? reservationId;  // 연결된 예약 ID (선택적)
  final String petType;      // 강아지 또는 고양이
  final String subject;      // 문의 주제
  final String content;      // 문의 내용
  final String? imageUrl;    // 첨부 이미지 URL (선택적)
  final String? answer;      // 파트너 답변
  final DateTime? answeredAt; // 답변 일시
  final String status;       // PENDING, ANSWERED, CLOSED, CANCELLED
  final String statusDescription; // 상태 한글 설명
  final DateTime createdAt;  // 작성일시

  const ConsultationRecord({
    required this.id,
    required this.userId,
    required this.userName,
    required this.partnerId,
    required this.partnerName,
    this.reservationId,
    required this.petType,
    required this.subject,
    required this.content,
    this.imageUrl,
    this.answer,
    this.answeredAt,
    required this.status,
    required this.statusDescription,
    required this.createdAt,
  });

  /// JSON에서 객체 생성
  factory ConsultationRecord.fromJson(Map<String, dynamic> json) {
    return ConsultationRecord(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String,
      partnerId: json['partnerId'] as int,
      partnerName: json['partnerName'] as String,
      reservationId: json['reservationId'] as int?,
      petType: json['petType'] as String,
      subject: json['subject'] as String,
      content: json['content'] as String,
      imageUrl: json['imageUrl'] as String?,
      answer: json['answer'] as String?,
      answeredAt: json['answeredAt'] != null
          ? DateTime.parse(json['answeredAt'] as String)
          : null,
      status: json['status'] as String,
      statusDescription: json['statusDescription'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 답변이 있는지 확인
  bool get hasAnswer => answer != null && answer!.isNotEmpty;

  /// 상태에 따른 한글 표시 (백엔드에서 제공하는 statusDescription 사용)
  String get statusText => statusDescription;
}
