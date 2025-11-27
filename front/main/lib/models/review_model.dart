/// 리뷰 모델
class ReviewModel {
  final int id;
  final int partnerId;
  final String partnerName;
  final int userId;
  final String userName;
  final double rating;
  final String? content;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ReviewModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.userId,
    required this.userName,
    required this.rating,
    this.content,
    required this.createdAt,
    this.updatedAt,
  });

  /// JSON to Model
  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      partnerId: json['partnerId'],
      partnerName: json['partnerName'] ?? '',
      userId: json['userId'],
      userName: json['userName'] ?? '익명',
      rating: (json['rating'] as num).toDouble(),
      content: json['content'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  /// Model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partnerId': partnerId,
      'partnerName': partnerName,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// 작성일 표시용 (예: 2024.01.15)
  String get formattedDate {
    return '${createdAt.year}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.day.toString().padLeft(2, '0')}';
  }

  /// 작성일 표시용 상대시간 (예: 3일 전)
  String get relativeDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 30) {
      return formattedDate;
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }
}
