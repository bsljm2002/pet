import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/consultation_record.dart';
import 'api_service.dart';

/// 상담 관련 API 서비스
class ConsultationService {
  static const String _baseUrl = ApiService.baseUrl;

  /// 독립적인 상담 생성 (예약 없이)
  Future<int> createConsultation({
    required int userId,
    required int partnerId,
    required String petType,
    required String subject,
    required String content,
    String? imageUrl,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/consultations');

      final requestBody = {
        'userId': userId,
        'partnerId': partnerId,
        'petType': petType,
        'subject': subject,
        'content': content,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

      print('📡 [DEBUG] 상담 생성 API 호출: $url');
      print('📡 [DEBUG] 요청 Body: ${json.encode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode(requestBody),
      );

      print('📡 [DEBUG] 응답 상태 코드: ${response.statusCode}');
      print('📡 [DEBUG] 응답 Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(
          utf8.decode(response.bodyBytes),
        );
        if (jsonData['ok'] == true && jsonData['data'] != null) {
          return jsonData['data']['id'] as int;
        }
      }

      throw Exception('상담 생성 실패: ${response.statusCode}');
    } catch (e) {
      print('❌ 상담 생성 오류: $e');
      rethrow;
    }
  }

  /// 특정 상담 조회
  Future<ConsultationRecord> getConsultation(int consultationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/consultations/$consultationId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok'] == true && jsonData['data'] != null) {
          return ConsultationRecord.fromJson(jsonData['data']);
        }
      }
      throw Exception('상담 조회 실패: ${response.statusCode}');
    } catch (e) {
      print('❌ 상담 조회 오류: $e');
      rethrow;
    }
  }

  /// 사용자의 모든 상담 조회
  Future<List<ConsultationRecord>> getUserConsultations(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/consultations/user/$userId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => ConsultationRecord.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ 사용자 상담 내역 조회 오류: $e');
      return [];
    }
  }

  /// 파트너의 모든 상담 조회
  Future<List<ConsultationRecord>> getPartnerConsultations(int partnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/consultations/partner/$partnerId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> data = jsonData['data'];
          return data.map((json) => ConsultationRecord.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ 파트너 상담 내역 조회 오류: $e');
      return [];
    }
  }

  /// 상담 답변 추가 (파트너용)
  Future<ConsultationRecord> addAnswer({
    required int consultationId,
    required String answer,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/consultations/$consultationId/answer'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'answer': answer,
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok'] == true && jsonData['data'] != null) {
          return ConsultationRecord.fromJson(jsonData['data']);
        }
      }
      throw Exception('답변 추가 실패: ${response.statusCode}');
    } catch (e) {
      print('❌ 답변 추가 오류: $e');
      rethrow;
    }
  }

  /// 상담 취소
  Future<void> cancelConsultation(int consultationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/consultations/$consultationId'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonData['ok'] != true) {
          throw Exception('상담 취소 실패');
        }
      } else {
        throw Exception('상담 취소 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 상담 취소 오류: $e');
      rethrow;
    }
  }
}
