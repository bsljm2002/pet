import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../../models/consultation_record.dart';
import '../../services/consultation_service.dart';

/// 파트너용 상담 상세 및 답변 화면
class PartnerConsultationDetailScreen extends StatefulWidget {
  final ConsultationRecord consultation;

  const PartnerConsultationDetailScreen({
    super.key,
    required this.consultation,
  });

  @override
  State<PartnerConsultationDetailScreen> createState() =>
      _PartnerConsultationDetailScreenState();
}

class _PartnerConsultationDetailScreenState
    extends State<PartnerConsultationDetailScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmitting = false;
  ConsultationRecord? _currentConsultation;

  @override
  void initState() {
    super.initState();
    _currentConsultation = widget.consultation;
    if (_currentConsultation!.hasAnswer) {
      _answerController.text = _currentConsultation!.answer!;
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitAnswer() async {
    if (_answerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('답변 내용을 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final updatedConsultation = await _consultationService.addAnswer(
        consultationId: _currentConsultation!.id,
        answer: _answerController.text.trim(),
      );

      setState(() {
        _currentConsultation = updatedConsultation;
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('답변이 등록되었습니다'),
          backgroundColor: Color(0xFF4FC59E),
        ),
      );

      // 목록 새로고침을 위해 true 반환
      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('답변 등록 실패: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final consultation = _currentConsultation!;
    final statusColor = _getStatusColor(consultation.status);
    final isPending = consultation.status == 'PENDING';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('상담 상세'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더 - 상태 & 사용자 정보
            _buildHeader(consultation, statusColor, isPending),

            const SizedBox(height: 8),

            // 상담 정보
            _buildInfoSection(consultation),

            // 상담 내용 (이미지 포함)
            _buildContentSection(consultation),

            // 답변 섹션
            _buildAnswerSection(consultation, isPending),

            // 하단 여백
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: isPending
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAnswer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC59E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          '답변 등록',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildHeader(
      ConsultationRecord consultation, Color statusColor, bool isPending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 상태 배지
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPending
                          ? Icons.pending_actions
                          : consultation.status == 'ANSWERED'
                              ? Icons.check_circle
                              : Icons.info,
                      size: 16,
                      color: statusColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      consultation.statusDescription,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isPending) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    '답변 필요',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // 사용자 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF4FC59E),
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.userName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '고객',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(ConsultationRecord consultation) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 문의 주제
          const Text(
            '문의 주제',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            consultation.subject,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 16),

          // 상담 일시 & 반려동물 종류
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.calendar_today,
                  label: '문의 일시',
                  value: DateFormat('yyyy.MM.dd\nHH:mm')
                      .format(consultation.createdAt),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.pets,
                  label: '반려동물',
                  value: consultation.petType,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF4FC59E)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF003829),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(ConsultationRecord consultation) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '문의 내용',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  consultation.content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Colors.black87,
                  ),
                ),
                // 첨부 이미지 (있는 경우)
                if (consultation.imageUrl != null && consultation.imageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildImageWidget(consultation.imageUrl!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildAnswerSection(ConsultationRecord consultation, bool isPending) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '답변',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              if (consultation.hasAnswer && consultation.answeredAt != null) ...[
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm')
                      .format(consultation.answeredAt!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (isPending || !consultation.hasAnswer)
            // 답변 입력 필드
            TextFormField(
              controller: _answerController,
              maxLines: 8,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: '고객에게 전달할 답변을 입력해주세요...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF4FC59E), width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            )
          else
            // 등록된 답변 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF4FC59E)),
              ),
              child: Text(
                consultation.answer!,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: Color(0xFF003829),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // 로컬 파일 경로인지 확인 (/ 또는 C:\ 로 시작하는 경우)
    final isLocalFile = imageUrl.startsWith('/') ||
                        imageUrl.contains(':\\') ||
                        imageUrl.startsWith('file://');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isLocalFile
          ? Image.file(
              File(imageUrl),
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageError();
              },
            )
          : Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildImageError();
              },
            ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            '이미지를 불러올 수 없습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFA726);
      case 'ANSWERED':
        return const Color(0xFF4FC59E);
      case 'CLOSED':
        return const Color(0xFF78909C);
      case 'CANCELLED':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }
}
