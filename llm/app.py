"""
Pet Diary LLM API Server
Flask 기반 LLM 일기 생성 API 서버
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
import logging

# 환경 변수 로드
load_dotenv()

app = Flask(__name__)
CORS(app)  # CORS 활성화

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# LLM API 설정
LLM_PROVIDER = os.getenv('LLM_PROVIDER', 'openai')  # openai, claude, gemini
API_KEY = os.getenv('LLM_API_KEY', '')


@app.route('/health', methods=['GET'])
def health_check():
    """헬스 체크 엔드포인트"""
    return jsonify({
        'status': 'healthy',
        'service': 'Pet Diary LLM API',
        'llm_provider': LLM_PROVIDER,
        'api_key_configured': bool(API_KEY)
    })


@app.route('/api/diary/generate', methods=['POST'])
def generate_diary():
    """
    LLM을 사용하여 펫 일기 생성

    Request Body:
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

    Response:
    {
        "success": true,
        "diary": "일기 내용...",
        "healthScore": 85
    }
    """
    data = None
    try:
        data = request.get_json()
        logger.info(f"Received diary generation request: {data}")

        # 데이터 추출
        pet_name = data.get('petName', '반려동물')
        breed = data.get('breed', '알 수 없음')
        mbti = data.get('mbti', 'ENFP')
        weight = data.get('weight', 5.0)
        heart_rate = data.get('heartRate', 80)
        stress_level = data.get('stressLevel', 3)
        mood = data.get('mood', '보통')
        activity = data.get('activity', '보통')
        appetite = data.get('appetite', '보통')

        # 건강 점수 계산
        health_score = calculate_health_score(heart_rate, stress_level, mood, activity, appetite)

        # 프롬프트 생성
        prompt = build_prompt(pet_name, breed, mbti, weight, heart_rate, stress_level, mood, activity, appetite, health_score)

        # LLM API 호출
        diary_content = call_llm_api(prompt)

        return jsonify({
            'success': True,
            'diary': diary_content,
            'healthScore': health_score
        })

    except Exception as e:
        logger.error(f"Error generating diary: {str(e)}")

        # Fallback: 템플릿 기반 일기 생성
        if data is None:
            data = {
                'petName': '반려동물',
                'breed': '알 수 없음',
                'mbti': 'ENFP',
                'weight': 5.0,
                'heartRate': 80,
                'stressLevel': 3,
                'mood': '보통',
                'activity': '보통',
                'appetite': '보통'
            }

        fallback_diary = generate_fallback_diary(data)

        return jsonify({
            'success': True,
            'diary': fallback_diary,
            'fallback': True,
            'healthScore': 70,
            'error': str(e)
        })


def calculate_health_score(heart_rate, stress_level, mood, activity, appetite):
    """건강 지표를 점수화하여 0-100점으로 계산"""
    total_score = 0

    # 1. 심박수 점수 (0-25점)
    if 70 <= heart_rate <= 100:
        total_score += 25  # 정상
    elif 60 <= heart_rate < 70 or 100 < heart_rate <= 120:
        total_score += 15  # 약간 비정상
    elif 50 <= heart_rate < 60 or 120 < heart_rate <= 140:
        total_score += 8   # 주의 필요
    else:
        total_score += 0   # 위험

    # 2. 스트레스 점수 (0-25점)
    if stress_level <= 3:
        total_score += 25  # 낮음
    elif stress_level <= 6:
        total_score += 15  # 보통
    else:
        total_score += 5   # 높음

    # 3. 기분 점수 (0-20점)
    mood_scores = {
        '매우 좋음': 20, '좋음': 15, '보통': 10, '나쁨': 5, '매우 나쁨': 0
    }
    total_score += mood_scores.get(mood, 10)

    # 4. 활동량 점수 (0-15점)
    activity_scores = {
        '매우 활발': 10, '활발': 15, '보통': 15, '조용': 10, '매우 조용': 5
    }
    total_score += activity_scores.get(activity, 15)

    # 5. 식욕 점수 (0-15점)
    appetite_scores = {
        '매우 좋음': 15, '좋음': 15, '보통': 10, '나쁨': 5, '매우 나쁨': 0
    }
    total_score += appetite_scores.get(appetite, 10)

    return total_score


def build_prompt(pet_name, breed, mbti, weight, heart_rate, stress_level, mood, activity, appetite, health_score):
    """LLM을 위한 프롬프트 생성"""

    # MBTI별 성격 특징
    mbti_traits = get_mbti_traits(mbti)

    # 건강 상태 분석
    emotion_level = get_emotion_level(health_score)

    # MBTI별 말투
    speaking_style = get_mbti_speaking_style(mbti, emotion_level)

    prompt = f"""당신은 '{pet_name}'라는 이름의 {breed}입니다.
