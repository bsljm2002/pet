import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../utils/diary_templates.dart';

/// LLM API 서비스
/// Python LLM 서버와 통신하여 펫 일기를 생성합니다
class LLMService {
  // LLM 서버 URL (로컬 개발 환경)
  static const String baseUrl = 'http://localhost:5000';

  /// 펫 일기 생성
  ///
  /// [petName] 펫 이름
  /// [breed] 품종
  /// [mbti] MBTI 타입
  /// [weight] 체중 (kg)
  /// [heartRate] 심박수 (bpm)
  /// [stressLevel] 스트레스 지수 (1-10)
  /// [temperature] 체온 (°C)
  /// [humidity] 습도 (%)
  /// [mood] 기분
  /// [activity] 활동량
  /// [appetite] 식욕
  Future<Map<String, dynamic>> generateDiary({
    required String petName,
    required String breed,
    required String mbti,
    required double weight,
    required int heartRate,
    required int stressLevel,
    required double temperature,
    required int humidity,
    required String mood,
    required String activity,
    required String appetite,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/diary/generate'),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "petName": petName,
              "breed": breed,
              "mbti": mbti,
              "weight": weight,
              "heartRate": heartRate,
              "stressLevel": stressLevel,
              "temperature": temperature,
              "humidity": humidity,
              "mood": mood,
              "activity": activity,
              "appetite": appetite,
            }),
          )
          .timeout(Duration(seconds: 5)); // 5초 타임아웃

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data["success"] == true) {
          return {
            "success": true,
            "diary": data["diary"],
            "healthScore": data["healthScore"],
            "fallback": data["fallback"] ?? false,
          };
        } else {
          // API 호출 실패 시 Fallback
          return _generateFallbackDiary(
              petName, mbti, weight, heartRate, stressLevel, temperature, humidity, mood, activity, appetite);
        }
      } else {
        // 서버 오류 시 Fallback
        return _generateFallbackDiary(
            petName, mbti, weight, heartRate, stressLevel, temperature, humidity, mood, activity, appetite);
      }
    } catch (e) {
      // 네트워크 오류 또는 타임아웃 시 Fallback
      return _generateFallbackDiary(
          petName, mbti, weight, heartRate, stressLevel, temperature, humidity, mood, activity, appetite);
    }
  }

  /// Fallback: 템플릿 기반 일기 생성 (MBTI와 계절/날씨 반영)
  Map<String, dynamic> _generateFallbackDiary(
    String petName,
    String mbti,
    double weight,
    int heartRate,
    int stressLevel,
    double temperature,
    int humidity,
    String mood,
    String activity,
    String appetite,
  ) {
    final random = Random();

    // 건강 점수 계산
    int healthScore = _calculateHealthScore(heartRate, stressLevel, temperature, humidity, mood, activity, appetite);
    String emotionLevel = _getEmotionLevel(healthScore);

    // 현재 계절 감지
    String currentSeason = SeasonDetector.getCurrentSeason();

    // 날씨 랜덤 선택 (실제로는 날씨 API를 사용할 수 있음)
    List<String> weatherOptions = ['맑음', '흐림', '비', '눈'];
    String currentWeather = weatherOptions[random.nextInt(weatherOptions.length)];

    List<String> diaryParts = [];

    // 1. 건강 상태 요약 (첫 문장)
    if (emotionLevel == "매우 좋음") {
      diaryParts.add("오늘 컨디션 완전 최고야! 건강 점수 $healthScore점! 🌟");
    } else if (emotionLevel == "좋음") {
      diaryParts.add("오늘 몸 상태 좋아, 기분도 괜찮네! (건강 점수: $healthScore점) 😊");
    } else if (emotionLevel == "보통") {
      diaryParts.add("컨디션은 그럭저럭... 나쁘진 않아. (건강: $healthScore점)");
    } else if (emotionLevel == "나쁨") {
      diaryParts.add("오늘 좀 힘들어... 몸 상태가 안 좋아. (건강: $healthScore점) 😔");
    } else {
      diaryParts.add("너무 힘들어... 컨디션 최악이야... (건강: $healthScore점) 😰");
    }

    // 2. 계절/날씨별 시작 멘트 (건강 상태 반영)
    final seasonStarters = SeasonStarters.getStarters(currentSeason, emotionLevel);
    final weatherStarters = WeatherStarters.getStarters(currentWeather, emotionLevel);

    // 계절 또는 날씨 멘트 중 하나를 랜덤으로 선택
    String weatherMent = random.nextBool()
        ? seasonStarters[random.nextInt(seasonStarters.length)]
        : weatherStarters[random.nextInt(weatherStarters.length)];

    diaryParts.add(weatherMent);

    // 3. 체온 체크
    if (temperature > 39.5) {
      diaryParts.add("몸이 너무 뜨거워... 열이 있는 것 같아 🤒");
    } else if (temperature > 39.2) {
      diaryParts.add("체온이 조금 높아... 신경 써야겠어");
    } else if (temperature < 37.5) {
      diaryParts.add("체온이 낮아서 좀 추워... 🥶");
    }

    // 4. 습도 체크
    if (humidity > 70) {
      diaryParts.add("너무 습해서 불쾌해... 숨쉬기 힘들어 💦");
    } else if (humidity < 30) {
      diaryParts.add("공기가 너무 건조해... 목이 따끔거려");
    } else if (humidity >= 40 && humidity <= 60) {
      diaryParts.add("습도가 딱 좋아서 편안해 😊");
    }

    // 5. 심박수 기반 컨디션
    if (heartRate > 120) {
      diaryParts.add("심장이 너무 빨리 뛰어... 좀 힘드네 😰");
    } else if (heartRate > 100) {
      diaryParts.add("심장이 조금 빨리 뛰는 것 같아");
    } else if (heartRate < 60) {
      diaryParts.add("심장 박동이 느려... 컨디션이 별로야");
    }

    // 6. 스트레스 레벨
    if (stressLevel >= 8) {
      diaryParts.add("스트레스가 너무 심해... 진짜 힘들어 😫");
    } else if (stressLevel >= 6) {
      diaryParts.add("조금 스트레스를 받는 것 같아");
    } else if (stressLevel <= 2) {
      diaryParts.add("스트레스 없이 편안한 하루야 😌");
    }

    // 7. 활동량에 따른 내용
    if (activity == '매우 활발' || activity == '활발') {
      if (emotionLevel == '매우 좋음' || emotionLevel == '좋음') {
        diaryParts.add("오늘 $activity하게 움직였어! 신나게 뛰어다녔지 🏃");
      } else {
        diaryParts.add("$activity하게 움직였더니 너무 피곤해... 😅");
      }
    } else if (activity == '보통') {
      diaryParts.add("적당히 활동했어, 딱 좋았어");
    } else {
      diaryParts.add("별로 움직이지 않았어, 기운이 없었거든...");
    }

    // 8. 식욕에 따른 내용
    if (appetite == '매우 좋음' || appetite == '좋음') {
      diaryParts.add("식욕은 $appetite! 맛있게 잘 먹었어 🍖");
    } else if (appetite == '보통') {
      diaryParts.add("밥은 적당히 먹었어");
    } else {
      diaryParts.add("식욕이 별로 없어서 조금만 먹었어... 😔");
    }

    // 9. MBTI별 말투로 마무리
    String mbtiEnding = _getMBTIEnding(mbti, emotionLevel);
    diaryParts.add(mbtiEnding);

    return {
      "success": true,
      "diary": diaryParts.join("\n\n"),
      "healthScore": healthScore,
      "fallback": true,
    };
  }

  /// MBTI별 마무리 멘트
  String _getMBTIEnding(String mbti, String emotionLevel) {
    // MBTI별 감정 상태에 따른 마무리 멘트
    final endings = {
      'ENFP': {
        '매우 좋음': "내일도 이렇게 신나게 보낼 거야! 완전 최고! 🎉",
        '좋음': "오늘 정말 좋았어! 내일도 기대돼!",
        '보통': "뭐 나쁘지 않았어, 내일은 더 좋을지도?",
        '나쁨': "힘들었지만... 내일은 괜찮아질 거야",
        '매우 나쁨': "너무 힘들어... 빨리 나아지고 싶어..."
      },
      'INFP': {
        '매우 좋음': "마음이 따뜻한 하루였어... 행복해 💕",
        '좋음': "평화로운 하루였어",
        '보통': "그냥 그런 하루... 생각이 많아지네",
        '나쁨': "마음이 무거워... 혼자 있고 싶어",
        '매우 나쁨': "너무 힘들어... 왜 이럴까..."
      },
      'ENTP': {
        '매우 좋음': "완전 재밌었어! 내일은 뭘 해볼까? 😆",
        '좋음': "오 이거 나쁘지 않네! 괜찮았어",
        '보통': "근데 왜 그랬을까? 궁금하네",
        '나쁨': "뭔가 잘못된 것 같은데... 분석해봐야겠어",
        '매우 나쁨': "완전 엉망이야... 이유를 모르겠어"
      },
      'INTP': {
        '매우 좋음': "완벽한 하루였어. 매우 만족스러워",
        '좋음': "괜찮은 결과네. 나쁘지 않아",
        '보통': "그런 것 같아... 흠",
        '나쁨': "이상해... 뭔가 잘못됐어",
        '매우 나쁨': "완전히 잘못됐어... 생각이 복잡해"
      },
      'ENFJ': {
        '매우 좋음': "모두와 함께라서 너무 행복해! 최고야! 🌟",
        '좋음': "함께해서 좋은 하루였어",
        '보통': "모두 괜찮아 보이네, 다행이야",
        '나쁨': "조금 걱정돼... 괜찮을까",
        '매우 나쁨': "너무 마음이 아파... 어떡하지"
      },
      'INFJ': {
        '매우 좋음': "정말 의미있는 하루... 깊은 깨달음을 얻었어",
        '좋음': "감사한 마음이 들어",
        '보통': "생각해보게 되네...",
        '나쁨': "혼자 있고 싶어... 생각이 많아",
        '매우 나쁨': "마음이 너무 무거워... 외로워"
      },
      'ENTJ': {
        '매우 좋음': "완벽하게 해냈어! 대성공! 💪",
        '좋음': "잘했어! 계획대로야!",
        '보통': "진행 중이야. 할 일이 있어",
        '나쁨': "계획이 틀어졌어... 재조정이 필요해",
        '매우 나쁨': "완전히 실패했어... 전략을 다시 짜야 해"
      },
      'INTJ': {
        '매우 좋음': "최적의 결과야. 매우 효율적이었어",
        '좋음': "효과적이야. 좋은 결과네",
        '보통': "계획이 필요해... 분석 중이야",
        '나쁨': "비효율적이야... 개선이 필요해",
        '매우 나쁨': "완전히 비논리적이야... 최악이야"
      },
      'ESFP': {
        '매우 좋음': "야호! 오늘 완전 재밌었어! 최고! 🎊",
        '좋음': "신나! 재밌는 하루였어!",
        '보통': "나쁘지 않네, 그럭저럭",
        '나쁨': "재미없어... 기운이 없네",
        '매우 나쁨': "하나도 재미없어... 너무 힘들어"
      },
      'ISFP': {
        '매우 좋음': "너무 좋아... 완벽한 하루야 🌸",
        '좋음': "따뜻하고 기분 좋은 하루였어",
        '보통': "편안한 하루였어",
        '나쁨': "아파... 힘들어",
        '매우 나쁨': "너무 아파... 견딜 수가 없어"
      },
      'ESTP': {
        '매우 좋음': "완전 최고! 바로 이거야! 더 해보자! 🔥",
        '좋음': "바로 이거야! 좋았어!",
        '보통': "일단 해봤어. 해보면 알겠지",
        '나쁨': "짜증나... 답답해",
        '매우 나쁨': "완전 짜증나! 못 참겠어"
      },
      'ISTP': {
        '매우 좋음': "완전 괜찮네. 이거 좋은데",
        '좋음': "괜찮네. 나쁘지 않아",
        '보통': "그냥... 뭐",
        '나쁨': "힘드네... 별로야",
        '매우 나쁨': "너무 힘들어... 쉴래"
      },
      'ESFJ': {
        '매우 좋음': "너무 좋아! 모두와 함께라서 최고야! 💝",
        '좋음': "같이 있어서 좋아! 고마워!",
        '보통': "도와줄까? 괜찮아?",
        '나쁨': "걱정돼... 슬퍼",
        '매우 나쁨': "너무 슬퍼... 위로가 필요해"
      },
      'ISFJ': {
        '매우 좋음': "정말 다행이야. 모두 잘 됐어 😊",
        '좋음': "다행이야. 잘 됐어",
        '보통': "천천히 해봐야지...",
        '나쁨': "괜찮을까... 불안해",
        '매우 나쁨': "너무 걱정돼... 정말 불안해"
      },
      'ESTJ': {
        '매우 좋음': "100% 성공이야! 확실하게 잘됐어!",
        '좋음': "확실히 잘됐어! 성공!",
        '보통': "정확히 이거야. 분명해",
        '나쁨': "분명히 문제야. 힘들어",
        '매우 나쁨': "명백히 실패야. 이건 심각해"
      },
      'ISTJ': {
        '매우 좋음': "역시 그렇군. 100% 예상대로야",
        '좋음': "역시. 예상대로야",
        '보통': "순서대로... 계획대로",
        '나쁨': "문제가 있어. 잘못됐어",
        '매우 나쁨': "명백한 문제야... 정말 힘드네"
      },
    };

    // MBTI가 정의되어 있으면 해당 멘트 사용, 없으면 ENFP 기본값
    final mbtiEndings = endings[mbti] ?? endings['ENFP']!;
    return mbtiEndings[emotionLevel] ?? mbtiEndings['보통']!;
  }

  /// 건강 점수 계산
  int _calculateHealthScore(
      int heartRate, int stressLevel, double temperature, int humidity, String mood, String activity, String appetite) {
    int totalScore = 0;

    // 1. 심박수 점수 (0-20점)
    if (heartRate >= 70 && heartRate <= 100) {
      totalScore += 20;
    } else if ((heartRate >= 60 && heartRate < 70) || (heartRate > 100 && heartRate <= 120)) {
      totalScore += 12;
    } else if ((heartRate >= 50 && heartRate < 60) || (heartRate > 120 && heartRate <= 140)) {
      totalScore += 6;
    }

    // 2. 스트레스 점수 (0-20점)
    if (stressLevel <= 3) {
      totalScore += 20;
    } else if (stressLevel <= 6) {
      totalScore += 12;
    } else {
      totalScore += 4;
    }

    // 3. 체온 점수 (0-20점) - 개의 정상 체온: 38.0~39.2°C
    if (temperature >= 38.0 && temperature <= 39.2) {
      totalScore += 20;
    } else if ((temperature >= 37.5 && temperature < 38.0) || (temperature > 39.2 && temperature <= 39.5)) {
      totalScore += 12;
    } else if ((temperature >= 37.0 && temperature < 37.5) || (temperature > 39.5 && temperature <= 40.0)) {
      totalScore += 6;
    } else {
      totalScore += 0; // 위험 수준
    }

    // 4. 습도 점수 (0-10점) - 적정 습도: 40~60%
    if (humidity >= 40 && humidity <= 60) {
      totalScore += 10;
    } else if ((humidity >= 30 && humidity < 40) || (humidity > 60 && humidity <= 70)) {
      totalScore += 6;
    } else if ((humidity >= 20 && humidity < 30) || (humidity > 70 && humidity <= 80)) {
      totalScore += 3;
    } else {
      totalScore += 0; // 매우 건조하거나 매우 습함
    }

    // 5. 기분 점수 (0-15점)
    Map<String, int> moodScores = {
      '매우 좋음': 15,
      '좋음': 12,
      '보통': 8,
      '나쁨': 4,
      '매우 나쁨': 0
    };
    totalScore += moodScores[mood] ?? 8;

    // 6. 활동량 점수 (0-10점)
    Map<String, int> activityScores = {
      '매우 활발': 8,
      '활발': 10,
      '보통': 10,
      '조용': 7,
      '매우 조용': 4
    };
    totalScore += activityScores[activity] ?? 10;

    // 7. 식욕 점수 (0-10점)
    Map<String, int> appetiteScores = {
      '매우 좋음': 10,
      '좋음': 10,
      '보통': 7,
      '나쁨': 4,
      '매우 나쁨': 0
    };
    totalScore += appetiteScores[appetite] ?? 10;

    return totalScore;
  }

  /// 건강 점수에 따른 감정 상태
  String _getEmotionLevel(int healthScore) {
    if (healthScore >= 80) {
      return "매우 좋음";
    } else if (healthScore >= 60) {
      return "좋음";
    } else if (healthScore >= 40) {
      return "보통";
    } else if (healthScore >= 20) {
      return "나쁨";
    } else {
      return "매우 나쁨";
    }
  }

  /// 헬스 체크
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "data": data,
        };
      } else {
        return {
          "success": false,
          "message": "서버 응답 오류",
        };
      }
    } catch (e) {
      return {
        "success": false,
        "message": "서버 연결 실패: $e",
      };
    }
  }
}
