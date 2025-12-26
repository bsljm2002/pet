import 'dart:convert';
import 'package:http/http.dart' as http;

/// 센서 데이터 모델
class SensorData {
  final double temperature;  // 온도 (°C)
  final double humidity;      // 습도 (%)
  final double gasRaw;        // 공기질 지수

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.gasRaw,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    final latest = json['latest'];
    return SensorData(
      temperature: (latest['temperature'] ?? 0.0).toDouble(),
      humidity: (latest['humidity'] ?? 0.0).toDouble(),
      gasRaw: (latest['gas_raw'] ?? 0.0).toDouble(),
    );
  }

  /// 공기질을 상태 텍스트로 변환
  String get airQualityText {
    if (gasRaw < 300) return '좋음';
    if (gasRaw < 500) return '보통';
    if (gasRaw < 700) return '나쁨';
    return '매우 나쁨';
  }

  /// 공기질 상태 색상
  String get airQualityColor {
    if (gasRaw < 300) return '#4CAF50'; // 초록
    if (gasRaw < 500) return '#FFC107'; // 노랑
    if (gasRaw < 700) return '#FF9800'; // 주황
    return '#F44336'; // 빨강
  }
}

/// 센서 데이터 조회 서비스
class SensorService {
  static const String baseUrl = 'http://223.130.130.225:1286';

  /// 최신 센서 데이터 조회
  Future<SensorData?> getLatestSensorData({String? deviceId}) async {
    try {
      final url = deviceId != null
          ? '$baseUrl/sensors/latest?device_id=$deviceId'
          : '$baseUrl/sensors/latest';

      print('📡 [SensorService] API 호출: $url');

      final response = await http.get(Uri.parse(url));

      print('📡 [SensorService] 응답 코드: ${response.statusCode}');
      print('📡 [SensorService] 응답 내용: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return SensorData.fromJson(data);
      } else {
        print('❌ [SensorService] 센서 데이터 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [SensorService] 오류: $e');
      return null;
    }
  }

  /// 집계 데이터 조회 (시간별 평균)
  Future<Map<String, dynamic>?> getAggregateData({String? deviceId}) async {
    try {
      final url = deviceId != null
          ? '$baseUrl/sensors/aggregates?device_id=$deviceId'
          : '$baseUrl/sensors/aggregates';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('❌ [SensorService] 집계 데이터 조회 실패: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ [SensorService] 오류: $e');
      return null;
    }
  }
}
