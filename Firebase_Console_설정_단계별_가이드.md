# 🔥 Firebase Console 설정 - 단계별 가이드

## 준비사항
- ✅ Android 패키지명: `com.example.signin`
- ✅ 앱 이름: `signin` (피터펫)

---

## 1단계: Firebase 프로젝트 생성

### A. Firebase Console 접속
1. 브라우저에서 다음 주소 열기:
   ```
   https://console.firebase.google.com
   ```
2. Google 계정으로 로그인

### B. 새 프로젝트 만들기
1. **"프로젝트 추가"** 또는 **"Add project"** 버튼 클릭
2. **프로젝트 이름** 입력:
   - 예시: `PetCare` 또는 `피터펫` (원하는 이름)
   - 자동으로 프로젝트 ID 생성됨 (예: `petcare-12345`)
3. **"계속"** 클릭

### C. Google Analytics 설정 (선택사항)
1. **"이 프로젝트에 Google Analytics 사용 설정"**
   - ✅ 활성화 (추천) 또는 비활성화
2. Analytics 계정 선택 (새 계정 만들기 또는 기존 계정 선택)
3. **"프로젝트 만들기"** 클릭
4. 프로젝트 생성 완료까지 **30초~1분** 대기

---

## 2단계: Android 앱 추가

### A. Android 앱 등록
1. Firebase 프로젝트 홈페이지에서 **Android 아이콘 (🤖)** 클릭
   - 또는 **"앱 추가" > "Android"** 선택
2. **Android 패키지 이름** 입력:
   ```
   com.example.signin
   ```
   ⚠️ **정확히 입력해야 합니다!** (오타 주의)

3. **앱 닉네임** (선택사항):
   ```
   피터펫 Android
   ```

4. **디버그 서명 인증서 SHA-1** (선택사항, 지금은 건너뛰기)
   - 나중에 추가 가능

5. **"앱 등록"** 클릭

### B. google-services.json 다운로드
1. **"google-services.json 다운로드"** 버튼 클릭
2. 파일이 다운로드 폴더에 저장됨
3. **다운로드한 파일을 다음 경로로 이동/복사**:
   ```
   c:\project\front\main\android\app\google-services.json
   ```

   **Windows 탐색기에서 파일 복사 방법**:
   - 다운로드 폴더에서 `google-services.json` 파일 찾기
   - 파일 복사 (Ctrl+C)
   - `c:\project\front\main\android\app` 폴더 열기
   - 붙여넣기 (Ctrl+V)

4. Firebase Console에서 **"다음"** 클릭

### C. Firebase SDK 추가 (이미 완료됨)
Firebase Console에서 안내하는 단계:
- ✅ 이미 설정되어 있으므로 **"다음"** 클릭

### D. 앱 실행 확인
- **"콘솔로 이동"** 클릭

---

## 3단계: Cloud Messaging (FCM) 설정

### A. Cloud Messaging API 활성화
1. Firebase Console 좌측 메뉴에서 **⚙️ 프로젝트 설정** 클릭
2. **"클라우드 메시징"** 탭 클릭
3. **Cloud Messaging API (V1)** 섹션에서:
   - "활성화" 또는 "Enable" 링크 클릭
   - Google Cloud Console로 이동됨
   - **"API 사용 설정"** 또는 **"Enable"** 클릭
4. 다시 Firebase Console로 돌아오기

### B. 프로젝트 정보 확인 및 복사
1. **"일반"** 탭 클릭
2. **"내 앱"** 섹션에서 Android 앱 찾기
3. 다음 정보 복사 (메모장에 저장):

   **웹 API 키**:
   ```
   AIzaSy... (복사)
   ```

   **앱 ID** (앱 등록 정보에서):
   ```
   1:123456789012:android:abcd1234... (복사)
   ```

   **프로젝트 ID**:
   ```
   petcare-12345 (복사)
   ```

4. **"클라우드 메시징"** 탭으로 다시 이동
5. **발신자 ID** 복사:
   ```
   123456789012 (복사)
   ```

---

## 4단계: firebase_options.dart 업데이트

### A. 파일 열기
다음 파일을 편집기로 열기:
```
c:\project\front\main\lib\firebase_options.dart
```

### B. Android 섹션 값 업데이트
복사한 값으로 교체:

```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'AIzaSy...',              // 👈 여기에 웹 API 키 붙여넣기
  appId: '1:123456...:android:...',  // 👈 여기에 앱 ID 붙여넣기
  messagingSenderId: '123456789012',  // 👈 여기에 발신자 ID 붙여넣기
  projectId: 'petcare-12345',        // 👈 여기에 프로젝트 ID 붙여넣기
  storageBucket: 'petcare-12345.appspot.com', // 👈 프로젝트ID.appspot.com
);
```

### C. 파일 저장
- Ctrl+S 또는 파일 > 저장

---

## 5단계: 백엔드용 서비스 계정 키 다운로드

