// 펫 프로필 데이터 모델
class PetProfile {
  final int? id;
  final int? userId; // nullable로 변경 (백엔드에서 Long 타입)
  final String name;
  final String species; // 종
  final String? imageUrl; // 사진
  final String birthdate; // 생일
  final double weight; //몸무게
  final String? speciesDetail; // 품종
  final String? gender;
  final String? disease; // 질병

  PetProfile({
    this.id, // nullable (백엔드에서 자동 생성)
    this.userId, // nullable로 변경
    required this.name, // 필수
    required this.species, // 필수
    required this.birthdate, // 필수
    required this.weight, // 필수
    this.gender, // nullable로 변경
    this.speciesDetail, // 품종
    this.imageUrl, // 선택사항
    this.disease, // 질병
  });

  // 생년월일에서 나이 계산
  int? get age {
    try {
      final birth = DateTime.parse(birthdate);
      final now = DateTime.now();
      int age = now.year - birth.year;
      if (now.month < birth.month || (now.month == birth.month && now.day < birth.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return null;
    }
  }

  // PetProfile 객체 -> JSON 변환 (백엔드 요청 전송용)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'species': species,
      'birthdate': birthdate,
      'weight': weight,
      'gender': gender,
      'speciesDetail': speciesDetail,
      'imageUrl': imageUrl,
      'disease': disease,
    };
  }

  // JSON -> PetProfile 객체로 변환 (백엔드 응답 파싱용)
  factory PetProfile.fromJson(Map<String, dynamic> json) {
    return PetProfile(
      id: json['id'] as int?, // nullable 처리
      userId: json['userId'] as int?, // nullable 처리
      name: json['name'] as String? ?? '', // null일 경우 빈 문자열
      species: json['species'] as String? ?? '', // null일 경우 빈 문자열
      birthdate: json['birthdate'] as String? ?? '', // null일 경우 빈 문자열
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0, // null일 경우 0.0
      gender: json['gender'] as String?, // nullable
      speciesDetail: json['speciesDetail'] as String?, // 품종
      imageUrl: json['imageUrl'] as String?, // nullable
      disease: json['disease'] as String?, // 질병
    );
  }

  // 프로필 복사 메서드 (업데이트 시 사용)
  PetProfile copyWith({
    int? id,
    int? userId,
    String? name,
    String? species,
    String? birthdate,
    double? weight,
    String? gender,
    String? speciesDetail,
    String? imageUrl,
    String? disease,
  }) {
    return PetProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      species: species ?? this.species,
      birthdate: birthdate ?? this.birthdate,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      speciesDetail: speciesDetail ?? this.speciesDetail,
      imageUrl: imageUrl ?? this.imageUrl,
      disease: disease ?? this.disease,
    );
  }
}
