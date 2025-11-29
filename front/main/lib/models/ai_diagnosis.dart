// AI 진단 결과 모델
import 'package:flutter/material.dart';

// 반려동물 종류
enum PetType {
  dog,
  cat,
}

// 진단 부위
enum BodyPart {
  skin,
  eye,
}

// 진단 모델 타입
enum DiagnosisModelType {
  dogSkin,
  dogEye,
  catSkin,
  catEye,
}

// 모델 타입 확장
extension DiagnosisModelTypeExtension on DiagnosisModelType {
  String get modelFileName {
    switch (this) {
      case DiagnosisModelType.dogSkin:
        return 'dog_skin_best.ptl';
      case DiagnosisModelType.dogEye:
        return 'dog_eyes_best.ptl';
      case DiagnosisModelType.catSkin:
        return 'cat_skin_best.ptl';
      case DiagnosisModelType.catEye:
        return 'cat_eyes_best.ptl';
    }
  }

  String get metadataFileName {
    switch (this) {
      case DiagnosisModelType.dogSkin:
        return 'dog_skin_best_metadata.json';
      case DiagnosisModelType.dogEye:
        return 'dog_eyes_best_metadata.json';
      case DiagnosisModelType.catSkin:
        return 'cat_skin_best_metadata.json';
      case DiagnosisModelType.catEye:
        return 'cat_eyes_best_metadata.json';
    }
  }

  String get displayName {
    switch (this) {
      case DiagnosisModelType.dogSkin:
        return '강아지 피부';
      case DiagnosisModelType.dogEye:
        return '강아지 눈';
      case DiagnosisModelType.catSkin:
        return '고양이 피부';
      case DiagnosisModelType.catEye:
        return '고양이 눈';
    }
  }

  static DiagnosisModelType fromSelection(PetType pet, BodyPart part) {
    if (pet == PetType.dog) {
      return part == BodyPart.skin
          ? DiagnosisModelType.dogSkin
          : DiagnosisModelType.dogEye;
    } else {
      return part == BodyPart.skin
          ? DiagnosisModelType.catSkin
          : DiagnosisModelType.catEye;
    }
  }
}

// 질병 한국어 번역 및 정보
class DiseaseInfo {
  final String koreanName;
  final String description;
  final List<String> symptoms;
  final List<String> recommendations;

  const DiseaseInfo({
    required this.koreanName,
    required this.description,
    required this.symptoms,
    required this.recommendations,
  });
}

