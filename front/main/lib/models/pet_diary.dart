/// 펫 일기 모델
class PetDiary {
  final int? id;
  final int petId;
  final String petName;
  final DateTime date;
  final String content;
  final int? healthScore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PetDiary({
    this.id,
    required this.petId,
    required this.petName,
    required this.date,
    required this.content,
    this.healthScore,
    this.createdAt,
    this.updatedAt,
  });

  /// JSON에서 PetDiary 객체 생성
  factory PetDiary.fromJson(Map<String, dynamic> json) {
    return PetDiary(
      id: json['id'] as int?,
      petId: json['petId'] as int,
      petName: json['petName'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      content: json['content'] as String,
      healthScore: json['healthScore'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// PetDiary 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'petId': petId,
      'petName': petName,
      'date': date.toIso8601String(),
      'content': content,
      if (healthScore != null) 'healthScore': healthScore,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}
