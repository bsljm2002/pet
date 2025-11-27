# 🔥 Firebase 설정 가이드

## 1단계: Firebase Console 접속 및 프로젝트 생성

1. **Firebase Console 접속**: https://console.firebase.google.com
2. **프로젝트 추가** 클릭
3. 프로젝트 이름 입력 (예: "PetCare" 또는 "피터펫")
4. Google Analytics 설정 (선택사항, 비활성화 가능)
5. **프로젝트 만들기** 클릭

---

## 2단계: Android 앱 추가

### A. Android 앱 등록

1. Firebase 프로젝트 페이지에서 **Android 아이콘(🤖)** 클릭
2. **Android 패키지 이름** 입력: `com.example.signin`
   - 중요: pubspec.yaml의 `name: signin` 기반
3. **앱 닉네임** (선택): "PetCare Android"
4. **디버그 서명 인증서 SHA-1** (선택, 나중에 추가 가능)
5. **앱 등록** 클릭

### B. google-services.json 다운로드

1. `google-services.json` 파일 다운로드
2. 다운로드한 파일을 다음 경로에 복사:
   ```
   c:\project\front\main\android\app\google-services.json
   ```

### C. Firebase SDK 추가 (이미 설정됨, 확인용)

`android/build.gradle` 확인:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.4.2'
    }
}
```

`android/app/build.gradle` 확인:
```gradle
apply plugin: 'com.google.gms.google-services'
```

---

## 3단계: Firebase Cloud Messaging (FCM) 설정

### A. 프로젝트 설정에서 Cloud Messaging 활성화

1. Firebase Console에서 **프로젝트 설정** (⚙️) 클릭
2. **클라우드 메시징** 탭 선택
3. **Cloud Messaging API (V1)** 활성화
4. **서버 키** 및 **발신자 ID** 확인 및 복사

### B. firebase_options.dart 업데이트

다음 파일을 수정하세요:
`c:\project\front\main\lib\firebase_options.dart`

Firebase Console의 **프로젝트 설정 > 일반** 탭에서 확인할 수 있는 값으로 변경:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...', // 웹 API 키
  appId: '1:1234567890:android:abcd1234', // Android 앱 ID
  messagingSenderId: '1234567890', // 발신자 ID
  projectId: 'your-project-id', // 프로젝트 ID
  storageBucket: 'your-project-id.appspot.com',
);
```

---

## 4단계: 백엔드 Firebase Admin SDK 설정

### A. Firebase 서비스 계정 키 생성

1. Firebase Console > **프로젝트 설정** > **서비스 계정** 탭
2. **새 비공개 키 생성** 클릭
3. JSON 파일 다운로드
4. 파일 이름을 `firebase-service-account.json`으로 변경
5. 다음 경로에 저장:
   ```
   c:\project\backend\demo\src\main\resources\firebase-service-account.json
   ```

### B. .gitignore 업데이트 (중요!)

`c:\project\backend\demo\.gitignore`에 다음 추가:
```
src/main/resources/firebase-service-account.json
```

---

## 5단계: 패키지 설치

터미널에서 실행:

```bash
cd c:\project\front\main
flutter pub get
```

---

## 6단계: 테스트

### A. Flutter 앱 실행

```bash
cd c:\project\front\main
flutter run
```

### B. FCM 토큰 확인

앱 로그에서 다음과 같은 메시지 확인:
```
✅ FCM 알림 권한 허용됨
📱 FCM 토큰: ey...
```

### C. 알림 테스트

Firebase Console > **Cloud Messaging** > **첫 번째 캠페인 만들기**에서 테스트 알림 전송

---

## 🎯 완료 체크리스트

- [ ] Firebase 프로젝트 생성
- [ ] Android 앱 추가
- [ ] `google-services.json` 파일 복사
- [ ] `firebase_options.dart` 값 업데이트
- [ ] Firebase 서비스 계정 키 다운로드 및 저장
- [ ] `.gitignore` 업데이트
- [ ] `flutter pub get` 실행
- [ ] 앱 실행 및 FCM 토큰 확인

---

## ⚠️ 주의사항

1. **절대 커밋하지 말 것**:
   - `google-services.json`
   - `firebase-service-account.json`
   - FCM 토큰

2. **Package Name 일치**:
   - Firebase: `com.example.signin`
   - AndroidManifest.xml: `com.example.signin`

3. **인터넷 연결 필수**: FCM은 인터넷이 필요합니다

---

## 🆘 문제 해결

### "MissingPluginException" 오류

```bash
flutter clean
flutter pub get
flutter run
```

### "Firebase not initialized" 오류

`firebase_options.dart`의 값이 올바른지 확인

### 알림이 오지 않을 때

1. 알림 권한 확인
2. FCM 토큰이 생성되었는지 확인
3. 백엔드 서버가 실행 중인지 확인
4. 인터넷 연결 확인
