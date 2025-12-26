import 'package:flutter/material.dart';
import 'dart:async';
import '../../models/partner_reservation_model.dart';
import '../../services/location_tracking_service.dart';

/// 펫시터용 고객 위치 확인 페이지
class SitterCustomerLocationPage extends StatefulWidget {
  final PartnerReservationModel reservation;

  const SitterCustomerLocationPage({super.key, required this.reservation});

  @override
  State<SitterCustomerLocationPage> createState() =>
      _SitterCustomerLocationPageState();
}

class _SitterCustomerLocationPageState
    extends State<SitterCustomerLocationPage> {
  final LocationTrackingService _locationService = LocationTrackingService();

  StreamSubscription<Map<String, dynamic>?>? _userLocationSubscription;

  double? _userLatitude;
  double? _userLongitude;
  String? _userAddress;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  @override
  void dispose() {
    _userLocationSubscription?.cancel();
    super.dispose();
  }

  /// 고객 위치 로드
  void _loadUserLocation() {
    _userLocationSubscription = _locationService
        .getUserLocationStream(widget.reservation.reservationId)
        .listen((locationData) {
      if (locationData != null && mounted) {
        setState(() {
          _userLatitude = locationData['latitude'] as double?;
          _userLongitude = locationData['longitude'] as double?;
        });

        print('📍 [파트너] 고객 위치 로드: $_userLatitude, $_userLongitude');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('고객 위치'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 예약 정보 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      color: Color(0xFF4FC59E),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${widget.reservation.userName}님',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      color: Color(0xFF4FC59E),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.reservation.formattedDate} ${widget.reservation.timeSlot}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF003829),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 위치 정보 카드
          Expanded(
            child: _userLatitude != null && _userLongitude != null
                ? _buildLocationInfo()
                : _buildLoadingState(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInfo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '고객 서비스 위치',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F7F1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF4FC59E).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildLocationRow(
                  Icons.my_location,
                  '위도',
                  _userLatitude!.toStringAsFixed(6),
                ),
                const SizedBox(height: 16),
                _buildLocationRow(
                  Icons.my_location,
                  '경도',
                  _userLongitude!.toStringAsFixed(6),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                // 지도 앱으로 열기 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: 지도 앱으로 열기 (카카오맵, 네이버맵 등)
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('지도 앱 연동 기능은 추후 추가 예정입니다'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map),
                    label: const Text('지도 앱으로 열기'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC59E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 좌표 복사 버튼
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // 좌표를 클립보드에 복사
                      final coords = '$_userLatitude, $_userLongitude';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('좌표가 복사되었습니다: $coords'),
                          backgroundColor: const Color(0xFF4FC59E),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('좌표 복사'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4FC59E),
                      side: const BorderSide(color: Color(0xFF4FC59E)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 안내 문구
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '이 위치는 고객이 예약 시 입력한 서비스 제공 주소입니다.\n해당 위치로 이동하여 서비스를 제공해주세요.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade800,
                      height: 1.5,
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

  Widget _buildLocationRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF4FC59E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
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
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF4FC59E),
          ),
          const SizedBox(height: 24),
          Text(
            '고객의 위치 정보를 불러오는 중...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '잠시만 기다려주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
