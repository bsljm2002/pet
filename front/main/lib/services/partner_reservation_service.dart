import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/partner_reservation_model.dart';
import 'api_service.dart';

class PartnerReservationService {
  /// 파트너가 받은 예약 목록 조회
  Future<List<PartnerReservationModel>> getPartnerReservations(
    int partnerId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/reservations/partner?partnerId=$partnerId',
      );

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> reservationsList = jsonData['data'];
          return reservationsList.map((item) {
            // MyReservationRes를 PartnerReservationModel로 변환
            return PartnerReservationModel(
              reservationId: item['reservationId'] ?? 0,
              userId: item['userId'] ?? 0,
              userName: item['userName'] ?? '',
              petId: item['petId'],
              petName: item['petName'],
              serviceType: item['serviceType'] ?? '',
              status: item['status'] ?? 'WAITING',
              createdAt: _parseDateTime(item['date'], item['hour']),
              reservationContent: item['reservationContent'],
              specialties: item['specialties'] != null
                  ? List<String>.from(item['specialties'])
                  : [],
            );
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('파트너 예약 목록 조회 오류: $e');
      return [];
    }
  }

  /// 예약 확정
  Future<bool> acceptReservation(int reservationId, int partnerId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/reservations/$reservationId/accept?partner_id=$partnerId',
      );

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData['ok'] == true;
      }

      return false;
    } catch (e) {
      print('예약 확정 오류: $e');
      return false;
    }
  }

  /// 예약 거절 (거절 사유 포함)
  Future<bool> rejectReservation(
    int reservationId,
    int partnerId,
    String? reason,
  ) async {
    try {
      var url = Uri.parse(
        '${ApiService.baseUrl}/reservations/$reservationId/reject?partnerId=$partnerId',
      );

      // 거절 사유가 있으면 쿼리 파라미터에 추가
      if (reason != null && reason.isNotEmpty) {
        url = Uri.parse(
          '${ApiService.baseUrl}/reservations/$reservationId/reject?partnerId=$partnerId&reason=${Uri.encodeComponent(reason)}',
        );
      }

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData['ok'] == true;
      }

      return false;
    } catch (e) {
      print('예약 거절 오류: $e');
      return false;
    }
  }

  /// 진료/서비스 완료
  Future<bool> completeReservation(
    int reservationId,
    int partnerId,
  ) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/reservations/$reservationId/complete?partnerId=$partnerId',
      );

      print('📡 [DEBUG] 예약 완료 API 호출: $url');
      print('📡 [DEBUG] reservationId: $reservationId, partnerId: $partnerId');

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 [DEBUG] 응답 상태 코드: ${response.statusCode}');
      print('📡 [DEBUG] 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        print('📡 [DEBUG] 파싱된 JSON: $jsonData');
        return jsonData['ok'] == true;
      }

      print('❌ [DEBUG] 응답 코드가 200이 아님');
      return false;
    } catch (e) {
      print('❌ 예약 완료 오류: $e');
      return false;
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

      final response = await http.patch(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        return jsonData['ok'] == true;
      }

      return false;
    } catch (e) {
      print('예약 취소 오류: $e');
      return false;
    }
  }

  /// 날짜와 시간을 DateTime으로 변환
  DateTime _parseDateTime(String? date, int? hour) {
    try {
      if (date != null) {
        // 날짜 형식: "yyyy.MM.dd"
        final parts = date.split('.');
        if (parts.length == 3) {
          final year = int.parse(parts[0]);
          final month = int.parse(parts[1]);
          final day = int.parse(parts[2]);
          return DateTime(year, month, day, hour ?? 0);
        }
      }
    } catch (e) {
      print('날짜 파싱 오류: $e');
    }
    return DateTime.now();
  }
}
