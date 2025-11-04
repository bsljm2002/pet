// 설정 화면 위젯
// 앱 설정 및 사용자 환경 관리 기능
import 'package:flutter/material.dart';

// 설정 화면
// 앱 환경설정, 알림 설정, 계정 관리, 테마 설정 등 제공
// 현재는 플레이스홀더 화면으로 구성되어 있으며, 향후 다양한 설정 옵션 구현 예정
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 설정 아이콘
          Icon(
            Icons.settings,
            size: 80,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
          SizedBox(height: 20),
          // 화면 제목
          Text(
            '설정',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 10),
          // 설명 텍스트
          Text(
            '앱 설정을 관리하세요',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
