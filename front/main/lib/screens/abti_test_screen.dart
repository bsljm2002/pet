// ABTI 테스트 화면
// 반려동물의 성향을 파악하는 ABTI 테스트를 진행하는 페이지
import 'package:flutter/material.dart';

/// ABTI 테스트 화면
///
/// 반려동물의 성향을 파악하기 위한 MBTI 스타일의 테스트
/// - 4가지 카테고리: 사회성(I/E), 자극 초점(S/N), 의사결정(T/F), 생활양식(J/P)
/// - 총 20개 질문 (각 카테고리당 5개)
/// - 결과는 16가지 ABTI 유형 중 하나로 표시
class AbtiTestScreen extends StatefulWidget {
  final String? petName;
  final String? currentAbtiType;

  const AbtiTestScreen({Key? key, this.petName, this.currentAbtiType})
    : super(key: key);

  @override
  State<AbtiTestScreen> createState() => _AbtiTestScreenState();
}

class _AbtiTestScreenState extends State<AbtiTestScreen> {
  // ABTI 테스트 답변 저장 (질문 인덱스 -> 답변)
  int _currentQuestionIndex = 0;
  // -2: 매우 그렇지 않다, -1: 그렇지 않다, 0: 보통이다, 1: 그렇다, 2: 매우 그렇다
  Map<int, int> _abtiAnswers = {};

  // 전체 질문 목록
  final List<Map<String, dynamic>> _questions = [
    // 사회성 (I/E) - 0~4
    {
      'category': '사회성 (I/E)',
      'question': '낯선 사람이 집에 오면 먼저 다가가 냄새 맡거나 인사하려 한다.',
      'isPositive': true,
    },
    {
      'category': '사회성 (I/E)',
      'question': '산책/외출 시 다른 개·고양이·사람을 피하고 거리를 둔다.',
      'isPositive': false,
    },
    {
      'category': '사회성 (I/E)',
      'question': '새로운 장소(카페/병원 대기실)에서 3분 내 주변 대상에 접근한다.',
      'isPositive': true,
    },
    {
      'category': '사회성 (I/E)',
      'question': '방문객이 있으면 은신처/높은 곳으로 이동해 조용히 지낸다.',
      'isPositive': false,
    },
    {
      'category': '사회성 (I/E)',
      'question': '사회적 놀이(그룹 플레이/교대 놀이)에 쉽게 합류한다.',
      'isPositive': true,
    },
    // 자극 초점 (S/N) - 5~9
    {
      'category': '자극 초점 (S/N)',
      'question': '장난감·그릇·가구 배치가 바뀌면 경계하거나 스트레스를 보인다.',
      'isPositive': false,
    },
    {
      'category': '자극 초점 (S/N)',
      'question': '새 장난감·퍼즐 급여기에 스스로 다가가 탐색한다.',
      'isPositive': true,
    },
    {
      'category': '자극 초점 (S/N)',
      'question': '익숙한 산책 코스/루틴일수록 안정적이다.',
      'isPositive': false,
    },
    {
      'category': '자극 초점 (S/N)',
      'question': '집에 새 물건이 생기면 금방 흥미를 보이고 활용한다.',
      'isPositive': true,
    },
    {
      'category': '자극 초점 (S/N)',
      'question': '냄새·소리 같은 구체 감각 단서가 있을 때 반응이 더 확실하다.',
      'isPositive': false,
    },
    // 의사결정 (T/F) - 10~14
    {
      'category': '의사결정 (T/F)',
      'question': '"앉아/기다려/이리 와"처럼 명확한 지시 및 보상에서 학습이 빠르다.',
      'isPositive': true,
    },
    {
      'category': '의사결정 (T/F)',
      'question': '보호자의 목소리 톤·표정 변화에 행동이 크게 달라진다.',
      'isPositive': false,
    },
    {
      'category': '의사결정 (T/F)',
      'question': '퍼즐 급여기/노즈워크 등 과제 해결형 놀이에 오래 몰입한다.',
      'isPositive': true,
    },
    {
      'category': '의사결정 (T/F)',
      'question': '쓰다듬기·함께 있기 같은 정서적 보상이 특히 잘 먹힌다.',
      'isPositive': false,
    },
    {
      'category': '의사결정 (T/F)',
      'question': '보상 규칙이 바뀌면 행동도 즉시 조정한다.',
      'isPositive': true,
    },
    // 생활양식 (J/P) - 15~19
    {
      'category': '생활양식 (J/P)',
      'question': '식사·산책·놀이 시간이 일정할수록 더 안정적이다.',
      'isPositive': true,
    },
    {
      'category': '생활양식 (J/P)',
      'question': '갑작스런 일정 변화(외출/방문객)에도 비교적 빨리 적응한다.',
      'isPositive': false,
    },
    {
      'category': '생활양식 (J/P)',
      'question': '"자리/대기/금지구역" 같은 규칙을 빠르게 이해한다.',
      'isPositive': true,
    },
    {
      'category': '생활양식 (J/P)',
      'question': '산책/놀이 중 활동 전환이 잦아도 스트레스가 적다.',
      'isPositive': false,
    },
    {
      'category': '생활양식 (J/P)',
      'question': '정해진 장소(화장실/배변패드/스크래처)를 꾸준히 사용한다.',
      'isPositive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 207, 229, 218),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 207, 229, 218),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              '펫 ABTI 테스트',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 4),
            Container(
              height: 3,
              width: 100,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 진행률 표시
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '질문 ${_currentQuestionIndex + 1} / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 0, 108, 82),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 0, 108, 82),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      const Color.fromARGB(255, 0, 108, 82),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // 질문 카드
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(30),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 카테고리 배지
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              0,
                              108,
                              82,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            currentQuestion['category'],
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color.fromARGB(255, 0, 108, 82),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 30),

                        // 질문 텍스트
                        Text(
                          currentQuestion['question'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black87,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 50),

                        // 5단계 답변 버튼
                        Column(
                          children: [
                            _buildAnswerButton('매우 그렇다', 2),
                            SizedBox(height: 12),
                            _buildAnswerButton('그렇다', 1),
                            SizedBox(height: 12),
                            _buildAnswerButton('보통이다', 0),
                            SizedBox(height: 12),
                            _buildAnswerButton('그렇지 않다', -1),
                            SizedBox(height: 12),
                            _buildAnswerButton('매우 그렇지 않다', -2),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 이전/다음 버튼
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                // 이전 버튼
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        side: BorderSide(
                          color: const Color.fromARGB(255, 0, 108, 82),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        '이전',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 0, 108, 82),
                        ),
                      ),
                    ),
                  ),
                if (_currentQuestionIndex > 0) SizedBox(width: 10),

                // 다음/결과 보기 버튼
                Expanded(
                  child: ElevatedButton(
                    onPressed: _abtiAnswers.containsKey(_currentQuestionIndex)
                        ? _nextQuestion
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                      _currentQuestionIndex == _questions.length - 1
                          ? '결과 보기'
                          : '다음',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 원형 라디오 버튼
  Widget _buildAnswerButton(String text, int value) {
    bool isSelected = _abtiAnswers[_currentQuestionIndex] == value;

    return InkWell(
      onTap: () {
        setState(() {
          _abtiAnswers[_currentQuestionIndex] = value;
        });
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 0, 108, 82)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 0, 108, 82)
                : const Color.fromARGB(255, 200, 200, 200),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  /// 이전 질문
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  /// 다음 질문
  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      // 마지막 질문 - 결과 계산
      _calculateAbtiResult();
    }
  }

  /// ABTI 결과 계산
  void _calculateAbtiResult() {
    if (_abtiAnswers.length < 20) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('모든 질문에 답변해주세요.')));
      return;
    }

