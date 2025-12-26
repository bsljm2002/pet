import 'package:intl/intl.dart';

/// 사용자(고객)용 예약 모델 (내가 예약한 내역)
class UserReservationModel {
  final int reservationId;
  final int userId;
  final String userName;
  final int? petId;
  final String? petName;
  final String serviceType; // "HOSPITAL" or "SITTER"
  final String slotLabel; // "오전" or "오후"
  final String date; // "yyyy.MM.dd" 형식
  final int? hour; // 시간 (0-23)
  final int? minute; // 분 (0-59)
  final int? partnerId; // 파트너 ID (리뷰 작성에 필요)
  final String? partnerName; // 병원/시터 이름
  final List<String> specialties; // 진료과목 or 서비스 항목
  final String status; // WAITING, CONFIRMED, COMPLETED, CANCELLED_BY_USER, CANCELLED_BY_BIZ
  final String? reservationContent; // 예약 메모/요청사항
  final bool hasReview; // 리뷰 작성 여부

  UserReservationModel({
    required this.reservationId,
    required this.userId,
    required this.userName,
    this.petId,
    this.petName,
    required this.serviceType,
    required this.slotLabel,
    required this.date,
    this.hour,
    this.minute,
    this.partnerId,
    this.partnerName,
    this.specialties = const [],
    required this.status,
    this.reservationContent,
    this.hasReview = false,
  });

  factory UserReservationModel.fromJson(Map<String, dynamic> json) {
    return UserReservationModel(
      reservationId: json['reservationId'] ?? 0,
      userId: json['userId'] ?? 0,
      userName: json['userName'] ?? '',
      petId: json['petId'],
      petName: json['petName'],
      serviceType: json['serviceType'] ?? '',
      slotLabel: json['slotLabel'] ?? '',
      date: json['date'] ?? '',
      hour: json['hour'],
      minute: json['minute'],
      partnerId: json['partnerId'],
      partnerName: json['partnerName'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : [],
      status: json['status'] ?? 'WAITING',
      reservationContent: json['reservationContent'],
      hasReview: json['hasReview'] ?? false,
    );
  }

  /// 날짜 문자열을 DateTime으로 변환
  DateTime get dateTime {
    try {
      // "yyyy.MM.dd" 형식을 파싱
      final parts = date.split('.');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return DateTime(year, month, day, hour ?? 0, minute ?? 0);
      }
    } catch (e) {
      print('날짜 파싱 오류: $e');
    }
    return DateTime.now();
  }

  /// 포맷팅된 날짜 (yyyy.MM.dd (E))
  String get formattedDate {
    try {
      return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(dateTime);
    } catch (e) {
      return date;
    }
  }

  /// 포맷팅된 시간 (HH:mm)
  String get formattedTime {
    if (hour != null) {
      return DateFormat('HH:mm').format(dateTime);
    }
    return slotLabel;
  }

  /// 상태 한글 표시
  String get statusLabel {
    switch (status) {
      case 'WAITING':
        return '대기중';
      case 'CONFIRMED':
        return '확정됨';
      case 'COMPLETED':
        return '완료됨';
      case 'CANCELLED_BY_USER':
        return '취소됨 (고객)';
      case 'CANCELLED_BY_BIZ':
        return '거절됨 (파트너)';
      default:
        return status;
    }
  }

  /// 서비스 타입 한글 표시
  String get serviceTypeLabel {
    switch (serviceType) {
      case 'HOSPITAL':
        return '병원 진료';
      case 'SITTER':
        return '펫시터 돌봄';
      default:
        return serviceType;
    }
  }
}
