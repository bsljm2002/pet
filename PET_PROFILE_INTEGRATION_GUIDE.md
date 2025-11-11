# 펫 등록 후 홈 페이지에서 펫 프로필 표시하기 가이드

## 📋 목차
1. [현재 상황 분석](#현재-상황-분석)
2. [문제점](#문제점)
3. [해결 방법](#해결-방법)
4. [단계별 구현 가이드](#단계별-구현-가이드)
5. [테스트 방법](#테스트-방법)

---

## 현재 상황 분석

### ✅ 이미 구현된 것들
- **백엔드 API**: 펫 등록(`POST /api/v1/pets`) 및 조회(`GET /api/v1/pets?ownerId={userId}`) API 완성
- **프론트엔드 등록 화면**: `add_pet_profile_screen.dart`에서 펫 등록 기능 구현
- **PetService**: 백엔드 API 호출 서비스 구현 완료
  - `createPet()`: 펫 등록
  - `getPetsByOwner()`: 사용자의 펫 목록 조회
- **홈 화면**: `home_screen.dart`에서 펫 프로필 목록 표시

### 📁 관련 파일 경로
```
front/main/lib/
├── models/
│   └── pet_profile.dart                    # 펫 데이터 모델
├── services/
│   ├── pet_service.dart                    # 백엔드 API 호출 서비스
│   ├── pet_profile_manager.dart            # 메모리 기반 펫 데이터 저장소
│   └── auth_service.dart                   # 사용자 인증 서비스
└── screens/
    ├── home_screen.dart                    # 홈 화면 (펫 프로필 목록 표시)
    └── add_pet_profile_screen.dart         # 펫 등록 화면
```

---

## 문제점

### ❌ 현재 발생하는 문제
펫을 등록하면 백엔드에는 저장되지만, **홈 화면에 표시되지 않는 이유**:

1. **백엔드 <-> 프론트엔드 데이터 동기화 부재**
   - `PetService.createPet()`으로 백엔드에 펫을 등록
   - 하지만 `PetProfileManager`에는 추가되지 않음

2. **홈 화면이 메모리 데이터만 참조**
   ```dart
   // home_screen.dart:159
   ...PetProfileManager().getAllProfiles().map((profile) { ... })
   ```
   - 홈 화면은 `PetProfileManager`의 메모리 목록만 표시
   - 백엔드 데이터를 조회하지 않음

3. **앱 재시작 시 데이터 소실**
   - `PetProfileManager`는 메모리 기반이므로 앱 종료 시 데이터 사라짐

---

## 해결 방법

### 🎯 구현 전략
**홈 화면 로드 시 백엔드에서 펫 목록을 조회하고, 이를 화면에 표시**

#### 옵션 1: 간단한 방법 (권장)
- 홈 화면 초기화 시 백엔드 API 호출
- 받아온 데이터를 위젯 상태로 관리
- `PetProfileManager` 사용하지 않음

#### 옵션 2: 기존 구조 유지
- 홈 화면 초기화 시 백엔드 API 호출
- 받아온 데이터를 `PetProfileManager`에 추가
- 기존 코드 최소 수정

이 가이드에서는 **옵션 1 (간단한 방법)**을 채택합니다.

---

## 단계별 구현 가이드

### 📝 Step 1: 홈 화면에 펫 목록 상태 추가

**파일**: `front/main/lib/screens/home_screen.dart`

#### 1-1. 필요한 import 추가
파일 상단에 다음 import를 추가하세요:

```dart
import '../services/pet_service.dart';
import '../services/auth_service.dart';
```

**위치**: 파일 3번째 줄 (`import 'package:flutter/material.dart';` 아래)

---

#### 1-2. State 클래스에 펫 목록 상태 변수 추가

`_HomeScreenState` 클래스 내부에 다음 변수들을 추가하세요:

```dart
class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 기존 코드

  // 👇 여기에 추가
  List<PetProfile> _petProfiles = [];  // 펫 목록 데이터
  bool _isLoading = true;              // 로딩 상태
  String? _errorMessage;               // 에러 메시지
```

**위치**: `home_screen.dart` 20번째 줄 아래

---

### 📝 Step 2: 펫 목록 조회 메서드 구현

#### 2-1. 펫 목록을 불러오는 메서드 추가

`_HomeScreenState` 클래스에 다음 메서드를 추가하세요:

```dart
/// 백엔드에서 펫 목록 조회
Future<void> _loadPetProfiles() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // 현재 로그인한 사용자 확인
    final currentUser = AuthService().currentUser;

    if (currentUser == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = "로그인이 필요합니다.";
      });
      return;
    }

    // 백엔드 API 호출
    final response = await PetService().getPetsByOwner(currentUser.id);

    if (response['success'] == true) {
      // 성공: JSON 데이터를 PetProfile 객체로 변환
      final List<dynamic> petsData = response['pets'];
      final List<PetProfile> profiles = petsData
          .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      setState(() {
        _petProfiles = profiles;
        _isLoading = false;
      });
    } else {
      // 실패: 에러 메시지 설정
      setState(() {
        _isLoading = false;
        _errorMessage = response['message'] ?? '펫 목록을 불러오지 못했습니다.';
      });
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
      _errorMessage = '네트워크 오류: $e';
    });
  }
}
```

**위치**: `_HomeScreenState` 클래스 내부 (아무 메서드 뒤에 추가 가능)

---

### 📝 Step 3: 화면 로드 시 펫 목록 자동 조회

#### 3-1. initState에서 펫 목록 조회

`_HomeScreenState` 클래스에 `initState` 메서드를 추가하세요:

```dart
@override
void initState() {
  super.initState();
  _loadPetProfiles(); // 화면 로드 시 펫 목록 조회
}
```

**위치**: `_HomeScreenState` 클래스 내부 (상태 변수 선언 바로 아래)

---

### 📝 Step 4: 펫 프로필 표시 로직 수정

#### 4-1. `_buildPetProfileContent` 메서드 수정

기존 코드:
```dart
...PetProfileManager().getAllProfiles().map((profile) {
  return Padding(
    padding: const EdgeInsets.only(right: 20),
    child: _buildPetProfile(context, profile: profile),
  );
})
```

**변경 후**:
```dart
// 로딩 중일 때
if (_isLoading)
  Padding(
    padding: const EdgeInsets.all(20),
    child: CircularProgressIndicator(
      color: Color.fromARGB(255, 0, 108, 82),
    ),
  )
// 에러가 있을 때
else if (_errorMessage != null)
  Padding(
    padding: const EdgeInsets.all(20),
    child: Text(
      _errorMessage!,
      style: TextStyle(color: Colors.red),
    ),
  )
// 정상적으로 데이터를 불러왔을 때
else
  ..._petProfiles.map((profile) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: _buildPetProfile(context, profile: profile),
    );
  }),
```

**위치**: `home_screen.dart` 약 158-164번째 줄 (기존 코드 교체)

**전체 코드 예시**:
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      // 등록된 펫 프로필 목록
      if (_isLoading)
        Padding(
          padding: const EdgeInsets.all(20),
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 0, 108, 82),
          ),
        )
      else if (_errorMessage != null)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            _errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
        )
      else
        ..._petProfiles.map((profile) {
          return Padding(
            padding: const EdgeInsets.only(right: 20),
            child: _buildPetProfile(context, profile: profile),
          );
        }),
      // 새로운 펫 추가 버튼
      _buildAddPetButton(context),
    ],
  ),
),
```

---

### 📝 Step 5: 펫 등록 후 목록 갱신

#### 5-1. `_buildAddPetButton` 메서드 수정

기존 코드:
```dart
onTap: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddPetProfileScreen()),
  );
  if (result == true) {
    setState(() {});
  }
}
```

**변경 후**:
```dart
onTap: () async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddPetProfileScreen()),
  );
  if (result == true) {
    // 펫 등록 성공 시 목록 다시 조회
    await _loadPetProfiles();
  }
}
```

**위치**: `home_screen.dart` 약 233-240번째 줄

---

### 📝 Step 6: 펫 상세 화면에서 돌아왔을 때 목록 갱신 (선택사항)

#### 6-1. `_buildPetProfile` 메서드 수정

펫 프로필을 수정하거나 삭제했을 경우를 대비해 상세 화면에서 돌아왔을 때도 목록을 갱신합니다.

기존 코드:
```dart
onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PetProfileDetailScreen(profile: profile),
    ),
  );
  setState(() {});
}
```

**변경 후**:
```dart
onTap: () async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PetProfileDetailScreen(profile: profile),
    ),
  );
  // 상세 화면에서 돌아왔을 때 목록 갱신
  await _loadPetProfiles();
}
```

**위치**: `home_screen.dart` 약 181-189번째 줄

---

## 테스트 방법

### ✅ 1단계: 앱 실행 전 체크리스트
- [ ] 백엔드 서버가 실행 중인지 확인 (`http://10.0.2.2:9075`)
- [ ] 사용자가 로그인된 상태인지 확인
- [ ] 모든 코드 변경사항 저장

