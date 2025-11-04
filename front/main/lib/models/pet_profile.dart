// 펫 프로필 데이터 모델
class PetProfile {
  final String id;
  final String name;
  final String? imageUrl;
  final String? birthday;
  final String? breed;
  final String? disease;
  final String? gender;
  final String? abtiType;

  PetProfile({
    required this.id,
    required this.name,
    this.imageUrl,
    this.birthday,
    this.breed,
    this.disease,
    this.gender,
    this.abtiType,
  });

  // JSON 변환을 위한 메서드 (추후 데이터베이스 연동 시 사용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'birthday': birthday,
      'breed': breed,
      'disease': disease,
      'gender': gender,
      'abtiType': abtiType,
    };
  }

  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      birthday: json['birthday'],
      breed: json['breed'],
      disease: json['disease'],
      gender: json['gender'],
      abtiType: json['abtiType'],
    );
  }

  // 프로필 복사 (업데이트 시 사용)
  PetProfile copyWith({
    String? id,
    String? name,
    String? imageUrl,
    String? birthday,
    String? breed,
    String? disease,
    String? gender,
    String? abtiType,
  }) {
    return PetProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      birthday: birthday ?? this.birthday,
      breed: breed ?? this.breed,
      disease: disease ?? this.disease,
      gender: gender ?? this.gender,
      abtiType: abtiType ?? this.abtiType,
    );
  }
}
