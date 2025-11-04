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
  });

  // JSON에서 객체로 변환
  factory VetModel.fromJson(Map<String, dynamic> json) {
    return VetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      doctorName: json['doctorName'],
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      specialties: List<String>.from(json['specialties'] ?? []),
      availableTimes: List<String>.from(json['availableTimes'] ?? []),
      distance: (json['distance'] ?? 0.0).toDouble(),
      isOpen: json['isOpen'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
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
    };
  }
}