### ✅ 2단계: 앱 실행 및 홈 화면 확인
```bash
flutter run
```

1. **앱 실행 후 홈 화면 이동**
   - 로딩 인디케이터가 잠시 표시됨
   - 기존에 등록한 펫이 있다면 자동으로 표시됨

2. **로딩 상태 확인**
   - 데이터를 불러오는 동안 `CircularProgressIndicator` 표시
   - 로딩 완료 후 펫 프로필 목록 표시

3. **에러 처리 확인**
   - 네트워크 오류 시 에러 메시지 표시
   - 로그인하지 않았을 경우 "로그인이 필요합니다" 메시지 표시

### ✅ 3단계: 펫 등록 후 자동 갱신 테스트

1. **홈 화면에서 "+" (Member) 버튼 클릭**
2. **펫 등록 화면에서 정보 입력**
   - 이름: 예) "보리"
   - 종: 개 또는 고양이 선택
   - 생년월일: 날짜 선택
   - 몸무게: 예) 5.0
   - 성별: 선택
   - ABTI 테스트: 완료 필수

3. **"등록하기" 버튼 클릭**
   - 성공 메시지 확인
   - 자동으로 홈 화면으로 돌아감

4. **홈 화면에서 새로 등록한 펫 확인**
   - 로딩 후 새로운 펫 프로필이 표시되어야 함
   - 펫 이름과 이미지(없으면 기본 아이콘) 확인

