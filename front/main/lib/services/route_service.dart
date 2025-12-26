import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:kakao_map_plugin/kakao_map_plugin.dart';

/// 경로 안내 서비스
/// OSRM (Open Source Routing Machine) API를 사용하여 실제 도로 경로를 가져옴
class RouteService {
  // OSRM 공개 API 서버
  static const String _baseUrl = 'https://router.project-osrm.org';

  /// 두 위치 사이의 경로를 가져옴
  /// Returns: 경로 좌표 리스트 (LatLng)
  Future<List<LatLng>> getRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      // OSRM API 호출
      // Format: /route/v1/{profile}/{coordinates}
      // profile: driving(자동차), walking(도보), cycling(자전거)
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson',
      );

      print('🗺️ [경로] OSRM API 호출: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final geometry = route['geometry'];
          final coordinates = geometry['coordinates'] as List;

          // GeoJSON 좌표를 LatLng로 변환
          final routePoints = coordinates.map((coord) {
            // GeoJSON은 [lng, lat] 순서
            return LatLng(coord[1] as double, coord[0] as double);
          }).toList();

          print('✅ [경로] 경로 포인트 ${routePoints.length}개 로드됨');

          // 거리와 소요시간 정보
          final distance = route['distance'] / 1000; // 미터 -> km
          final duration = route['duration'] / 60; // 초 -> 분

          print('📍 [경로] 거리: ${distance.toStringAsFixed(1)}km, 소요시간: ${duration.toStringAsFixed(0)}분');

          return routePoints;
        } else {
          print('⚠️ [경로] 경로를 찾을 수 없음: ${data['code']}');
          return [];
        }
      } else {
        print('❌ [경로] API 호출 실패: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ [경로] 오류 발생: $e');
      return [];
    }
  }

  /// 경로 정보 (거리, 소요시간)를 가져옴
  Future<Map<String, dynamic>?> getRouteInfo({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    try {
      final url = Uri.parse(
        '$_baseUrl/route/v1/driving/$startLng,$startLat;$endLng,$endLat',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['code'] == 'Ok' && data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];

          return {
            'distance': route['distance'] / 1000, // km
            'duration': route['duration'] / 60, // 분
          };
        }
      }

      return null;
    } catch (e) {
      print('❌ [경로정보] 오류 발생: $e');
      return null;
    }
  }
}
