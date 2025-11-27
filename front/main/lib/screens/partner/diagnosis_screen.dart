import 'package:flutter/material.dart';
import '../../models/partner_reservation_model.dart';
import '../../services/partner_reservation_service.dart';

/// 진료 화면 - 증상 확인, 의사 소견, 처방약 입력
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

  final TextEditingController _diagnosisController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _prescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _completeDiagnosis() async {
    if (_diagnosisController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('진단 소견을 입력해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('진료 완료'),
        content: const Text('진료를 완료하시겠습니까?\n완료 후에는 수정할 수 없습니다.'),
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
      // TODO: 1. 진단 정보 저장 API (나중에 추가)
      // await _reservationService.saveDiagnosis(
      //   widget.reservation.reservationId,
      //   _diagnosisController.text,
      //   _prescriptionController.text,
      //   _notesController.text,
      // );

      // 2. 예약 상태를 COMPLETED로 변경
      final success = await _reservationService.completeReservation(
        widget.reservation.reservationId,
        widget.partnerId,
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
                  const SizedBox(height: 8),
                  TextField(
                    controller: _prescriptionController,
                    decoration: InputDecoration(
                      hintText: '처방약 및 복용법을 입력하세요\n예) 항생제 1일 2회, 7일간 복용',
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

                  // 완료 버튼
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
}
