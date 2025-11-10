import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/pet_profile.dart';
import '../models/reservation_model.dart';
import '../services/pet_profile_manager.dart';

class ReservationDetailPage extends StatefulWidget {
  final ReservationModel reservation;

  const ReservationDetailPage({super.key, required this.reservation});

  @override
  State<ReservationDetailPage> createState() => _ReservationDetailPageState();
}

class _ReservationDetailPageState extends State<ReservationDetailPage> {
  PetProfile? _petProfile;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    _petProfile = _findPetProfile(widget.reservation.petName);
  }

  @override
  Widget build(BuildContext context) {
    final reservation = widget.reservation;
    final accentColor = _statusColor(reservation.status);
    final formattedDate =
        DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(reservation.reservationDate);
    final appointmentDateTime = _combineDateTime(
      reservation.reservationDate,
      reservation.timeSlot,
    );
    final isUpcoming = appointmentDateTime.isAfter(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('예약 상세')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderCard(
              vetName: reservation.vetName,
              status: reservation.status,
              accentColor: accentColor,
              dateLabel: formattedDate,
              timeLabel: reservation.timeSlot,
              specialty: reservation.specialty,
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('진료 대상'),
            _buildPetSummary(reservation.petName, reservation.petType),
            const SizedBox(height: 16),
            _buildPetDetailCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('진료 내용'),
            _buildMemoCard(reservation.memo),
            const SizedBox(height: 24),
            _buildSectionTitle('담당 수의사 & 예약 시간'),
            _buildDoctorCard(reservation.vetName, reservation.timeSlot, formattedDate),
            const SizedBox(height: 24),
            _buildSectionTitle('병원 위치'),
            _buildMapPlaceholder(),
            if (isUpcoming) ...[
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
        color: Color(0xFF003829),
      ),
    );
  }

  Widget _buildPetSummary(String petName, String petType) {
    return Row(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: const Color(0xFFE6F7F1),
          child: const Icon(Icons.pets, color: Color(0xFF4FC59E)),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              petName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              petType,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF4FC59E),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPetDetailCard() {
    final profile = _petProfile;
    if (profile == null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Text(
          '등록된 상세 프로필 정보가 없습니다.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final ageLabel = _formatAge(profile.birthdate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (ageLabel != null) _detailRow('나이', ageLabel),
          if (profile.speciesDetail != null && profile.speciesDetail!.trim().isNotEmpty)
            _detailRow('품종', profile.speciesDetail!),
          if (profile.gender != null && profile.gender!.trim().isNotEmpty)
            _detailRow('성별', profile.gender!),
          if (profile.abtiTypeCode != null && profile.abtiTypeCode!.trim().isNotEmpty)
            _detailRow('성격 유형', profile.abtiTypeCode!),
          if (profile.imageUrl != null && profile.imageUrl!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  profile.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemoCard(String? memo) {
    final hasMemo = memo != null && memo.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Text(
        hasMemo ? memo! : '등록된 메모가 없습니다.',
        style: const TextStyle(fontSize: 14.5, height: 1.6),
      ),
    );
  }

  Widget _buildDoctorCard(String vetName, String timeSlot, String dateLabel) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detailRow('담당 수의사', vetName),
          _detailRow('예약 일정', '$dateLabel $timeSlot'),
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
              color: const Color(0xFFE6F7F1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.map_outlined, size: 48, color: Color(0xFF4FC59E)),
                SizedBox(height: 8),
                Text(
                  '지도 표시 영역',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2B8C6C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '지도 API 키를 설정하면 병원 위치를 볼 수 있어요.',
                  style: TextStyle(color: Color(0xFF2B8C6C)),
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
            const SnackBar(content: Text('예약이 취소되었습니다.')),
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
          '예약 취소',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF2B8C6C),
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

  PetProfile? _findPetProfile(String petName) {
    try {
      return PetProfileManager()
          .getAllProfiles()
          .firstWhere((profile) => profile.name == petName);
    } catch (e) {
      return null;
    }
  }

  String? _formatAge(String? birthday) {
    if (birthday == null || birthday.trim().isEmpty) {
      return null;
    }
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

  DateTime _combineDateTime(DateTime date, String time) {
    try {
      final parts = time.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return date;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case '예약완료':
        return const Color(0xFF4FC59E);
      case '진료중':
        return const Color(0xFF2B8C6C);
      case '완료':
        return const Color(0xFF2196F3);
      case '취소':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF4FC59E);
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String vetName;
  final String status;
  final Color accentColor;
  final String dateLabel;
  final String timeLabel;
  final String specialty;

  const _HeaderCard({
    required this.vetName,
    required this.status,
    required this.accentColor,
    required this.dateLabel,
    required this.timeLabel,
    required this.specialty,
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
              const Icon(Icons.local_hospital, color: Color(0xFF2B8C6C)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vetName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003829),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.14),
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
              _headerChip(Icons.calendar_today_outlined, dateLabel),
              const SizedBox(width: 8),
              _headerChip(Icons.schedule, timeLabel),
              const SizedBox(width: 8),
              _headerChip(Icons.medical_services_outlined, specialty),
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
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B8C6C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF2B8C6C),
            ),
          ),
        ],
      ),
    );
  }
}
