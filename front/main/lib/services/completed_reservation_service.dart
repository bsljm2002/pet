import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/completed_reservation_model.dart';

class CompletedReservationService {
  static const String baseUrl =
      'http://10.0.2.2:9075/api/v1/reservations';

  /// 수의사(병원)에서 받은 진료 내역 조회
  Future<List<CompletedReservationModel>> getCompletedHospitalReservations(
    int userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/completed/hospital?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data
            .map((json) => CompletedReservationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load hospital reservations');
      }
    } catch (e) {
      print('Error fetching hospital reservations: $e');
      return [];
    }
  }

  /// 펫시터에게 받은 도움 내역 조회
  Future<List<CompletedReservationModel>> getCompletedSitterReservations(
    int userId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/completed/sitter?userId=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        return data
            .map((json) => CompletedReservationModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load sitter reservations');
      }
    } catch (e) {
      print('Error fetching sitter reservations: $e');
      return [];
    }
  }
}