### A. 서비스 계정 키 생성
1. Firebase Console에서 **⚙️ 프로젝트 설정** 클릭
2. **"서비스 계정"** 탭 클릭
3. **"새 비공개 키 생성"** 버튼 클릭
4. 경고 창에서 **"키 생성"** 확인
5. JSON 파일 자동 다운로드됨

### B. 파일 이름 변경 및 이동
1. 다운로드 폴더에서 다운로드된 JSON 파일 찾기
   - 파일명 예시: `petcare-12345-firebase-adminsdk-xxxxx-xxxxxxxxxx.json`
2. 파일 이름을 다음으로 변경:
   ```
   firebase-service-account.json
   ```
3. 파일을 다음 경로로 이동/복사:
   ```
   c:\project\backend\demo\src\main\resources\firebase-service-account.json
   ```

### C. .gitignore 확인 (보안 중요!)
다음 파일이 이미 gitignore에 추가되어 있는지 확인:
```
c:\project\backend\demo\.gitignore
```

다음 줄이 있어야 함:
```
src/main/resources/firebase-service-account.json
```

없다면 추가하기!

---

## 6단계: 설정 확인

### A. 파일 위치 확인
다음 파일들이 올바른 위치에 있는지 확인:

✅ `c:\project\front\main\android\app\google-services.json`
✅ `c:\project\front\main\lib\firebase_options.dart` (값 업데이트됨)
✅ `c:\project\backend\demo\src\main\resources\firebase-service-account.json`

### B. git 커밋 전 확인
⚠️ **절대 커밋하면 안 되는 파일**:
- ❌ `google-services.json`
- ❌ `firebase-service-account.json`
- ❌ `firebase_options.dart` (실제 키 값 있는 경우)

이 파일들이 `.gitignore`에 포함되어 있는지 확인!

---

## 7단계: 앱 테스트

### A. Flutter 앱 실행
```bash
cd c:\project\front\main
flutter run
```

### B. 로그 확인
앱 실행 후 다음과 같은 로그가 나타나야 함:
```
✅ FCM 알림 권한 허용됨
📱 FCM 토큰: eyJhbGciOiJ...
✅ FCM 서비스 초기화 완료
```

### C. 알림 권한 허용
앱 첫 실행 시 알림 권한 요청 팝업:
- **"허용"** 클릭

---

## 8단계: Firebase Console에서 테스트 알림 전송

### A. 테스트 알림 보내기
1. Firebase Console > **Engage** > **Messaging (Cloud Messaging)**
2. **"첫 번째 캠페인 만들기"** 또는 **"Create your first campaign"** 클릭
3. **"Firebase 알림 메시지"** 선택
4. 알림 제목 및 텍스트 입력:
   - 알림 제목: `테스트`
   - 알림 텍스트: `Firebase 연동 테스트`
5. **"다음"** 클릭
6. **타겟 선택**:
   - 앱: `com.example.signin` 선택
7. **"다음"** 클릭
8. **"검토"** > **"게시"** 클릭

### B. 알림 수신 확인
- 앱에 알림이 도착하는지 확인
- 앱이 포그라운드(열려있음) 상태일 때 콘솔 로그 확인:
  ```
  📩 포그라운드 메시지 수신: ...
  ```

---

## ✅ 설정 완료 체크리스트

설정이 완료되었으면 다음을 확인:

- [ ] Firebase 프로젝트 생성됨
- [ ] Android 앱 추가됨
- [ ] `google-services.json` 파일이 올바른 위치에 있음
- [ ] `firebase_options.dart` 값이 업데이트됨
- [ ] `firebase-service-account.json` 파일이 백엔드 resources에 있음
- [ ] `.gitignore`에 Firebase 파일들이 추가되어 있음
- [ ] Flutter 앱이 정상 실행됨
- [ ] FCM 토큰이 생성됨
- [ ] 알림 권한이 허용됨
- [ ] 테스트 알림이 정상적으로 도착함

---

## 🎉 다음 단계

설정이 완료되면:

1. **백엔드 서버 재시작**
2. **Flutter 앱 재시작**
3. **예약 확정/거절 테스트**:
   - 일반 사용자로 예약 생성
   - 파트너 계정으로 확정/거절
   - 자동으로 UI 업데이트되는지 확인

---

## 🆘 문제 발생 시

### "google-services.json not found" 오류
- 파일이 `android/app/` 폴더에 있는지 확인
- 파일 이름이 정확히 `google-services.json`인지 확인

### "Firebase initialization failed" 오류
- `firebase_options.dart`의 값이 올바른지 확인
- 작은따옴표(') 안에 값이 정확히 들어갔는지 확인

### 알림이 오지 않음
1. FCM 토큰이 생성되었는지 로그 확인
2. 알림 권한이 허용되었는지 확인
3. 인터넷 연결 확인
4. Firebase Console에서 Cloud Messaging API가 활성화되었는지 확인

---

**준비 완료!** 🚀

이제 파트너가 예약을 확정/거절하면 자동으로 UI가 업데이트됩니다!
