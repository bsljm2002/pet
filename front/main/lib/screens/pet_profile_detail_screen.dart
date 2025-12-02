// 펫 프로필 상세보기 화면
// 반려동물의 상세 정보를 확인하고 관리하는 페이지
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/pet_profile.dart';
import '../models/pet_diary.dart';
import '../services/pet_service.dart';
import '../services/diary_service.dart';
import 'create_pet_diary_screen.dart';
import 'edit_pet_profile_screen.dart';

/// 펫 프로필 상세보기 화면
///
/// 반려동물의 상세 정보를 표시:
/// - 프로필 이미지 및 이름
/// - 반려동물 정보 (나이, 체중, 품종, 성별)
/// - 반려동물 상태 (스트레스, 비만도, 피부병)
/// - 종합 상태 일지
class PetProfileDetailScreen extends StatefulWidget {
  final PetProfile profile;

  const PetProfileDetailScreen({Key? key, required this.profile})
    : super(key: key);

  @override
  State<PetProfileDetailScreen> createState() => _PetProfileDetailScreenState();
}

class _PetProfileDetailScreenState extends State<PetProfileDetailScreen> {
  // 설정 메뉴 표시 여부
  bool _showSettingsMenu = false;

  PetProfile? _latestProfile; // 최신 펫 데이터
  bool _isLoading = true; // 로딩 상태

  bool _isDeleting = false;

  // 달력 및 일기 관련 상태
  DateTime _selectedDate = DateTime.now();
  int _calendarWeekOffset = 0; // 주간 달력 오프셋
  String _selectedDiaryTab = '하루 일기'; // 하루 일기 / 종합 상태 선택
  final TextEditingController _diaryController = TextEditingController();
  PetDiary? _currentDiary; // 현재 선택된 날짜의 일기

  @override
  void initState() {
    super.initState();
    _loadPetDetails();
  }

