/// 진료 기록 모델
class MedicalRecord {
  final int reservationId;
  final int partnerId;
  final String partnerName;
  final String partnerType;
  final DateTime createdAt;
  final String? serviceCategorical;
  final String? reservationContent;

  // 진료 정보
  final String? diagnosis;       // 진단 소견
  final String? prescription;    // 처방약
  final String? dosageSchedule;  // 복용 시간 (예: "아침,점심,저녁")
  final int? dosageDays;         // 복용 일수
  final String? medicalNotes;    // 추가 안내사항
  final List<String> checkedMedicationKeys; // 체크된 복용 키 목록

  MedicalRecord({
    required this.reservationId,
    required this.partnerId,
    required this.partnerName,
    required this.partnerType,
    required this.createdAt,
    this.serviceCategorical,
    this.reservationContent,
    this.diagnosis,
    this.prescription,
    this.dosageSchedule,
    this.dosageDays,
    this.medicalNotes,
    this.checkedMedicationKeys = const [],
  });

  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    return MedicalRecord(
      reservationId: json['reservationId'] ?? 0,
      partnerId: json['partnerId'] ?? 0,
      partnerName: json['partnerName'] ?? '',
      partnerType: json['partnerType'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      serviceCategorical: json['serviceCategorical'],
      reservationContent: json['reservationContent'],
      diagnosis: json['diagnosis'],
      prescription: json['prescription'],
      dosageSchedule: json['dosageSchedule'],
      dosageDays: json['dosageDays'],
      medicalNotes: json['medicalNotes'],
      checkedMedicationKeys: json['checkedMedicationKeys'] != null
          ? List<String>.from(json['checkedMedicationKeys'])
          : [],
    );
  }

  /// 복용 시간 리스트로 변환
  List<String> get dosageScheduleList {
    if (dosageSchedule == null || dosageSchedule!.isEmpty) {
      return [];
    }
    return dosageSchedule!.split(',').map((s) => s.trim()).toList();
  }

  /// 복용 시간 포맷팅 (예: "아침, 점심, 저녁")
  String get dosageScheduleFormatted {
    final list = dosageScheduleList;
    if (list.isEmpty) return '복용 시간 없음';
    return list.join(', ');
  }

  /// 복용 일수 포맷팅
  String get dosageDaysFormatted {
    if (dosageDays == null) return '';
    return '$dosageDays일간';
  }
}