### ✅ 4단계: 앱 재시작 후 데이터 유지 확인

1. **앱 완전히 종료**
2. **앱 다시 실행**
3. **홈 화면에서 이전에 등록한 펫들이 모두 표시되는지 확인**
   - 백엔드에서 데이터를 불러오므로 앱 재시작 후에도 데이터 유지

---

## 🔍 디버깅 팁

### 문제 1: 펫이 표시되지 않음
**확인사항**:
1. Flutter 콘솔에서 에러 메시지 확인
2. 백엔드 서버 실행 여부 확인
3. 로그인 상태 확인 (`AuthService().currentUser != null`)
4. API 응답 로그 확인

**디버그 로그 추가**:
```dart
Future<void> _loadPetProfiles() async {
  // ... 기존 코드 ...

  final response = await PetService().getPetsByOwner(currentUser.id);
  print('🐾 펫 조회 응답: $response'); // 👈 디버그 로그 추가

  // ... 나머지 코드 ...
}
```

### 문제 2: 로딩이 계속됨
**원인**: API 호출이 실패했지만 에러 처리가 안 됨

**해결**:
- `_loadPetProfiles()` 메서드의 try-catch 블록 확인
- 백엔드 응답 형식이 올바른지 확인

### 문제 3: 에러 메시지 표시
**확인사항**:
1. 백엔드 API 엔드포인트 확인: `GET /api/v1/pets?ownerId={userId}`
2. userId가 올바르게 전달되는지 확인
3. 백엔드 로그에서 에러 내용 확인

---

## 📊 데이터 흐름 다이어그램

```
┌─────────────────┐
│   HomeScreen    │
│   (initState)   │
└────────┬────────┘
         │
         ▼
┌──────────────────────┐
│ _loadPetProfiles()   │
│ 1. AuthService로     │
│    현재 사용자 확인  │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│   PetService         │
│ getPetsByOwner(id)   │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│   Backend API        │
│ GET /api/v1/pets     │
│ ?ownerId={userId}    │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│ Response 처리        │
│ - success: true      │
│   → PetProfile 변환  │
│ - success: false     │
│   → 에러 메시지 표시 │
└────────┬─────────────┘
         │
         ▼
┌──────────────────────┐
│   setState()         │
│ _petProfiles 업데이트│
│ UI 자동 갱신         │
└──────────────────────┘
```

---

## 🎉 완료!

이제 펫 등록 후 홈 화면에서 펫 프로필이 자동으로 표시됩니다!

### 구현된 기능
- ✅ 홈 화면 로드 시 백엔드에서 펫 목록 자동 조회
- ✅ 로딩 인디케이터 표시
- ✅ 에러 처리 및 메시지 표시
- ✅ 펫 등록 후 목록 자동 갱신
- ✅ 앱 재시작 후에도 데이터 유지

### 추가 개선 아이디어 (선택사항)
1. **Pull-to-Refresh**: 아래로 당겨서 새로고침 기능
2. **Provider 패턴 적용**: 전역 상태 관리로 개선
3. **캐싱**: 네트워크 요청 최소화를 위한 로컬 캐싱
4. **오프라인 지원**: 네트워크 연결 없이도 마지막 조회 데이터 표시

---

## 📞 문제 발생 시

코드 작성 중 막히는 부분이 있다면:
1. 각 단계별로 코드를 추가한 후 저장
2. `flutter run`으로 앱 실행하여 에러 확인
3. Flutter 콘솔에서 에러 메시지 확인
4. 위의 "디버깅 팁" 섹션 참고

**파이팅! 🚀**
