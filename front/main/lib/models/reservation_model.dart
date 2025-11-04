// 예약 데이터 모델
class ReservationModel {
  final String id;
  final String vetId;
  final String vetName;
  final String petName;
  final String petType; // 강아지, 고양이, 기타
  final String specialty; // 진료 과목
  final DateTime reservationDate;
  final String timeSlot;
  final String status; // 예약완료, 진료중, 완료, 취소
  final String? memo; // 메모

  ReservationModel({
    required this.id,
    required this.vetId,
    required this.vetName,
    required this.petName,
    required this.petType,
    required this.specialty,
    required this.reservationDate,
    required this.timeSlot,
    required this.status,
    this.memo,
  });

  factory ReservationModel.fromJson(Map<String, dynamic> json) {
    return ReservationModel(
      id: json['id'] ?? '',
      vetId: json['vetId'] ?? '',
      vetName: json['vetName'] ?? '',
      petName: json['petName'] ?? '',
      petType: json['petType'] ?? '',
      specialty: json['specialty'] ?? '',
      reservationDate: DateTime.parse(json['reservationDate']),
      timeSlot: json['timeSlot'] ?? '',
      status: json['status'] ?? '',
      memo: json['memo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vetId': vetId,
      'vetName': vetName,
      'petName': petName,
      'petType': petType,
      'specialty': specialty,
      'reservationDate': reservationDate.toIso8601String(),
      'timeSlot': timeSlot,
      'status': status,
      'memo': memo,
    };
  }
}
