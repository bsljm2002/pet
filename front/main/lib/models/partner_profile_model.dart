/// 파트너 프로필 모델 (등록/수정용)
class PartnerProfileModel {
  final int? id;
  final String partnerType; // "HOSPITAL" or "SITTER"
  final String name;
  final String? doctorName;
  final String address;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String? imageUrl;
  final List<String> galleryImages;
  final String? description;
  final List<String> specialties;
  final List<String> availableTimes;
  final List<String> education;
  final String? experience;
  final List<String> certifications;
  final double rating;
  final bool isOpen;
  final int? userId;
  final List<String> workingDays;
  final String? workingStartHours;
  final String? workingEndHours;

  PartnerProfileModel({
    this.id,
    required this.partnerType,
    required this.name,
    this.doctorName,
    required this.address,
    this.latitude,
    this.longitude,
    required this.phone,
    this.imageUrl,
    this.galleryImages = const [],
    this.description,
    this.specialties = const [],
    this.availableTimes = const [],
    this.education = const [],
    this.experience,
    this.certifications = const [],
    this.rating = 0.0,
    this.isOpen = true,
    this.userId,
    this.workingDays = const [],
    this.workingStartHours,
    this.workingEndHours,
  });

  factory PartnerProfileModel.fromJson(Map<String, dynamic> json) {
    return PartnerProfileModel(
      id: json['id'],
      partnerType: json['partnerType'] ?? 'HOSPITAL',
      name: json['name'] ?? '',
      doctorName: json['doctorName'],
      address: json['address'] ?? '',
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'],
      galleryImages: json['galleryImages'] != null
          ? List<String>.from(json['galleryImages'])
          : [],
      description: json['description'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      availableTimes: json['availableTimes'] != null
          ? List<String>.from(json['availableTimes'])
          : [],
      education: json['education'] != null
          ? List<String>.from(json['education'])
          : [],
      experience: json['experience'],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      isOpen: json['isOpen'] ?? true,
      userId: json['userId'],
      workingDays: json['workingDays'] != null
          ? List<String>.from(json['workingDays'])
          : [],
      workingStartHours: json['workingStartHours'],
      workingEndHours: json['workingEndHours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'partnerType': partnerType,
      'name': name,
      if (doctorName != null) 'doctorName': doctorName,
      'address': address,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'phone': phone,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'galleryImages': galleryImages,
      if (description != null) 'description': description,
      'specialties': specialties,
      'availableTimes': availableTimes,
      'education': education,
      if (experience != null) 'experience': experience,
      'certifications': certifications,
      'isOpen': isOpen,
      if (userId != null) 'userId': userId,
    };
  }

  PartnerProfileModel copyWith({
    int? id,
    String? partnerType,
    String? name,
    String? doctorName,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? imageUrl,
    List<String>? galleryImages,
    String? description,
    List<String>? specialties,
    List<String>? availableTimes,
    List<String>? education,
    String? experience,
    List<String>? certifications,
    double? rating,
    bool? isOpen,
    int? userId,
    List<String>? workingDays,
    String? workingStartHours,
    String? workingEndHours,
  }) {
    return PartnerProfileModel(
      id: id ?? this.id,
      partnerType: partnerType ?? this.partnerType,
      name: name ?? this.name,
      doctorName: doctorName ?? this.doctorName,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryImages: galleryImages ?? this.galleryImages,
      description: description ?? this.description,
      specialties: specialties ?? this.specialties,
      availableTimes: availableTimes ?? this.availableTimes,
      education: education ?? this.education,
      experience: experience ?? this.experience,
      certifications: certifications ?? this.certifications,
      rating: rating ?? this.rating,
      isOpen: isOpen ?? this.isOpen,
      userId: userId ?? this.userId,
      workingDays: workingDays ?? this.workingDays,
      workingStartHours: workingStartHours ?? this.workingStartHours,
      workingEndHours: workingEndHours ?? this.workingEndHours,
    );
  }
}
