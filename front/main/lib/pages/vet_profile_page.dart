import 'package:flutter/material.dart';

import '../models/vet_model.dart';
import 'reservation_request_page.dart';
import 'consultation_request_page.dart';

/// 수의사 프로필 상세 페이지
/// 병원과 의료진 정보를 요약해서 보여주고 예약/상담 액션으로 연결한다.
class VetProfilePage extends StatelessWidget {
  final VetModel vet;

  const VetProfilePage({super.key, required this.vet});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('수의사 프로필')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(vet: vet),
            const SizedBox(height: 24),
            _IntroEducationCard(vet: vet),
            const SizedBox(height: 24),
            _InfoCard(
              icon: Icons.location_on_outlined,
              title: '병원 위치',
              value: vet.address,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.phone_outlined,
              title: '연락처',
              value: vet.phone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    icon: Icons.star_rate_rounded,
                    title: '평점',
                    value: '${vet.rating}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoCard(
                    icon: Icons.directions_walk_outlined,
                    title: '거리',
                    value: '${vet.distance}km',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '전문 진료',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: vet.specialties
                  .map(
                    (specialty) => Chip(
                      backgroundColor: const Color(0xFFE6F7F1),
                      side: BorderSide.none,
                      label: Text(
                        specialty,
                        style: const TextStyle(color: Color(0xFF2B8C6C)),
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (vet.availableTimes.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                '예약 가능 시간',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Column(
                children: vet.availableTimes
                    .map(
                      (time) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.schedule_outlined),
                        title: Text(time),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: vet.isOpen
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReservationRequestPage(vet: vet),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC59E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.calendar_month),
                label: const Text('예약하기'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ConsultationRequestPage(vet: vet),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4FC59E),
                  side: const BorderSide(color: Color(0xFF4FC59E)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('상담하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final VetModel vet;

  const _ProfileHeader({required this.vet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: const Color(0xFFE6F7F1),
            backgroundImage: vet.imageUrl.isNotEmpty
                ? NetworkImage(vet.imageUrl)
                : null,
            child: vet.imageUrl.isNotEmpty
                ? null
                : const Icon(
                    Icons.local_hospital_outlined,
                    size: 36,
                    color: Color(0xFF4FC59E),
                  ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vet.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003829),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  vet.doctorName ?? '담당 수의사 미정',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4FC59E),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (vet.isOpen
                                ? const Color(0xFF4FC59E)
                                : Colors.redAccent)
                            .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vet.isOpen ? '현재 영업중' : '현재 휴무',
                    style: TextStyle(
                      color: vet.isOpen
                          ? const Color(0xFF2B8C6C)
                          : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IntroEducationCard extends StatelessWidget {
  final VetModel vet;

  const _IntroEducationCard({required this.vet});

  @override
  Widget build(BuildContext context) {
    final introduction = vet.description.trim().isEmpty
        ? '소개 정보가 등록되지 않았습니다.'
        : vet.description.trim();
    final hasEducation = vet.education.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    const Icon(Icons.badge_outlined, color: Color(0xFF2B8C6C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자기 소개',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      introduction,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            '학력 사항',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          if (hasEducation)
            ...vet.education.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF2B8C6C),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            const Text(
              '학력 정보가 등록되지 않았습니다.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF2B8C6C)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
