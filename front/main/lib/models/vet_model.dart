// 수의사/병원 데이터 모델
class VetModel {
  final String id;
  final String name;
  final String? doctorName;
  final String address;
  final String phone;
  final double rating;
  final List<String> specialties; // 진료 과목
  final List<String> availableTimes; // 가능한 시간
  final double distance; // 거리 (km)
  final bool isOpen; // 현재 영업 여부
  final String imageUrl;
  final List<String> galleryImages; // 갤러리 이미지들
  final String description; // 수의사/병원 소개
  final List<String> education; // 학력 사항
  final String experience; // 경력
  final List<String> certifications; // 자격증
  final double? latitude; // 위도
  final double? longitude; // 경도
  final List<String> workingDays; // 근무 요일 (예: ["MONDAY", "TUESDAY"])
  final String? workingStartHours; // 근무 시작 시간 (예: "09:00")
  final String? workingEndHours; // 근무 종료 시간 (예: "18:00")

  VetModel({
    required this.id,
    required this.name,
    this.doctorName,
    required this.address,
    required this.phone,
    required this.rating,
    required this.specialties,
    required this.availableTimes,
    required this.distance,
    required this.isOpen,
    required this.imageUrl,
    this.galleryImages = const [],
    required this.description,
    this.education = const [],
    this.experience = '',
    this.certifications = const [],
    this.latitude,
    this.longitude,
    this.workingDays = const [],
    this.workingStartHours,
    this.workingEndHours,
  });

  // JSON에서 객체로 변환
  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      doctorName: json['doctorName'],
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      specialties: json['specialties'] != null
          ? (json['specialties'] is List
              ? List<String>.from(json['specialties'])
              : [])
          : [],
      availableTimes: json['availableTimes'] != null
          ? (json['availableTimes'] is List
              ? List<String>.from(json['availableTimes'])
              : [])
          : [],
      distance: (json['distance'] ?? 0.0).toDouble(),
      isOpen: json['isOpen'] ?? true,
      imageUrl: json['imageUrl'] ?? '',
      galleryImages: json['galleryImages'] != null
          ? (json['galleryImages'] is List
              ? List<String>.from(json['galleryImages'])
              : [])
          : [],
      description: json['description'] ?? '',
      education: json['education'] != null
          ? (json['education'] is List
              ? List<String>.from(json['education'])
              : [])
          : [],
      experience: json['experience'] ?? '',
      certifications: json['certifications'] != null
          ? (json['certifications'] is List
              ? List<String>.from(json['certifications'])
              : [])
          : [],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      workingDays: json['workingDays'] != null
          ? (json['workingDays'] is List
              ? List<String>.from(json['workingDays'])
              : [])
          : [],
      workingStartHours: json['workingStartHours'] as String?,
      workingEndHours: json['workingEndHours'] as String?,
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'doctorName': doctorName,
      'address': address,
      'phone': phone,
      'rating': rating,
      'specialties': specialties,
      'availableTimes': availableTimes,
      'distance': distance,
      'isOpen': isOpen,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'description': description,
      'education': education,
      'experience': experience,
      'certifications': certifications,
      'latitude': latitude,
      'longitude': longitude,
      'workingDays': workingDays,
      'workingStartHours': workingStartHours,
      'workingEndHours': workingEndHours,
    };
  }
}
