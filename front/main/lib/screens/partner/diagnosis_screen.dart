import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/partner_reservation_model.dart';
import '../../models/pet_profile.dart';
import '../../services/partner_reservation_service.dart';
import '../../services/pet_service.dart';

/// 진료 화면 - 반려동물 정보, 증상 확인, 의사 소견, 처방약 입력
class DiagnosisScreen extends StatefulWidget {
  final PartnerReservationModel reservation;
  final int partnerId;
  final List<String> symptoms; // 확정 시 체크한 증상 목록
  final String? initialNotes; // 확정 시 입력한 추가 사항

  const DiagnosisScreen({
    super.key,
    required this.reservation,
    required this.partnerId,
    this.symptoms = const [],
    this.initialNotes,
  });

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final PartnerReservationService _reservationService =
      PartnerReservationService();
  final PetService _petService = PetService();

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  final TextEditingController _dosageDaysController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingPet = true;
  bool _isEditingMedical = false;
  bool _hasDisease = false;
  PetProfile? _petProfile;
  String? _petLoadError;
  String _currentStatus = ''; // 현재 예약 상태를 추적

  // 처방약 복용 스케줄
  bool _morningDose = false;
  bool _lunchDose = false;
  bool _dinnerDose = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.reservation.status; // 초기 상태 설정
    _loadPetProfile();
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    _weightController.dispose();
    _diseaseController.dispose();
    _dosageDaysController.dispose();
    super.dispose();
  }

  Future<void> _loadPetProfile() async {
    print('🐾 [DEBUG] _loadPetProfile 시작');
    print('🐾 [DEBUG] petId: ${widget.reservation.petId}');

    if (widget.reservation.petId == null) {
      print('❌ [DEBUG] petId가 null입니다');
      setState(() {
        _isLoadingPet = false;
        _petLoadError = '반려동물 정보가 없습니다.';
      });
      return;
    }

    try {
      print('🐾 [DEBUG] getPetById 호출: ${widget.reservation.petId}');
      final response = await _petService.getPetById(widget.reservation.petId!);
      print('🐾 [DEBUG] 응답: $response');

      if (response['success'] == true && response['pet'] != null) {
        print('✅ [DEBUG] 펫 정보 조회 성공');
        final petData = response['pet'] as Map<String, dynamic>;
        print('🐾 [DEBUG] petData: $petData');

        final pet = PetProfile.fromJson(petData);
        print('🐾 [DEBUG] PetProfile 생성 완료: ${pet.name}');

        setState(() {
          _petProfile = pet;
          _weightController.text = pet.weight.toString();
          _diseaseController.text = pet.disease ?? '';
          _hasDisease = (pet.disease != null && pet.disease!.isNotEmpty);
          _isLoadingPet = false;
        });
      } else {
        print('❌ [DEBUG] 펫 정보 조회 실패: ${response['message']}');
        setState(() {
          _isLoadingPet = false;
          _petLoadError = '반려동물 정보를 불러올 수 없습니다.\n${response['message'] ?? ''}';
        });
      }
    } catch (e, stackTrace) {
      print('❌ [DEBUG] 예외 발생: $e');
      print('❌ [DEBUG] 스택 트레이스: $stackTrace');
      setState(() {
        _isLoadingPet = false;
        _petLoadError = '오류 발생: $e';
      });
    }
  }

  Future<void> _saveMedicalInfo() async {
    if (_petProfile == null) return;

    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 몸무게를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final disease = _hasDisease ? _diseaseController.text.trim() : '';

      final response = await _petService.updatePetMedicalInfo(
        petId: _petProfile!.id!,
        weight: weight,
        disease: disease,
      );

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (response['success'] == true) {
        setState(() {
          _petProfile = PetProfile(
            id: _petProfile!.id,
            userId: _petProfile!.userId,
            name: _petProfile!.name,
            species: _petProfile!.species,
            birthdate: _petProfile!.birthdate,
            weight: weight,
            gender: _petProfile!.gender,
            speciesDetail: _petProfile!.speciesDetail,
            imageUrl: _petProfile!.imageUrl,
            disease: disease,
          );
          _isEditingMedical = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('의료 정보가 저장되었습니다'),
              backgroundColor: Color(0xFF4FC59E),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkinReservation() async {
    // 체크인 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진료 시작'),
        content: const Text('진료를 시작하시겠습니까?\n(체크인)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC59E),
              foregroundColor: Colors.white,
            ),
            child: const Text('시작'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final success = await _reservationService.checkinReservation(
        widget.reservation.reservationId,
        widget.partnerId,
      );

      if (!success) {
        throw Exception('체크인 처리에 실패했습니다');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('진료가 시작되었습니다'),
            backgroundColor: Color(0xFF4FC59E),
          ),
        );

        // 상태 변경 후 화면 새로고침
        setState(() {
          _currentStatus = 'CHECKED_IN';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _completeDiagnosis() async {
    // 체크인 상태 확인
    if (_currentStatus != 'CHECKED_IN') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('먼저 진료를 시작해주세요 (체크인 필요)'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('진단 소견을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 몸무게 유효성 검사
    if (_petProfile != null) {
      final weight = double.tryParse(_weightController.text.trim());
      if (weight == null || weight <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('올바른 몸무게를 입력해주세요'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진료 완료'),
        content: const Text('진료를 완료하시겠습니까?\n반려동물 정보도 함께 업데이트됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC59E),
              foregroundColor: Colors.white,
            ),
            child: const Text('완료'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. 반려동물 의료 정보 업데이트
      if (_petProfile != null) {
        final weight = double.parse(_weightController.text.trim());
        final disease = _hasDisease ? _diseaseController.text.trim() : '';

        final petUpdateResult = await _petService.updatePetMedicalInfo(
          petId: _petProfile!.id!,
          weight: weight,
          disease: disease,
        );

        if (petUpdateResult['success'] != true) {
          throw Exception('반려동물 정보 업데이트 실패: ${petUpdateResult['message']}');
        }
      }

      // 2. 진료 정보 수집
      final diagnosis = _diagnosisController.text.trim();
      final prescription = _prescriptionController.text.trim();
      final medicalNotes = _notesController.text.trim();

      // 복용 스케줄 생성 (체크된 항목만)
      final List<String> scheduleList = [];
      if (_morningDose) scheduleList.add('아침');
      if (_lunchDose) scheduleList.add('점심');
      if (_dinnerDose) scheduleList.add('저녁');
      final dosageSchedule = scheduleList.isNotEmpty ? scheduleList.join(',') : null;

      // 복용 일수
      final dosageDays = _dosageDaysController.text.trim().isNotEmpty
          ? int.tryParse(_dosageDaysController.text.trim())
          : null;

      // 3. 예약 상태를 COMPLETED로 변경 (진료 정보 포함)
      final success = await _reservationService.completeReservation(
        widget.reservation.reservationId,
        widget.partnerId,
        diagnosis: diagnosis.isNotEmpty ? diagnosis : null,
        prescription: prescription.isNotEmpty ? prescription : null,
        dosageSchedule: dosageSchedule,
        dosageDays: dosageDays,
        medicalNotes: medicalNotes.isNotEmpty ? medicalNotes : null,
      );

      if (!success) {
        throw Exception('예약 완료 처리에 실패했습니다');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('진료가 완료되었습니다'),
            backgroundColor: Color(0xFF4FC59E),
          ),
        );

        // 이전 화면으로 돌아가기
        Navigator.pop(context, true); // true: 목록 새로고침 필요
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('진료하기'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
        actions: [
          if (_petProfile != null && !_isEditingMedical)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditingMedical = true;
                });
              },
              tooltip: '의료 정보 수정',
            ),
          if (_isEditingMedical)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMedicalInfo,
              tooltip: '저장',
            ),
          if (_isEditingMedical)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditingMedical = false;
                  _weightController.text = _petProfile?.weight.toString() ?? '';
                  _diseaseController.text = _petProfile?.disease ?? '';
                  _hasDisease = (_petProfile?.disease != null &&
                                 _petProfile!.disease!.isNotEmpty);
                });
              },
              tooltip: '취소',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환자 정보 카드
            Container(
              width: double.infinity,
              color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 왼쪽: 텍스트 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '환자 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003829),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.person,
                          '보호자',
                          widget.reservation.userName,
                        ),
                        const SizedBox(height: 8),
                        if (widget.reservation.petName != null)
                          _buildInfoRow(
                            Icons.pets,
                            '환자',
                            widget.reservation.petName!,
                          ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.calendar_today,
                          '진료일',
                          widget.reservation.formattedDate,
                        ),
                      ],
                    ),
                  ),
                  // 오른쪽: 반려동물 프로필 사진
                  const SizedBox(width: 16),
                  _buildPatientProfileImage(),
                ],
              ),
            ),

            // 반려동물 상세 정보 섹션
            if (_isLoadingPet)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_petLoadError != null)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _petLoadError!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (_petProfile != null)
              _buildPetInfoSection(),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 주요 증상
                  const Text(
                    '주요 증상',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (widget.symptoms.isEmpty)
                    const Text(
                      '체크된 증상이 없습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.symptoms.map((symptom) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC59E).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF4FC59E),
                            ),
                          ),
                          child: Text(
                            symptom,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF003829),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // 초기 증상 메모
                  if (widget.initialNotes != null &&
                      widget.initialNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '추가 증상 메모',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.initialNotes!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],

                  // 보호자 요청사항
                  if (widget.reservation.reservationContent != null &&
                      widget.reservation.reservationContent!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      '보호자 요청사항',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.reservation.reservationContent!,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),

                  // 진단 소견
                  const Text(
                    '진단 소견 *',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _diagnosisController,
                    decoration: InputDecoration(
                      hintText: '진단 결과 및 소견을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4FC59E),
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 5,
                    maxLength: 1000,
                  ),

                  const SizedBox(height: 24),

                  // 처방약
                  const Text(
                    '처방약',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 복용 스케줄
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC59E).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4FC59E).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '복용 스케줄',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF003829),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 아침, 점심, 저녁 체크박스
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('아침'),
                                value: _morningDose,
                                onChanged: (value) {
                                  setState(() {
                                    _morningDose = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF4FC59E),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('점심'),
                                value: _lunchDose,
                                onChanged: (value) {
                                  setState(() {
                                    _lunchDose = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF4FC59E),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                title: const Text('저녁'),
                                value: _dinnerDose,
                                onChanged: (value) {
                                  setState(() {
                                    _dinnerDose = value ?? false;
                                  });
                                },
                                activeColor: const Color(0xFF4FC59E),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // 복용 일수
                        Row(
                          children: [
                            const Text(
                              '복용 일수',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF003829),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _dosageDaysController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '7',
                                  suffixText: '일',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF4FC59E),
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 처방약 상세 입력
                  TextField(
                    controller: _prescriptionController,
                    decoration: InputDecoration(
                      hintText: '처방약명 및 추가 복용법을 입력하세요\n예) 항생제 (아목시실린 250mg)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4FC59E),
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 4,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 24),

                  // 추가 안내사항
                  const Text(
                    '추가 안내사항',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      hintText: '보호자에게 전달할 주의사항이나 안내사항을 입력하세요',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF4FC59E),
                          width: 2,
                        ),
                      ),
                    ),
                    maxLines: 3,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 32),

                  // 상태에 따른 버튼 표시
                  if (_currentStatus == 'CONFIRMED') ...[
                    // CONFIRMED 상태: 진료 시작 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _checkinReservation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC59E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '진료 시작 (체크인)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else if (_currentStatus == 'CHECKED_IN') ...[
                    // CHECKED_IN 상태: 진료 완료 버튼
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _completeDiagnosis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC59E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: Colors.grey.shade300,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                '진료 완료',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // 그 외 상태: 상태 표시만
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '현재 상태: $_currentStatus',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4FC59E)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPetInfoSection() {
    if (_petProfile == null) return const SizedBox();

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4FC59E).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pets, color: Color(0xFF4FC59E), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _isEditingMedical
                      ? '반려동물 상세 정보 (수정 중)'
                      : '반려동물 상세 정보',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003829),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // 기본 정보
          _buildPetDetailRow('품종', _petProfile!.speciesDetail ?? '미등록'),
          const SizedBox(height: 12),
          _buildPetDetailRow('나이', _calculateAge()),
          const SizedBox(height: 12),
          _buildPetDetailRow('성별', _getGenderText()),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),

          // 의료 정보 (항상 수정 가능)
          _buildEditableWeightRow(),
          const SizedBox(height: 16),
          _buildEditableDiseaseRow(),
        ],
      ),
    );
  }

  Widget _buildPetDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF003829),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableWeightRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '몸무게 *',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          enabled: _isEditingMedical,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: TextStyle(
            color: _isEditingMedical ? Colors.black : Colors.grey.shade700,
          ),
          decoration: InputDecoration(
            hintText: '예: 5.5',
            suffixText: 'kg',
            filled: true,
            fillColor: _isEditingMedical ? Colors.white : Colors.grey.shade100,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4FC59E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDiseaseRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '질병 유무',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: _hasDisease,
              onChanged: _isEditingMedical
                  ? (value) {
                      setState(() {
                        _hasDisease = value;
                        if (!value) {
                          _diseaseController.clear();
                        }
                      });
                    }
                  : null,
              activeTrackColor: const Color(0xFF4FC59E).withValues(alpha: 0.5),
              activeColor: const Color(0xFF4FC59E),
            ),
          ],
        ),
        if (_hasDisease) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _diseaseController,
            enabled: _isEditingMedical,
            maxLines: 2,
            style: TextStyle(
              color: _isEditingMedical ? Colors.black : Colors.grey.shade700,
            ),
            decoration: InputDecoration(
              hintText: '질병명 및 상세 내용을 입력하세요',
              filled: true,
              fillColor: _isEditingMedical ? Colors.white : Colors.grey.shade100,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4FC59E), width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ],
    );
  }

  String _calculateAge() {
    final age = _petProfile!.age;
    if (age == null) return '미등록';
    return '$age세';
  }

  String _getGenderText() {
    if (_petProfile!.gender == null) return '미등록';
    switch (_petProfile!.gender) {
      case 'M':
      case 'MALE':
        return '수컷';
      case 'F':
      case 'FEMALE':
        return '암컷';
      default:
        return _petProfile!.gender!;
    }
  }

  Widget _buildPatientProfileImage() {
    // 로딩 중
    if (_isLoadingPet) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 30,
            height: 30,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // 에러 또는 프로필 없음
    if (_petProfile == null || _petProfile!.imageUrl == null || _petProfile!.imageUrl!.isEmpty) {
      return Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF4FC59E).withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pets,
              size: 40,
              color: Color(0xFF4FC59E),
            ),
            SizedBox(height: 4),
            Text(
              '사진 없음',
              style: TextStyle(
                fontSize: 10,
                color: Color(0xFF4FC59E),
              ),
            ),
          ],
        ),
      );
    }

    // 이미지 URL 처리
    String imageUrl = _petProfile!.imageUrl!;
    if (!imageUrl.startsWith('http')) {
      imageUrl = 'http://223.130.130.225:9075$imageUrl';
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4FC59E),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          imageUrl,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey.shade200,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 30, color: Colors.grey),
                  SizedBox(height: 4),
                  Text(
                    '로드 실패',
                    style: TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: Colors.grey.shade100,
              child: Center(
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
