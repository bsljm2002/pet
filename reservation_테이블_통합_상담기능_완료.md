# Reservation 테이블 통합 상담 기능 구현 완료 ✅

## 🎯 구현 방식

**`reservation` 테이블 하나로 예약(RESERVATION)과 상담(CONSULTATION)을 모두 관리**

`record_type` 컬럼으로 두 가지 유형을 구분합니다.

---

## ✨ 핵심 개념

### 레코드 타입 구분
```
reservation 테이블
├── record_type = 'RESERVATION' → 예약 레코드
│   ├── visit_date_time (필수)
│   ├── status (필수)
│   └── consultation_* (선택: 예약 후 추가 상담)
│
└── record_type = 'CONSULTATION' → 상담 레코드
    ├── consultation_subject (필수)
    ├── consultation_content (필수)
    ├── consultation_status (필수)
    └── visit_date_time (NULL)
```

---

## 📊 사용 시나리오

### 시나리오 1: 독립적인 상담 (예약 없이)
```
사용자 → 병원 프로필 → "간편 상담" 버튼
→ 질문 작성: "우리 강아지가 이상한데 진료 받아야 할까요?"
→ 제출 → record_type='CONSULTATION' 레코드 생성
→ 파트너 답변
```

### 시나리오 2: 예약만
```
사용자 → 병원 프로필 → "예약하기"
→ 예약 생성 → record_type='RESERVATION' 레코드 생성
→ 방문 → 완료
```

### 시나리오 3: 예약 후 추가 상담
```
사용자 → 예약 완료
→ "내 예약"에서 "추가 상담" 버튼 클릭
→ 질문 작성 → 같은 RESERVATION 레코드에 상담 정보 추가
→ 파트너 답변
```

---

## 📝 수정된 파일

### Backend

#### 1. **Reservation.java** (엔티티)
```java
// 레코드 타입 Enum 추가
public enum RecordType {
    RESERVATION,   // 예약 레코드
    CONSULTATION   // 상담 레코드
}

// 필드 추가
@Enumerated(EnumType.STRING)
@Column(name = "record_type", length = 20, nullable = false)
@Builder.Default
private RecordType recordType = RecordType.RESERVATION;

// 상담 관련 필드 (기존)
@Column(name = "consultation_subject", length = 100)
private String consultationSubject;

@Column(name = "consultation_content", columnDefinition = "TEXT")
private String consultationContent;

@Column(name = "consultation_answer", columnDefinition = "TEXT")
private String consultationAnswer;

@Enumerated(EnumType.STRING)
@Column(name = "consultation_status", length = 20)
@Builder.Default
private ConsultationStatus consultationStatus = ConsultationStatus.NONE;

@Column(name = "consultation_requested_at")
private LocalDateTime consultationRequestedAt;

@Column(name = "consultation_answered_at")
private LocalDateTime consultationAnsweredAt;
```

#### 2. **ReservationService.java**
새 메서드 추가:
```java
/**
 * 독립적인 상담 생성 (예약 없이, CONSULTATION 레코드 생성)
 */
public Long createConsultation(Long userId, Long partnerId, String petType, String subject, String content) {
    Reservation consultation = Reservation.builder()
            .recordType(Reservation.RecordType.CONSULTATION)
            .userId(userId)
            .partnerId(partnerId)
            .serviceCategorical(null)  // 상담은 서비스 유형 불필요
            .userType(null)
            .status(null)  // 상담은 예약 상태 불필요
            .createdAt(OffsetDateTime.now())
            .visitDateTime(null)  // 상담은 방문 시간 불필요
            .petId(null)
            .vetSpecialtyCsv(petType)  // petType 저장
            .consultationSubject(subject)
            .consultationContent(content)
            .consultationStatus(Reservation.ConsultationStatus.PENDING)
            .consultationRequestedAt(LocalDateTime.now())
            .build();

    Reservation saved = reservations.save(consultation);

    // 파트너에게 알림 전송
    // ...

    return saved.getId();
}
```

