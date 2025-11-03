// 동물병원 예약 화면 위젯
// 반려동물 병원 예약 및 관리 기능
import 'package:flutter/material.dart';

// 동물병원 예약 화면
// 근처 동물병원 검색, 예약 생성, 예약 내역 관리 기능 제공
// 현재는 플레이스홀더 화면으로 구성되어 있으며, 향후 예약 시스템 구현 예정
class HospitalScreen extends StatelessWidget {
  const HospitalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 동물병원 아이콘
          Icon(
            Icons.medical_services,
            size: 80,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
          SizedBox(height: 20),
          // 화면 제목
          Text(
            '동물병원 예약',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 10),
          // 설명 텍스트
          Text(
            '동물병원 예약을 관리해보세요',
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
