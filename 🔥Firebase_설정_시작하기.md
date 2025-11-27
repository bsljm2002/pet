# 🔥 Firebase 설정 시작하기

## ✅ 자동 완료된 작업

다음 작업들은 **이미 완료**되었습니다:

1. ✅ Firebase 패키지 설치 (`firebase_core`, `firebase_messaging`)
2. ✅ FCM 서비스 코드 작성
3. ✅ Android Gradle 설정
4. ✅ `.gitignore` 보안 설정
5. ✅ 백엔드 NotificationService 구현
6. ✅ Flutter 패키지 설치 완료

---

## 📋 지금 해야 할 작업 (Firebase Console에서)

### 🎯 필수 작업 3가지만 하면 됩니다!

#### 1️⃣ **Firebase 프로젝트 생성** (5분)
- https://console.firebase.google.com 접속
- "프로젝트 추가" 클릭
- 프로젝트 이름 입력 (예: `PetCare`)

#### 2️⃣ **Android 앱 추가 및 파일 다운로드** (3분)
- Android 아이콘(🤖) 클릭
- 패키지명 입력: `com.example.signin`
- **`google-services.json` 다운로드**
- 파일을 다음 위치에 복사:
  ```
  c:\project\front\main\android\app\google-services.json
  ```

#### 3️⃣ **설정 값 복사 및 업데이트** (5분)
- Firebase Console에서 프로젝트 설정 > 일반 탭
- API 키, 앱 ID 등을 복사
- `firebase_options.dart` 파일에 붙여넣기

---

## 📖 상세 가이드

**단계별 스크린샷 포함 가이드:**
👉 [Firebase_Console_설정_단계별_가이드.md](./Firebase_Console_설정_단계별_가이드.md)

**완료 체크리스트:**
👉 [Firebase_설정_완료_체크리스트.md](./Firebase_설정_완료_체크리스트.md)

---

## 🚀 빠른 시작

### 1. Firebase Console 접속
```
https://console.firebase.google.com
```

### 2. 필요한 정보
- ✅ Android 패키지명: `com.example.signin`
- ✅ 앱 이름: `signin` (피터펫)

### 3. 다운로드해야 할 파일
1. **`google-services.json`** (Android 앱)
   - 저장 위치: `c:\project\front\main\android\app\`

2. **서비스 계정 JSON** (백엔드)
   - 저장 위치: `c:\project\backend\demo\src\main\resources\`
   - 파일명: `firebase-service-account.json`

### 4. 업데이트해야 할 파일
**`c:\project\front\main\lib\firebase_options.dart`**
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',              // 👈 여기 업데이트
  appId: '1:123456...:android:...', // 👈 여기 업데이트
  messagingSenderId: '123456789012',// 👈 여기 업데이트
  projectId: 'your-project-id',     // 👈 여기 업데이트
  storageBucket: 'your-project-id.appspot.com',
);
```

---

## ⏱️ 예상 소요 시간

- Firebase 프로젝트 생성: **5분**
- Android 앱 추가: **3분**
- 파일 다운로드 및 복사: **2분**
- 설정 값 업데이트: **5분**

**총 소요 시간: 약 15분** ⏰

---

## 🎯 완료 후 테스트

### 1. Flutter 앱 실행
```bash
cd c:\project\front\main
flutter run
```

### 2. 로그 확인
다음과 같은 로그가 나타나면 성공:
```
✅ FCM 알림 권한 허용됨
📱 FCM 토큰: eyJhbGciOiJ...
✅ FCM 서비스 초기화 완료
```

### 3. 실제 기능 테스트
1. 일반 사용자로 예약 생성
2. 파트너 계정으로 예약 확정/거절
3. **자동으로 UI가 업데이트**되는지 확인! ✨

---

## ⚠️ 중요 주의사항

### 절대 커밋하지 말 것
- ❌ `google-services.json`
- ❌ `firebase-service-account.json`
- ❌ `firebase_options.dart` (실제 키 입력 후)

이 파일들은 이미 `.gitignore`에 추가되어 있습니다.

### 패키지명 정확히 입력
Firebase Console에서 Android 앱 추가 시:
```
com.example.signin
```
**오타 주의!** 한 글자라도 틀리면 작동하지 않습니다.

---

## 🆘 도움이 필요하면

1. **상세 가이드 확인**: [Firebase_Console_설정_단계별_가이드.md](./Firebase_Console_설정_단계별_가이드.md)
2. **체크리스트 확인**: [Firebase_설정_완료_체크리스트.md](./Firebase_설정_완료_체크리스트.md)
3. **문제 해결 섹션** 참고

---

## 🎉 준비 완료!

위 3가지 필수 작업만 완료하면:
- ✨ 예약 확정/거절 시 **자동으로 UI 업데이트**
- 📱 고객에게 **실시간 푸시 알림** 전송
- 🔄 **새로고침 버튼 없이** 자동 갱신

**지금 바로 시작하세요!** 🚀

👉 **다음 단계**: [Firebase_Console_설정_단계별_가이드.md](./Firebase_Console_설정_단계별_가이드.md)