#### 3. **ReservationController.java**
새 API 엔드포인트:
```java
/**
 * 독립적인 상담 생성 (예약 없이)
 * POST /api/v1/reservations/consultations
 */
@PostMapping("/consultations")
public ResponseEntity<ApiResponse<Map<String, Long>>> createConsultation(
    @RequestParam("userId") Long userId,
    @RequestParam("partnerId") Long partnerId,
    @RequestParam("petType") String petType,
    @RequestParam("subject") String subject,
    @RequestParam("content") String content
) {
    Long consultationId = reservationService.createConsultation(userId, partnerId, petType, subject, content);
    return ResponseEntity.ok(ApiResponse.ok(Map.of("consultation_id", consultationId)));
}
```

### Frontend

#### 1. **consultation_service.dart**
```dart
/// 독립적인 상담 생성 (예약 없이)
Future<int> createConsultation({
  required int userId,
  required int partnerId,
  required String petType,
  required String subject,
  required String content,
}) async {
  final url = Uri.parse(
    '$_baseUrl/reservations/consultations?userId=$userId&partnerId=$partnerId&petType=${Uri.encodeComponent(petType)}&subject=${Uri.encodeComponent(subject)}&content=${Uri.encodeComponent(content)}',
  );

  final response = await http.post(url, headers: {'Content-Type': 'application/json'});

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = json.decode(utf8.decode(response.bodyBytes));
    if (jsonData['ok'] == true && jsonData['data'] != null) {
      return jsonData['data']['consultation_id'] as int;
    }
  }

  throw Exception('상담 생성 실패');
}
```

#### 2. **simple_consultation_page.dart**
reservationId 파라미터 제거, 독립적인 상담 생성으로 변경

---

## 🗄️ 데이터베이스 마이그레이션 (필수!)

### SQL 실행:

```sql
-- 1. 레코드 타입 컬럼 추가
ALTER TABLE reservation
ADD COLUMN record_type VARCHAR(20) NOT NULL DEFAULT 'RESERVATION' COMMENT '레코드 타입: RESERVATION 또는 CONSULTATION';

-- 2. 상담 관련 컬럼 추가
ALTER TABLE reservation
ADD COLUMN consultation_subject VARCHAR(100) NULL COMMENT '상담 제목',
ADD COLUMN consultation_content TEXT NULL COMMENT '상담 내용',
ADD COLUMN consultation_answer TEXT NULL COMMENT '파트너 답변',
ADD COLUMN consultation_status VARCHAR(20) DEFAULT 'NONE' COMMENT '상담 상태: NONE/PENDING/ANSWERED',
ADD COLUMN consultation_requested_at DATETIME NULL COMMENT '상담 요청 일시',
ADD COLUMN consultation_answered_at DATETIME NULL COMMENT '답변 일시';

-- 3. 인덱스 추가
CREATE INDEX idx_record_type ON reservation(record_type);
CREATE INDEX idx_consultation_status ON reservation(consultation_status);

-- 4. 확인
SELECT
    COLUMN_NAME,
    COLUMN_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM
    INFORMATION_SCHEMA.COLUMNS
WHERE
    TABLE_SCHEMA = DATABASE()
    AND TABLE_NAME = 'reservation'
    AND (COLUMN_NAME LIKE 'consultation%' OR COLUMN_NAME = 'record_type')
ORDER BY ORDINAL_POSITION;
```

---

## 📊 데이터베이스 예시

### 예약 레코드:
```
id | record_type  | user_id | partner_id | status    | visit_date_time      | consultation_status | consultation_subject
---|--------------|---------|------------|-----------|----------------------|---------------------|--------------------
40 | RESERVATION  | 21      | 147        | COMPLETED | 2025-11-04 10:00:00  | NONE                | NULL
```

### 독립 상담 레코드:
```
id | record_type   | user_id | partner_id | status | visit_date_time | consultation_status | consultation_subject | consultation_content
---|---------------|---------|------------|--------|-----------------|---------------------|----------------------|--------------------
65 | CONSULTATION  | 21      | 147        | NULL   | NULL            | PENDING             | "약 복용 문의"        | "처방받은 약..."
```

