import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';

/// 파트너(병원/펫시터) 위치를 보여주는 카카오맵 위젯
class PartnerMapWidget extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final double? latitude;
  final double? longitude;

  const PartnerMapWidget({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.latitude,
    this.longitude,
  });

  @override
  State<PartnerMapWidget> createState() => _PartnerMapWidgetState();
}

class _PartnerMapWidgetState extends State<PartnerMapWidget> {
  late KakaoMapController mapController;
  Set<Marker> markers = {};

  /// 마커 초기화 - 맵 생성 후 호출
  void _initializeMarker() {
    if (widget.latitude != null && widget.longitude != null) {
      print('🗺️ [MAP] 파트너 마커 초기화');
      print('  - ID: ${widget.partnerId}');
      print('  - 이름: ${widget.partnerName}');
      print('  - 위도: ${widget.latitude}');
      print('  - 경도: ${widget.longitude}');

      final marker = Marker(
        markerId: widget.partnerId,
        latLng: LatLng(widget.latitude!, widget.longitude!),
        width: 30,
        height: 44,
        markerImageSrc:
            'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
      );

      setState(() {
        markers.add(marker);
      });

      print('  ✅ 마커 추가 완료 (총 ${markers.length}개)');
    } else {
      print('⚠️ [MAP] 위치 정보 없음');
    }
  }

  /// 카카오내비로 길안내 시작
  Future<void> _launchKakaoNavi() async {
    if (widget.latitude == null || widget.longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보가 없습니다.')),
      );
      return;
    }

    // 카카오내비 앱 실행 URL
    final naviUrl = Uri.parse(
      'kakaomap://route?'
      'ep=${widget.latitude},${widget.longitude}&'
      'by=CAR',
    );

    // 카카오맵 웹 길찾기 URL (앱이 없을 경우)
    final webUrl = Uri.parse(
      'https://map.kakao.com/link/to/'
      '${Uri.encodeComponent(widget.partnerName)},'
      '${widget.latitude},${widget.longitude}',
    );

    try {
      // 카카오내비 앱 실행 시도
      if (await canLaunchUrl(naviUrl)) {
        await launchUrl(naviUrl, mode: LaunchMode.externalApplication);
      } else {
        // 앱이 없으면 웹 버전 실행
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl, mode: LaunchMode.externalApplication);
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('길 안내를 실행할 수 없습니다.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 위치 정보가 없는 경우
    if (widget.latitude == null || widget.longitude == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                '위치 정보가 등록되지 않았습니다.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 지도
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.hardEdge,
          child: KakaoMap(
            onMapCreated: (controller) {
              mapController = controller;
              print('🗺️ [MAP] 카카오맵 생성 완료, 마커 초기화 시작');
              _initializeMarker();
            },
            center: LatLng(widget.latitude!, widget.longitude!),
            markers: markers.toList(),
          ),
        ),

        const SizedBox(height: 16),

        // 지도 컨트롤 버튼들
        Row(
          children: [
            // 확대 버튼
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final currentLevel = await mapController.getLevel();
                  if (currentLevel > 1) {
                    await mapController.setLevel(currentLevel - 1);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4FC59E),
                  side: const BorderSide(color: Color(0xFF4FC59E)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('확대'),
              ),
            ),
            const SizedBox(width: 12),

            // 축소 버튼
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final currentLevel = await mapController.getLevel();
                  if (currentLevel < 14) {
                    await mapController.setLevel(currentLevel + 1);
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF4FC59E),
                  side: const BorderSide(color: Color(0xFF4FC59E)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.remove),
                label: const Text('축소'),
              ),
            ),
            const SizedBox(width: 12),

            // 길 안내 버튼
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _launchKakaoNavi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC59E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.navigation),
                label: const Text(
                  '길 안내',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
