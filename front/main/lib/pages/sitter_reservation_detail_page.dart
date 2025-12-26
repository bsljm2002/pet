import 'package:flutter/material.dart';
import 'dart:async';

import '../models/user_reservation_model.dart';
import '../services/location_tracking_service.dart';

/// 펫시터 예약 상세 페이지 (위치 추적 포함)
class SitterReservationDetailPage extends StatefulWidget {
  final UserReservationModel reservation;

  const SitterReservationDetailPage({super.key, required this.reservation});

  @override
  State<SitterReservationDetailPage> createState() =>
      _SitterReservationDetailPageState();
}

class _SitterReservationDetailPageState
    extends State<SitterReservationDetailPage> {
  final LocationTrackingService _locationService = LocationTrackingService();

  StreamSubscription<Map<String, dynamic>?>? _locationSubscription;

  double? _sitterLatitude; // 펫시터 현재 위도
  double? _sitterLongitude; // 펫시터 현재 경도
  DateTime? _lastUpdateTime; // 마지막 업데이트 시간

  @override
  void initState() {
    super.initState();
    _initializeTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  /// 위치 추적 초기화
  void _initializeTracking() {
    // 예약이 확정된 경우에만 위치 추적 시작
    if (widget.reservation.status == 'CONFIRMED') {
      _startLocationTracking();
    }
  }

  /// 펫시터 위치 실시간 추적
  void _startLocationTracking() {
    _locationSubscription = _locationService
        .getSitterLocationStream(widget.reservation.reservationId)
        .listen((locationData) {
      if (locationData != null && mounted) {
        setState(() {
          _sitterLatitude = locationData['latitude'] as double?;
          _sitterLongitude = locationData['longitude'] as double?;
          _lastUpdateTime = DateTime.now();
        });

        print(
          '📍 [위치추적] 펫시터 위치 업데이트: $_sitterLatitude, $_sitterLongitude',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 224),
      appBar: AppBar(
        title: const Text('펫시터 예약 상세'),
        backgroundColor: const Color.fromARGB(255, 252, 255, 224),
        foregroundColor: const Color.fromARGB(255, 11, 114, 87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 예약 정보 카드
            _buildReservationInfoCard(),
            const SizedBox(height: 16),

            // 위치 추적 카드 (확정된 예약만)
            if (widget.reservation.status == 'CONFIRMED')
              _buildLocationTrackingCard(),

            const SizedBox(height: 16),

            // 펫시터 정보 카드
            _buildSitterInfoCard(),
            const SizedBox(height: 16),

            // 요청사항 카드
            if (widget.reservation.reservationContent != null &&
                widget.reservation.reservationContent!.isNotEmpty)
              _buildMemoCard(),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '예약 정보',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              _buildStatusBadge(widget.reservation.status),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.calendar_today, '예약 날짜',
              widget.reservation.formattedDate),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.access_time, '예약 시간',
              widget.reservation.formattedTime),
          const SizedBox(height: 12),
          if (widget.reservation.petName != null)
            _buildInfoRow(Icons.pets, '반려동물', widget.reservation.petName!),
        ],
      ),
    );
  }

  Widget _buildLocationTrackingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF4FC59E),
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '펫시터 실시간 위치',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_sitterLatitude != null && _sitterLongitude != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Color(0xFF4FC59E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '위도',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _sitterLatitude!.toStringAsFixed(6),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003829),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        color: Color(0xFF4FC59E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '경도',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              _sitterLongitude!.toStringAsFixed(6),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF003829),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_lastUpdateTime != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          color: Color(0xFF4FC59E),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '최근 업데이트: ${_lastUpdateTime!.hour}:${_lastUpdateTime!.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '펫시터가 이동 중입니다. 실시간으로 위치가 업데이트됩니다.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_empty,
                    color: Colors.grey,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '펫시터의 위치 정보를 기다리는 중입니다...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSitterInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '펫시터 정보',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFE6F7F1),
                child: const Icon(
                  Icons.person,
                  size: 30,
                  color: Color(0xFF4FC59E),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.reservation.partnerName ?? '펫시터',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (widget.reservation.specialties.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.reservation.specialties.map((service) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMemoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요청사항',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.reservation.reservationContent ?? '',
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4FC59E)),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
      ],
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
}
