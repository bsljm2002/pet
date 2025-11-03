// 사용자 모델 클래스
// ERD의 users 테이블 구조를 기반으로 작성
class User {
  final String id;
  final String username;
  final String email;
  final String password;
  final String? gender;
  final DateTime? birthdate;
  final String? address;
  final String? addressDetail;
  final String? addressNote;
  final UserType userType;
  final String? companyName; // 법인명 (파트너용)
  final String? businessNumber; // 사업자번호 (파트너용)

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.password,
    this.gender,
    this.birthdate,
    this.address,
    this.addressDetail,
    this.addressNote,
    required this.userType,
    this.companyName,
    this.businessNumber,
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'gender': gender,
      'birthdate': birthdate?.toIso8601String(),
      'address': address,
      'addressDetail': addressDetail,
      'addressNote': addressNote,
      'userType': userType.toString().split('.').last,
      'companyName': companyName,
      'businessNumber': businessNumber,
    };
  }

  // JSON에서 생성
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      gender: json['gender'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.parse(json['birthdate'] as String)
          : null,
      address: json['address'] as String?,
      addressDetail: json['addressDetail'] as String?,
      addressNote: json['addressNote'] as String?,
      userType: UserType.values.firstWhere(
        (e) => e.toString().split('.').last == json['userType'],
        orElse: () => UserType.general,
      ),
      companyName: json['companyName'] as String?,
      businessNumber: json['businessNumber'] as String?,
    );
  }

  // 복사본 생성 (불변성 유지)
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? password,
    String? gender,
    DateTime? birthdate,
    String? address,
    String? addressDetail,
    String? addressNote,
    UserType? userType,
    String? companyName,
    String? businessNumber,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      gender: gender ?? this.gender,
      birthdate: birthdate ?? this.birthdate,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
      addressNote: addressNote ?? this.addressNote,
      userType: userType ?? this.userType,
      companyName: companyName ?? this.companyName,
      businessNumber: businessNumber ?? this.businessNumber,
    );
  }
}

// 사용자 타입 Enum (ERD 기반)
enum UserType {
  general, // 일반 사용자
  seller, // 판매자
  hospital, // 병원
  grooming, // 미용실
  sitter, // 펫시터
  cafe, // 카페
}
