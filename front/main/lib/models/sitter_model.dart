// 펫시터 데이터 모델
class SitterModel {
  final String id;
  final String name;
  final String sitterName;
  final String address;
  final String phone;
  final double rating;
  final List<String> services; // 제공 서비스 (산책, 돌봄, 호텔 등)
  final List<String> availableTimes; // 가능한 시간
  final double distance; // 거리 (km)
  final bool isAvailable; // 현재 예약 가능 여부
  final String imageUrl;
  final List<String> galleryImages; // 갤러리 이미지 목록
  final String description; // 펫시터 소개
  final List<String> certifications; // 자격증/인증 사항
  final String experience; // 경력
  final double? latitude; // 위도
  final double? longitude; // 경도

  SitterModel({
    required this.id,
    required this.name,
    required this.sitterName,
    required this.address,
    required this.phone,
    required this.rating,
    required this.services,
    required this.availableTimes,
    required this.distance,
    required this.isAvailable,
    required this.imageUrl,
    this.galleryImages = const [],
    required this.description,
    this.certifications = const [],
    this.experience = '',
    this.latitude,
    this.longitude,
  });

  // JSON에서 객체로 변환
  factory SitterModel.fromJson(Map<String, dynamic> json) {
    return SitterModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      sitterName: json['doctorName'] ?? json['sitterName'] ?? '',  // 백엔드는 doctorName 필드 사용
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      services: json['specialties'] != null  // 백엔드는 specialties 필드 사용
          ? (json['specialties'] is List
              ? List<String>.from(json['specialties'])
              : [])
          : (json['services'] != null
              ? (json['services'] is List
                  ? List<String>.from(json['services'])
                  : [])
              : []),
      availableTimes: json['availableTimes'] != null
          ? (json['availableTimes'] is List
              ? List<String>.from(json['availableTimes'])
              : [])
          : [],
      distance: (json['distance'] ?? 0.0).toDouble(),
      isAvailable: json['isOpen'] ?? json['isAvailable'] ?? true,  // 백엔드는 isOpen 필드 사용
      imageUrl: json['imageUrl'] ?? '',
      galleryImages: json['galleryImages'] != null
          ? (json['galleryImages'] is List
              ? List<String>.from(json['galleryImages'])
              : [])
          : [],
      description: json['description'] ?? '',
      certifications: json['certifications'] != null
          ? (json['certifications'] is List
              ? List<String>.from(json['certifications'])
              : [])
          : [],
      experience: json['experience'] ?? '3년',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
    );
  }

  // 객체를 JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sitterName': sitterName,
      'address': address,
      'phone': phone,
      'rating': rating,
      'services': services,
      'availableTimes': availableTimes,
      'distance': distance,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      'description': description,
      'certifications': certifications,
      'experience': experience,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
