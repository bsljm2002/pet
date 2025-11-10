// 커스텀 하단 네비게이션 바 위젯
// 앱의 주요 5개 화면 간 이동을 담당하는 네비게이션 바
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

// 하단 네비게이션 바 위젯
// 홈, AI케어, 펫 일기, 동물병원, 설정 화면으로 이동할 수 있는 5개의 탭 제공
class CustomBottomNav extends StatelessWidget {
  final int currentIndex; // 현재 선택된 탭의 인덱스
  final Function(int) onTap; // 탭 클릭 시 호출되는 콜백 함수

  const CustomBottomNav({
    Key? key,
    required this.currentIndex, // 필수: 현재 선택된 탭 인덱스
    required this.onTap, // 필수: 탭 클릭 이벤트 핸들러
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed, // 모든 항목 표시
      currentIndex: currentIndex, // 현재 선택된 탭 표시
      onTap: onTap, // 탭 클릭 시 부모 위젯에 전달
      selectedItemColor: Color.fromARGB(
        255,
        255,
        255,
        255,
      ), // 선택된 탭 아이콘/텍스트 색상 (흰색)
      unselectedItemColor: Colors.grey, // 선택되지 않은 탭 색상 (회색)
      backgroundColor: const Color.fromARGB(
        255,
        0,
        33,
        23,
      ), // 네비게이션 바 배경색 (짙은 녹색)
      selectedFontSize: 12, // 선택된 탭 폰트 크기
      unselectedFontSize: 12, // 선택되지 않은 탭 폰트 크기
      items: [
        // 0번: 홈 (SVG 아이콘 사용)
        BottomNavigationBarItem(
          icon: SvgPicture.asset(
            'assets/icons/pethome.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              currentIndex == 0 ? Colors.white : Colors.grey,
              BlendMode.srcIn,
            ),
          ),
          label: '펫홈',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology),
          label: 'AI케어',
        ), // 1번: AI케어 (케이지/AI진단)
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: '의사/시터', // 2번: 동물병원
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag),
          label: '펫샵',
        ), // 3번: 펫샵
        BottomNavigationBarItem(
          icon: Icon(Icons.settings),
          label: '설정',
        ), // 4번: 설정
      ],
    );
  }
}
