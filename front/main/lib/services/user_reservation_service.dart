import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_reservation_model.dart';
import 'api_service.dart';

/// 사용자(고객)의 예약 관리 서비스
class UserReservationService {
  /// 내 예약 목록 조회
  Future<List<UserReservationModel>> getMyReservations(
    int userId, {
    String? serviceType, // "HOSPITAL" or "SITTER" (optional filter)
  }) async {
    try {
      var url = Uri.parse(
        '${ApiService.baseUrl}/reservations/mine?userId=$userId',
      );

      // 서비스 타입 필터가 있으면 추가
      if (serviceType != null && serviceType.isNotEmpty) {
        url = Uri.parse(
          '${ApiService.baseUrl}/reservations/mine?userId=$userId&serviceType=$serviceType',
        );
      }

      print('📡 [DEBUG] 내 예약 조회 API 호출: $url');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 [DEBUG] 응답 상태 코드: ${response.statusCode}');
      print('📡 [DEBUG] 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> reservationsList = jsonData['data'];
          return reservationsList.map((item) {
            return UserReservationModel.fromJson(item);
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ 내 예약 목록 조회 오류: $e');
      return [];
    }
  }

  /// 예약 취소 (사용자)
  Future<bool> cancelReservation(
    int reservationId,
    int userId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/reservations/$reservationId/cancel?userId=$userId',
      );

      print('📡 [DEBUG] 예약 취소 API 호출: $url');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 [DEBUG] 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData['ok'] == true;
      }

      return false;
    } catch (e) {
      print('❌ 예약 취소 오류: $e');
      return false;
    }
  }
}
