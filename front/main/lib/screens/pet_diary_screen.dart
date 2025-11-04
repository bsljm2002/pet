// 펫 일기 화면 위젯
// 반려동물의 일상과 추억을 기록하는 다이어리 기능
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';

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
    final profiles = PetProfileManager().getAllProfiles();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 펫일기 섹션 제목
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Color(0xFFD4F4E7),
            child: Column(
              children: [
                Text(
                  '펫일기',
                  style: TextStyle(
                    fontSize: 18,
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
          if (profiles.isNotEmpty) _buildPetCarousel(profiles),

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
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  // 프로필 이미지
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Color(0xFF00B27A)
                            : Colors.transparent,
                        width: 3,
                      ),
                      image: profile.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(profile.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.grey[300],
                    ),
                    child: profile.imageUrl == null
                        ? Icon(Icons.pets, size: 35, color: Colors.grey[600])
                        : null,
                  ),
                  SizedBox(height: 8),
                  // 반려동물 이름
                  Text(
                    profile.name,
                    style: TextStyle(
                      fontSize: 14,
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
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? Color(0xFF00B27A)
                            : isToday
                            ? Color(0xFF8ED4BD)
                            : Colors.transparent,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: isSelected || isToday
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
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
          height: 200,
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFD4F4E7), // 연한 민트색
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _diaryController,
            maxLines: null,
            expands: true,
            decoration: InputDecoration(
              hintText: '오늘의 일기를 작성해주세요...',
              border: InputBorder.none,
              hintStyle: TextStyle(color: Colors.grey[500]),
            ),
            style: TextStyle(fontSize: 16),
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
