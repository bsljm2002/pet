import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../widgets/ticket_shell.dart';

class MyContacts extends StatefulWidget {
  const MyContacts({super.key});

  @override
  State<MyContacts> createState() => _MyContactsState();
}

class _MyContactsState extends State<MyContacts> {
  late final List<_ConsultationRecord> _records;

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    _records = [
      _ConsultationRecord(
        id: 'c1',
        vetName: '루나 동물의료센터',
        topic: '피부 알레르기 상담',
        pets: const ['멍멍이'],
        requestedAt: DateTime.now().subtract(const Duration(days: 1)),
        contactMethod: '카카오톡',
        status: '상담 완료',
        notes: '약 처방 관련 후속 상담 예정',
      ),
      _ConsultationRecord(
        id: 'c2',
        vetName: '브릿지 동물클리닉',
        topic: '영양제 추천 문의',
        pets: const ['냥냥이', '초코'],
        requestedAt: DateTime.now().subtract(const Duration(days: 5)),
        contactMethod: '전화',
        status: '상담 대기',
        notes: '11월 25일 오후 3시 통화 예정',
      ),
      _ConsultationRecord(
        id: 'c3',
        vetName: '마포 24시 센트럴동물병원',
        topic: '야간 응급 상담',
        pets: const ['쿠키'],
        requestedAt: DateTime.now().subtract(const Duration(days: 11)),
        contactMethod: '영상통화',
        status: '상담 완료',
        notes: '응급 조치 안내 후 내원 조치 완료',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 상담 내역')),
      body: _records.isEmpty
          ? const _EmptyConsultationView()
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              itemBuilder: (context, index) {
                final record = _records[index];
                return _ConsultationTicket(record: record);
              },
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemCount: _records.length,
            ),
    );
  }
}

class _ConsultationTicket extends StatelessWidget {
  final _ConsultationRecord record;

  const _ConsultationTicket({required this.record});

  @override
  Widget build(BuildContext context) {
    final accentColor = _statusColor(record.status);
    final formattedDate =
        DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(record.requestedAt);
    final petsSummary = record.pets.join(', ');

    return TicketShell(
      accentColor: accentColor,
      gradient: LinearGradient(
        colors: [
          Colors.white,
          const Color(0xFFFFF3E0).withOpacity(0.85),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      upperSection: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: Color(0xFFB26A00)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.topic,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4E2A00),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.vetName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB26A00),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(status: record.status, color: accentColor),
        ],
      ),
      lowerSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.event_available_outlined,
                  label: '요청 시각',
                  value: formattedDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailTile(
                  icon: Icons.call_split,
                  label: '상담 방식',
                  value: record.contactMethod,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _DetailTile(
            icon: Icons.pets,
            label: '반려동물',
            value: petsSummary,
          ),
          if (record.notes != null && record.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '상담 메모',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.brown.shade400,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.notes!,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ],
      ),
      notchPosition: 0.5,
    );
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

class _ConsultationRecord {
  final String id;
  final String vetName;
  final String topic;
  final List<String> pets;
  final DateTime requestedAt;
  final String contactMethod;
  final String status;
  final String? notes;

  const _ConsultationRecord({
    required this.id,
    required this.vetName,
    required this.topic,
    required this.pets,
    required this.requestedAt,
    required this.contactMethod,
    required this.status,
    this.notes,
  });
}

class _EmptyConsultationView extends StatelessWidget {
  const _EmptyConsultationView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.chat_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 18),
            Text(
              '상담 내역이 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              '상담을 신청하면 진행 상황과 메모를 한 장의 티켓으로 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFFB26A00)),
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
          const SizedBox(height: 8),
          Text(
            value,
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
