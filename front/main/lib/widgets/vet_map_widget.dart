import 'package:flutter/material.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/vet_model.dart';

/// 수의사/병원 위치를 보여주는 카카오맵 위젯
class VetMapWidget extends StatefulWidget {
  final VetModel vet;

  const VetMapWidget({super.key, required this.vet});

  @override
  State<VetMapWidget> createState() => _VetMapWidgetState();
}

class _VetMapWidgetState extends State<VetMapWidget> {
  late KakaoMapController mapController;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    _initializeMarker();
  }

  /// 마커 초기화
  void _initializeMarker() {
    if (widget.vet.latitude != null && widget.vet.longitude != null) {
      final marker = Marker(
        markerId: widget.vet.id,
        latLng: LatLng(widget.vet.latitude!, widget.vet.longitude!),
        width: 40,
        height: 40,
        offsetX: 20,
        offsetY: 40,
        markerImageSrc:
            'https://t1.daumcdn.net/localimg/localimages/07/mapapidoc/marker_red.png',
      );
      setState(() {
        markers.add(marker);
      });
    }
  }

  /// 카카오내비로 길안내 시작
  Future<void> _launchKakaoNavi() async {
    if (widget.vet.latitude == null || widget.vet.longitude == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('위치 정보가 없습니다.')),
      );
      return;
    }

    // 카카오내비 앱 실행 URL
    final naviUrl = Uri.parse(
      'kakaomap://route?'
      'ep=${widget.vet.latitude},${widget.vet.longitude}&'
      'by=CAR',
    );

    // 카카오맵 웹 길찾기 URL (앱이 없을 경우)
    final webUrl = Uri.parse(
      'https://map.kakao.com/link/to/'
      '${Uri.encodeComponent(widget.vet.name)},'
      '${widget.vet.latitude},${widget.vet.longitude}',
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
    if (widget.vet.latitude == null || widget.vet.longitude == null) {
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
            },
            center: LatLng(widget.vet.latitude!, widget.vet.longitude!),
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
