# 🐾 펫 프로필 등록 API 연결 가이드 (완전판)

> 이 가이드는 Flutter 프론트엔드의 펫 프로필 등록 화면을 Spring Boot 백엔드 API와 **단계별로** 연결하는 방법을 설명합니다.

---

## 📋 목차
1. [시작하기 전에](#시작하기-전에)
2. [백엔드 API 이해하기](#백엔드-api-이해하기)
3. [Step 1: PetService 수정](#step-1-petservice-수정)
4. [Step 2: add_pet_profile_screen.dart 수정](#step-2-add_pet_profile_screendart-수정)
5. [Step 3: 테스트하기](#step-3-테스트하기)
6. [문제 해결](#문제-해결)

---

## 시작하기 전에

### ✅ 준비물 체크리스트

- [x] **백엔드 서버 실행 확인**
  ```bash
  cd C:\project\backend\demo
  ./gradlew bootRun
  ```
  서버가 `http://localhost:9075`에서 실행 중이어야 합니다.

- [x] **Flutter 프로젝트 열기**
  - VSCode에서 `C:\project\front\main` 폴더 열기

- [x] **http 패키지 확인**
  - `pubspec.yaml`에 `http: ^1.1.0` 있는지 확인
  - 없으면 추가 후 `flutter pub get` 실행

### 📁 수정할 파일

| 파일 | 경로 | 수정 필요 여부 |
|------|------|---------------|
| `pet_profile.dart` | `lib/models/pet_profile.dart` | ✅ 완료 |
| `pet_service.dart` | `lib/services/pet_service.dart` | ⚠️ 수정 필요 |
| `add_pet_profile_screen.dart` | `lib/screens/add_pet_profile_screen.dart` | ⚠️ 수정 필요 |

---

## 백엔드 API 이해하기

### 🎯 엔드포인트

```
POST http://localhost:9075/api/v1/pets
Content-Type: application/json
```

### 📤 요청 형식 (Request Body)

```json
{
  "userId": 1,
  "name": "댕댕이",
  "species": "DOG",
  "birthdate": "2020-05-15",
  "weight": 5.5,
  "abitTypeCode": "ENFP",
  "gender": "MALE",
  "speciesDetail": "말티즈",
  "imageUrl": null
}
```

### 📥 응답 형식 (Response)

**성공 (201 Created)**:
```json
{
  "ok": true,
  "data": { "id": 123 },
  "error": null,
  "message": null
}
```

**실패 (400 Bad Request)**:
```json
{
  "ok": false,
  "data": null,
  "error": "VALIDATION_ERROR",
  "message": "이름은 20자 이하로 입력해주세요"
}
```

### 🔑 필수 필드 (반드시 값이 있어야 함!)

| 필드 | 타입 | 예시 값 | 주의사항 |
|------|------|---------|---------|
| `userId` | 정수 | `1` | 로그인한 사용자 ID |
| `name` | 문자열 | `"댕댕이"` | 최대 20자 |
| `species` | 문자열 | `"DOG"` 또는 `"CAT"` | **반드시 대문자!** |
| `birthdate` | 문자열 | `"2020-05-15"` | yyyy-MM-dd 형식 |
| `weight` | 실수 | `5.5` | 0보다 큰 값 |
| `abitTypeCode` | 문자열 | `"ENFP"` | 16개 MBTI 중 하나, **대문자** |
| `gender` | 문자열 | `"MALE"` 또는 `"FEMALE"` | **반드시 대문자!** |

### ⚪ 선택 필드 (없어도 됨)

| 필드 | 타입 | 예시 값 |
|------|------|---------|
| `speciesDetail` | 문자열 | `"말티즈"` |
| `imageUrl` | 문자열 | `"http://..."` |

---

## Step 1: PetService 수정

### 📍 파일: `lib/services/pet_service.dart`

현재 `pet_service.dart`에는 `gender`와 `speciesDetail` 필드가 **누락**되어 있습니다!

### 🔴 현재 코드 (Line 12-20)

```dart
Future<Map<String, dynamic>> createPet({
  required int userId,
  required String name,
  required String species, // "DOG" or "CAT"
  required String birthdate, // "yyyy-MM-dd"
  required double weight, // 몸무게 (kg)
  required String abitTypeCode, // MBTI 코드
  String? imageUrl, // 나중에 구현
}) async {
```

### ✅ 수정된 코드

아래 코드로 **Line 12-62 전체를 교체**하세요:

```dart
  /// 펫 프로필 등록 API 호출
  Future<Map<String, dynamic>> createPet({
    required int userId,
    required String name,
    required String species,       // "DOG" or "CAT"
    required String birthdate,     // "yyyy-MM-dd"
    required double weight,        // 몸무게 (kg)
    required String abitTypeCode,  // MBTI 코드 (예: "ENFP")
    required String gender,        // ✅ 추가: "MALE" or "FEMALE"
    String? speciesDetail,         // ✅ 추가: 품종 (예: "말티즈")
    String? imageUrl,              // 선택사항
  }) async {
    final url = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "name": name,
          "species": species,
          "birthdate": birthdate,
          "weight": weight,
          "abitTypeCode": abitTypeCode,
          "gender": gender,              // ✅ 추가
          "speciesDetail": speciesDetail, // ✅ 추가
          "imageUrl": imageUrl,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {
            "success": true,
            "message": "펫 프로필이 등록되었습니다.",
            "petId": data["data"]["id"],
          };
        } else {
          return {
            "success": false,
            "message": data["message"] ?? "펫 프로필 등록 실패",
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "서버 오류 (${response.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }
```

### 📝 수정 요약

1. **Line 19**: `required String gender,` 추가
2. **Line 20**: `String? speciesDetail,` 추가
3. **Line 32**: `"gender": gender,` 추가
4. **Line 33**: `"speciesDetail": speciesDetail,` 추가

---

## Step 2: add_pet_profile_screen.dart 수정

### 📍 파일: `lib/screens/add_pet_profile_screen.dart`

이 파일은 **5단계**로 나눠서 수정합니다.

---

### 🔹 수정 1: import 추가 (Line 1-6)

**현재 코드**:
```dart
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';
```

**수정 후**:
```dart
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';
import '../services/pet_service.dart';  // ✅ 이 줄 추가!
```

---

### 🔹 수정 2: 상태 변수 값 변경 (Line 34-38)

현재 성별과 종류가 한글/소문자로 되어 있는데, 백엔드는 **영어 대문자**를 요구합니다!

**Line 34 수정 전**:
```dart
String? _selectedGender;  // 'Man' 또는 'Woman'
```

**Line 34 수정 후**:
```dart
String? _selectedGender;  // 'MALE' 또는 'FEMALE' (백엔드 형식)
```

**Line 37 수정 전**:
```dart
String? _selectedSpecies;  // 'dog' 또는 'cat'
```

**Line 37 수정 후**:
```dart
String? _selectedSpecies;  // 'DOG' 또는 'CAT' (백엔드 형식)
```

---

### 🔹 수정 3: dispose 메서드에 _weightController 추가 (Line 92-99)

**현재 코드**:
```dart
@override
void dispose() {
  _nameController.dispose();
  _birthdayController.dispose();
  _breedController.dispose();
  _diseaseController.dispose();
  super.dispose();
}
```

**수정 후**:
```dart
@override
void dispose() {
  _nameController.dispose();
  _birthdayController.dispose();
  _breedController.dispose();
  _diseaseController.dispose();
  _weightController.dispose();  // ✅ 추가!
  super.dispose();
}
```

---

### 🔹 수정 4: 성별 버튼 값 변경 (화면에서 찾기)

`_buildGenderButton`을 호출하는 부분을 찾아서 값을 변경합니다.

**Ctrl + F**로 `_buildGenderButton` 검색 → 해당 부분을 찾으세요.

**현재 코드** (예상):
```dart
_buildGenderButton('Man', Icons.male, Colors.blue),
_buildGenderButton('Woman', Icons.female, Colors.red),
```

**수정 후**:
```dart
_buildGenderButton('MALE', Icons.male, Colors.blue),
_buildGenderButton('FEMALE', Icons.female, Colors.red),
```

---

### 🔹 수정 5: 등록 버튼 로직 완전 교체 (Line 577-635)

이 부분이 **가장 중요**합니다! `_buildRegisterButton()` 메서드를 **완전히 교체**하세요.

**현재 코드** (Line 577-635):
```dart
Widget _buildRegisterButton() {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(20),
    child: ElevatedButton(
      onPressed: () {
        // 필수 입력 확인
        if (_nameController.text.trim().isEmpty) {
          // ... 생략 ...
        }

        // 프로필 저장
        final profile = PetProfile(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: _nameController.text.trim(),
          // ... 생략 ...
        );

        // 프로필 매니저에 추가
        PetProfileManager().addProfile(profile);
        // ... 생략 ...
      },
      // ... 생략 ...
    ),
  );
}
```

**수정 후** (아래 코드로 **전체 교체**):

```dart
  /// 프로필 등록 버튼
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () async {
          // ===== 1. 입력 검증 =====
          if (_nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('펫 이름을 입력해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          if (_selectedSpecies == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('강아지 또는 고양이를 선택해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          if (_birthdayController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('생년월일을 입력해주세요. (예: 2020-05-15)'), backgroundColor: Colors.red),
            );
            return;
          }

          if (_weightController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('몸무게를 입력해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          double? weight;
          try {
            weight = double.parse(_weightController.text.trim());
            if (weight <= 0) {
              throw FormatException('양수여야 합니다');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('몸무게는 0보다 큰 숫자로 입력해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          if (_selectedGender == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('성별을 선택해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          if (_selectedAbtiType == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('ABTI 테스트를 완료해주세요.'), backgroundColor: Colors.red),
            );
            return;
          }

          // ===== 2. 로딩 표시 =====
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color.fromARGB(255, 0, 108, 82)),
              ),
            ),
          );

          try {
            // ===== 3. API 호출 =====
            final result = await PetService().createPet(
              userId: 1, // TODO: 실제 로그인한 사용자 ID로 변경
              name: _nameController.text.trim(),
              species: _selectedSpecies!,  // "DOG" 또는 "CAT"
              birthdate: _birthdayController.text.trim(),  // "yyyy-MM-dd"
              weight: weight,
              abitTypeCode: _selectedAbtiType!,  // "ENFP" 등
              gender: _selectedGender!,  // "MALE" 또는 "FEMALE"
              speciesDetail: _selectedBreed,  // 품종 (선택사항)
              imageUrl: _selectedImageUrl,  // 이미지 URL (선택사항)
            );

            // ===== 4. 로딩 닫기 =====
            Navigator.pop(context);

            // ===== 5. 결과 처리 =====
            if (result['success'] == true) {
              // 성공
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_nameController.text.trim()} 프로필이 등록되었습니다!'),
                  backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                ),
              );
              Navigator.pop(context, true);  // 이전 화면으로 돌아가기
            } else {
              // 실패
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? '등록 실패'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            // ===== 6. 오류 처리 =====
            Navigator.pop(context);  // 로딩 닫기
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('오류가 발생했습니다: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 108, 82),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '프로필 등록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
```

### 📝 주요 변경 사항

| 항목 | 변경 전 | 변경 후 |
|------|---------|---------|
| 함수 타입 | `onPressed: ()` | `onPressed: () async` |
| 저장 방식 | `PetProfileManager()` | `PetService().createPet()` |
| 검증 | 이름만 | 모든 필수 필드 |
| 로딩 | 없음 | CircularProgressIndicator |
| 에러 처리 | 없음 | try-catch |

---

## Step 3: 테스트하기

### 🧪 테스트 시나리오

#### ✅ 정상 케이스

1. **Flutter 앱 실행**
   ```bash
   cd C:\project\front\main
   flutter run
   ```

2. **펫 등록 화면으로 이동**

3. **다음 정보 입력**:
   - 펫 이름: `댕댕이`
   - 종: **강아지 선택** (자동으로 "DOG"로 저장)
   - 생년월일: `2020-05-15`
   - 몸무게: `5.5`
   - 품종: `말티즈`
   - 성별: **남자 선택** (자동으로 "MALE"로 저장)
   - ABTI: `ENFP`

4. **등록 버튼 클릭**

5. **예상 결과**:
   - 로딩 표시 나타남
   - "댕댕이 프로필이 등록되었습니다!" 메시지
   - 이전 화면으로 돌아감

#### ❌ 에러 케이스

**테스트 1**: 필수 필드 누락
- 이름만 입력하고 등록 → "강아지 또는 고양이를 선택해주세요." 에러

**테스트 2**: 잘못된 몸무게
- 몸무게에 `abc` 입력 → "몸무게는 0보다 큰 숫자로 입력해주세요." 에러

**테스트 3**: 날짜 형식 오류
- 생년월일에 `20200515` 입력 → 백엔드에서 400 에러 반환

---

### 🗄️ 데이터베이스 확인

등록 성공 후 MySQL에서 확인:

```sql
mysql -h project-db-campus.smhrd.com -P 3312 -u Insa6_aiservice_p3_2 -p
use Insa6_aiservice_p3_2;

SELECT * FROM pets ORDER BY id DESC LIMIT 5;
```

**확인할 내용**:
- `p_name`: "댕댕이"
- `species`: "DOG" (대문자)
- `p_birthdate`: "2020-05-15"
- `weight`: 5.5
- `abit_type_code`: "ENFP"
- `gender`: "MALE" (대문자)
- `species_detail`: "말티즈"

---

## 문제 해결

### 🔴 문제 1: "네트워크 오류" 발생

**원인**: 백엔드 서버가 꺼져 있거나 URL이 잘못됨

**해결**:
1. 백엔드 실행 확인:
   ```bash
   curl http://localhost:9075/api/v1/pets
   ```

2. **Android 에뮬레이터** 사용 시:
   - `pet_service.dart`의 Line 9 확인
   - `baseUrl`이 `http://10.0.2.2:9075/api/v1/pets`인지 확인

3. **실제 기기** 사용 시:
   - 컴퓨터와 같은 Wi-Fi 연결
   - `baseUrl`을 `http://[컴퓨터IP]:9075/api/v1/pets`로 변경
   - 예: `http://192.168.0.10:9075/api/v1/pets`

---

### 🔴 문제 2: "VALIDATION_ERROR" 발생

**원인**: 백엔드 검증 규칙 위반

**해결**:
1. **대문자 확인**:
   - `species`: "DOG" 또는 "CAT" (소문자 ❌)
   - `gender`: "MALE" 또는 "FEMALE" (소문자 ❌)
   - `abitTypeCode`: "ENFP" 등 (소문자 ❌)

2. **날짜 형식 확인**:
   - ✅ "2020-05-15"
   - ❌ "2020/05/15"
   - ❌ "20200515"

3. **필드 길이 확인**:
   - `name`: 최대 20자
   - `speciesDetail`: 최대 30자

---

### 🔴 문제 3: "사용자 ID를 찾을 수 없음" 에러

**원인**: `userId: 1`이 데이터베이스에 없음

**해결**:
1. **Flutter 앱에서 회원가입** 진행
2. 로그인 후 실제 사용자 ID 사용
3. 또는 데이터베이스에 있는 사용자 ID로 변경

**임시 해결** (테스트용):
```dart
userId: 1, // ← 이 값을 데이터베이스에 있는 ID로 변경
```

---

### 🔴 문제 4: 성별/종이 영어로 표시됨

**원인**: 버튼 라벨을 "MALE", "DOG"로 변경해서 화면에도 영어로 보임

**해결** (선택사항 - UI 개선):

`_buildGenderButton` 메서드를 찾아서 다음처럼 수정:

```dart
Widget _buildGenderButton(String value, IconData icon, Color color) {
  final bool isSelected = _selectedGender == value;

  // 화면 표시용 라벨 (한글)
  String displayLabel = value == 'MALE' ? '남자' : '여자';

  return GestureDetector(
    onTap: () {
      setState(() {
        _selectedGender = value;  // 내부 값은 "MALE"/"FEMALE"
      });
    },
    child: Column(
      children: [
        // ... 아이콘 ...
        Text(
          displayLabel,  // 화면에는 "남자"/"여자" 표시
          // ... 스타일 ...
        ),
      ],
    ),
  );
}
```

---

## 🎯 최종 체크리스트

연결 완료 후 확인:

- [ ] `pet_service.dart`에 `gender`, `speciesDetail` 파라미터 추가됨
- [ ] `add_pet_profile_screen.dart`에 `import '../services/pet_service.dart';` 추가됨
- [ ] 성별 값이 "MALE"/"FEMALE"로 변경됨
- [ ] 종 값이 "DOG"/"CAT"로 변경됨
- [ ] `_weightController.dispose()` 추가됨
- [ ] `_buildRegisterButton()` 메서드가 새 코드로 교체됨
- [ ] 백엔드 서버 실행 중
- [ ] 테스트: 정상 케이스 통과
- [ ] 테스트: 에러 케이스 통과
- [ ] 데이터베이스에 데이터 확인됨

---

## 🎓 학습 포인트

이 작업을 통해 배울 수 있는 것:

1. **RESTful API 통신**: HTTP POST 요청으로 데이터 전송
2. **JSON 직렬화**: Dart 객체 → JSON → 서버
3. **비동기 프로그래밍**: `async/await`로 API 호출 대기
4. **에러 핸들링**: `try-catch`로 네트워크 오류 처리
5. **사용자 입력 검증**: 필수 필드 확인, 형식 검증
6. **로딩 UI**: 사용자 경험 개선

---

## 📚 참고 자료

### 백엔드 파일
- Controller: `backend/demo/src/main/java/com/example/pet/demo/pets/api/PetController.java`
- DTO: `backend/demo/src/main/java/com/example/pet/demo/pets/api/dto/PetCreateReq.java`
- Entity (Pet): `backend/demo/src/main/java/com/example/pet/demo/pets/domain/Pet.java`

### 프론트엔드 파일
- Service: `front/main/lib/services/pet_service.dart`
- Screen: `front/main/lib/screens/add_pet_profile_screen.dart`
- Model: `front/main/lib/models/pet_profile.dart`

### 유용한 링크
- Flutter HTTP 패키지: https://pub.dev/packages/http
- Spring Boot REST API: https://spring.io/guides/gs/rest-service/
- Flutter Form Validation: https://docs.flutter.dev/cookbook/forms/validation

---

## 🚀 다음 단계

1. **이미지 업로드** 기능 추가
2. **펫 목록 조회** 구현
3. **펫 프로필 수정/삭제** 기능
4. **실제 로그인 사용자 ID** 연동

---

막히는 부분이 있으면 에러 메시지를 캡처해서 확인하세요!

화이팅! 🎉