  Future<void> _loadPetDetails() async {
    if (widget.profile.id == null) {
      setState(() {
        _latestProfile = widget.profile;
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await PetService().getPetById(widget.profile.id!);

      if (response['success'] == true) {
        final petData = response['pet'];
        final profile = PetProfile.fromJson(petData as Map<String, dynamic>);

        setState(() {
          _latestProfile = profile;
          _isLoading = false;
        });

        // 펫 정보 로드 후 일기 로드
        await _loadDiary();
      } else {
        // 실패 시 기존 데이터 사용
        setState(() {
          _latestProfile = widget.profile;
          _isLoading = false;
        });

        // 기존 데이터로 일기 로드 시도
        await _loadDiary();
      }
    } catch (e) {
      // 오류 시 기존 데이터 사용
      setState(() {
        _latestProfile = widget.profile;
        _isLoading = false;
      });

      // 오류 발생 시에도 일기 로드 시도
      await _loadDiary();
    }
  }

  /// 삭제 확인 다이얼로그 표시
  Future<void> _showDeleteConfirmDialog() async {
    if (widget.profile.id == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장되지 않은 프로필은 삭제할 수 없습니다.')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로필 삭제'),
        content: const Text('정말 삭제할까요? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: _isDeleting ? null : () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: _isDeleting
                ? null
                : () async {
                    Navigator.pop(ctx);
                    await _deletePet();
                  },
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('삭제'),
          ),
        ],
      ),
    );
  }

  /// 펫 프로필 삭제
  Future<void> _deletePet() async {
    final petId = _latestProfile?.id ?? widget.profile.id;
    if (petId == null) return;

    setState(() => _isDeleting = true);
    final result = await PetService().deletePet(petId);
    if (!mounted) return;

    setState(() => _isDeleting = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 삭제되었습니다.')));
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? '삭제에 실패했습니다.')),
      );
    }
  }

  /// 유효한 네트워크 URL인지 확인
  bool _isValidNetworkUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/media/');
  }

  /// 이미지 URL을 전체 경로로 변환
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/media/')) {
      // 백엔드 서버 주소 추가 (Android 에뮬레이터: 10.0.2.2)
      return 'http://10.0.2.2:9075$url';
    }
    return url;
  }

  /// 생년월일로부터 나이 계산
  String _calculateAge() {
    final profile = _latestProfile ?? widget.profile;
    if (profile.birthdate.isEmpty) {
      return '미등록';
    }

    try {
      // 생년월일 파싱 (여러 형식 지원)
      DateTime? birthDate;
      final birthday = profile.birthdate;

      // YYYY-MM-DD 또는 YYYY.MM.DD 형식
      if (birthday.contains('-')) {
        birthDate = DateTime.parse(birthday);
      } else if (birthday.contains('.')) {
        final parts = birthday.split('.');
        if (parts.length >= 3) {
          birthDate = DateTime(
            int.parse(parts[0]),
            int.parse(parts[1]),
            int.parse(parts[2]),
          );
        }
      }

      if (birthDate == null) return '미등록';

      // 현재 날짜와 비교하여 나이 계산
      final now = DateTime.now();
      int age = now.year - birthDate.year;

      // 생일이 지나지 않았으면 1살 차감
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      return '$age살';
    } catch (e) {
      return '미등록';
    }
  }

  /// 성별 표시 문자열 반환
  String _getGenderDisplay() {
    final profile = _latestProfile ?? widget.profile;
    if (profile.gender == null) {
      return '미등록';
    }

    switch (profile.gender!.toUpperCase()) {
      case 'MALE':
      case 'MAN':
        return '♂ 수컷';
      case 'FEMALE':
      case 'WOMAN':
        return '♀ 암컷';
      default:
        return '미등록';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 224),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 255, 224),
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
              '나의 반려동물',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 4),
            Container(
              height: 3,
              width: 120,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 설정 아이콘
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/settings.svg',
              width: 28,
              height: 28,
              colorFilter: ColorFilter.mode(Colors.grey, BlendMode.srcIn),
            ),
            onPressed: () {
              setState(() {
                _showSettingsMenu = !_showSettingsMenu;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 메인 컨텐츠
          SingleChildScrollView(
            child: Column(
              children: [
                // 상단 프로필 영역
                _buildProfileHeader(),
                // 하단 흰색 영역
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 반려동물 정보 섹션
                        _buildSectionHeader('반려동물 정보'),
                        SizedBox(height: 20),
                        _buildInfoSection(),
                        SizedBox(height: 40),

                        // 달력 섹션
                        _buildSectionHeader('달력'),
                        SizedBox(height: 20),
                        _buildCalendarSection(),
                        SizedBox(height: 30),

                        // 하루 일기 / 종합 상태 탭
                        _buildDiaryTabs(),
                        SizedBox(height: 20),

                        // 일기 내용 영역
                        _buildDiaryContent(),
                        SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 설정 메뉴 (화면 위에 오버레이)
          if (_showSettingsMenu)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildSettingsMenuItem('프로필 수정', () async {
                      setState(() {
                        _showSettingsMenu = false;
                      });

                      // 프로필 수정 화면으로 이동
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPetProfileScreen(
                            profile: _latestProfile ?? widget.profile,
                          ),
                        ),
                      );

                      // 수정 완료 시 프로필 다시 로드
                      if (result == true) {
                        _loadPetDetails();
                      }
                    }),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildSettingsMenuItem('삭제', () async {
                      setState(() {
                        _showSettingsMenu = false;
                      });
                      await _showDeleteConfirmDialog();
                    }),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildSettingsMenuItem('취소', () async {
                      setState(() {
                        _showSettingsMenu = false;
                      });
                    }),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 상단 프로필 헤더
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: 20, bottom: 30),
      child: Column(
        children: [
          // 프로필 이미지
          SizedBox(
            width: 140,
            height: 140,
            child: PhysicalShape(
              clipper: _SvgMaskClipper(
                (_latestProfile ?? widget.profile).species,
              ),
              color: Colors.transparent,
              shadowColor: Colors.black,
              elevation: 3,
              child: ClipPath(
                clipper: _SvgMaskClipper(
                  (_latestProfile ?? widget.profile).species,
                ),
                child: Container(
                  width: 140,
                  height: 140,
                  color: Color(0xFFE5E7EB),
                  child:
                      _isValidNetworkUrl(
                        (_latestProfile ?? widget.profile).imageUrl,
                      )
                      ? Image.network(
                          _getFullImageUrl(
                            (_latestProfile ?? widget.profile).imageUrl,
                          ),
                          fit: BoxFit.cover,
                          width: 140,
                          height: 140,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.pets,
                                size: 70,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Icon(Icons.pets, size: 70, color: Colors.grey),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 15),
          // 펫 이름
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                (_latestProfile ?? widget.profile).name,
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFF3BA688),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // 오늘의 일기 작성 버튼
          ElevatedButton.icon(
            onPressed: () async {
              // 일기 생성 화면으로 이동
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreatePetDiaryScreen(
                    profile: _latestProfile ?? widget.profile,
                  ),
                ),
              );
            },
            icon: Icon(Icons.edit_note, color: Colors.white),
            label: Text(
              '오늘의 일기 작성',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromARGB(255, 0, 108, 82),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(String title) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 2,
          width: double.infinity,
          color: const Color.fromARGB(255, 0, 108, 82),
        ),
      ],
    );
  }

  /// 반려동물 정보 섹션
  Widget _buildInfoSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 정보 카드
        Expanded(
          child: Container(
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('나이:', _calculateAge(), Colors.black87),
                SizedBox(height: 8),
                _buildInfoRow(
                  '체중:',
                  '${(_latestProfile ?? widget.profile).weight.toStringAsFixed(2)}Kg',
                  Color(0xFFFF9500),
                ),
                SizedBox(height: 8),
                _buildInfoRow(
                  '품종:',
                  (_latestProfile ?? widget.profile).speciesDetail ?? '미등록',
                  Color(0xFF0066CC),
                ),
                SizedBox(height: 8),
                _buildInfoRow('성별:', _getGenderDisplay(), Color(0xFF00CC66)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 정보 행
  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// 설정 메뉴 아이템
  Widget _buildSettingsMenuItem(String text, Future<void> Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, color: Colors.black87),
        ),
      ),
    );
  }

  /// 반려동물 상태 섹션
  Widget _buildStatusSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusCard('스트레스'),
        _buildStatusCard('비만도'),
        _buildStatusCard('피부병'),
      ],
    );
  }

  /// 상태 카드
  Widget _buildStatusCard(String title) {
    return Container(
      width: 100,
      height: 140,
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Container(height: 1, color: Colors.grey.shade300),
          SizedBox(height: 15),
          // 원형 상태 표시
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 0, 108, 82),
                width: 3,
              ),
            ),
          ),
        ],
      ),
    );
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

  /// 일기 불러오기
  Future<void> _loadDiary() async {
    final profile = _latestProfile ?? widget.profile;
    if (profile.id == null) {
      print('📋 일기 불러오기 실패: 펫 ID가 없음');
      return;
    }

    print(
      '📋 일기 불러오기 시작: petId=${profile.id}, date=${_selectedDate.toString().split(' ')[0]}',
    );

    final diary = await DiaryService().getDiary(profile.id!, _selectedDate);

    print(
      '📋 일기 조회 결과: ${diary != null ? "일기 있음 (${diary.content?.length ?? 0}자)" : "일기 없음"}',
    );

    setState(() {
      _currentDiary = diary;
      _diaryController.text = diary?.content ?? '';
    });
  }

  /// 달력 섹션
  Widget _buildCalendarSection() {
    final weekDates = _getWeekDates();
    final weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
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
                    final weekDates = _getWeekDates();
                    _selectedDate = weekDates[3];
                  });
                  _loadDiary();
                },
              ),
              Text(
                '${weekDates[0].year}.${weekDates[0].month.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B27A),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: Color(0xFF00B27A)),
                onPressed: () {
                  setState(() {
                    _calendarWeekOffset++;
                    final weekDates = _getWeekDates();
                    _selectedDate = weekDates[3];
                  });
                  _loadDiary();
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
                  _loadDiary();
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

  /// 하루 일기 / 종합 상태 탭
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

  /// 일기 내용 영역
  Widget _buildDiaryContent() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFD4F4E7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: TextField(
          controller: _diaryController,
          maxLines: null,
          readOnly: true,
          decoration: InputDecoration(
            hintText: _selectedDiaryTab == '하루 일기'
                ? '아직 작성된 일기가 없습니다.'
                : '종합 상태 정보가 없습니다.',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[500]),
          ),
          style: TextStyle(fontSize: 16, height: 1.5),
        ),
      ),
    );
  }

  /// 종합 상태 일지 섹션
  Widget _buildDiarySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 245, 245, 245),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // 날짜
          Text(
            '-2025.10.23-',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 15),
          // 일지 내용
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '오늘은 금능 횟수가 눈에\n띄게 줄었고 피부도 덜 빨개\n보여서 마음이 놓였다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.8,
                color: Colors.black87,
              ),
            ),
          ),
        ],
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