// 질병 정보 데이터베이스
class DiseaseDatabase {
  static const Map<String, DiseaseInfo> diseases = {
    // 강아지 피부 질환
    'Bacterial_Dermatosis': DiseaseInfo(
      koreanName: '세균성 피부염',
      description: '세균 감염으로 인한 피부 염증입니다.',
      symptoms: ['피부 발적', '가려움증', '농포', '딱지 형성'],
      recommendations: ['수의사 상담 권장', '청결 유지', '항생제 치료 필요'],
    ),
    'Fungal_Infections': DiseaseInfo(
      koreanName: '진균 감염',
      description: '곰팡이균에 의한 피부 감염입니다.',
      symptoms: ['원형 탈모', '비듬', '피부 각질화', '가려움'],
      recommendations: ['수의사 진료 필수', '항진균제 사용', '환경 소독'],
    ),
    'Allergic_Dermatitis': DiseaseInfo(
      koreanName: '알레르기성 피부염',
      description: '알레르기 반응으로 인한 피부 염증입니다.',
      symptoms: ['심한 가려움', '발적', '긁은 상처', '피부 발진'],
      recommendations: ['알레르기 원인 파악', '수의사 상담', '저자극 사료 고려'],
    ),
    'Seborrhea': DiseaseInfo(
      koreanName: '지루증',
      description: '피지선 이상으로 인한 피부 질환입니다.',
      symptoms: ['과도한 비듬', '기름진 피부', '악취', '각질'],
      recommendations: ['약용 샴푸 사용', '정기적 목욕', '수의사 상담'],
    ),
    'Alopecia': DiseaseInfo(
      koreanName: '탈모증',
      description: '비정상적인 털 빠짐 현상입니다.',
      symptoms: ['부분 또는 전신 탈모', '피부 노출', '가려움 동반 가능'],
      recommendations: ['원인 진단 필요', '호르몬 검사 권장', '수의사 진료'],
    ),
    // 강아지 눈 질환
    'Blepharitis': DiseaseInfo(
      koreanName: '안검염',
      description: '눈꺼풀의 염증입니다.',
      symptoms: ['눈꺼풀 부종', '눈곱', '눈물', '가려움'],
      recommendations: ['안약 처방 필요', '청결 유지', '수의사 진료'],
    ),
    'Conjunctivitis': DiseaseInfo(
      koreanName: '결막염',
      description: '결막의 염증으로 흔한 눈 질환입니다.',
      symptoms: ['충혈', '눈곱', '눈물', '눈 비비기'],
      recommendations: ['안약 사용', '청결 유지', '원인 파악'],
    ),
    'Corneal_Ulcer': DiseaseInfo(
      koreanName: '각막 궤양',
      description: '각막에 상처가 생긴 상태입니다.',
      symptoms: ['눈 통증', '눈물', '눈 감기', '각막 혼탁'],
      recommendations: ['즉시 수의사 진료', '안약 처방', '보호 칼라 착용'],
    ),
    'Entropion': DiseaseInfo(
      koreanName: '안검내반증',
      description: '눈꺼풀이 안쪽으로 말려 들어가는 상태입니다.',
      symptoms: ['눈물', '눈 비비기', '각막 자극', '눈곱'],
      recommendations: ['수술적 교정 필요', '수의사 상담'],
    ),
    'Nuclear_Sclerosis': DiseaseInfo(
      koreanName: '수정체 핵경화증',
      description: '노화로 인한 수정체 변화입니다.',
      symptoms: ['눈 혼탁', '시력 저하 가능', '푸르스름한 눈'],
      recommendations: ['정기 검진', '백내장과 구분 필요', '노화 현상'],
    ),
    'Pigmentary_Keratitis': DiseaseInfo(
      koreanName: '색소성 각막염',
      description: '각막에 색소가 침착되는 질환입니다.',
      symptoms: ['각막 혼탁', '갈색 색소 침착', '시력 저하'],
      recommendations: ['원인 치료', '수의사 진료', '점안액 사용'],
    ),
    // 고양이 눈 질환
    'Feline_Corneal_Sequestrum': DiseaseInfo(
      koreanName: '고양이 각막 괴사',
      description: '고양이 특유의 각막 질환입니다.',
      symptoms: ['각막 흑색 반점', '눈물', '눈 통증', '눈 감기'],
      recommendations: ['수의사 진료 필수', '수술 필요 가능', '안약 치료'],
    ),
    'Non_Ulcerative_Keratitis': DiseaseInfo(
      koreanName: '비궤양성 각막염',
      description: '궤양 없이 발생하는 각막 염증입니다.',
      symptoms: ['각막 혼탁', '눈물', '충혈'],
      recommendations: ['안약 처방', '원인 파악', '수의사 상담'],
    ),
    // 고양이 피부 질환
    'Feline_Acne': DiseaseInfo(
      koreanName: '고양이 여드름',
      description: '턱 부위에 흔히 발생하는 피부 질환입니다.',
      symptoms: ['턱 부위 검은 점', '붓기', '농포', '가려움'],
      recommendations: ['청결 유지', '플라스틱 그릇 교체', '소독'],
    ),
    'Feline_Ringworm': DiseaseInfo(
      koreanName: '고양이 링웜 (백선)',
      description: '곰팡이에 의한 피부 감염입니다.',
      symptoms: ['원형 탈모', '비듬', '각질', '가려움'],
      recommendations: ['수의사 진료 필수', '격리 필요', '환경 소독'],
    ),
    // 정상 상태
    'Health': DiseaseInfo(
      koreanName: '건강함',
      description: '특별한 이상이 발견되지 않았습니다.',
      symptoms: ['정상 상태'],
      recommendations: ['정기 검진 권장', '현재 상태 유지'],
    ),
    'Healthy': DiseaseInfo(
      koreanName: '건강함',
      description: '특별한 이상이 발견되지 않았습니다.',
      symptoms: ['정상 상태'],
      recommendations: ['정기 검진 권장', '현재 상태 유지'],
    ),
  };

  static DiseaseInfo? getInfo(String diseaseName) {
    return diseases[diseaseName];
  }
}

class AIDiagnosis {
  final String id;
  final String imagePath;
  final DateTime diagnosisDate;
  final String petName;
  final String? petId;

  // 진단 결과
  final String diagnosis; // 진단명
  final String description; // 상세 설명
  final String severity; // 심각도: 'low', 'medium', 'high'
  final List<String> symptoms; // 증상 목록
  final List<String> recommendations; // 권장사항
  final double confidence; // 신뢰도 (0.0 ~ 1.0)

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
    );
  }

  // 심각도 색상 반환
  Color getSeverityColor() {
    switch (severity) {
      case 'low':
        return const Color(0xFF4CAF50); // 녹색
      case 'medium':
        return const Color(0xFFFFA726); // 주황색
      case 'high':
        return const Color(0xFFEF5350); // 빨간색
      default:
        return const Color(0xFF9E9E9E); // 회색
    }
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
      default:
        return '알 수 없음';
    }
  }
}
