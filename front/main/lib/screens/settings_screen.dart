// 설정 화면 위젯
// 앱 설정 및 사용자 환경 관리 기능
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../main.dart';
import 'login_screen.dart';

// 설정 화면
// 사용자 프로필, 바로가기 메뉴, 로그아웃 기능 제공
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final User? currentUser = _authService.currentUser;

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 0),

          // 사용자 프로필 섹션
          _buildUserProfileSection(currentUser),

          SizedBox(height: 30),

          // 섹션 구분선
          _buildSectionDivider('바로가기'),

          // 바로가기 메뉴
          _buildShortcutSection(context),

          SizedBox(height: 30),

          // 로그아웃 버튼
          _buildLogoutButton(context),

          SizedBox(height: 40),
        ],
      ),
    );
  }

  /// 사용자 프로필 섹션
  Widget _buildUserProfileSection(User? user) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 프로필 아이콘
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color.fromARGB(255, 212, 244, 228),
              border: Border.all(
                color: Color.fromARGB(255, 0, 108, 82),
                width: 2.5,
              ),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Color.fromARGB(255, 0, 108, 82),
            ),
          ),
          SizedBox(width: 20),

          // 사용자 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.nickname ?? user?.username ?? '게스트',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 56, 41),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  user?.email ?? '로그인이 필요합니다',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                if (user != null) ...[
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 212, 244, 228),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getUserTypeLabel(user.userType),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 0, 108, 82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 섹션 구분선
  Widget _buildSectionDivider(String title) {
    return Container(
      width: double.infinity,
      height: 50,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Color.fromARGB(255, 0, 108, 82),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Container(
            height: 2,
            width: double.infinity,
            color: Color.fromARGB(255, 230, 233, 229),
          ),
        ],
      ),
    );
  }

  /// 바로가기 메뉴 섹션
  Widget _buildShortcutSection(BuildContext context) {
    return Container(
      width: double.infinity,
      child: Column(
        children: [
          // 홈 섹션
          _buildExpandableShortcutCard(
            context,
            icon: Icons.home,
            title: '홈',
            items: [
              {
                'icon': Icons.sensors,
                'title': '케이지 센서',
                'subtitle': '온도, 습도, 공기질 확인',
                'tabIndex': 0,
              },
              {
                'icon': Icons.pets,
                'title': '펫 프로필',
                'subtitle': '반려동물 프로필 관리',
                'tabIndex': 0,
              },
            ],
            mainTabIndex: 0,
          ),
          SizedBox(height: 12),

          // 펫 일기 섹션
          _buildExpandableShortcutCard(
            context,
            icon: Icons.book,
            title: '펫 일기',
            items: [
              {
                'icon': Icons.create,
                'title': '일기 작성',
                'subtitle': '오늘의 기록 남기기',
                'tabIndex': 1,
              },
              {
                'icon': Icons.history,
                'title': '일기 목록',
                'subtitle': '지난 일기 보기',
                'tabIndex': 1,
              },
            ],
            mainTabIndex: 1,
          ),
          SizedBox(height: 12),

          // AI 진단 섹션
          _buildExpandableShortcutCard(
            context,
            icon: Icons.medical_services,
            title: 'AI 진단',
            items: [
              {
                'icon': Icons.camera_alt,
                'title': '증상 촬영',
                'subtitle': '사진으로 건강 체크',
                'tabIndex': 2,
              },
              {
                'icon': Icons.history_edu,
                'title': '진단 기록',
                'subtitle': '이전 진단 결과 확인',
                'tabIndex': 2,
              },
            ],
            mainTabIndex: 2,
          ),
          SizedBox(height: 12),

          // 동물병원 섹션
          _buildExpandableShortcutCard(
            context,
            icon: Icons.local_hospital,
            title: '동물병원',
            items: [
              {
                'icon': Icons.search,
                'title': '병원 찾기',
                'subtitle': '근처 동물병원 검색',
                'tabIndex': 3,
              },
              {
                'icon': Icons.calendar_today,
                'title': '예약 관리',
                'subtitle': '병원 예약 확인',
                'tabIndex': 3,
              },
              {
                'icon': Icons.chat,
                'title': '상담 신청',
                'subtitle': '온라인 상담 요청',
                'tabIndex': 3,
              },
            ],
            mainTabIndex: 3,
          ),
        ],
      ),
    );
  }

  /// 확장 가능한 바로가기 카드
  Widget _buildExpandableShortcutCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Map<String, dynamic>> items,
    required int mainTabIndex,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 메인 헤더
          GestureDetector(
            onTap: () => _navigateToTab(context, mainTabIndex),
            child: Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  // 아이콘
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color.fromARGB(255, 212, 244, 228),
                    ),
                    child: Icon(
                      icon,
                      color: Color.fromARGB(255, 0, 108, 82),
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),

                  // 타이틀
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 56, 41),
                      ),
                    ),
                  ),

                  // 화살표 아이콘
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey[400],
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // 구분선
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            height: 1,
            color: Color.fromARGB(255, 230, 233, 229),
          ),

          // 하위 항목들
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: items.map((item) {
                return _buildSubMenuItem(
                  context,
                  icon: item['icon'] as IconData,
                  title: item['title'] as String,
                  subtitle: item['subtitle'] as String,
                  tabIndex: item['tabIndex'] as int,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 하위 메뉴 아이템
  Widget _buildSubMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int tabIndex,
  }) {
    return GestureDetector(
      onTap: () => _navigateToTab(context, tabIndex),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        margin: EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: Color.fromARGB(255, 248, 250, 252),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // 작은 아이콘
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                icon,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 20,
              ),
            ),
            SizedBox(width: 12),

            // 텍스트
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color.fromARGB(255, 0, 56, 41),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            // 작은 화살표
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
          ],
        ),
      ),
    );
  }

  /// 로그아웃 버튼
  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: () => _handleLogout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 0, 108, 82),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white, size: 24),
            SizedBox(width: 12),
            Text(
              '로그아웃',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 사용자 타입 라벨 변환
  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.general:
        return '일반 회원';
      case UserType.seller:
        return '판매자';
      case UserType.hospital:
        return '병원';
      case UserType.grooming:
        return '미용실';
      case UserType.sitter:
        return '펫시터';
      case UserType.cafe:
        return '카페';
    }
  }

  /// 탭 이동 처리
  void _navigateToTab(BuildContext context, int tabIndex) {
    // MainScreen을 새로 생성하여 해당 탭으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(initialIndex: tabIndex),
      ),
    );
  }

  /// 로그아웃 처리
  void _handleLogout(BuildContext context) async {
    // 확인 다이얼로그 표시
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            '로그아웃',
            style: TextStyle(
              color: Color.fromARGB(255, 0, 56, 41),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소', style: TextStyle(color: Colors.grey[600])),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                '로그아웃',
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 108, 82),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // 로그아웃 실행
    if (confirm == true) {
      await _authService.logout();

      if (!context.mounted) return;

      // 로그인 화면으로 이동
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    }
  }
}
