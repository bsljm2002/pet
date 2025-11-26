// AI 진단 결과 모델
import 'package:flutter/material.dart';

class AIDiagnosis {
  final String id;
  final String imagePath;
  final DateTime diagnosisDate;
  final String petName;
  final String? petId;

  // 진단 결과
  final String diagnosis; // 진단명
  final String description; // 상세 설명
  final String severity; // 심각도: 'low', 'medium', 'high', 'none'
  final List<String> symptoms; // 증상 목록
  final List<String> recommendations; // 권장사항
  final double confidence; // 신뢰도 (0.0 ~ 1.0)
  final String? diseaseStatus; // 예: '유', '무'

  AIDiagnosis({
    required this.id,
    required this.imagePath,
    required this.diagnosisDate,
    required this.petName,
    this.petId,
    required this.diagnosis,
    required this.description,
    required this.severity,
    required this.symptoms,
    required this.recommendations,
    required this.confidence,
    this.diseaseStatus,
  });

  // JSON 직렬화
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'diagnosisDate': diagnosisDate.toIso8601String(),
      'petName': petName,
      'petId': petId,
      'diagnosis': diagnosis,
      'description': description,
      'severity': severity,
      'symptoms': symptoms,
      'recommendations': recommendations,
      'confidence': confidence,
      'diseaseStatus': diseaseStatus,
    };
  }

  // JSON 역직렬화
  factory AIDiagnosis.fromJson(Map<String, dynamic> json) {
    return AIDiagnosis(
      id: json['id'],
      imagePath: json['imagePath'],
      diagnosisDate: DateTime.parse(json['diagnosisDate']),
      petName: json['petName'],
      petId: json['petId'],
      diagnosis: json['diagnosis'],
      description: json['description'],
      severity: json['severity'],
      symptoms: List<String>.from(json['symptoms']),
      recommendations: List<String>.from(json['recommendations']),
      confidence: json['confidence'],
      diseaseStatus: json['diseaseStatus'],
    );
  }

  bool get hasSeverity => severity != 'none';
  bool get hasStatus => diseaseStatus != null;
  bool get isNormal => diseaseStatus == '정상';
  bool get hasAbnormality => diseaseStatus == '질병 의심';

  // 심각도 색상 반환
  Color getSeverityColor() {
    switch (severity) {
      case 'low':
        return const Color(0xFF4CAF50); // 녹색
      case 'medium':
        return const Color(0xFFFFA726); // 주황색
      case 'high':
        return const Color(0xFFEF5350); // 빨간색
      case 'none':
        return const Color(0xFF4CAF50); // 녹색 (정상)
      default:
        return const Color(0xFF9E9E9E); // 회색
    }
  }

  Color getStatusColor() {
    return hasAbnormality ? const Color(0xFFEF5350) : const Color(0xFF4CAF50);
  }

  String getStatusText() {
    return diseaseStatus ?? '분석 완료';
  }

  // 심각도 텍스트 반환
  String getSeverityText() {
    switch (severity) {
      case 'low':
        return '경미';
      case 'medium':
        return '주의';
      case 'high':
        return '심각';
      case 'none':
        return '정상';
      default:
        return '알 수 없음';
    }
  }
}
