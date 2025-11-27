import 'package:intl/intl.dart';

class CompletedReservationModel {
  final int reservationId;
  final int partnerId;
  final String partnerName;
  final String partnerType;
  final DateTime createdAt;
  final String serviceCategorical;
  final bool hasReview;

  CompletedReservationModel({
    required this.reservationId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerType,
    required this.createdAt,
    required this.serviceCategorical,
    required this.hasReview,
  });

  factory CompletedReservationModel.fromJson(Map<String, dynamic> json) {
    return CompletedReservationModel(
      reservationId: json['reservationId'] ?? 0,
      partnerId: json['partnerId'] ?? 0,
      partnerName: json['partnerName'] ?? '',
      partnerType: json['partnerType'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      serviceCategorical: json['serviceCategorical'] ?? '',
      hasReview: json['hasReview'] ?? false,
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