당신의 MBTI는 {mbti}이며, 다음과 같은 성격적 특징을 가지고 있습니다:

{mbti_traits}

### 오늘의 건강 기록
- 체중: {weight}kg
- 심박수: {heart_rate} bpm
- 스트레스 지수: {stress_level}/10
- 기분: {mood}
- 활동량: {activity}
- 식욕: {appetite}

### 종합 건강 상태
⭐ 오늘의 건강 점수: {health_score}점 / 100점
📊 컨디션: {emotion_level}

### 작성 규칙
1. **건강 상태를 최상단에 먼저 언급**
2. **MBTI {mbti} 성격에 맞는 말투 사용**: {speaking_style}
3. **감정 기복 반영**: 건강 상태({emotion_level})에 따라 감정 표현
4. **분량**: 200-300자
5. **이모지**: 2-3개만 자연스럽게

⚠️ 금지 사항:
- "안녕", "일기를 쓴다", "하루를 기록한다" 같은 표현 절대 금지
- 항상 밝지 말고, 실제 컨디션에 맞는 감정 표현

이제 {pet_name}의 목소리로 오늘 느낀 것을 자연스럽게 말해주세요:"""

    return prompt


def get_mbti_traits(mbti):
    """MBTI별 성격 특징"""
    traits_map = {
        'ENFP': "외향적이고 활발하며, 호기심이 많고 자유로운 영혼입니다.",
        'INFP': "내향적이고 감성적이며, 깊은 생각과 상상을 좋아합니다.",
        'ENTP': "외향적이고 논리적이며, 새로운 아이디어에 흥미를 느낍니다.",
        'INTP': "내향적이고 분석적이며, 조용히 관찰하는 것을 좋아합니다.",
        'ESFP': "외향적이고 즉흥적이며, 지금 이 순간을 즐기는 것을 좋아합니다.",
        'ISFP': "내향적이고 감각적이며, 평화롭고 따뜻한 것을 선호합니다.",
    }
    return traits_map.get(mbti, "자유롭고 활발한 성격입니다.")


def get_emotion_level(health_score):
    """건강 점수에 따른 감정 상태"""
    if health_score >= 80:
        return "매우 좋음"
    elif health_score >= 60:
        return "좋음"
    elif health_score >= 40:
        return "보통"
    elif health_score >= 20:
        return "나쁨"
    else:
        return "매우 나쁨"


def get_mbti_speaking_style(mbti, emotion_level):
    """감정 상태에 따른 MBTI별 말투"""
    styles = {
        'ENFP': {
            '매우 좋음': "폭발적으로 신나는 (예: 와아! 완전 최고야!)",
            '좋음': "밝고 활기찬 (예: 오늘 진짜 좋아!)",
            '보통': "여전히 친근한 (예: 그럭저럭 괜찮아)",
            '나쁨': "힘들지만 애쓰는 (예: 조금 힘들긴 한데...)",
            '매우 나쁨': "완전히 풀이 죽은 (예: 너무 힘들어...)"
        },
        'INFP': {
            '매우 좋음': "깊이 행복한 (예: 마음이 벅차올라...)",
            '좋음': "따뜻하게 기뻐하는 (예: 마음이 따뜻해져)",
            '보통': "조용히 성찰하는 (예: 생각에 잠기게 돼)",
            '나쁨': "우울해지는 (예: 마음이 조금 무거워...)",
            '매우 나쁨': "깊은 슬픔에 잠긴 (예: 마음이 너무 아파...)"
        }
    }

    mbti_style = styles.get(mbti, styles['ENFP'])
    return mbti_style.get(emotion_level, mbti_style['보통'])


def call_llm_api(prompt):
    """LLM API 호출"""

    # API Key가 없으면 바로 Fallback으로
    if not API_KEY:
        logger.warning("LLM API key not configured, using fallback")
        raise Exception("API key not configured")

    if LLM_PROVIDER.lower() == 'openai':
        return call_openai_api(prompt)
    elif LLM_PROVIDER.lower() == 'claude':
        return call_claude_api(prompt)
    elif LLM_PROVIDER.lower() == 'gemini':
        return call_gemini_api(prompt)
    else:
        logger.warning(f"Unknown LLM provider: {LLM_PROVIDER}")
        raise Exception(f"Unknown LLM provider: {LLM_PROVIDER}")


def call_openai_api(prompt):
    """OpenAI API 호출"""
    from openai import OpenAI

    client = OpenAI(api_key=API_KEY)

    response = client.chat.completions.create(
        model=os.getenv('OPENAI_MODEL', 'gpt-3.5-turbo'),
        messages=[
            {"role": "user", "content": prompt}
        ],
        temperature=0.7,
        max_tokens=500
    )

    return response.choices[0].message.content.strip()


def call_claude_api(prompt):
    """Anthropic Claude API 호출"""
    import anthropic

    client = anthropic.Anthropic(api_key=API_KEY)

    message = client.messages.create(
        model=os.getenv('CLAUDE_MODEL', 'claude-3-sonnet-20240229'),
        max_tokens=500,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    return message.content[0].text.strip()


def call_gemini_api(prompt):
    """Google Gemini API 호출"""
    import google.generativeai as genai

    genai.configure(api_key=API_KEY)
    model = genai.GenerativeModel(os.getenv('GEMINI_MODEL', 'gemini-pro'))

    response = model.generate_content(prompt)
    return response.text.strip()


def generate_fallback_diary(data):
    """Fallback: API 호출 실패 시 템플릿 기반 일기 생성"""
    pet_name = data.get('petName', '나')
    weight = data.get('weight', 5.0)
    heart_rate = data.get('heartRate', 80)
    stress_level = data.get('stressLevel', 3)
    mood = data.get('mood', '보통')
    activity = data.get('activity', '보통')
    appetite = data.get('appetite', '보통')

    # 건강 점수 계산
    health_score = calculate_health_score(heart_rate, stress_level, mood, activity, appetite)
    emotion_level = get_emotion_level(health_score)

    # 기본 템플릿
    diary_parts = []

    # 건강 상태 요약
    if emotion_level == "매우 좋음":
        diary_parts.append(f"오늘 컨디션 완전 최고야! 건강 점수 {health_score}점! 🌟")
    elif emotion_level == "좋음":
        diary_parts.append(f"오늘 몸 상태 좋아, 기분도 괜찮네! (건강 점수: {health_score}점) 😊")
    elif emotion_level == "보통":
        diary_parts.append(f"컨디션은 그럭저럭... 나쁘진 않아. (건강: {health_score}점)")
    elif emotion_level == "나쁨":
        diary_parts.append(f"오늘 좀 힘들어... 몸 상태가 안 좋아. (건강: {health_score}점) 😔")
    else:
        diary_parts.append(f"너무 힘들어... 컨디션 최악이야... (건강: {health_score}점) 😰")

    # 기분에 따른 내용
    if mood in ['매우 좋음', '좋음']:
        diary_parts.append(f"기분이 {mood}이어서 활기차게 보냈어! 🐾")
    elif mood == '보통':
        diary_parts.append("그냥 평범한 하루였어.")
    else:
        diary_parts.append(f"기분이 {mood}이라 힘든 하루였어...")

    # 활동량에 따른 내용
    if activity in ['매우 활발', '활발']:
        diary_parts.append(f"오늘 {activity}하게 움직였더니 피곤하네 😅")
    elif activity == '보통':
        diary_parts.append("적당히 활동했어, 딱 좋았어.")
    else:
        diary_parts.append("별로 움직이지 않았어, 기운이 없었거든...")

    # 식욕에 따른 내용
    if appetite in ['매우 좋음', '좋음']:
        diary_parts.append(f"식욕은 {appetite}! 맛있게 잘 먹었어 🍖")
    elif appetite == '보통':
        diary_parts.append("밥은 적당히 먹었어.")
    else:
        diary_parts.append("식욕이 별로 없어서 조금만 먹었어...")

    # 마무리
    if emotion_level in ['매우 좋음', '좋음']:
        diary_parts.append("내일도 이렇게 좋으면 좋겠어! 😊")
    else:
        diary_parts.append("내일은 나아지면 좋겠어...")

    return "\n\n".join(diary_parts)


if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'True').lower() == 'true'

    logger.info(f"Starting Pet Diary LLM API Server on port {port}")
    logger.info(f"LLM Provider: {LLM_PROVIDER}")
    logger.info(f"API Key Configured: {bool(API_KEY)}")

    app.run(host='0.0.0.0', port=port, debug=debug)
