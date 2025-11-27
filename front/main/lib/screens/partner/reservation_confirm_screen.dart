import 'package:flutter/material.dart';
import '../../models/partner_reservation_model.dart';
import '../../services/partner_reservation_service.dart';

/// 예약 확정 화면 - 증상 체크 및 확정 처리
class ReservationConfirmScreen extends StatefulWidget {
  final PartnerReservationModel reservation;
  final int partnerId;

  const ReservationConfirmScreen({
    super.key,
    required this.reservation,
    required this.partnerId,
  });

  @override
  State<ReservationConfirmScreen> createState() =>
      _ReservationConfirmScreenState();
}

class _ReservationConfirmScreenState extends State<ReservationConfirmScreen> {
  final PartnerReservationService _reservationService =
      PartnerReservationService();

  // 증상 체크리스트
  final List<String> _symptomOptions = [
    '발열',
    '구토',
    '설사',
    '기침',
    '재채기',
    '식욕부진',
    '무기력',
    '피부 발진',
    '탈모',
    '눈곱',
    '귀 이상',
    '보행 이상',
    '호흡곤란',
    '경련',
    '기타',
  ];

  final Set<String> _selectedSymptoms = {};
  final TextEditingController _additionalNotesController =
      TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _confirmReservation() async {
    if (_selectedSymptoms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 증상을 선택해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 예약 확정 API 호출
      final success = await _reservationService.acceptReservation(
        widget.reservation.reservationId,
        widget.partnerId,
      );

      if (success) {
        if (mounted) {
          // 증상 정보 저장 (TODO: 백엔드 API 추가 필요)
          // await _reservationService.saveSymptoms(
          //   widget.reservation.reservationId,
          //   _selectedSymptoms.toList(),
          //   _additionalNotesController.text,
          // );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약이 확정되었습니다'),
              backgroundColor: Color(0xFF4FC59E),
            ),
          );

          // 이전 화면으로 돌아가기
          Navigator.pop(context, true); // true: 목록 새로고침 필요
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('예약 확정에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
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
        title: const Text('예약 확정'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 예약 정보 카드
            Container(
              width: double.infinity,
              color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '예약 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person, '고객명', widget.reservation.userName),
                  const SizedBox(height: 8),
                  if (widget.reservation.petName != null)
                    _buildInfoRow(
                      Icons.pets,
                      '반려동물',
                      widget.reservation.petName!,
                    ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    '예약일',
                    widget.reservation.formattedDate,
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    '예약시간',
                    '${widget.reservation.timeSlot} ${widget.reservation.formattedTime}',
                  ),
                  if (widget.reservation.reservationContent != null &&
                      widget.reservation.reservationContent!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.note,
                      '요청사항',
                      widget.reservation.reservationContent!,
                    ),
                  ],
                ],
              ),
            ),

            // 증상 체크리스트
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '증상 체크',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '해당하는 증상을 모두 선택해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 증상 체크박스 그리드
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _symptomOptions.map((symptom) {
                      final isSelected = _selectedSymptoms.contains(symptom);
                      return FilterChip(
                        label: Text(symptom),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedSymptoms.add(symptom);
                            } else {
                              _selectedSymptoms.remove(symptom);
                            }
                          });
                        },
                        selectedColor: const Color(0xFF4FC59E).withValues(alpha: 0.3),
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: const Color(0xFF003829),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? const Color(0xFF003829)
                              : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // 추가 메모
                  const Text(
                    '추가 사항',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _additionalNotesController,
                    decoration: InputDecoration(
                      hintText: '추가로 확인이 필요한 사항을 입력하세요',
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

                  // 확정 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _confirmReservation,
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
                              '예약 확정',
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
