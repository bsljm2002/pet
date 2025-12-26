import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/consultation_record.dart';

/// 상담 상세 페이지 (간편 상담용)
/// 상담 내용과 답변을 표시하는 화면
class ConsultationDetailPage extends StatelessWidget {
  final ConsultationRecord consultation;

  const ConsultationDetailPage({
    super.key,
    required this.consultation,
  });

  @override
  Widget build(BuildContext context) {
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
            // 헤더 - 파트너 정보 & 상태
            _buildHeader(),

            const SizedBox(height: 8),

            // 상담 정보
            _buildInfoSection(),

            // 상담 내용
            _buildContentSection(),

            // 답변 (있는 경우)
            if (consultation.hasAnswer) _buildAnswerSection(),

            // 하단 여백
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final statusColor = _getStatusColor(consultation.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4FC59E).withOpacity(0.1),
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
                  _getStatusIcon(consultation.status),
                  size: 16,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  consultation.statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 파트너 정보
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_hospital,
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
                      consultation.partnerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '동물병원',
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

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            Icons.pets,
            '반려동물 종류',
            consultation.petType,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            '신청 일시',
            DateFormat('yyyy년 MM월 dd일 HH:mm').format(consultation.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
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
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFF4FC59E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '문의 내용',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 주제
          Text(
            consultation.subject,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // 내용
          Text(
            consultation.content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade800,
              height: 1.6,
            ),
          ),
          // 첨부 이미지 (있는 경우)
          if (consultation.imageUrl != null && consultation.imageUrl!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildImageWidget(consultation.imageUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildAnswerSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F7F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF4FC59E).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC59E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '파트너 답변',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 답변 내용
          Text(
            consultation.answer!,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF003829),
              height: 1.6,
            ),
          ),
          if (consultation.answeredAt != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  DateFormat('yyyy.MM.dd HH:mm').format(consultation.answeredAt!),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
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
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey.shade400,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF4FC59E),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'ANSWERED':
        return const Color(0xFF4FC59E);
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'ANSWERED':
        return Icons.check_circle;
      case 'CANCELLED':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }
}
