import 'package:intl/intl.dart';
import 'ai_diagnosis.dart';

/// 파트너용 예약 모델 (병원/시터가 받은 예약)
class PartnerReservationModel {
  final int reservationId;
  final int userId; // 예약한 고객 ID
  final String userName; // 예약한 고객 이름
  final int? petId;
  final String? petName;
  final String serviceType;
  final String status; // WAITING, CONFIRMED, COMPLETED, CANCELLED_BY_USER, CANCELLED_BY_BIZ
  final DateTime createdAt;
  final String? reservationContent;
  final List<String> specialties;
  final List<String> resvUrls; // AI 진단 이미지 URL 목록
  final List<AIDiagnosis> aiDiagnoses; // AI 진단 정보 목록

  PartnerReservationModel({
    required this.reservationId,
    required this.userId,
    required this.userName,
    this.petId,
    this.petName,
    required this.serviceType,
    required this.status,
    required this.createdAt,
    this.reservationContent,
    this.specialties = const [],
    this.resvUrls = const [],
    this.aiDiagnoses = const [],
  });

  factory PartnerReservationModel.fromJson(Map<String, dynamic> json) {
    return PartnerReservationModel(
      reservationId: json['reservationId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      petId: json['petId'],
      petName: json['petName'],
      serviceType: json['serviceType'] ?? '',
      status: json['status'] ?? 'WAITING',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      reservationContent: json['reservationContent'],
      specialties: json['specialties'] != null
          ? (json['specialties'] is List
              ? List<String>.from(json['specialties'])
              : [])
          : [],
      resvUrls: json['resvUrls'] != null
          ? (json['resvUrls'] is List
              ? List<String>.from(json['resvUrls'])
              : [])
          : [],
      aiDiagnoses: json['aiDiagnoses'] != null
          ? (json['aiDiagnoses'] is List
              ? (json['aiDiagnoses'] as List)
                  .map((d) => AIDiagnosis.fromJson(d as Map<String, dynamic>))
                  .toList()
              : [])
          : [],
    );
  }

  String get formattedDate {
    return DateFormat('yyyy.MM.dd').format(createdAt);
  }

  String get formattedTime {
    return DateFormat('HH:mm').format(createdAt);
  }

  String get timeSlot {
    return createdAt.hour < 12 ? '오전' : '오후';
  }
}
