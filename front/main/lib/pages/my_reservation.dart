import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../models/user_reservation_model.dart';
import '../services/user_reservation_service.dart';
import '../services/auth_service.dart';
import '../widgets/ticket_shell.dart';
import 'write_review_page.dart';

class MyReservation extends StatefulWidget {
  const MyReservation({super.key});

  @override
  State<MyReservation> createState() => _MyReservationState();
}

class _MyReservationState extends State<MyReservation> {
  final UserReservationService _reservationService = UserReservationService();
  final AuthService _authService = AuthService();

  List<UserReservationModel> _reservations = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'WAITING'; // WAITING, CONFIRMED, COMPLETED, CANCELLED (기본값: 대기중)
  String _selectedServiceType = 'ALL'; // ALL, HOSPITAL, SITTER (기본값: 전체)

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale ??= 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final userId = int.parse(currentUser.id);

      // 서비스 타입 필터 적용 (ALL이면 null로 전달하여 전체 조회)
      final serviceTypeFilter = _selectedServiceType == 'ALL' ? null : _selectedServiceType;
      final reservations = await _reservationService.getMyReservations(
        userId,
        serviceType: serviceTypeFilter,
      );

      setState(() {
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '예약 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  List<UserReservationModel> _getFilteredReservations() {
    if (_selectedFilter == 'CANCELLED') {
      // 취소됨 필터: 사용자 취소, 파트너 거절 모두 포함
      return _reservations
          .where((reservation) =>
              reservation.status == 'CANCELLED_BY_USER' ||
              reservation.status == 'CANCELLED_BY_BIZ')
          .toList();
    }
    // 선택된 필터에 해당하는 예약만 반환
    return _reservations
        .where((reservation) => reservation.status == _selectedFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReservations = _getFilteredReservations();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('내 예약'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 서비스 타입 필터 (수의사/펫시터)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF5F5F5),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildServiceTypeChip('전체', 'ALL'),
                  const SizedBox(width: 8),
                  _buildServiceTypeChip('수의사', 'HOSPITAL'),
                  const SizedBox(width: 8),
                  _buildServiceTypeChip('펫시터', 'SITTER'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 상태 필터 칩
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('대기중', 'WAITING'),
                  const SizedBox(width: 8),
                  _buildFilterChip('확정됨', 'CONFIRMED'),
                  const SizedBox(width: 8),
                  _buildFilterChip('완료됨', 'COMPLETED'),
                  const SizedBox(width: 8),
                  _buildFilterChip('취소됨', 'CANCELLED'),
                ],
              ),
            ),
          ),
          const Divider(height: 1),

