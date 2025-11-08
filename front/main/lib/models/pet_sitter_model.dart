// 펫시터 데이터 모델
class PetSitterModel {
  final String id;
  final String name;
  final String? tagline;
  final double rating;
  final List<String> services;
  final List<String> availableTimes;
  final double distance;
  final bool isAvailable;
  final String imageUrl;
  final String description;
  final int experienceYears;
  final double pricePerHour;

  PetSitterModel({
    required this.id,
    required this.name,
    this.tagline,
    required this.rating,
    required this.services,
    required this.availableTimes,
    required this.distance,
    required this.isAvailable,
    required this.imageUrl,
    required this.description,
    required this.experienceYears,
    required this.pricePerHour,
  });

  factory PetSitterModel.fromJson(Map<String, dynamic> json) {
    return PetSitterModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      tagline: json['tagline'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      services: List<String>.from(json['services'] ?? []),
      availableTimes: List<String>.from(json['availableTimes'] ?? []),
      distance: (json['distance'] ?? 0.0).toDouble(),
      isAvailable: json['isAvailable'] ?? false,
      imageUrl: json['imageUrl'] ?? '',
      description: json['description'] ?? '',
      experienceYears: json['experienceYears'] ?? 0,
      pricePerHour: (json['pricePerHour'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tagline': tagline,
      'rating': rating,
      'services': services,
      'availableTimes': availableTimes,
      'distance': distance,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
      'description': description,
      'experienceYears': experienceYears,
      'pricePerHour': pricePerHour,
    };
  }
}
