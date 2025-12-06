import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/partner_profile_model.dart';

class PartnerService {
  static const String baseUrl = 'http://223.130.130.225:9075/api/v1/partners';

  /// 파트너 프로필 생성
  Future<int?> createPartner(PartnerProfileModel profile) async {
    try {
      print('=== 파트너 생성 API 호출 ===');
      print('URL: $baseUrl');
      print('요청 데이터: ${json.encode(profile.toJson())}');

      final response = await http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(profile.toJson()),
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final partnerId = jsonResponse['data']['partnerId'] as int?;
        print('생성된 partnerId: $partnerId');
        return partnerId;
      } else {
        print('파트너 생성 실패: ${response.statusCode}');
        throw Exception('Failed to create partner');
      }
    } catch (e, stackTrace) {
      print('Error creating partner: $e');
      print('스택 트레이스: $stackTrace');
      return null;
    }
  }

  /// 파트너 프로필 수정
  Future<PartnerProfileModel?> updatePartner(
    int partnerId,
    PartnerProfileModel profile,
  ) async {
    try {
      print('=== 파트너 수정 API 호출 ===');
      print('URL: $baseUrl/$partnerId/profile');
      final requestBody = profile.toJson();
      print('요청 데이터: ${json.encode(requestBody)}');
      print('galleryImages in request: ${requestBody['galleryImages']}');

      final response = await http.put(
        Uri.parse('$baseUrl/$partnerId/profile'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PartnerProfileModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to update partner');
      }
    } catch (e) {
      print('Error updating partner: $e');
      return null;
    }
  }

  /// 파트너 프로필 조회
  Future<PartnerProfileModel?> getPartnerDetail(int partnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$partnerId/detail'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        return PartnerProfileModel.fromJson(jsonResponse['data']);
      } else {
        throw Exception('Failed to load partner');
      }
    } catch (e) {
      print('Error loading partner: $e');
      return null;
    }
  }

  /// 사용자의 파트너 목록 조회
  Future<List<PartnerProfileModel>> getMyPartners(int userId) async {
    try {
      final url = '$baseUrl/my?userId=$userId';
      print('=== 파트너 목록 조회 API 호출 ===');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      print('응답 코드: ${response.statusCode}');
      print('응답 본문: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];
        print('파트너 수: ${data.length}');

        final partners = data
            .map((json) => PartnerProfileModel.fromJson(json))
            .toList();

        return partners;
      } else {
        print('파트너 목록 조회 실패: ${response.statusCode}');
        throw Exception('Failed to load my partners');
      }
    } catch (e, stackTrace) {
      print('Error loading my partners: $e');
      print('스택 트레이스: $stackTrace');
      return [];
    }
  }

  /// 파트너 삭제
  Future<bool> deletePartner(int partnerId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$partnerId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting partner: $e');
      return false;
    }
  }

  /// 영업 상태 토글
  Future<bool> toggleOpen(int partnerId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$partnerId/toggle-open'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error toggling open status: $e');
      return false;
    }
  }
}
