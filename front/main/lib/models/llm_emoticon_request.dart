import 'llm_emoticon_status.dart';

/// LLM 이모티콘 생성 요청/응답 모델
class LlmEmoticonRequest {
  /// 요청 ID
  final int? id;

  /// 사용자 ID
  final int userId;

  /// 펫 ID (선택)
  final int? petId;

  /// 원본 이미지 URL
  final String imageUrl;

  /// 프롬프트 메타데이터 (스타일, 감정 등)
  final Map<String, dynamic>? promptMeta;

  /// 현재 상태
  final EmoticonStatus status;

  /// 생성된 이모티콘 이미지 URL
  final String? generatedImageUrl;

  /// 실패 사유
  final String? failureReason;

  /// 생성 일시
  final DateTime? createdAt;

  /// 수정 일시
  final DateTime? updatedAt;

  LlmEmoticonRequest({
    this.id,
    required this.userId,
    this.petId,
    required this.imageUrl,
    this.promptMeta,
    this.status = EmoticonStatus.requested,
    this.generatedImageUrl,
    this.failureReason,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON → Dart 객체 변환
  factory LlmEmoticonRequest.fromJson(Map<String, dynamic> json) {
    return LlmEmoticonRequest(
      id: json['id'],
      userId: json['userId'],
      petId: json['petId'],
      imageUrl: json['imageUrl'],
      promptMeta: json['promptMeta'] != null
          ? Map<String, dynamic>.from(json['promptMeta'])
          : null,
      status: EmoticonStatus.fromString(json['status'] ?? 'REQUESTED'),
      generatedImageUrl: json['generatedImageUrl'],
      failureReason: json['failureReason'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Dart 객체 → JSON 변환 (요청용)
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'petId': petId,
      'imageUrl': imageUrl,
      'promptMeta': promptMeta ?? {},
    };
  }

  /// 진행률 계산 (0-100%)
  int get progress {
    switch (status) {
      case EmoticonStatus.requested:
        return 0;
      case EmoticonStatus.processing:
        return 50;
      case EmoticonStatus.succeeded:
      case EmoticonStatus.failed:
        return 100;
    }
  }

  /// 상태 메시지
  String get statusMessage {
    switch (status) {
      case EmoticonStatus.requested:
        return '대기 중...';
      case EmoticonStatus.processing:
        return 'AI가 이모티콘을 생성하고 있어요 🎨';
      case EmoticonStatus.succeeded:
        return '완료! 🎉';
      case EmoticonStatus.failed:
        return '실패: ${failureReason ?? "알 수 없는 오류"}';
    }
  }

  /// 완료 여부
  bool get isCompleted {
    return status == EmoticonStatus.succeeded ||
        status == EmoticonStatus.failed;
  }

  /// 성공 여부
  bool get isSucceeded {
    return status == EmoticonStatus.succeeded;
  }

  /// 실패 여부
  bool get isFailed {
    return status == EmoticonStatus.failed;
  }

  /// 진행 중 여부
  bool get isInProgress {
    return status == EmoticonStatus.requested ||
        status == EmoticonStatus.processing;
  }

  /// 복사본 생성 (불변 객체 업데이트용)
  LlmEmoticonRequest copyWith({
    int? id,
    int? userId,
    int? petId,
    String? imageUrl,
    Map<String, dynamic>? promptMeta,
    EmoticonStatus? status,
    String? generatedImageUrl,
    String? failureReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LlmEmoticonRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      petId: petId ?? this.petId,
      imageUrl: imageUrl ?? this.imageUrl,
      promptMeta: promptMeta ?? this.promptMeta,
      status: status ?? this.status,
      generatedImageUrl: generatedImageUrl ?? this.generatedImageUrl,
      failureReason: failureReason ?? this.failureReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
