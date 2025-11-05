// 커스텀 하단 네비게이션 바 위젯
// 앱의 주요 5개 화면 간 이동을 담당하는 네비게이션 바
import 'package:flutter/material.dart';

// 하단 네비게이션 바 위젯
// 홈, 펫 일기, AI진단, 동물병원, 설정 화면으로 이동할 수 있는 5개의 탭 제공
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
      type: BottomNavigationBarType.fixed, // 5개 이상의 항목도 모두 표시
      currentIndex: currentIndex, // 현재 선택된 탭 표시
      onTap: onTap, // 탭 클릭 시 부모 위젯에 전달
      selectedItemColor: Color.fromARGB(255, 255, 255, 255), // 선택된 탭 아이콘/텍스트 색상 (흰색)
      unselectedItemColor: Colors.grey, // 선택되지 않은 탭 색상 (회색)
      backgroundColor: const Color.fromARGB(255, 0, 33, 23), // 네비게이션 바 배경색 (짙은 녹색)
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'), // 0번 인덱스: 홈 화면
        BottomNavigationBarItem(icon: Icon(Icons.pets), label: '펫 일기'), // 1번 인덱스: 펫 일기
        BottomNavigationBarItem(icon: Icon(Icons.psychology), label: 'AI진단'), // 2번 인덱스: AI 진단
        BottomNavigationBarItem(
          icon: Icon(Icons.medical_services),
          label: '동물병원', // 3번 인덱스: 동물병원 예약
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'), // 4번 인덱스: 설정
      ],
    );
  }
}
