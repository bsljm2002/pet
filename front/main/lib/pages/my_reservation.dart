import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/reservation_model.dart';
import '../providers/hospital_provider.dart';
import '../widgets/ticket_shell.dart';

class MyReservation extends StatefulWidget {
  const MyReservation({super.key});

  @override
  State<MyReservation> createState() => _MyReservationState();
}

class _MyReservationState extends State<MyReservation> {
  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    Future.microtask(() => context.read<HospitalProvider>().loadReservations());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 예약')),
      body: Consumer<HospitalProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingReservations) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reservationsError != null) {
            return _ErrorView(
              message: provider.reservationsError!,
              onRetry: provider.loadReservations,
            );
          }

          final reservations = provider.reservations;
          if (reservations.isEmpty) {
            return const _EmptyView(
              title: '예약 내역이 없습니다',
              description: '동물병원에서 예약을 진행하면 이곳에서 확인할 수 있어요.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            itemCount: reservations.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return _ReservationTicket(reservation: reservation);
            },
          );
        },
      ),
    );
  }
}

class _ReservationTicket extends StatelessWidget {
  final ReservationModel reservation;

  const _ReservationTicket({required this.reservation});

  @override
  Widget build(BuildContext context) {
    final accentColor = _statusColor(reservation.status);
    final formattedDate = DateFormat(
      'yyyy.MM.dd (E)',
      'ko_KR',
    ).format(reservation.reservationDate);
    final formattedTime = reservation.timeSlot;

    return TicketShell(
      accentColor: accentColor,
      gradient: LinearGradient(
        colors: [Colors.white, const Color(0xFFE6F7F1).withOpacity(0.85)],
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
            child: const Icon(
              Icons.local_hospital_outlined,
              color: Color(0xFF2B8C6C),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.vetName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003829),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _InfoChip(icon: Icons.pets, label: reservation.petName),
                    _InfoChip(
                      icon: Icons.medical_services_outlined,
                      label: reservation.specialty,
                    ),
                    _InfoChip(
                      icon: Icons.badge_outlined,
                      label: reservation.petType,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(status: reservation.status, color: accentColor),
        ],
      ),
      lowerSection: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DetailTile(
                  icon: Icons.calendar_today_outlined,
                  label: '예약 날짜',
                  value: formattedDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailTile(
                  icon: Icons.schedule,
                  label: '예약 시간',
                  value: formattedTime,
                ),
              ),
            ],
          ),
          if (reservation.memo != null &&
              reservation.memo!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '메모',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                reservation.memo!,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],
        ],
      ),
    );
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2B8C6C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2B8C6C),
            ),
          ),
        ],
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2B8C6C)),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B8C6C),
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String title;
  final String description;

  const _EmptyView({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_note, size: 64, color: Colors.grey),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}
