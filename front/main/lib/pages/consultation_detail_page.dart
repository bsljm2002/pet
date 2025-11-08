import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/consultation_record.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';

class ConsultationDetailPage extends StatefulWidget {
  final ConsultationRecord record;

  const ConsultationDetailPage({super.key, required this.record});

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  late final List<PetProfile> _matchedProfiles;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    _matchedProfiles = widget.record.petNames
        .map(_findPetProfile)
        .where((profile) => profile != null)
        .cast<PetProfile>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final accentColor = _statusColor(record.status);
    final requestedLabel =
        DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(record.requestedAt);
    final isUpcoming = record.requestedAt.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('상담 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(
              topic: record.topic,
              vetName: record.vetName,
              status: record.status,
              accentColor: accentColor,
              requestedLabel: requestedLabel,
              contactMethod: record.contactMethod,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('상담 대상'),
            _buildPetSummary(record.petNames),
            const SizedBox(height: 16),
            _buildPetDetailCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('상담 내용'),
            _buildNotesCard(record.notes),
            const SizedBox(height: 24),
            _buildSectionTitle('담당 수의사 & 상담 일정'),
            _buildDoctorCard(record.vetName, requestedLabel, record.contactMethod),
            const SizedBox(height: 24),
            _buildSectionTitle('병원 위치'),
            _buildMapPlaceholder(),
            if (isUpcoming && record.status != '상담 취소') ...[
              const SizedBox(height: 32),
              _buildCancelButton(),
            ],
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

  Widget _buildPetSummary(List<String> petNames) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: petNames
          .map(
            (name) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFE0B2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pets, size: 18, color: Color(0xFFB26A00)),
                  const SizedBox(width: 6),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFB26A00),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPetDetailCards() {
    if (_matchedProfiles.isEmpty) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Text(
          '등록된 반려동물 프로필 정보를 찾을 수 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: _matchedProfiles.map((profile) {
        final ageLabel = _formatAge(profile.birthday);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6, bottom: 12),
          padding: const EdgeInsets.all(18),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4E2A00),
                ),
              ),
              const SizedBox(height: 12),
              if (ageLabel != null) _detailRow('나이', ageLabel),
              if (profile.breed != null && profile.breed!.trim().isNotEmpty)
                _detailRow('품종', profile.breed!),
              if (profile.gender != null && profile.gender!.trim().isNotEmpty)
                _detailRow('성별', profile.gender!),
              if (profile.disease != null && profile.disease!.trim().isNotEmpty)
                _detailRow('기저 질환', profile.disease!),
              if (profile.abtiType != null && profile.abtiType!.trim().isNotEmpty)
                _detailRow('성격 유형', profile.abtiType!),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesCard(String? notes) {
    final hasNotes = notes != null && notes.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        hasNotes ? notes! : '작성된 상담 메모가 없습니다.',
        style: const TextStyle(fontSize: 14.5, height: 1.6),
      ),
    );
  }

  Widget _buildDoctorCard(String vetName, String requestedLabel, String contactMethod) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('담당 수의사', vetName),
          _detailRow('상담 일정', requestedLabel),
          _detailRow('상담 방식', contactMethod),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE0B2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.map_outlined, size: 48, color: Color(0xFFB26A00)),
                SizedBox(height: 8),
                Text(
                  '지도 표시 영역',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB26A00),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '지도 API 키를 설정하면 병원 위치를 볼 수 있어요.',
                  style: TextStyle(color: Color(0xFFB26A00)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.vpn_key_outlined),
              label: const Text('지도 API 키 설정'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('상담이 취소되었습니다.')),
          );
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(Icons.cancel_outlined),
        label: const Text(
          '상담 취소',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
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
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  PetProfile? _findPetProfile(String name) {
    try {
      return PetProfileManager()
          .getAllProfiles()
          .firstWhere((profile) => profile.name == name);
    } catch (_) {
      return null;
    }
  }

  String? _formatAge(String? birthday) {
    if (birthday == null || birthday.trim().isEmpty) return null;
    try {
      final date = DateFormat('yyyy-MM-dd').parse(birthday);
      final now = DateTime.now();
      int years = now.year - date.year;
      int months = now.month - date.month;
      if (now.day < date.day) {
        months -= 1;
      }
      if (months < 0) {
        years -= 1;
        months += 12;
      }
      if (years < 0) years = 0;
      if (months < 0) months = 0;
      if (years == 0) {
        return '$months개월';
      }
      return months == 0 ? '${years}살' : '${years}살 ${months}개월';
    } catch (_) {
      return birthday;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '상담 대기':
        return const Color(0xFFFFA000);
      case '상담 취소':
        return const Color(0xFFE57373);
      case '상담 완료':
        return const Color(0xFF8BC34A);
      default:
        return const Color(0xFFFFA000);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String topic;
  final String vetName;
  final String status;
  final Color accentColor;
  final String requestedLabel;
  final String contactMethod;

  const _HeaderCard({
    required this.topic,
    required this.vetName,
    required this.status,
    required this.accentColor,
    required this.requestedLabel,
    required this.contactMethod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accentColor.withOpacity(0.12),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.chat, color: Color(0xFFB26A00)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E2A00),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerChip(Icons.event_available_outlined, requestedLabel),
              const SizedBox(width: 8),
              _headerChip(Icons.call_split, contactMethod),
              const SizedBox(width: 8),
              _headerChip(Icons.local_hospital_outlined, vetName),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFE0B2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB26A00)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFFB26A00),
            ),
          ),
        ],
      ),
    );
  }
}
