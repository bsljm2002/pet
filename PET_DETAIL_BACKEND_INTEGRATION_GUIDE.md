# 펫 상세 페이지 백엔드 연결 가이드

## 📋 목차
1. [현재 상황 분석](#현재-상황-분석)
2. [연결할 데이터 항목](#연결할-데이터-항목)
3. [백엔드 API 준비](#백엔드-api-준비)
4. [프론트엔드 연결 가이드](#프론트엔드-연결-가이드)
5. [테스트 방법](#테스트-방법)

---

## 현재 상황 분석

### ✅ 현재 펫 상세 페이지 구조

**파일 위치**: `c:/project/front/main/lib/screens/pet_profile_detail_screen.dart`

**표시 중인 데이터**:
- ✅ **이름**: `widget.profile.name` (273번째 줄) - 백엔드 연결됨
- ✅ **나이**: `_calculateAge()` 메서드로 생년월일에서 계산 (406번째 줄)
- ⚠️ **체중**: 하드코딩 `'5.12Kg'` (408번째 줄) - **백엔드 연결 필요**
- ✅ **품종**: `widget.profile.speciesDetail ?? '미등록'` (412번째 줄) - 백엔드 연결됨
- ✅ **성별**: `_getGenderDisplay()` 메서드 (416번째 줄) - 백엔드 연결됨
- ✅ **이미지**: `widget.profile.imageUrl` (259번째 줄) - 백엔드 연결됨

### 🎯 해결할 문제
1. **체중 데이터**: 현재 하드코딩된 `'5.12Kg'`를 `widget.profile.weight`로 변경
2. **성별 매핑**: 백엔드는 `MALE`/`FEMALE`, 화면은 `Man`/`Woman` 체크 필요

---

## 연결할 데이터 항목

### 백엔드 Pet 엔티티 구조
```java
{
  "id": Long,
  "userId": Long,
  "name": String,
  "species": "DOG" | "CAT",
  "birthdate": "yyyy-MM-dd",
  "weight": BigDecimal,
  "gender": "MALE" | "FEMALE",
  "speciesDetail": String,
  "imageUrl": String,
  "abitTypeCode": "ENFP" (MBTI 코드)
}
```

### 프론트엔드 PetProfile 모델
```dart
class PetProfile {
  final int? id;
  final int? userId;
  final String name;
  final String species;
  final String birthdate;
  final double weight;
  final String? gender;
  final String? speciesDetail;
  final String? imageUrl;
  final String? abtiTypeCode;
}
```

---

## 백엔드 API 준비

### Step 1: 백엔드에 개별 펫 조회 API 추가

#### 1-1. PetService에 메서드 추가

**파일**: `c:/project/backend/demo/src/main/java/com/example/pet/demo/pets/app/PetService.java`

**44번째 줄 뒤에 추가**:

```java
    @Transactional(readOnly = true)
    public Pet getPetById(Long id) {
        return pets.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found with id: " + id));
    }
```

**전체 코드 예시**:
```java
    @Transactional(readOnly = true)
    public List<Pet> getPetsByOwner(Long ownerId) {
        return pets.findByOwnerId(ownerId);
    }

    @Transactional(readOnly = true)
    public Pet getPetById(Long id) {
        return pets.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("Pet not found with id: " + id));
    }
}
```

---

#### 1-2. PetController에 엔드포인트 추가

**파일**: `c:/project/backend/demo/src/main/java/com/example/pet/demo/pets/api/PetController.java`

**65번째 줄 뒤에 추가**:

```java
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Pet>> getPetById(@PathVariable Long id) {
        return ResponseEntity.ok(
                ApiResponse.ok(petService.getPetById(id)));
    }
```

**전체 코드 예시**:
```java
    @GetMapping
    public ResponseEntity<ApiResponse<List<Pet>>> getPetsByOwner(@RequestParam("ownerId") Long ownerId) {
        return ResponseEntity.ok(
                ApiResponse.ok(petService.getPetsByOwner(ownerId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<Pet>> getPetById(@PathVariable Long id) {
        return ResponseEntity.ok(
                ApiResponse.ok(petService.getPetById(id)));
    }
}
```

---

#### 1-3. 백엔드 재시작

백엔드 서버를 재시작합니다:

```bash
cd c:/project/backend/demo
./gradlew bootRun
```

또는 IDE에서 재시작하세요.

---

#### 1-4. API 테스트 (선택사항)

브라우저나 Postman으로 테스트:

```
GET http://localhost:9075/api/v1/pets/1
```

**예상 응답**:
```json
{
  "ok": true,
  "data": {
    "id": 1,
    "userId": 1,
    "name": "보리",
    "species": "DOG",
    "birthdate": "2020-05-15",
    "weight": 5.12,
    "gender": "MALE",
    "speciesDetail": "골든 리트리버",
    "imageUrl": null,
    "abitTypeCode": "ENFP"
  }
}
```

---

## 프론트엔드 연결 가이드

### Step 2: PetService에 개별 펫 조회 메서드 추가

#### 2-1. pet_service.dart 수정

**파일**: `c:/project/front/main/lib/services/pet_service.dart`

**89번째 줄 뒤에 추가**:

```dart
  /// 개별 펫 조회
  Future<Map<String, dynamic>> getPetById(int petId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$petId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {"success": true, "pet": data["data"]};
        } else {
          return {"success": false, "message": data["message"]};
        }
      } else {
        return {"success": false, "message": "조회 실패 (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }
```

---

### Step 3: 펫 상세 페이지에서 체중 데이터 연결

#### 3-1. 하드코딩된 체중을 실제 데이터로 변경

**파일**: `c:/project/front/main/lib/screens/pet_profile_detail_screen.dart`

**408번째 줄 찾기**:
```dart
_buildInfoRow('체중:', '5.12Kg', Color(0xFFFF9500)),
```

**다음으로 변경**:
```dart
_buildInfoRow('체중:', '${widget.profile.weight.toStringAsFixed(2)}Kg', Color(0xFFFF9500)),
```

**설명**:
- `widget.profile.weight`: PetProfile 모델의 체중 데이터 (double 타입)
- `.toStringAsFixed(2)`: 소수점 2자리까지 표시
- 예: `5.12` → `"5.12Kg"`

---

### Step 4: 성별 표시 수정 (백엔드 데이터 형식에 맞춤)

#### 4-1. _getGenderDisplay() 메서드 수정

**파일**: `c:/project/front/main/lib/screens/pet_profile_detail_screen.dart`

**84-97번째 줄 찾기**:
```dart
  String _getGenderDisplay() {
    if (widget.profile.gender == null) {
      return '미등록';
    }

    switch (widget.profile.gender) {
      case 'Man':
        return '♂ 수컷';
      case 'Woman':
        return '♀ 암컷';
      default:
        return '미등록';
    }
  }
```

**다음으로 변경**:
```dart
  String _getGenderDisplay() {
    if (widget.profile.gender == null) {
      return '미등록';
    }

    switch (widget.profile.gender!.toUpperCase()) {
      case 'MALE':
      case 'MAN':
        return '♂ 수컷';
      case 'FEMALE':
      case 'WOMAN':
        return '♀ 암컷';
      default:
        return '미등록';
    }
  }
```

**변경 사항**:
- `widget.profile.gender!.toUpperCase()`: 대소문자 구분 없이 비교
- `MALE`, `FEMALE` (백엔드 형식) 추가
- 기존 `Man`, `Woman` 호환성 유지

---

### Step 5: (선택사항) 펫 상세 정보를 실시간으로 불러오기

현재는 홈 화면에서 받은 `PetProfile` 객체를 그대로 사용하지만, 최신 데이터를 보장하려면 상세 페이지 진입 시 API를 다시 호출할 수 있습니다.

#### 5-1. 상세 페이지에서 데이터 다시 조회

**파일**: `c:/project/front/main/lib/screens/pet_profile_detail_screen.dart`

**필요한 import 추가** (파일 상단):
```dart
import '../services/pet_service.dart';
```

**State 클래스에 변수 추가** (26번째 줄 근처):
```dart
class _PetProfileDetailScreenState extends State<PetProfileDetailScreen> {
  bool _showSettingsMenu = false;
  String? _currentAbtiType;

  // 👇 추가
  PetProfile? _latestProfile;  // 최신 펫 데이터
  bool _isLoading = true;      // 로딩 상태
```

**initState 수정** (34-38번째 줄):
```dart
  @override
  void initState() {
    super.initState();
    _currentAbtiType = widget.profile.abtiTypeCode;
    _loadPetDetails();  // 👈 추가
  }

  // 👇 메서드 추가
  Future<void> _loadPetDetails() async {
    if (widget.profile.id == null) {
      setState(() {
        _latestProfile = widget.profile;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await PetService().getPetById(widget.profile.id!);

      if (response['success'] == true) {
        final petData = response['pet'];
        final profile = PetProfile.fromJson(petData as Map<String, dynamic>);

        setState(() {
          _latestProfile = profile;
          _currentAbtiType = profile.abtiTypeCode;
          _isLoading = false;
        });
      } else {
        // 실패 시 기존 데이터 사용
        setState(() {
          _latestProfile = widget.profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      // 오류 시 기존 데이터 사용
      setState(() {
        _latestProfile = widget.profile;
        _isLoading = false;
      });
    }
  }
```

**build 메서드에서 사용할 프로필 변경**:

모든 `widget.profile`을 `_latestProfile ?? widget.profile`로 변경합니다.

**예시** (273번째 줄):
```dart
// 변경 전
Text(
  widget.profile.name,
  ...
)

// 변경 후
Text(
  _latestProfile?.name ?? widget.profile.name,
  ...
)
```

**또는 간단하게**:

build 메서드 시작 부분에 변수 선언:
```dart
@override
Widget build(BuildContext context) {
  final profile = _latestProfile ?? widget.profile;  // 👈 추가

  return Scaffold(
    ...
```

그리고 모든 `widget.profile`을 `profile`로 변경.

---

## 전체 수정 요약

### 필수 수정 사항

#### ✅ 1. 체중 데이터 연결
**위치**: `pet_profile_detail_screen.dart:408`

```dart
// 변경 전
_buildInfoRow('체중:', '5.12Kg', Color(0xFFFF9500)),

// 변경 후
_buildInfoRow('체중:', '${widget.profile.weight.toStringAsFixed(2)}Kg', Color(0xFFFF9500)),
```

#### ✅ 2. 성별 표시 수정
**위치**: `pet_profile_detail_screen.dart:84-97`

```dart
String _getGenderDisplay() {
  if (widget.profile.gender == null) {
    return '미등록';
  }

  switch (widget.profile.gender!.toUpperCase()) {
    case 'MALE':
    case 'MAN':
      return '♂ 수컷';
    case 'FEMALE':
    case 'WOMAN':
      return '♀ 암컷';
    default:
      return '미등록';
  }
}
```

---

## 테스트 방법

### ✅ 1단계: 백엔드 서버 실행 확인
```bash
# 백엔드가 실행 중인지 확인
curl http://localhost:9075/api/v1/pets/1
```

### ✅ 2단계: Flutter 앱 실행
```bash
cd c:/project/front/main
flutter run
```

### ✅ 3단계: 펫 상세 페이지 확인

1. **홈 화면에서 펫 프로필 클릭**
2. **펫 상세 페이지 진입**
3. **데이터 확인**:
   - ✅ **이름**: 등록한 펫 이름 표시
   - ✅ **나이**: 생년월일 기준으로 자동 계산
   - ✅ **체중**: 등록한 체중 표시 (예: `5.12Kg`)
   - ✅ **품종**: 등록한 품종 표시
   - ✅ **성별**: `♂ 수컷` 또는 `♀ 암컷` 표시
   - ✅ **이미지**: 등록한 이미지 (없으면 기본 아이콘)

---

## 🔍 디버깅 팁

### 문제 1: 체중이 `0.0Kg`로 표시됨

**원인**: 백엔드에서 체중 데이터가 null이거나 잘못된 형식

**확인 사항**:
1. 펫 등록 시 체중을 올바르게 입력했는지 확인
2. 백엔드 API 응답 확인:
   ```bash
   curl http://localhost:9075/api/v1/pets?ownerId=1
   ```
3. `PetProfile.fromJson()`에서 weight 파싱 확인

**해결**:
```dart
// pet_profile.dart의 fromJson 메서드
weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
```

---

### 문제 2: 성별이 `미등록`으로 표시됨

**원인**: 성별 데이터 형식 불일치

**확인 사항**:
1. 백엔드 API 응답에서 `gender` 필드 확인
2. 값이 `MALE` 또는 `FEMALE`인지 확인

**디버그 로그 추가**:
```dart
String _getGenderDisplay() {
  print('🔍 Gender value: ${widget.profile.gender}');  // 👈 디버그 로그

  if (widget.profile.gender == null) {
    return '미등록';
  }
  // ...
}
```

---

### 문제 3: 이미지가 표시되지 않음

**원인**: 이미지 URL이 null이거나 잘못된 경로

**확인 사항**:
1. `widget.profile.imageUrl` 값 확인
2. URL이 유효한지 확인 (http:// 또는 https://)

**임시 해결** (기본 아이콘 표시):
```dart
backgroundImage: widget.profile.imageUrl != null && widget.profile.imageUrl!.isNotEmpty
    ? NetworkImage(widget.profile.imageUrl!)
    : null,
child: widget.profile.imageUrl == null || widget.profile.imageUrl!.isEmpty
    ? Icon(Icons.pets, size: 60, color: Colors.grey)
    : null,
```

---

## 📊 데이터 흐름 다이어그램

```
┌─────────────────────┐
│   HomeScreen        │
│ (펫 목록 조회)      │
└──────────┬──────────┘
           │ 펫 프로필 클릭
           ▼
┌─────────────────────┐
│ PetProfileDetail    │
│ (widget.profile)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ 화면에 데이터 표시  │
│ - 이름              │
│ - 나이 (계산)       │
│ - 체중 ✨ 수정      │
│ - 품종              │
│ - 성별 ✨ 수정      │
│ - 이미지            │
└─────────────────────┘
```

### (선택사항) 최신 데이터 조회 흐름

```
┌─────────────────────┐
│ PetProfileDetail    │
│ (initState)         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ _loadPetDetails()   │
│ API 호출            │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   PetService        │
│ getPetById(id)      │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Backend API       │
│ GET /api/v1/pets/1  │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ PetProfile.fromJson │
│ 데이터 파싱         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ setState()          │
│ _latestProfile 업데이트│
│ UI 자동 갱신        │
└─────────────────────┘
```

---

## 🎉 완료!

이제 펫 상세 페이지가 백엔드와 완전히 연결되었습니다!

### 구현된 기능
- ✅ 이름 표시 (백엔드 연결)
- ✅ 나이 자동 계산 및 표시
- ✅ 체중 표시 (백엔드 연결)
- ✅ 품종 표시 (백엔드 연결)
- ✅ 성별 표시 (백엔드 연결, MALE/FEMALE 형식 지원)
- ✅ 이미지 표시 (백엔드 연결)

### 추가 개선 아이디어 (선택사항)
1. **Pull-to-Refresh**: 아래로 당겨서 최신 데이터 새로고침
2. **프로필 수정 기능**: 설정 메뉴의 "프로필 수정" 구현
3. **프로필 삭제 기능**: 설정 메뉴의 "삭제" 구현
4. **반려동물 상태**: 스트레스, 비만도, 피부병 데이터 연결
5. **종합 상태 일지**: 일지 CRUD 기능 구현

---

## 📞 문제 발생 시

1. **Flutter 콘솔 확인**: 에러 메시지 확인
2. **백엔드 로그 확인**: API 호출 성공 여부 확인
3. **디버그 로그 추가**: `print()` 문으로 데이터 값 확인
4. **API 테스트**: Postman이나 curl로 백엔드 API 직접 테스트

**파이팅! 🚀**
