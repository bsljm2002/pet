# 가이드 2: 백엔드 API 주소

## 🔌 API 엔드포인트

### 1. 수의사 목록
```
GET /api/v1/users/partners?user_type=HOSPITAL
```

### 2. 펫시터 목록
```
GET /api/v1/users/partners?user_type=SITTER
```

### 3. 예약 생성
```
POST /api/v1/reservations
```

### 4. 내 예약 목록
```
GET /api/v1/reservations/mine?userId={userId}
```

## 📌 다음 단계

가이드3에서 Enum 매핑표를 확인하세요!