          // 예약 목록
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _ErrorView(
                        message: _errorMessage!,
                        onRetry: _loadReservations,
                      )
                    : filteredReservations.isEmpty
                        ? _EmptyView(
                            title: '해당하는 예약이 없습니다',
                            description: '${_getFilterLabel(_selectedFilter)} 상태의 예약이 없습니다.',
                          )
                        : RefreshIndicator(
                            onRefresh: _loadReservations,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                              itemCount: filteredReservations.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final reservation = filteredReservations[index];
                                final currentUser = _authService.currentUser;
                                final userId = currentUser != null ? int.parse(currentUser.id) : 0;
                                return _ReservationTicket(
                                  reservation: reservation,
                                  onCancel: () => _cancelReservation(reservation),
                                  onRefresh: _loadReservations,
                                  userId: userId,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceTypeChip(String label, String value) {
    final isSelected = _selectedServiceType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedServiceType = value;
          _loadReservations(); // 서비스 타입 변경 시 목록 다시 로드
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF2196F3).withOpacity(0.2),
      checkmarkColor: const Color(0xFF2196F3),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFF4FC59E).withOpacity(0.2),
      checkmarkColor: const Color(0xFF4FC59E),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF4FC59E) : Colors.grey.shade700,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? const Color(0xFF4FC59E) : Colors.grey.shade300,
      ),
    );
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'WAITING':
        return '대기중';
      case 'CONFIRMED':
        return '확정됨';
      case 'COMPLETED':
        return '완료됨';
      case 'CANCELLED':
        return '취소됨';
      default:
        return '전체';
    }
  }

  Future<void> _cancelReservation(UserReservationModel reservation) async {
    // 취소 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 취소'),
        content: const Text('예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('취소'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = int.parse(currentUser.id);
      final success = await _reservationService.cancelReservation(
        reservation.reservationId,
        userId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 취소되었습니다'),
            backgroundColor: Color(0xFF4FC59E),
          ),
        );
        await _loadReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 취소에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _ReservationTicket extends StatelessWidget {
  final UserReservationModel reservation;
  final VoidCallback onCancel;
  final VoidCallback onRefresh;
  final int userId;

  const _ReservationTicket({
    required this.reservation,
    required this.onCancel,
    required this.onRefresh,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = _statusColor(reservation.status);

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
            child: Icon(
              reservation.serviceType == 'HOSPITAL'
                  ? Icons.local_hospital_outlined
                  : Icons.pets,
              color: const Color(0xFF2B8C6C),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.partnerName ?? '파트너 정보 없음',
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
                    if (reservation.petName != null)
                      _InfoChip(
                        icon: Icons.pets,
                        label: reservation.petName!,
                      ),
                    _InfoChip(
                      icon: Icons.category_outlined,
                      label: reservation.serviceTypeLabel,
                    ),
                    if (reservation.specialties.isNotEmpty)
                      _InfoChip(
                        icon: Icons.medical_services_outlined,
                        label: reservation.specialties.first,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusBadge(status: reservation.statusLabel, color: accentColor),
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
                  value: reservation.formattedDate,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DetailTile(
                  icon: Icons.schedule,
                  label: '예약 시간',
                  value: reservation.formattedTime,
                ),
              ),
            ],
          ),

          // 전문 분야 / 서비스 목록
          if (reservation.specialties.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              reservation.serviceType == 'HOSPITAL' ? '진료 과목' : '서비스',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reservation.specialties.map((specialty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4FC59E).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    specialty,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF2B8C6C),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 예약 메모
          if (reservation.reservationContent != null &&
              reservation.reservationContent!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '요청사항',
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
                reservation.reservationContent!,
                style: const TextStyle(fontSize: 13.5, height: 1.4),
              ),
            ),
          ],

          // 리뷰 쓰기 버튼 (완료된 예약이고 아직 리뷰를 작성하지 않은 경우만)
          if (reservation.status == 'COMPLETED' && !reservation.hasReview) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _writeReview(context),
                icon: const Icon(Icons.rate_review),
                label: const Text('리뷰 쓰기'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC59E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],

          // 리뷰 작성 완료 표시 (완료된 예약이고 이미 리뷰를 작성한 경우)
          if (reservation.status == 'COMPLETED' && reservation.hasReview) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.grey.shade600, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '리뷰 작성 완료',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 취소 버튼 (대기중이거나 확정된 예약만)
          if (reservation.status == 'WAITING' ||
              reservation.status == 'CONFIRMED') ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('예약 취소'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'WAITING':
        return const Color(0xFFFFA726); // 주황색
      case 'CONFIRMED':
        return const Color(0xFF4FC59E); // 민트색
      case 'COMPLETED':
        return const Color(0xFF2196F3); // 파란색
      case 'CANCELLED_BY_USER':
      case 'CANCELLED_BY_BIZ':
        return const Color(0xFFE57373); // 빨간색
      default:
        return const Color(0xFF4FC59E);
    }
  }

  void _writeReview(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewPage(reservation: reservation),
      ),
    );

    // 리뷰 작성 성공 시 목록 새로고침
    if (result == true) {
      onRefresh();
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
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC59E),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