    // E/I 계산 (질문 0-4)
    // 질문 0, 2, 4: 긍정적 답변(높은 점수)일수록 E
    // 질문 1, 3: 긍정적 답변(높은 점수)일수록 I (반전)
    int eScore = 0;
    for (int i = 0; i < 5; i++) {
      int answer = _abtiAnswers[i] ?? 0;
      if (i == 0 || i == 2 || i == 4) {
        // E에 해당하는 질문
        eScore += answer;
      } else {
        // I에 해당하는 질문 (반전)
        eScore -= answer;
      }
    }
    String ei = eScore > 0 ? 'E' : 'I';

    // S/N 계산 (질문 5-9)
    // 질문 6, 8: 긍정적 답변일수록 N
    // 질문 5, 7, 9: 긍정적 답변일수록 S (반전)
    int nScore = 0;
    for (int i = 5; i < 10; i++) {
      int answer = _abtiAnswers[i] ?? 0;
      if (i == 6 || i == 8) {
        // N에 해당하는 질문
        nScore += answer;
      } else {
        // S에 해당하는 질문 (반전)
        nScore -= answer;
      }
    }
    String sn = nScore > 0 ? 'N' : 'S';

    // T/F 계산 (질문 10-14)
    // 질문 10, 12, 14: 긍정적 답변일수록 T
    // 질문 11, 13: 긍정적 답변일수록 F (반전)
    int tScore = 0;
    for (int i = 10; i < 15; i++) {
      int answer = _abtiAnswers[i] ?? 0;
      if (i == 10 || i == 12 || i == 14) {
        // T에 해당하는 질문
        tScore += answer;
      } else {
        // F에 해당하는 질문 (반전)
        tScore -= answer;
      }
    }
    String tf = tScore > 0 ? 'T' : 'F';

    // J/P 계산 (질문 15-19)
    // 질문 15, 17, 19: 긍정적 답변일수록 J
    // 질문 16, 18: 긍정적 답변일수록 P (반전)
    int jScore = 0;
    for (int i = 15; i < 20; i++) {
      int answer = _abtiAnswers[i] ?? 0;
      if (i == 15 || i == 17 || i == 19) {
        // J에 해당하는 질문
        jScore += answer;
      } else {
        // P에 해당하는 질문 (반전)
        jScore -= answer;
      }
    }
    String jp = jScore > 0 ? 'J' : 'P';

    String abtiType = ei + sn + tf + jp;

