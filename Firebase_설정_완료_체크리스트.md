# ✅ Firebase 설정 완료 체크리스트

## 🎯 완료된 작업

### 1. ✅ Flutter 프론트엔드 설정
- [x] Firebase 패키지 설치 (`firebase_core`, `firebase_messaging`)
- [x] FCM 서비스 생성 (`lib/services/fcm_service.dart`)
- [x] main.dart에서 Firebase 초기화
- [x] `firebase_options.dart` 템플릿 생성
- [x] Android Gradle 설정 (`google-services` 플러그인 추가)
- [x] `.gitignore` 업데이트 (보안)
- [x] `flutter pub get` 실행 완료
- [x] Hospital Reservation Screen에 FCM 리스너 추가

### 2. ✅ 백엔드 설정
- [x] NotificationService 업데이트
  - `sendReservationAccepted()` - 고객에게 예약 수락 알림
  - `sendNewReservationToPartner()` - 파트너에게 새 예약 알림
  - `sendReservationUpdateToPartner()` - 파트너에게 예약 업데이트 알림
  - `sendReservationRejected()` - 고객에게 예약 거절 알림
- [x] ReservationService에서 알림 전송 연동

---

## 📝 아직 해야 할 작업

### 1. Firebase Console 설정 (중요! 반드시 필요)

#### A. Firebase 프로젝트 생성
1. https://console.firebase.google.com 접속
2. "프로젝트 추가" 클릭
3. 프로젝트 이름 입력 (예: "PetCare" 또는 원하는 이름)
4. Google Analytics 설정 (선택사항)
5. "프로젝트 만들기" 클릭

#### B. Android 앱 추가
1. Firebase Console에서 **Android 아이콘(🤖)** 클릭
2. Android 패키지 이름: `com.example.signin` (정확히 입력!)
3. 앱 닉네임 (선택): "PetCare Android"
4. "앱 등록" 클릭
5. **`google-services.json` 다운로드**
6. 다운로드한 파일을 **다음 경로에 복사**:
   ```
   c:\project\front\main\android\app\google-services.json
   ```

#### C. firebase_options.dart 값 업데이트
1. Firebase Console > **프로젝트 설정** (⚙️ 아이콘)
2. **일반** 탭에서 Android 앱 정보 확인
3. 다음 값을 복사:
   - API 키 (웹 API 키)
   - 앱 ID (Android 앱 ID)
   - 발신자 ID (Cloud Messaging 발신자 ID)
   - 프로젝트 ID

4. `c:\project\front\main\lib\firebase_options.dart` 파일 수정:
   ```dart
   static const FirebaseOptions android = FirebaseOptions(
     apiKey: 'AIzaSy...여기에_복사한_API_키',
     appId: '1:123456...:android:abcd...',
     messagingSenderId: '123456...',
     projectId: 'your-project-id',
     storageBucket: 'your-project-id.appspot.com',
   );
   ```

#### D. Cloud Messaging API 활성화
1. Firebase Console > **프로젝트 설정** > **클라우드 메시징** 탭
2. **Cloud Messaging API (V1)** 활성화

#### E. 백엔드용 서비스 계정 키 생성
1. Firebase Console > **프로젝트 설정** > **서비스 계정** 탭
2. **새 비공개 키 생성** 클릭
3. JSON 파일 다운로드
4. 파일 이름을 `firebase-service-account.json`으로 변경
5. **다음 경로에 저장**:
   ```
   c:\project\backend\demo\src\main\resources\firebase-service-account.json
   ```
6. ⚠️ **`.gitignore`에 추가** (이미 추가되어 있어야 함):
   ```
   src/main/resources/firebase-service-account.json
   ```

---

### 2. Sitter Reservation Screen FCM 추가 (선택사항)

펫시터 예약 화면에도 동일한 FCM 리스너를 추가하려면:

파일: `c:\project\front\main\lib\screens\partner\sitter_reservation_screen.dart`

Hospital Reservation Screen과 동일한 방식으로 FCM 리스너 추가

---

## 🧪 테스트 방법

### 1. 앱 실행
```bash
cd c:\project\front\main
flutter run
```

### 2. FCM 토큰 확인
앱 실행 후 콘솔 로그에서 다음 확인:
```
✅ FCM 알림 권한 허용됨
📱 FCM 토큰: eyJ...
```

### 3. 알림 권한 허용
- 앱 첫 실행 시 알림 권한 요청 팝업이 나타남
- **허용** 클릭

### 4. 예약 확정/거절 테스트
1. **일반 사용자 계정**으로 예약 생성
2. **파트너 계정**으로 로그인
3. 예약 관리 화면에서 **확정** 또는 **거절** 클릭
4. 예약 목록이 **자동으로 새로고침**되는지 확인
5. 일반 사용자 앱에 **알림**이 도착하는지 확인

---

## ⚠️ 중요 주의사항

### 1. 절대 커밋하지 말 것
- ❌ `google-services.json`
- ❌ `firebase-service-account.json`
- ❌ `firebase_options.dart` (실제 키 값 입력 후)

### 2. Package Name 일치 필수
모든 곳에서 **`com.example.signin`** 사용:
- Firebase Console
- AndroidManifest.xml
- build.gradle.kts

### 3. 인터넷 연결 필수
FCM은 인터넷 연결이 필요합니다.

---

## 🔍 문제 해결

### "MissingPluginException" 오류
```bash
flutter clean
flutter pub get
flutter run
```

### "Firebase not initialized" 오류
- `firebase_options.dart`의 값이 올바른지 확인
- `google-services.json` 파일이 올바른 위치에 있는지 확인

### 알림이 오지 않을 때
1. ✅ 알림 권한 허용했는지 확인
2. ✅ FCM 토큰이 생성되었는지 로그 확인
3. ✅ `google-services.json` 파일 올바른 위치 확인
4. ✅ `firebase_options.dart` 값 정확히 입력했는지 확인
5. ✅ 백엔드 서버 실행 중인지 확인
6. ✅ 인터넷 연결 확인

### Firebase Console에서 테스트 알림 보내기
1. Firebase Console > **Cloud Messaging**
2. **첫 번째 캠페인 만들기** 클릭
3. 알림 메시지 작성
4. FCM 토큰 직접 입력하여 테스트

---

## 📚 참고 문서

- [Firebase 설정 가이드 전체](c:\project\Firebase_설정_가이드.md)
- [Flutter Firebase 공식 문서](https://firebase.flutter.dev/)
- [FCM 개요](https://firebase.google.com/docs/cloud-messaging)

---

## 🎉 완료 후 확인

다음이 모두 작동하면 설정 완료:

- [ ] 앱이 정상적으로 실행됨
- [ ] FCM 토큰이 생성됨
- [ ] 알림 권한 허용됨
- [ ] 파트너가 예약 확정/거절 시 자동으로 UI 업데이트됨
- [ ] 고객에게 알림이 도착함

---

**다음 단계**: 위의 "📝 아직 해야 할 작업" 섹션을 순서대로 진행하세요!
