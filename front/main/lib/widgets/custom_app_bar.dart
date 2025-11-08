// 커스텀 앱 바 위젯
// 앱 상단에 표시되는 타이틀 바를 정의
import 'package:flutter/material.dart';

// 커스텀 앱 바 위젯
// PreferredSizeWidget을 구현하여 Scaffold의 appBar 속성에 사용 가능
// 앱 전체에서 일관된 상단 바 디자인을 제공
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton; // 뒤로가기 버튼 표시 여부

  const CustomAppBar({Key? key, this.showBackButton = true}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 현재 페이지가 네비게이션 스택에서 첫 번째인지 확인
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      // 뒤로가기 버튼 제어
      automaticallyImplyLeading: showBackButton && canPop,
      // 앱 타이틀 표시
      title: Text(
        '숨숨루나', // 앱 이름
        style: TextStyle(
          color: Color.fromARGB(255, 0, 56, 41), // 짙은 녹색 텍스트
          fontSize: 20,
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 212, 244, 228), // 연한 녹색 배경
    );
  }

  // AppBar의 높이를 지정
  // PreferredSizeWidget 인터페이스 구현을 위한 필수 getter
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
