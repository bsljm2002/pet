# 가이드 6: Provider 수정 (2/2)

## 📁 파일

`lib/providers/hospital_provider.dart`

## Step 3: 헬퍼 메서드 추가

클래스 안에 다음 메서드들을 추가:

```dart
List<String> _parseSpecialties(dynamic specialties) {
  if (specialties == null) return [];

  final Map<String, String> map = {
    'INTERNAL_MEDICINE': '내과',
    'SURGERY': '외과',
    'ORTHOPEDICS': '정형외과',
    'OPHTHALMOLOGY': '안과',
    'DENTISTRY': '치과',
    'DERMATOLOGY': '피부과',
    'EMERGENCY_MEDICINE': '응급의학과',
    'GENERAL': '일반',
  };

  if (specialties is List) {
    return specialties.map((s) => map[s] ?? s.toString()).toList();
  }
  return [];
}

List<String> _parseWorkingHours(dynamic schedule) {
  if (schedule == null) return ['09:00', '14:00', '16:00'];

  try {
    String start = schedule['working_start_hours'] ?? '09:00';
    String end = schedule['working_end_hours'] ?? '18:00';

    List<String> times = [];
    int startHour = int.parse(start.split(':')[0]);
    int endHour = int.parse(end.split(':')[0]);

    for (int hour = startHour; hour < endHour; hour++) {
      times.add('${hour.toString().padLeft(2, '0')}:00');
    }
    return times;
  } catch (e) {
    return ['09:00', '14:00', '16:00'];
  }
}

String _parseStatus(String? status) {
  final Map<String, String> map = {
    'WAITING': '대기중',
    'CONFIRMED': '승인됨',
    'COMPLETED': '완료',
  };
  return map[status] ?? '알 수 없음';
}
```

## 📌 다음 단계

가이드7에서 테스트 방법을 확인하세요!
