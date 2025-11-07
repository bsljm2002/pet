// 상담 내역 데이터 모델
class ConsultationRecord {
  final String id;
  final String vetName;
  final String topic;
  final List<String> petNames;
  final DateTime requestedAt;
  final String contactMethod;
  final String status;
  final String? notes;

  const ConsultationRecord({
    required this.id,
    required this.vetName,
    required this.topic,
    required this.petNames,
    required this.requestedAt,
    required this.contactMethod,
    required this.status,
    this.notes,
  });
}