### 예약 후 추가 상담:
```
id | record_type  | user_id | partner_id | status    | visit_date_time      | consultation_status | consultation_subject | consultation_content
---|--------------|---------|------------|-----------|----------------------|---------------------|----------------------|--------------------
40 | RESERVATION  | 21      | 147        | COMPLETED | 2025-11-04 10:00:00  | PENDING             | "추가 문의"          | "약 먹고 졸려요"
```

---

## 📡 API 엔드포인트

### 1. 독립적인 상담 생성 (새로 추가)
```
POST /api/v1/reservations/consultations
Query Parameters:
  - userId: Long
  - partnerId: Long
  - petType: String (예: "강아지", "고양이")
  - subject: String
  - content: String

Response: { "ok": true, "data": { "consultation_id": 65 } }
```

### 2. 예약에 대한 상담 요청 (기존)
```
POST /api/v1/reservations/{id}/consultation
Query Parameters:
  - userId: Long
  - subject: String
  - content: String

Response: { "ok": true, "data": { "message": "상담 요청이 완료되었습니다" } }
```

### 3. 상담 답변 (파트너)
```
PATCH /api/v1/reservations/{id}/consultation/answer
Query Parameters:
  - partnerId: Long
  - answer: String

Response: { "ok": true, "data": { "message": "답변이 완료되었습니다" } }
```

---

## 🔧 테스트 방법

### 1. 데이터베이스 마이그레이션 실행 ⚠️
위의 SQL 스크립트 실행

### 2. 백엔드 서버 재시작
```bash
cd backend/demo
./gradlew bootRun
```

### 3. 프론트엔드 실행
```bash
cd front/main
flutter run
```

### 4. 기능 테스트

#### 독립 상담 테스트:
1. 앱 실행 → 로그인
2. 병원 또는 펫시터 프로필로 이동
3. "간편 상담" 버튼 클릭
4. 상담 내용 작성 및 제출
5. 성공 메시지 확인

#### 예약 후 추가 상담 테스트:
1. 예약 생성 및 완료 처리
2. "내 예약"에서 "추가 상담" 버튼 클릭
3. 상담 내용 작성 및 제출
4. 성공 메시지 확인

---

## ✅ 장점

1. **테이블 1개로 통합 관리** → 간단한 구조
2. **유연한 사용** → 예약 없이도 상담 가능
3. **데이터 연결 자유로움** → 예약 후 추가 상담도 가능
4. **공통 필드 재사용** → user_id, partner_id 등

---

## ⚠️ 주의사항

1. **컬럼 낭비**:
   - RESERVATION 레코드: consultation_* 컬럼이 NULL이 될 수 있음
   - CONSULTATION 레코드: visit_date_time, status 등이 NULL

2. **쿼리 시 필터링 필요**:
   ```sql
   -- 예약만 조회
   SELECT * FROM reservation WHERE record_type = 'RESERVATION';

   -- 상담만 조회
   SELECT * FROM reservation WHERE record_type = 'CONSULTATION';
   ```

3. **데이터 검증**:
   - RESERVATION 레코드는 visit_date_time, status 필수
   - CONSULTATION 레코드는 consultation_subject, consultation_content 필수

---

## 📋 체크리스트

- [ ] 데이터베이스에 `record_type` 컬럼 추가
- [ ] 데이터베이스에 `consultation_*` 컬럼 6개 추가
- [ ] 인덱스 2개 생성 (`idx_record_type`, `idx_consultation_status`)
- [ ] 백엔드 서버 정상 시작
- [ ] 프론트엔드 앱 정상 실행
- [ ] 독립 상담 생성 테스트 성공
- [ ] 예약 후 추가 상담 테스트 성공
- [ ] 파트너 답변 테스트 성공

---

**구현 완료일:** 2025-11-25

**핵심 특징:**
- ✅ reservation 테이블 하나로 예약과 상담 모두 관리
- ✅ record_type으로 명확히 구분
- ✅ 독립적인 상담 기능 (예약 없이 사용 가능)
- ✅ 예약 후 추가 상담도 지원

🎉 **완료!**
