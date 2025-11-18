// 펫 일기 생성 화면
// 펫의 상태를 체크하고 LLM으로 일기를 자동 생성하는 페이지
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../models/pet_diary.dart';
import '../services/llm_service.dart';
import '../services/diary_service.dart';

/// 펫 일기 생성 화면
class CreatePetDiaryScreen extends StatefulWidget {
  final PetProfile profile;

  const CreatePetDiaryScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<CreatePetDiaryScreen> createState() => _CreatePetDiaryScreenState();
}

class _CreatePetDiaryScreenState extends State<CreatePetDiaryScreen> {
  // 펫 상태 체크 항목
  double _weight = 5.0; // 체중 (kg)
  int _heartRate = 80; // 심박수 (bpm)
  int _stressLevel = 3; // 스트레스 (1-10)
  double _temperature = 38.5; // 체온 (°C)
  int _humidity = 50; // 습도 (%)
  String _mood = '보통'; // 기분
  String _activity = '보통'; // 활동량
  String _appetite = '보통'; // 식욕
  bool _isGenerating = false; // 일기 생성 중 상태
  String? _generatedDiary; // 생성된 일기

  final List<String> _moodOptions = ['매우 좋음', '좋음', '보통', '나쁨', '매우 나쁨'];
  final List<String> _activityOptions = ['매우 활발', '활발', '보통', '조용', '매우 조용'];
  final List<String> _appetiteOptions = ['매우 좋음', '좋음', '보통', '나쁨', '매우 나쁨'];

  /// 일기 생성 함수
  Future<void> _generateDiary() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      // LLM API 호출하여 일기 생성
      final response = await LLMService().generateDiary(
        petName: widget.profile.name,
        breed: widget.profile.speciesDetail ?? widget.profile.species,
        mbti: widget.profile.abtiTypeCode ?? 'ENFP',
        weight: _weight,
        heartRate: _heartRate,
        stressLevel: _stressLevel,
        temperature: _temperature,
        humidity: _humidity,
        mood: _mood,
        activity: _activity,
        appetite: _appetite,
      );

      if (response['success'] == true) {
        final diary = response['diary'];

        setState(() {
          _generatedDiary = diary;
          _isGenerating = false;
        });

        // 생성된 일기를 모달 오버레이로 표시
        if (mounted) {
          _showDiaryOverlay(diary);
        }
      } else {
        throw Exception(response['message'] ?? '일기 생성 실패');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('일기 생성 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  /// 생성된 일기를 오버레이로 표시
  void _showDiaryOverlay(String diary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              // 핸들바
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 20),

              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '생성된 일기',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 108, 82),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Divider(color: Colors.grey[300], thickness: 1),
              SizedBox(height: 10),

              // 일기 내용
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFD4F4E7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      diary,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),

              // 저장 버튼
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // 오버레이 닫기
                      _saveDiary();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF00B27A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '일기 저장하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 일기 저장 및 펫 일기 화면으로 이동
  Future<void> _saveDiary() async {
    if (_generatedDiary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('먼저 일기를 생성해주세요')),
      );
      return;
    }

    try {
      // 펫 ID 확인
      if (widget.profile.id == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('펫 정보가 올바르지 않습니다.')),
          );
        }
        return;
      }

      // 일기 객체 생성
      final diary = PetDiary(
        petId: widget.profile.id!,
        petName: widget.profile.name,
        date: DateTime.now(),
        content: _generatedDiary!,
        healthScore: null, // LLM 응답에서 healthScore를 받는다면 저장 가능
      );

      // 일기 저장
      final result = await DiaryService().saveDiary(diary);

      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '일기가 저장되었습니다.'),
              backgroundColor: Color(0xFF00B27A),
            ),
          );

          // 일기 화면으로 돌아가면서 새로고침 신호 전달
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? '일기 저장에 실패했습니다.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일기 저장 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 0, 108, 82),
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 0, 108, 82),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '오늘의 일기 작성',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 상단 펫 프로필
            Container(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: widget.profile.imageUrl != null
                        ? NetworkImage(widget.profile.imageUrl!)
                        : null,
                    child: widget.profile.imageUrl == null
                        ? Icon(Icons.pets, size: 50, color: Colors.grey)
                        : null,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.profile.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    DateTime.now().toString().split(' ')[0],
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // 하단 흰색 영역
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    Text(
                      '오늘의 ${widget.profile.name} 상태',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 108, 82),
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(color: Colors.grey[300], thickness: 2),
                    SizedBox(height: 20),

                    // 체중
                    _buildSliderSection(
                      '체중',
                      _weight,
                      'kg',
                      1.0,
                      20.0,
                      (value) => setState(() => _weight = value),
                    ),
                    SizedBox(height: 20),

                    // 심박수
                    _buildSliderSection(
                      '심박수',
                      _heartRate.toDouble(),
                      'bpm',
                      60.0,
                      150.0,
                      (value) => setState(() => _heartRate = value.toInt()),
                    ),
                    SizedBox(height: 20),

                    // 스트레스 지수
                    _buildSliderSection(
                      '스트레스 지수',
                      _stressLevel.toDouble(),
                      '/10',
                      1.0,
                      10.0,
                      (value) => setState(() => _stressLevel = value.toInt()),
                    ),
                    SizedBox(height: 20),

                    // 체온
                    _buildSliderSection(
                      '체온',
                      _temperature,
                      '°C',
                      36.0,
                      41.0,
                      (value) => setState(() => _temperature = value),
                      divisions: 50,
                    ),
                    SizedBox(height: 20),

                    // 습도
                    _buildSliderSection(
                      '습도',
                      _humidity.toDouble(),
                      '%',
                      0.0,
                      100.0,
                      (value) => setState(() => _humidity = value.toInt()),
                    ),
                    SizedBox(height: 20),

                    // 기분
                    _buildDropdownSection('기분', _mood, _moodOptions,
                        (value) => setState(() => _mood = value!)),
                    SizedBox(height: 20),

                    // 활동량
                    _buildDropdownSection('활동량', _activity, _activityOptions,
                        (value) => setState(() => _activity = value!)),
                    SizedBox(height: 20),

                    // 식욕
                    _buildDropdownSection('식욕', _appetite, _appetiteOptions,
                        (value) => setState(() => _appetite = value!)),
                    SizedBox(height: 30),

                    // 일기 생성 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isGenerating ? null : _generateDiary,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 0, 108, 82),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isGenerating
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '일기 생성 중...',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'AI로 일기 생성하기',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 슬라이더 섹션 위젯
  Widget _buildSliderSection(
    String label,
    double value,
    String unit,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            Text(
              '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} $unit',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 108, 82),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Color.fromARGB(255, 0, 108, 82),
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Color.fromARGB(255, 0, 108, 82),
            overlayColor: Color.fromARGB(50, 0, 108, 82),
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? ((max - min) * (unit == 'kg' ? 10 : 1)).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// 드롭다운 섹션 위젯
  Widget _buildDropdownSection(
    String label,
    String value,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: onChanged,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
