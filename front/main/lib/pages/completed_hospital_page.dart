import 'package:flutter/material.dart';
import '../models/completed_reservation_model.dart';
import '../services/completed_reservation_service.dart';

class CompletedHospitalPage extends StatefulWidget {
  final int userId;

  const CompletedHospitalPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CompletedHospitalPage> createState() => _CompletedHospitalPageState();
}

class _CompletedHospitalPageState extends State<CompletedHospitalPage> {
  final CompletedReservationService _service = CompletedReservationService();
  List<CompletedReservationModel> _reservations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
    });

    final reservations =
        await _service.getCompletedHospitalReservations(widget.userId);

    setState(() {
      _reservations = reservations;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('받은 진료 내역'),
        backgroundColor: const Color(0xFF4A90E2),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reservations.isEmpty
              ? const Center(
                  child: Text(
                    '받은 진료 내역이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadReservations,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = _reservations[index];
                      return _buildReservationCard(reservation);
                    },
                  ),
                ),
    );
  }

  Widget _buildReservationCard(CompletedReservationModel reservation) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation.partnerName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A90E2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.partnerType == 'VET' ? '수의사' : '병원',
                    style: const TextStyle(
                      color: Color(0xFF4A90E2),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  '${reservation.formattedDate} ${reservation.timeSlot} ${reservation.formattedTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: reservation.hasReview
                    ? null
                    : () {
                        // TODO: Navigate to review write page
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('리뷰 작성 페이지로 이동'),
                          ),
                        );
                      },
                icon: Icon(
                  reservation.hasReview ? Icons.check_circle : Icons.rate_review,
                ),
                label: Text(
                  reservation.hasReview ? '리뷰 작성 완료' : '리뷰 작성하기',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: reservation.hasReview
                      ? Colors.grey
                      : const Color(0xFF4A90E2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
