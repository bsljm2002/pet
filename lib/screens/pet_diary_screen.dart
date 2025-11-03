// 펫 일기 화면 위젯
// 반려동물의 일상과 추억을 기록하는 다이어리 기능
import 'package:flutter/material.dart';

// 펫 일기 화면
// 반려동물의 일상, 건강 상태, 특별한 순간 등을 기록하고 관리
// 현재는 플레이스홀더 화면으로 구성되어 있으며, 향후 일기 작성 및 목록 기능 구현 예정
class PetDiaryScreen extends StatelessWidget {
  const PetDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 펫 일기 아이콘
          Icon(Icons.pets, size: 80, color: Color.fromARGB(255, 0, 56, 41)),
          SizedBox(height: 20),
          // 화면 제목
          Text(
            '펫 일기',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 10),
          // 설명 텍스트
          Text(
            '반려동물의 추억을 기록해보세요',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
