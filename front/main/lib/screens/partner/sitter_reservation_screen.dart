import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/partner_service.dart';
import '../../services/partner_reservation_service.dart';
import '../../models/partner_reservation_model.dart';

/// 펫시터 예약 상담 화면
class SitterReservationScreen extends StatefulWidget {
  const SitterReservationScreen({super.key});

  @override
  State<SitterReservationScreen> createState() =>
      _SitterReservationScreenState();
}

class _SitterReservationScreenState extends State<SitterReservationScreen> {
  final AuthService _authService = AuthService();
  final PartnerService _partnerService = PartnerService();
  final PartnerReservationService _reservationService =
      PartnerReservationService();

  List<PartnerReservationModel> _reservations = [];
  bool _isLoading = true;
  String _selectedFilter =
      'WAITING'; // WAITING, CONFIRMED, COMPLETED, CANCELLED (기본값: 대기중)

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final userId = int.parse(currentUser.id);

        // 파트너 프로필 가져오기
        final partners = await _partnerService.getMyPartners(userId);
        print('🔍 [DEBUG] 조회된 파트너 수: ${partners.length}');
        if (partners.isNotEmpty) {
          final partnerId = partners.first.id;
          print('🔍 [DEBUG] 사용 중인 Partner ID: $partnerId');
          print('🔍 [DEBUG] 파트너 이름: ${partners.first.name}');
          if (partnerId == null) {
            print('⚠️ [DEBUG] Partner ID가 null입니다!');
            setState(() {
              _reservations = [];
              _isLoading = false;
            });
            return;
          }

          // 예약 목록 조회
          print(
            '📡 [DEBUG] API 호출: /reservations/partner?partnerId=$partnerId',
          );
          final reservations = await _reservationService.getPartnerReservations(
            partnerId,
          );
          print('✅ [DEBUG] 받은 예약 수: ${reservations.length}');

          setState(() {
            _reservations = reservations;
            _isLoading = false;
          });
        } else {
          setState(() {
            _reservations = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('예약 목록 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<PartnerReservationModel> _getFilteredReservations() {
    if (_selectedFilter == 'CANCELLED') {
      // 취소됨 필터: 사용자 취소, 파트너 거절 모두 포함
      return _reservations
          .where(
            (reservation) =>
                reservation.status == 'CANCELLED_BY_USER' ||
                reservation.status == 'CANCELLED_BY_BIZ',
          )
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
        title: const Text('예약 관리'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 필터 탭
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                : filteredReservations.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadReservations,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredReservations.length,
                      itemBuilder: (context, index) {
                        return _buildReservationCard(
                          filteredReservations[index],
                        );
                      },
                    ),
                  ),
          ),
        ],
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
      selectedColor: const Color(0xFF4FC59E).withValues(alpha: 0.3),
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: const Color(0xFF003829),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003829) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'ALL' ? '예약이 없습니다' : '해당 상태의 예약이 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            '고객의 예약 요청을 기다리고 있습니다',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(PartnerReservationModel reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          _showReservationDetail(reservation);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 배지
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(reservation.status),
                  Text(
                    reservation.formattedDate,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 고객 정보
              Row(
                children: [
                  const Icon(Icons.person, size: 20, color: Color(0xFF4FC59E)),
                  const SizedBox(width: 8),
                  Text(
                    reservation.userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 예약 시간
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 20,
                    color: Color(0xFF4FC59E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${reservation.timeSlot} ${reservation.formattedTime}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 펫 정보
              if (reservation.petName != null &&
                  reservation.petName!.isNotEmpty)
                Row(
                  children: [
                    const Icon(Icons.pets, size: 20, color: Color(0xFF4FC59E)),
                    const SizedBox(width: 8),
                    Text(
                      reservation.petName!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),

              // 서비스 유형
              if (reservation.specialties.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: reservation.specialties.map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF003829),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // 버튼
              if (reservation.status == 'WAITING') ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _rejectReservation(reservation);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        child: const Text('거절'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _confirmReservation(reservation);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC59E),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('확정'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;

    switch (status) {
      case 'WAITING':
        color = Colors.orange;
        text = '대기중';
        break;
      case 'CONFIRMED':
        color = const Color(0xFF4FC59E);
        text = '확정됨';
        break;
      case 'COMPLETED':
        color = Colors.blue;
        text = '완료됨';
        break;
      case 'CANCELLED_BY_USER':
      case 'CANCELLED_BY_BIZ':
        color = Colors.red;
        text = '취소됨';
        break;
      default:
        color = Colors.grey;
        text = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showReservationDetail(PartnerReservationModel reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '예약 상세',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow('상태', _buildStatusBadge(reservation.status)),
                  _buildDetailRow('고객명', Text(reservation.userName)),
                  _buildDetailRow('예약일', Text(reservation.formattedDate)),
                  _buildDetailRow(
                    '예약시간',
                    Text(
                      '${reservation.timeSlot} ${reservation.formattedTime}',
                    ),
                  ),
                  if (reservation.petName != null &&
                      reservation.petName!.isNotEmpty)
                    _buildDetailRow('반려동물', Text(reservation.petName!)),
                  if (reservation.specialties.isNotEmpty)
                    _buildDetailRow(
                      '서비스',
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: reservation.specialties.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF4FC59E,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              service,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF003829),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  if (reservation.reservationContent != null &&
                      reservation.reservationContent!.isNotEmpty)
                    _buildDetailRow(
                      '요청사항',
                      Text(reservation.reservationContent!),
                    ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC59E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('닫기'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ),
          Expanded(child: value),
        ],
      ),
    );
  }

  void _confirmReservation(PartnerReservationModel reservation) async {
    // 확인 다이얼로그
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 확정'),
        content: Text('${reservation.userName}님의 예약을 확정하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4FC59E),
              foregroundColor: Colors.white,
            ),
            child: const Text('확정'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // 파트너 ID 가져오기
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      final userId = int.parse(currentUser.id);
      final partners = await _partnerService.getMyPartners(userId);
      if (partners.isEmpty || partners.first.id == null) return;

      final partnerId = partners.first.id!;

      // 예약 확정 API 호출
      final success = await _reservationService.acceptReservation(
        reservation.reservationId,
        partnerId,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약이 확정되었습니다'),
            backgroundColor: Color(0xFF4FC59E),
          ),
        );
        await _loadReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 확정에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _rejectReservation(PartnerReservationModel reservation) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예약 거절'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('이 예약을 거절하시겠습니까?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거절 사유 (선택)',
                hintText: '고객에게 전달될 거절 사유를 입력하세요',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              reasonController.dispose();
              Navigator.pop(context);
            },
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reason = reasonController.text.trim();
              reasonController.dispose();
              Navigator.pop(context);

              // 파트너 ID 가져오기
              final currentUser = _authService.currentUser;
              if (currentUser == null) return;

              final userId = int.parse(currentUser.id);
              final partners = await _partnerService.getMyPartners(userId);
              if (partners.isEmpty || partners.first.id == null) return;

              final partnerId = partners.first.id!;

              // 예약 거절 API 호출
              final success = await _reservationService.rejectReservation(
                reservation.reservationId,
                partnerId,
                reason.isNotEmpty ? reason : null,
              );

              if (success) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('예약이 거절되었습니다')));
                }
                _loadReservations();
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('예약 거절에 실패했습니다')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('거절'),
          ),
        ],
      ),
    );
  }
}
