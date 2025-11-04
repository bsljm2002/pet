// AI 진단 서비스
import 'dart:math';
import '../models/ai_diagnosis.dart';

class AIDiagnosisService {
  static final AIDiagnosisService _instance = AIDiagnosisService._internal();
  factory AIDiagnosisService() => _instance;
  AIDiagnosisService._internal();

  final List<AIDiagnosis> _diagnoses = [];

  // 모든 진단 결과 가져오기
  Future<List<AIDiagnosis>> getAllDiagnoses() async {
    return List.from(_diagnoses);
  }

  // 특정 반려동물의 진단 결과 가져오기
  Future<List<AIDiagnosis>> getDiagnosesByPet(String petId) async {
    final allDiagnoses = await getAllDiagnoses();
    return allDiagnoses.where((d) => d.petId == petId).toList();
  }

  // AI 진단 수행 (실제로는 서버 API 호출, 여기서는 시뮬레이션)
  Future<AIDiagnosis> performDiagnosis({
    required String imagePath,
    required String petName,
    String? petId,
  }) async {
    // TODO: 실제 AI 서버 API 호출
    // 현재는 시뮬레이션으로 랜덤 결과 생성
    await Future.delayed(const Duration(seconds: 2)); // API 호출 시뮬레이션

    final random = Random();
    final severities = ['low', 'medium', 'high'];
    final severity = severities[random.nextInt(severities.length)];

    // 샘플 진단 결과들
    final sampleDiagnoses = _getSampleDiagnoses(severity);
    final selectedDiagnosis =
        sampleDiagnoses[random.nextInt(sampleDiagnoses.length)];

    final diagnosis = AIDiagnosis(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      diagnosisDate: DateTime.now(),
      petName: petName,
      petId: petId,
      diagnosis: selectedDiagnosis['diagnosis']!,
      description: selectedDiagnosis['description']!,
      severity: severity,
      symptoms: selectedDiagnosis['symptoms']!,
      recommendations: selectedDiagnosis['recommendations']!,
      confidence: 0.75 + random.nextDouble() * 0.2, // 0.75 ~ 0.95
    );

    await saveDiagnosis(diagnosis);
    return diagnosis;
  }

  // 진단 결과 저장
  Future<void> saveDiagnosis(AIDiagnosis diagnosis) async {
    _diagnoses.insert(0, diagnosis); // 최신 항목을 앞에 추가
  }

  // 진단 결과 삭제
  Future<void> deleteDiagnosis(String id) async {
    _diagnoses.removeWhere((d) => d.id == id);
  }

  // 샘플 진단 결과 데이터
  List<Map<String, dynamic>> _getSampleDiagnoses(String severity) {
    if (severity == 'low') {
      return [
        {
          'diagnosis': '경미한 피부 자극',
          'description': '피부에 경미한 붉은 반점이 관찰됩니다. 알레르기나 경미한 자극으로 인한 것으로 보입니다.',
          'symptoms': ['붉은 반점', '가벼운 가려움증'],
          'recommendations': [
            '해당 부위를 청결하게 유지하세요',
            '긁지 못하도록 주의하세요',
            '2-3일 내에 호전되지 않으면 병원 방문을 권장합니다'
          ],
        },
        {
          'diagnosis': '정상 범위의 눈곱',
          'description': '정상적인 범위의 눈곱이 관찰됩니다. 건강 상태에 큰 문제는 없어 보입니다.',
          'symptoms': ['소량의 눈곱'],
          'recommendations': [
            '깨끗한 거즈로 부드럽게 닦아주세요',
            '눈곱 양이 갑자기 증가하면 병원을 방문하세요',
            '정기적인 눈 건강 체크를 권장합니다'
          ],
        },
      ];
    } else if (severity == 'medium') {
      return [
        {
          'diagnosis': '외이염 의심',
          'description': '귀 내부에 염증 징후가 보입니다. 외이염일 가능성이 있으며 조기 치료가 필요합니다.',
          'symptoms': ['귀 내부 붉음', '분비물', '귀 냄새'],
          'recommendations': [
            '빠른 시일 내에 동물병원을 방문하세요',
            '귀를 긁지 못하도록 주의하세요',
            '귀 청소는 전문가의 지도 하에 진행하세요'
          ],
        },
        {
          'diagnosis': '치석 축적',
          'description': '치아에 치석이 상당량 축적되어 있습니다. 구강 건강 관리가 필요합니다.',
          'symptoms': ['치석', '잇몸 붉음', '구취'],
          'recommendations': [
            '치과 스케일링을 고려하세요',
            '정기적인 양치질을 시작하세요',
            '치아 건강 간식을 제공하세요'
          ],
        },
      ];
    } else {
      // high
      return [
        {
          'diagnosis': '심각한 피부 질환 가능성',
          'description':
              '피부에 심각한 병변이 관찰됩니다. 세균 감염, 곰팡이 감염, 또는 기타 피부 질환의 가능성이 있습니다.',
          'symptoms': ['심한 붉은 반점', '탈모', '진물', '딱지'],
          'recommendations': [
            '즉시 동물병원을 방문하세요',
            '해당 부위를 긁거나 만지지 않도록 하세요',
            '다른 반려동물과의 접촉을 제한하세요'
          ],
        },
        {
          'diagnosis': '눈 감염 또는 외상',
          'description': '눈에 심각한 충혈과 염증이 관찰됩니다. 감염이나 외상의 가능성이 높습니다.',
          'symptoms': ['심한 충혈', '과도한 눈물', '눈 부음', '눈곱'],
          'recommendations': [
            '긴급히 동물병원을 방문하세요',
            '눈을 비비지 못하도록 하세요',
            '깨끗한 식염수로 부드럽게 씻어주세요'
          ],
        },
      ];
    }
  }
}