    // 결과 다이얼로그 표시
    _showAbtiResult(abtiType);
  }

  /// ABTI 결과 다이얼로그
  void _showAbtiResult(String abtiType) {
    Map<String, Map<String, String>> abtiData = _getAbtiData();
    Map<String, String>? result = abtiData[abtiType];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '펫 ABTI 결과: $abtiType',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '특징',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(result?['특징'] ?? ''),
              SizedBox(height: 10),
              Text(
                '말투/페르소나',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(result?['말투'] ?? ''),
              SizedBox(height: 10),
              Text(
                '놀이/훈련',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(result?['놀이'] ?? ''),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context, abtiType); // 결과를 이전 화면으로 전달
            },
            child: Text(
              '확인',
              style: TextStyle(
                color: const Color.fromARGB(255, 0, 108, 82),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ABTI 16가지 유형 데이터
  Map<String, Map<String, String>> _getAbtiData() {
    return {
      'ESTJ': {
        '특징': '사회적·감각형·규칙 선호·루틴 고집',
        '말투': '"규칙대로 하자, 시간 지켜"',
        '놀이': '짧고 명확한 지시 연속, 방문객 루틴, 급식·산책 시간 고정',
      },
      'ESTP': {
        '특징': '사회적·감각형·즉흥·고에너지',
        '말투': '"바로 가자, 공 던져"',
        '놀이': '고강도 프리플레이·스프린트, 안전한 에너지 발산 동선',
      },
      'ESFJ': {
        '특징': '사회적·정서 민감·루틴 선호, 분리불안 소인',
        '말투': '"함께 하는 게 좋아"',
        '놀이': '칭찬+스킨십 중심, 점진 사회화, 출·퇴근 의식화',
      },
      'ESFP': {
        '특징': '사회적·정서 민감·유연, 흥분 전환 빠름',
        '말투': '"지금 놀자, 재밌다"',
        '놀이': '짧고 빈번한 상호작용 놀이, 쿨다운 스테이션 준비',
      },
      'ENTJ': {
        '특징': '사회적·탐색·과제지향·루틴',
        '말투': '"목표 정하고 단계별로 간다"',
        '놀이': '퍼즐 난이도 상승 커리큘럼, 예측 가능한 패턴 내 변화',
      },
      'ENTP': {
        '특징': '사회적·탐색·즉흥, 지루함에 민감',
        '말투': '"새 방식으로 해보자"',
        '놀이': '노즈워크/퍼즐 변형, 장난감 주간 로테이션',
      },
      'ENFJ': {
        '특징': '사회적·탐색·정서 민감·루틴',
        '말투': '"함께 성장하자"',
        '놀이': '칭찬+퍼즐 혼합, 일정 유지+환경 풍부화',
      },
      'ENFP': {
        '특징': '사회적·탐색·정서 민감·유연',
        '말투': '"새 친구·새 장난감 좋아"',
        '놀이': '자유놀이+짧은 컨트롤, 과자극 시 쿨다운',
      },
      'ISTJ': {
        '특징': '독립·감각·규칙·루틴, 낯가림',
        '말투': '"내 자리·내 시간 그대로"',
        '놀이': '일관 보상으로 짧은 반복, 배치·화장실 위치 고정',
      },
      'ISTP': {
        '특징': '독립·감각·즉흥, 사냥 드라이브 강함',
        '말투': '"조용히, 내가 알아서"',
        '놀이': '텃(Tug) 컨트롤·릴리즈 명확, 단독 사냥놀이 짧고 빈번',
      },
      'ISFJ': {
        '특징': '독립·정서 민감·루틴, 과자극 취약',
        '말투': '"천천히, 네 옆이면 괜찮아"',
        '놀이': '부드러운 톤·짧은 접촉, 저자극 환경·안전기지 유지',
      },
      'ISFP': {
        '특징': '독립·정서 민감·유연, 강압 싫어함',
        '말투': '"내 페이스를 존중해"',
        '놀이': '선택권 기반 훈련, 강제 접촉 금지, 은신/높은 곳 제공',
      },
      'INTJ': {
        '특징': '독립·탐색·과제·루틴, 문제해결 지향',
        '말투': '"문제를 주면 해결한다"',
        '놀이': '셰이핑·고급 트릭, 퍼즐 단계적 난도 상승',
      },
      'INTP': {
        '특징': '독립·탐색·즉흥, 자유실험형',
        '말투': '"왜 그럴까? 해보자"',
        '놀이': '자유 탐색 후 짧은 트릭, 규칙 잦은 변경으로 지루함 방지',
      },
      'INFJ': {
        '특징': '독립·탐색·정서 민감·루틴, 신중한 확장',
        '말투': '"조용히, 깊게"',
        '놀이': '예측 가능한 탐색 루틴, 점진 노출·짧은 퍼즐',
      },
      'INFP': {
        '특징': '독립·탐색·정서 민감·유연, 강압 역효과',
        '말투': '"내 선택을 존중해줘"',
        '놀이': '선택 기반 보상, 짧고 빈번한 스킨십, 서서히 변화',
      },
    };
  }
}
