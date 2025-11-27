# 가이드 5: Provider 수정 (1/2)

## 📁 파일

`lib/providers/hospital_provider.dart`

## Step 1: Import 추가

파일 상단에 추가:

```dart
import '../services/vet_service.dart';
import '../services/auth_service.dart';
```

## Step 2: loadVets() 메서드 교체

기존 메서드를 삭제하고 다음으로 교체:

```dart
Future<void> loadVets() async {
  _isLoadingVets = true;
  _vetsError = null;
  notifyListeners();

  try {
    final response = await VetService.getPartners('HOSPITAL');

    if (response['success'] == true) {
      final data = response['data'];
      final List<dynamic> result = data['result'] ?? [];

      _vets = result.map((json) {
        return VetModel(
          id: json['id'].toString(),
          name: json['username'] ?? '',
          doctorName: json['username'] ?? '',
          address: '주소 미등록',
          phone: '전화번호 미등록',
          rating: 4.5,
          specialties: _parseSpecialties(json['vet_specialty']),
          availableTimes: _parseWorkingHours(json['working_schedule']),
          distance: 0.0,
          isOpen: true,
          imageUrl: VetService.getFullImageUrl(json['image_url']),
          description: '수의사 소개',
        );
      }).toList();
    } else {
      _vetsError = response['message'] ?? '수의사 목록을 불러올 수 없습니다';
      _vets = [];
    }
  } catch (e) {
    _vetsError = e.toString();
    _vets = [];
  } finally {
    _isLoadingVets = false;
    notifyListeners();
  }
}
```

## 📌 다음 단계

가이드6에서 헬퍼 메서드를 추가하세요!
