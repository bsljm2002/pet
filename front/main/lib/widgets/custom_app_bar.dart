// 커스텀 앱 바 위젯
// 앱 상단에 표시되는 타이틀 바를 정의
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../pages/my_favorites_page.dart';

// 커스텀 앱 바 위젯
// PreferredSizeWidget을 구현하여 Scaffold의 appBar 속성에 사용 가능
// 앱 전체에서 일관된 상단 바 디자인을 제공
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBackButton; // 뒤로가기 버튼 표시 여부
  final bool showFavoriteButton; // 즐겨찾기 버튼 표시 여부

  const CustomAppBar({
    Key? key,
    this.showBackButton = true,
    this.showFavoriteButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 현재 페이지가 네비게이션 스택에서 첫 번째인지 확인
    final canPop = Navigator.of(context).canPop();

    return AppBar(
      // 뒤로가기 버튼 제어
      automaticallyImplyLeading: showBackButton && canPop,
      // 앱 타이틀 로고 표시
      title: SvgPicture.asset(
        'assets/icons/rogo_img_2.svg',
        height: 40,
        colorFilter: const ColorFilter.mode(
          Color(0xFF3BA688),
          BlendMode.srcIn,
        ), // 로고 높이
      ),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255), // 연한 녹색 배경
    );
  }

  // AppBar의 높이를 지정
  // PreferredSizeWidget 인터페이스 구현을 위한 필수 getter
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
