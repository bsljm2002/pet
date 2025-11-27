# Pet Diary LLM API Server

펫 일기 자동 생성을 위한 LLM API 서버입니다.

## 설치

```bash
pip install -r requirements.txt
```

## 설정

1. `.env.example` 파일을 복사하여 `.env` 파일 생성
2. LLM API 키 설정

```bash
cp .env.example .env
```

`.env` 파일 수정:
```
LLM_PROVIDER=openai
LLM_API_KEY=your-api-key-here
```

## 실행

```bash
python app.py
```

서버는 기본적으로 `http://localhost:5000`에서 실행됩니다.

## API 엔드포인트

### 1. 헬스 체크
```
GET /health
```

### 2. 일기 생성
```
POST /api/diary/generate
Content-Type: application/json

{
  "petName": "루나",
  "breed": "골든 리트리버",
  "mbti": "ENFP",
  "weight": 5.2,
  "heartRate": 85,
  "stressLevel": 3,
  "mood": "보통",
  "activity": "보통",
  "appetite": "보통"
}
```

응답:
```json
{
  "success": true,
  "diary": "오늘 컨디션 완전 최고야!...",
  "healthScore": 85
}
```

## 지원하는 LLM

- OpenAI (GPT-3.5, GPT-4)
- Anthropic Claude
- Google Gemini

## Fallback

API 키가 없거나 API 호출이 실패할 경우, 템플릿 기반으로 자동 생성됩니다.
