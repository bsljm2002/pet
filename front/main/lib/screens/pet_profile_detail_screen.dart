// 펫 프로필 상세보기 화면
// 반려동물의 상세 정보를 확인하고 관리하는 페이지
import 'package:flutter/material.dart';
import 'abti_test_screen.dart';
import '../services/pet_profile_manager.dart';
import '../models/pet_profile.dart';

/// 펫 프로필 상세보기 화면
///
/// 반려동물의 상세 정보를 표시:
/// - 프로필 이미지 및 이름
/// - ABTI 결과
/// - 반려동물 정보 (나이, 체중, 품종, 성별)
/// - 반려동물 상태 (스트레스, 비만도, 피부병)
/// - 종합 상태 일지
class PetProfileDetailScreen extends StatefulWidget {
  final PetProfile profile;

  const PetProfileDetailScreen({
    Key? key,
    required this.profile,
  }) : super(key: key);

  @override
  State<PetProfileDetailScreen> createState() => _PetProfileDetailScreenState();
}

class _PetProfileDetailScreenState extends State<PetProfileDetailScreen> {
  // 설정 메뉴 표시 여부
  bool _showSettingsMenu = false;

  // ABTI 결과 (테스트 완료 시 업데이트)
  String? _currentAbtiType;

  @override
  void initState() {
    super.initState();
    // 초기 ABTI 타입 설정
    _currentAbtiType = widget.profile.abtiType;
  }

  /// 생년월일로부터 나이 계산
  String _calculateAge() {
    if (widget.profile.birthday == null || widget.profile.birthday!.isEmpty) {
      return '미등록';
    }

    try {
      // 생년월일 파싱 (여러 형식 지원)
      DateTime? birthDate;
      final birthday = widget.profile.birthday!;

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
    if (widget.profile.gender == null) {
      return '미등록';
    }

    switch (widget.profile.gender) {
      case 'Man':
        return '♂ 수컷';
      case 'Woman':
        return '♀ 암컷';
      default:
        return '미등록';
    }
  }

  @override
  Widget build(BuildContext context) {
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
              '펫 프로필',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 4),
            Container(
              height: 3,
              width: 80,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          // 설정 아이콘
          IconButton(
            icon: Icon(Icons.settings, color: Colors.grey, size: 28),
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
                        SizedBox(height: 30),
                        // 반려동물 상태 섹션
                        _buildSectionHeader('반려동물 상태'),
                        SizedBox(height: 20),
                        _buildStatusSection(),
                        SizedBox(height: 30),
                        // 종합 상태 섹션
                        _buildSectionHeader('종합 상태'),
                        SizedBox(height: 20),
                        _buildDiarySection(),
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
                    _buildSettingsMenuItem('프로필 수정', () {
                      // TODO: 프로필 수정 기능
                      print('프로필 수정');
                    }),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildSettingsMenuItem('삭제', () {
                      // TODO: 삭제 기능
                      print('삭제');
                    }),
                    Divider(height: 1, color: Colors.grey.shade300),
                    _buildSettingsMenuItem('취소', () {
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
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 60,
              backgroundColor: Color(0xFFE5E7EB),
              backgroundImage: widget.profile.imageUrl != null
                ? NetworkImage(widget.profile.imageUrl!)
                : null,
              child: widget.profile.imageUrl == null
                ? Icon(Icons.pets, size: 60, color: Colors.grey)
                : null,
            ),
          ),
          SizedBox(height: 15),
          // 펫 이름
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.profile.name,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
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
        // ABTI 원형 (클릭 가능)
        GestureDetector(
          onTap: () async {
            // ABTI 테스트 페이지로 이동
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AbtiTestScreen(
                  petName: widget.profile.name,
                  currentAbtiType: _currentAbtiType,
                ),
              ),
            );

            // 결과가 있으면 상태 업데이트
            if (result != null) {
              setState(() {
                _currentAbtiType = result;
              });

              // 프로필 매니저에도 업데이트
              PetProfileManager().updateProfile(
                widget.profile.id,
                widget.profile.copyWith(abtiType: result),
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('ABTI 테스트 결과: $result'),
                    backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                  ),
                );
              }
            }
          },
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color.fromARGB(255, 0, 108, 82),
                width: 3,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ABTI',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 0, 108, 82),
                    ),
                  ),
                  if (_currentAbtiType != null)
                    Text(
                      _currentAbtiType!,
                      style: TextStyle(
                        fontSize: 14,
                        color: const Color.fromARGB(255, 0, 108, 82),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 30),
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
                _buildInfoRow('체중:', '5.12Kg', Color(0xFFFF9500)),
                SizedBox(height: 8),
                _buildInfoRow('품종:', widget.profile.breed ?? '미등록', Color(0xFF0066CC)),
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
  Widget _buildSettingsMenuItem(String text, VoidCallback onTap) {
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
