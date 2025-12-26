import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medical_record.dart';
import 'api_service.dart';

/// 진료 기록 서비스
class MedicalRecordService {
  /// 반려동물의 진료 기록 조회
  Future<List<MedicalRecord>> getPetMedicalRecords(int petId) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/reservations/pet/$petId/medical-records',
      );

      print('📡 [DEBUG] 진료 기록 조회 API 호출: $url');

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
          final List<dynamic> recordsList = jsonData['data'];
          return recordsList
              .map((item) => MedicalRecord.fromJson(item))
              .toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ 진료 기록 조회 오류: $e');
      return [];
    }
  }

  /// 약 복용 체크 토글
  Future<bool> toggleMedication({
    required int reservationId,
    required int userId,
    required int petId,
    required String medicationKey,
  }) async {
    try {
      final url = Uri.parse(
        '${ApiService.baseUrl}/medication-logs/toggle',
      );

      print('💊 [DEBUG] 약 복용 토글 API 호출: $url');
      print('💊 [DEBUG] 요청 데이터: reservationId=$reservationId, medicationKey=$medicationKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'reservationId': reservationId,
          'userId': userId,
          'petId': petId,
          'medicationKey': medicationKey,
        }),
      );

      print('💊 [DEBUG] 응답 상태 코드: ${response.statusCode}');
      print('💊 [DEBUG] 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          return jsonData['data']['checked'] ?? false;
        }
      }

      return false;
    } catch (e) {
      print('❌ 약 복용 토글 오류: $e');
      return false;
    }
  }
}
