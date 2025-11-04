// AI 진단 화면 위젯
// AI 기반 반려동물 건강 진단 기능
import 'package:flutter/material.dart';

// AI 진단 화면
// 반려동물의 증상, 행동, 사진 등을 분석하여 AI 기반 건강 상태 진단 제공
// 질병 예측, 건강 조언, 병원 방문 권장 등의 기능 포함
// 현재는 플레이스홀더 화면으로 구성되어 있으며, 향후 AI 모델 통합 예정
class AiDiagnosisScreen extends StatelessWidget {
  const AiDiagnosisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // AI 진단 아이콘
          Icon(
            Icons.psychology,
            size: 80,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
          SizedBox(height: 20),
          // 화면 제목
          Text(
            'AI 진단',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 10),
          // 설명 텍스트
          Text(
            '반려동물의 건강 상태를 AI로 진단해보세요',
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
