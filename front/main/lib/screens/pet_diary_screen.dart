// 펫 일기 화면 위젯
// 반려동물의 일상과 추억을 기록하는 다이어리 기능
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../models/pet_diary.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import '../services/diary_service.dart';

// 펫 일기 화면
// 반려동물의 일상, 건강 상태, 특별한 순간 등을 기록하고 관리
class PetDiaryScreen extends StatefulWidget {
  const PetDiaryScreen({super.key});

  @override
  State<PetDiaryScreen> createState() => _PetDiaryScreenState();
}

class _PetDiaryScreenState extends State<PetDiaryScreen> {
  int _selectedPetIndex = 0;
  DateTime _selectedDate = DateTime.now();
  int _calendarWeekOffset = 0; // 주간 달력 오프셋
  String _selectedBottomTab = '체중'; // 하단 탭 선택 상태
  String _selectedDiaryTab = '하루 일기'; // 하루 일기 / 종합 상태 선택
  final TextEditingController _diaryController = TextEditingController();

  List<PetProfile> _petProfiles = []; // 펫 목록 데이터
  bool _isLoading = true; // 로딩 상태
  String? _errorMessage; // 에러 메시지
  PetDiary? _currentDiary; // 현재 선택된 날짜의 일기

  // 이미지 URL을 완전한 URL로 변환하는 헬퍼 함수
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    // 이미 완전한 URL인 경우 그대로 반환
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    // 상대 경로인 경우 백엔드 서버 주소를 붙여서 반환
    return 'http://192.168.70.210:9075$imageUrl';
  }

  @override
  void initState() {
    super.initState();
    _loadPetProfiles(); // 화면 로드 시 펫 목록 조회
  }

  Future<void> _loadPetProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 현재 로그인 한 사용자 확인
      final currentUser = AuthService().currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "로그인이 필요합니다.";
        });
        return;
      }
      // 백엔드 API 호출
      final response = await PetService().getPetsByOwner(currentUser.id);

      if (response['success'] == true) {
        // 성공: JSON 데이터를 PetProfile 객체로 변환
        final List<dynamic> petsData = response['pets'];
        final List<PetProfile> profiles = petsData
            .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
            .toList();

        // 디버깅: 이미지 URL 확인
        for (var profile in profiles) {
          print('Pet: ${profile.name}, ImageURL: ${profile.imageUrl}');
        }

        setState(() {
          _petProfiles = profiles;
          _isLoading = false;
        });

        // 펫 목록 로드 후 일기 불러오기
        _loadDiary();
      } else {
        // 실패: 에러 메시지 설정
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? '펫 목록을 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '네트워크 오류: $e';
      });
    }
  }

  /// 일기 불러오기
  Future<void> _loadDiary() async {
    if (_petProfiles.isEmpty) {
      print('📋 일기 불러오기 실패: 펫 프로필이 없음');
      return;
    }
    if (_petProfiles[_selectedPetIndex].id == null) {
      print('📋 일기 불러오기 실패: 펫 ID가 없음');
      return;
    }

    print(
      '📋 일기 불러오기 시작: petId=${_petProfiles[_selectedPetIndex].id}, date=${_selectedDate.toString().split(' ')[0]}',
    );

    final diary = await DiaryService().getDiary(
      _petProfiles[_selectedPetIndex].id!,
      _selectedDate,
    );

    print(
      '📋 일기 조회 결과: ${diary != null ? "일기 있음 (${diary.content?.length ?? 0}자)" : "일기 없음"}',
    );

    setState(() {
      _currentDiary = diary;
      _diaryController.text = diary?.content ?? '';
    });
  }

  @override
  void dispose() {
    _diaryController.dispose();
    super.dispose();
  }

  // 선택된 주의 날짜 목록 가져오기
  List<DateTime> _getWeekDates() {
    final today = DateTime.now();
    final firstDayOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final targetWeek = firstDayOfWeek.add(
      Duration(days: 7 * _calendarWeekOffset),
    );

    return List.generate(7, (index) {
      return targetWeek.add(Duration(days: index));
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 펫일기 섹션 제목
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Color.fromARGB(255, 224, 224, 224),
            child: Column(
              children: [
                Text(
                  'MyPet',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B27A),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Color(0xFF00B27A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),

          // 펫 프로필 캐러셀 (동그라미 아이콘)
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF00B27A)),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            )
          else if (_petProfiles.isNotEmpty)
            _buildPetCarousel(_petProfiles),

          // 반려동물과 달력 사이 간격
          SizedBox(height: 24),

          // 달력 섹션 제목
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Text(
                  '달력',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 1,
                  color: Colors.grey[300],
                ),
              ],
            ),
          ),

          // 달력 섹션
          _buildCalendarSection(),

          // 하루 일기 / 종합 상태 탭
          _buildDiaryTabs(),

          // 일기 내용 영역
          _buildDiaryContent(),

          // 하단 버튼 영역
          _buildBottomButtons(),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  // 펫 프로필 캐러셀
  Widget _buildPetCarousel(List<PetProfile> profiles) {
    return Container(
      height: 120,
      padding: EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: profiles.length,
        itemBuilder: (context, index) {
          final profile = profiles[index];
          final isSelected = _selectedPetIndex == index;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedPetIndex = index;
              });
              _loadDiary(); // 펫 변경 시 일기 다시 불러오기
            },
            child: Container(
              width: 90,
              margin: EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                children: [
                  // 프로필 이미지
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: PhysicalShape(
                      clipper: _SvgMaskClipper(profile.species),
                      color: Colors.transparent,
                      shadowColor: isSelected
                          ? Color(0xFF00B27A)
                          : Colors.black,
                      elevation: isSelected ? 3 : 1,
                      child: ClipPath(
                        clipper: _SvgMaskClipper(profile.species),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[300],
                          child:
                              (profile.imageUrl != null &&
                                  profile.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  _getFullImageUrl(profile.imageUrl),
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                      'Image load error for ${profile.name}: $error',
                                    );
                                    return Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 35,
                                        color: Colors.grey[600],
                                      ),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: Color(0xFF00B27A),
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
                                )
                              : Center(
                                  child: Icon(
                                    Icons.pets,
                                    size: 35,
                                    color: Colors.grey[600],
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 1),
                  // 반려동물 이름
                  Text(
                    profile.name,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: isSelected ? Color(0xFF00B27A) : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 달력 섹션
  Widget _buildCalendarSection() {
    final weekDates = _getWeekDates();
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 달력 헤더 (연월 표시 및 이전/다음 버튼)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: Color(0xFF00B27A)),
                onPressed: () {
                  setState(() {
                    _calendarWeekOffset--;
                    // 주간 오프셋에 따라 표시되는 주의 중간 날짜로 업데이트
                    final weekDates = _getWeekDates();
                    _selectedDate = weekDates[3]; // 수요일을 기준으로 설정
                  });
                  _loadDiary(); // 주 변경 시 일기 다시 불러오기
                },
              ),
              Text(
                '${weekDates[0].year}.${weekDates[0].month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B27A),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Color(0xFF00B27A)),
                onPressed: () {
                  setState(() {
                    _calendarWeekOffset++;
                    // 주간 오프셋에 따라 표시되는 주의 중간 날짜로 업데이트
                    final weekDates = _getWeekDates();
                    _selectedDate = weekDates[3]; // 수요일을 기준으로 설정
                  });
                  _loadDiary(); // 주 변경 시 일기 다시 불러오기
                },
              ),
            ],
          ),
          SizedBox(height: 16),
          // 주간 달력
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = weekDates[index];
              final isSelected =
                  date.day == _selectedDate.day &&
                  date.month == _selectedDate.month &&
                  date.year == _selectedDate.year;
              final isToday =
                  date.day == DateTime.now().day &&
                  date.month == DateTime.now().month &&
                  date.year == DateTime.now().year;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                  _loadDiary(); // 날짜 변경 시 일기 다시 불러오기
                },
                child: Column(
                  children: [
                    // 요일
                    Text(
                      weekdays[index],
                      style: TextStyle(
                        fontSize: 14,
                        color: index == 0
                            ? Colors.red
                            : index == 6
                            ? Colors.blue
                            : Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    // 날짜
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 배경 (선택된 날짜 또는 오늘 날짜인 경우 발바닥 모양)
                          if (isSelected || isToday)
                            CustomPaint(
                              size: Size(40, 40),
                              painter: _PawMarkPainter(
                                color: isSelected
                                    ? Color(0xFF00B27A)
                                    : Color(0xFF8ED4BD),
                              ),
                            ),
                          // 날짜 텍스트
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected || isToday
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // 하루 일기 / 종합 상태 탭
  Widget _buildDiaryTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDiaryTab = '하루 일기';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedDiaryTab == '하루 일기'
                          ? Color(0xFF00B27A)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '하루 일기',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedDiaryTab == '하루 일기'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedDiaryTab == '하루 일기'
                        ? Color(0xFF00B27A)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDiaryTab = '종합 상태';
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedDiaryTab == '종합 상태'
                          ? Color(0xFF00B27A)
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  '종합 상태',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedDiaryTab == '종합 상태'
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: _selectedDiaryTab == '종합 상태'
                        ? Color(0xFF00B27A)
                        : Colors.grey,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 일기 내용 영역
  Widget _buildDiaryContent() {
    return Column(
      children: [
        // 일기 작성 영역
        Container(
          height: 350,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFD4F4E7), // 연한 민트색
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: TextField(
              controller: _diaryController,
              maxLines: null,
              readOnly: true, // 읽기 전용으로 설정
              decoration: InputDecoration(
                hintText: '아직 작성된 일기가 없습니다.',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[500]),
              ),
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),

        // 선택된 탭에 따른 데이터 표시
        _buildSelectedTabContent(),
      ],
    );
  }

  // 선택된 탭의 내용 표시
  Widget _buildSelectedTabContent() {
    switch (_selectedBottomTab) {
      case '체중':
        return _buildWeightChart();
      case '심박수':
        return _buildHeartRateChart();
      case '스트레스':
        return _buildStressChart();
      case '질환':
        return _buildDiseaseInfo();
      default:
        return SizedBox.shrink();
    }
  }

  // 체중 차트
  Widget _buildWeightChart() {
    // 샘플 데이터
    final data = {'오늘': 5.2, '이번주': 5.3, '이번달': 5.5, '전체': 5.0};
    final maxValue = 7.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '체중 변화',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          ...data.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value} kg',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00B27A),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: entry.value / maxValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF00B27A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 심박수 차트
  Widget _buildHeartRateChart() {
    final data = {'오늘': 85, '이번주': 88, '이번달': 90, '전체': 87};
    final maxValue = 120;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '심박수 변화',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          ...data.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value} bpm',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[400],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: entry.value / maxValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 스트레스 차트
  Widget _buildStressChart() {
    final data = {'오늘': 3, '이번주': 4, '이번달': 5, '전체': 4};
    final maxValue = 10;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '스트레스 지수',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          ...data.entries.map((entry) {
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${entry.value} / 10',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: entry.value / maxValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // 질환 정보
  Widget _buildDiseaseInfo() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '질환 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 20),
          _buildDiseaseItem('피부염', '2024.01.15 진단', Colors.purple[300]!),
          SizedBox(height: 12),
          _buildDiseaseItem('관절염', '2024.03.20 진단', Colors.blue[300]!),
          SizedBox(height: 12),
          _buildDiseaseItem('알레르기', '2024.05.10 진단', Colors.pink[300]!),
        ],
      ),
    );
  }

  // 질환 아이템
  Widget _buildDiseaseItem(String name, String date, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 하단 버튼 영역 (체중, 심박수, 스트레스, 질환)
  Widget _buildBottomButtons() {
    final buttons = ['체중', '심박수', '스트레스', '질환'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: buttons.map((label) {
          final isSelected = _selectedBottomTab == label;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedBottomTab = label;
                });
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF00B27A) : Colors.white,
                  border: Border.all(color: Color(0xFF00B27A), width: 1.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected ? Colors.white : Color(0xFF00B27A),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// SVG 모양으로 이미지를 마스킹하는 CustomClipper
class _SvgMaskClipper extends CustomClipper<Path> {
  final String species;

  _SvgMaskClipper(this.species);

  @override
  Path getClip(Size size) {
    final path = Path();
    final speciesLower = species.toLowerCase();

    // 크기에 맞게 스케일 조정
    final scaleX = size.width / 302;
    final scaleY = size.height / 325;

    if (speciesLower.contains('dog') || speciesLower.contains('개')) {
      // 개 프레임 경로 (dog_i.svg의 path)
      path.moveTo(111 * scaleX, 30.1659 * scaleY);
      path.cubicTo(
        123.333 * scaleX,
        25.8325 * scaleY,
        156.6 * scaleX,
        19.7659 * scaleY,
        191 * scaleX,
        30.1659 * scaleY,
      );
      path.cubicTo(
        193.833 * scaleX,
        22.1659 * scaleY,
        204.5 * scaleX,
        5.16587 * scaleY,
        224.5 * scaleX,
        1.16587 * scaleY,
      );
      path.cubicTo(
        244.5 * scaleX,
        -2.83413 * scaleY,
        260.833 * scaleX,
        12.1659 * scaleY,
        266.5 * scaleX,
        20.1659 * scaleY,
      );
      path.cubicTo(
        274.667 * scaleX,
        30.9992 * scaleY,
        287.3 * scaleX,
        59.3659 * scaleY,
        272.5 * scaleX,
        86.1659 * scaleY,
      );
      path.cubicTo(
        282.833 * scaleX,
        99.4992 * scaleY,
        303 * scaleX,
        136.666 * scaleY,
        301 * scaleX,
        178.666 * scaleY,
      );
      path.cubicTo(
        299.333 * scaleX,
        197.499 * scaleY,
        291.3 * scaleX,
        240.766 * scaleY,
        272.5 * scaleX,
        263.166 * scaleY,
      );
      path.cubicTo(
        261 * scaleX,
        277.499 * scaleY,
        228.6 * scaleX,
        308.766 * scaleY,
        191 * scaleX,
        319.166 * scaleY,
      );
      path.cubicTo(
        177.667 * scaleX,
        322.833 * scaleY,
        143 * scaleX,
        327.966 * scaleY,
        111 * scaleX,
        319.166 * scaleY,
      );
      path.cubicTo(
        94.6667 * scaleX,
        314.999 * scaleY,
        55.6 * scaleX,
        297.966 * scaleY,
        30 * scaleX,
        263.166 * scaleY,
      );
      path.cubicTo(
        20.3333 * scaleX,
        252.333 * scaleY,
        0.9 * scaleX,
        220.266 * scaleY,
        0.5 * scaleX,
        178.666 * scaleY,
      );
      path.cubicTo(
        0.833333 * scaleX,
        159.666 * scaleY,
        7.2 * scaleX,
        114.566 * scaleY,
        30 * scaleX,
        86.1659 * scaleY,
      );
      path.cubicTo(
        23.5 * scaleX,
        76.1659 * scaleY,
        15.5 * scaleX,
        48.9659 * scaleY,
        35.5 * scaleX,
        20.1659 * scaleY,
      );
      path.cubicTo(
        40 * scaleX,
        12.6659 * scaleY,
        54.7 * scaleX,
        -1.63412 * scaleY,
        77.5 * scaleX,
        1.16587 * scaleY,
      );
      path.cubicTo(
        85.6667 * scaleX,
        2.49921 * scaleY,
        103.8 * scaleX,
        10.1659 * scaleY,
        111 * scaleX,
        30.1659 * scaleY,
      );
    } else {
      // 고양이 프레임 경로 (cat_i.svg의 path)
      final catScaleY = size.height / 331;
      path.moveTo(186.347 * scaleX, 35.1901 * catScaleY);
      path.cubicTo(
        172.847 * scaleX,
        32.0235 * catScaleY,
        139.547 * scaleX,
        27.5901 * catScaleY,
        114.347 * scaleX,
        35.1901 * catScaleY,
      );
      path.cubicTo(
        108.18 * scaleX,
        26.0235 * catScaleY,
        94.047 * scaleX,
        6.29012 * catScaleY,
        86.847 * scaleX,
        0.690125 * catScaleY,
      );
      path.cubicTo(
        76.1803 * scaleX,
        9.52346 * catScaleY,
        52.547 * scaleX,
        36.8901 * catScaleY,
        43.347 * scaleX,
        75.6901 * catScaleY,
      );
      path.cubicTo(
        11.0136 * scaleX,
        109.19 * catScaleY,
        -34.253 * scaleX,
        198.09 * catScaleY,
        43.347 * scaleX,
        285.69 * catScaleY,
      );
      path.cubicTo(
        56.347 * scaleX,
        300.023 * catScaleY,
        94.5469 * scaleX,
        328.99 * catScaleY,
        143.347 * scaleX,
        330.19 * catScaleY,
      );
      path.cubicTo(
        167.014 * scaleX,
        331.19 * catScaleY,
        223.047 * scaleX,
        323.69 * catScaleY,
        257.847 * scaleX,
        285.69 * catScaleY,
      );
      path.cubicTo(
        290.18 * scaleX,
        254.523 * catScaleY,
        335.447 * scaleX,
        168.89 * catScaleY,
        257.847 * scaleX,
        75.6901 * catScaleY,
      );
      path.cubicTo(
        252.347 * scaleX,
        58.5235 * catScaleY,
        235.847 * scaleX,
        19.4901 * catScaleY,
        213.847 * scaleX,
        0.690125 * catScaleY,
      );
      path.cubicTo(
        206.18 * scaleX,
        8.85679 * catScaleY,
        189.947 * scaleX,
        27.1901 * catScaleY,
        186.347 * scaleX,
        35.1901 * catScaleY,
      );
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// 발바닥 모양을 그리는 CustomPainter
class _PawMarkPainter extends CustomPainter {
  final Color color;

  _PawMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // mark.svg의 path를 40x40 크기에 맞게 스케일 조정
    final scaleX = size.width / 353;
    final scaleY = size.height / 342;
    final offsetY = -size.height * 0.2; // 위로 8% 이동

    // 첫 번째 path (우측 상단 발가락)
    path.moveTo(350.751 * scaleX, 110.68 * scaleY + offsetY);
    path.cubicTo(
      348.418 * scaleX,
      98.5128 * scaleY + offsetY,
      335.951 * scaleX,
      77.4795 * scaleY + offsetY,
      304.751 * scaleX,
      90.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      273.551 * scaleX,
      103.88 * scaleY + offsetY,
      266.751 * scaleX,
      137.18 * scaleY + offsetY,
      267.251 * scaleX,
      152.18 * scaleY + offsetY,
    );
    path.cubicTo(
      267.084 * scaleX,
      163.513 * scaleY + offsetY,
      271.951 * scaleX,
      186.88 * scaleY + offsetY,
      292.751 * scaleX,
      189.68 * scaleY + offsetY,
    );
    path.cubicTo(
      318.751 * scaleX,
      193.18 * scaleY + offsetY,
      333.751 * scaleX,
      175.18 * scaleY + offsetY,
      342.251 * scaleX,
      161.18 * scaleY + offsetY,
    );
    path.cubicTo(
      349.051 * scaleX,
      149.98 * scaleY + offsetY,
      350.751 * scaleX,
      140.513 * scaleY + offsetY,
      350.751 * scaleX,
      137.18 * scaleY + offsetY,
    );
    path.cubicTo(
      351.81 * scaleX,
      131.346 * scaleY + offsetY,
      353.292 * scaleX,
      117.88 * scaleY + offsetY,
      350.751 * scaleX,
      110.68 * scaleY + offsetY,
    );
    path.close();

    // 두 번째 path (중앙 상단 발가락)
    path.moveTo(256.751 * scaleX, 7.17951 * scaleY + offsetY);
    path.cubicTo(
      247.584 * scaleX,
      -0.487154 * scaleY + offsetY,
      224.051 * scaleX,
      -7.92049 * scaleY + offsetY,
      203.251 * scaleX,
      23.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      182.451 * scaleX,
      55.2795 * scaleY + offsetY,
      189.584 * scaleX,
      87.5128 * scaleY + offsetY,
      195.751 * scaleX,
      99.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      201.251 * scaleX,
      112.346 * scaleY + offsetY,
      217.551 * scaleX,
      134.68 * scaleY + offsetY,
      238.751 * scaleX,
      122.68 * scaleY + offsetY,
    );
    path.cubicTo(
      259.951 * scaleX,
      110.68 * scaleY + offsetY,
      271.584 * scaleX,
      86.0128 * scaleY + offsetY,
      274.751 * scaleX,
      75.1795 * scaleY + offsetY,
    );
    path.cubicTo(
      276.918 * scaleX,
      67.3462 * scaleY + offsetY,
      279.951 * scaleX,
      48.2795 * scaleY + offsetY,
      274.751 * scaleX,
      34.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      269.551 * scaleX,
      21.0795 * scaleY + offsetY,
      260.584 * scaleX,
      10.6795 * scaleY + offsetY,
      256.751 * scaleX,
      7.17951 * scaleY + offsetY,
    );
    path.close();

    // 세 번째 path (좌측 상단 발가락)
    path.moveTo(125.751 * scaleX, 1.67951 * scaleY + offsetY);
    path.cubicTo(
      114.251 * scaleX,
      -1.32049 * scaleY + offsetY,
      88.951 * scaleX,
      1.07951 * scaleY + offsetY,
      79.751 * scaleX,
      34.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      70.551 * scaleX,
      68.2795 * scaleY + offsetY,
      88.9177 * scaleX,
      99.3462 * scaleY + offsetY,
      99.251 * scaleX,
      110.68 * scaleY + offsetY,
    );
    path.cubicTo(
      105.584 * scaleX,
      118.68 * scaleY + offsetY,
      122.751 * scaleX,
      132.28 * scaleY + offsetY,
      140.751 * scaleX,
      122.68 * scaleY + offsetY,
    );
    path.cubicTo(
      158.751 * scaleX,
      113.08 * scaleY + offsetY,
      165.584 * scaleX,
      84.6795 * scaleY + offsetY,
      166.751 * scaleX,
      71.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      166.751 * scaleX,
      59.0128 * scaleY + offsetY,
      163.451 * scaleX,
      30.4795 * scaleY + offsetY,
      150.251 * scaleX,
      17.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      137.051 * scaleX,
      4.87951 * scaleY + offsetY,
      128.418 * scaleX,
      1.67951 * scaleY + offsetY,
      125.751 * scaleX,
      1.67951 * scaleY + offsetY,
    );
    path.close();

    // 네 번째 path (좌측 발가락)
    path.moveTo(21.751 * scaleX, 87.1795 * scaleY + offsetY);
    path.cubicTo(
      13.751 * scaleX,
      89.0128 * scaleY + offsetY,
      -1.64897 * scaleX,
      99.1795 * scaleY + offsetY,
      0.75103 * scaleX,
      125.18 * scaleY + offsetY,
    );
    path.cubicTo(
      3.15103 * scaleX,
      151.18 * scaleY + offsetY,
      12.4177 * scaleX,
      164.68 * scaleY + offsetY,
      16.751 * scaleX,
      168.18 * scaleY + offsetY,
    );
    path.cubicTo(
      26.0844 * scaleX,
      178.513 * scaleY + offsetY,
      49.951 * scaleX,
      196.38 * scaleY + offsetY,
      70.751 * scaleX,
      185.18 * scaleY + offsetY,
    );
    path.cubicTo(
      91.551 * scaleX,
      173.98 * scaleY + offsetY,
      87.0844 * scaleX,
      140.513 * scaleY + offsetY,
      82.251 * scaleX,
      125.18 * scaleY + offsetY,
    );
    path.cubicTo(
      78.751 * scaleX,
      116.346 * scaleY + offsetY,
      67.651 * scaleX,
      97.0795 * scaleY + offsetY,
      51.251 * scaleX,
      90.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      34.851 * scaleX,
      84.2795 * scaleY + offsetY,
      24.751 * scaleX,
      85.6795 * scaleY + offsetY,
      21.751 * scaleX,
      87.1795 * scaleY + offsetY,
    );
    path.close();

    // 다섯 번째 path (메인 발바닥)
    path.moveTo(245.751 * scaleX, 174.68 * scaleY + offsetY);
    path.cubicTo(
      239.918 * scaleX,
      166.18 * scaleY + offsetY,
      220.651 * scaleX,
      147.98 * scaleY + offsetY,
      190.251 * scaleX,
      143.18 * scaleY + offsetY,
    );
    path.cubicTo(
      180.418 * scaleX,
      142.513 * scaleY + offsetY,
      158.751 * scaleX,
      142.28 * scaleY + offsetY,
      150.751 * scaleX,
      146.68 * scaleY + offsetY,
    );
    path.cubicTo(
      140.751 * scaleX,
      152.18 * scaleY + offsetY,
      133.251 * scaleX,
      150.18 * scaleY + offsetY,
      112.251 * scaleX,
      171.68 * scaleY + offsetY,
    );
    path.cubicTo(
      110.251 * scaleX,
      174.68 * scaleY + offsetY,
      105.951 * scaleX,
      181.58 * scaleY + offsetY,
      104.751 * scaleX,
      185.18 * scaleY + offsetY,
    );
    path.cubicTo(
      103.551 * scaleX,
      188.78 * scaleY + offsetY,
      89.251 * scaleX,
      203.013 * scaleY + offsetY,
      82.251 * scaleX,
      209.68 * scaleY + offsetY,
    );
    path.cubicTo(
      73.9177 * scaleX,
      216.513 * scaleY + offsetY,
      56.651 * scaleX,
      236.18 * scaleY + offsetY,
      54.251 * scaleX,
      260.18 * scaleY + offsetY,
    );
    path.cubicTo(
      51.851 * scaleX,
      284.18 * scaleY + offsetY,
      64.251 * scaleX,
      306.18 * scaleY + offsetY,
      70.751 * scaleX,
      314.18 * scaleY + offsetY,
    );
    path.cubicTo(
      77.751 * scaleX,
      324.013 * scaleY + offsetY,
      99.751 * scaleX,
      343.08 * scaleY + offsetY,
      131.751 * scaleX,
      340.68 * scaleY + offsetY,
    );
    path.cubicTo(
      137.251 * scaleX,
      340.013 * scaleY + offsetY,
      150.951 * scaleX,
      337.98 * scaleY + offsetY,
      161.751 * scaleX,
      335.18 * scaleY + offsetY,
    );
    path.cubicTo(
      172.551 * scaleX,
      332.38 * scaleY + offsetY,
      188.918 * scaleX,
      334.013 * scaleY + offsetY,
      195.751 * scaleX,
      335.18 * scaleY + offsetY,
    );
    path.cubicTo(
      202.584 * scaleX,
      337.013 * scaleY + offsetY,
      219.551 * scaleX,
      340.68 * scaleY + offsetY,
      232.751 * scaleX,
      340.68 * scaleY + offsetY,
    );
    path.cubicTo(
      249.251 * scaleX,
      340.68 * scaleY + offsetY,
      272.751 * scaleX,
      332.68 * scaleY + offsetY,
      288.751 * scaleX,
      307.18 * scaleY + offsetY,
    );
    path.cubicTo(
      304.751 * scaleX,
      281.68 * scaleY + offsetY,
      299.751 * scaleX,
      254.18 * scaleY + offsetY,
      296.251 * scaleX,
      239.68 * scaleY + offsetY,
    );
    path.cubicTo(
      293.451 * scaleX,
      228.08 * scaleY + offsetY,
      275.751 * scaleX,
      209.846 * scaleY + offsetY,
      267.251 * scaleX,
      202.18 * scaleY + offsetY,
    );
    path.cubicTo(
      262.418 * scaleX,
      198.18 * scaleY + offsetY,
      251.351 * scaleX,
      187.08 * scaleY + offsetY,
      245.751 * scaleX,
      174.68 * scaleY + offsetY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
