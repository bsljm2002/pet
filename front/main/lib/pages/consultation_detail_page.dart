import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/consultation_record.dart';

class ConsultationDetailPage extends StatefulWidget {
  final ConsultationRecord record;

  const ConsultationDetailPage({super.key, required this.record});

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final accentColor = _statusColor(record.status);
    final requestedLabel = DateFormat(
      'yyyy.MM.dd (E) HH:mm',
      'ko_KR',
    ).format(record.createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 상세'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF4E2A00),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(
              topic: record.subject,
              partnerName: record.partnerName,
              status: record.statusText,
              accentColor: accentColor,
              requestedLabel: requestedLabel,
              petType: record.petType,
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('반려동물'),
            const SizedBox(height: 8),
            _buildPetTypeCard(record.petType),
            const SizedBox(height: 24),
            _buildSectionTitle('상담 내용'),
            const SizedBox(height: 8),
            _buildNotesCard(record.content),
            const SizedBox(height: 24),
            if (record.hasAnswer) ...[
              _buildSectionTitle('파트너 답변'),
              const SizedBox(height: 8),
              _buildAnswerCard(record.answer!, record.answeredAt),
              const SizedBox(height: 24),
            ],
            _buildSectionTitle('담당 파트너'),
            const SizedBox(height: 8),
            _buildPartnerCard(
              record.partnerName,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF4E2A00),
      ),
    );
  }

  Widget _buildPetTypeCard(String petType) {
    IconData icon = petType.contains('강아지') ? Icons.pets : Icons.eco;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFB26A00), size: 24),
          const SizedBox(width: 12),
          Text(
            petType,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4E2A00),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        content,
        style: const TextStyle(fontSize: 14.5, height: 1.6),
      ),
    );
  }

  Widget _buildAnswerCard(String answer, DateTime? answeredAt) {
    final answeredLabel = answeredAt != null
        ? DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(answeredAt)
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration().copyWith(
        color: const Color(0xFFF5F5F5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (answeredLabel.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  answeredLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(
            answer,
            style: const TextStyle(fontSize: 14.5, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerCard(String partnerName) {
    IconData icon = Icons.local_hospital;
    String typeLabel = '동물병원';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow(icon, '이름', partnerName),
          _detailRow(Icons.work_outline, '유형', typeLabel),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFFB26A00)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFFB26A00),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14.5),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    if (status.contains('대기')) {
      return const Color(0xFFFFA000);
    } else if (status.contains('완료')) {
      return const Color(0xFF4FC59E);
    } else if (status.contains('취소')) {
      return const Color(0xFFE57373);
    }
    return const Color(0xFFFFA000);
  }
}

class _HeaderCard extends StatelessWidget {
  final String topic;
  final String partnerName;
  final String status;
  final Color accentColor;
  final String requestedLabel;
  final String petType;

  const _HeaderCard({
    required this.topic,
    required this.partnerName,
    required this.status,
    required this.accentColor,
    required this.requestedLabel,
    required this.petType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat_bubble_outline,
                color: Color(0xFFB26A00),
                size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E2A00),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerChip(Icons.event, requestedLabel),
              _headerChip(
                Icons.local_hospital,
                partnerName,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB26A00)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB26A00),
            ),
          ),
        ],
      ),
    );
  }
}
