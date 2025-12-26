import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/vet_model.dart';
import '../models/sitter_model.dart';

/// VetService
/// 수의사/펫시터 관련 API 통신 서비스
class VetService {
  static final VetService _instance = VetService._internal();
  factory VetService() => _instance;
  VetService._internal();

  // 백엔드 서버 URL
  static const String baseUrl = "http://223.130.130.225:9075/api/v1/partners";

  /// 수의사 목록 조회
  ///
  /// [specialty] - 전문분야 필터 (선택)
  Future<Map<String, dynamic>> getVets({String? specialty}) async {
    try {
      // 쿼리 파라미터 구성
      Map<String, String> queryParams = {'type': 'HOSPITAL'};
      if (specialty != null && specialty.isNotEmpty) {
        queryParams['specialty'] = specialty;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('수의사 목록 조회 - 상태 코드: ${response.statusCode}');
      print('수의사 목록 조회 - 응답: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final List<dynamic> vetList = data['data'] as List;
          print('수의사 원본 JSON 데이터 샘플: ${vetList.isNotEmpty ? vetList[0] : "비어있음"}');
          final vets = vetList.map((json) => VetModel.fromJson(json)).toList();
          if (vets.isNotEmpty) {
            print('변환된 VetModel 샘플 - education: ${vets[0].education}, description: ${vets[0].description}');
          }
          return {'success': true, 'vets': vets};
        } else {
          return {'success': false, 'message': data['message'] ?? '조회 실패'};
        }
      } else {
        return {'success': false, 'message': '서버 오류 (${response.statusCode})'};
      }
    } catch (e) {
      print('수의사 목록 조회 오류: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// 펫시터 목록 조회
  ///
  /// [service] - 서비스 유형 필터 (선택)
  Future<Map<String, dynamic>> getSitters({String? service}) async {
    try {
      // 쿼리 파라미터 구성
      Map<String, String> queryParams = {'type': 'SITTER'};
      if (service != null && service.isNotEmpty) {
        queryParams['specialty'] = service;
      }

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('펫시터 목록 조회 - 상태 코드: ${response.statusCode}');
      print('펫시터 목록 조회 - 응답: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          final List<dynamic> sitterList = data['data'] as List;
          final sitters =
              sitterList.map((json) => SitterModel.fromJson(json)).toList();
          return {'success': true, 'sitters': sitters};
        } else {
          return {'success': false, 'message': data['message'] ?? '조회 실패'};
        }
      } else {
        return {'success': false, 'message': '서버 오류 (${response.statusCode})'};
      }
    } catch (e) {
      print('펫시터 목록 조회 오류: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// 파트너 상세 조회 (수의사 또는 펫시터)
  ///
  /// [partnerId] - 파트너 ID
  Future<Map<String, dynamic>> getPartnerById(int partnerId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$partnerId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('파트너 상세 조회 - 상태 코드: ${response.statusCode}');
      print('파트너 상세 조회 - 응답: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return {'success': true, 'partner': data['data']};
        } else {
          return {'success': false, 'message': data['message'] ?? '조회 실패'};
        }
      } else {
        return {'success': false, 'message': '서버 오류 (${response.statusCode})'};
      }
    } catch (e) {
      print('파트너 상세 조회 오류: $e');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// 파트너 위치 정보 업데이트
  ///
  /// [partnerId] - 파트너 ID
  /// [latitude] - 위도
  /// [longitude] - 경도
  Future<Map<String, dynamic>> updateLocation(
    int partnerId,
    double latitude,
    double longitude,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$partnerId/location').replace(queryParameters: {
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          return {'success': true, 'message': '위치 정보가 업데이트되었습니다.'};
        } else {
          return {'success': false, 'message': data['message'] ?? '업데이트 실패'};
        }
      } else {
        return {'success': false, 'message': '서버 오류 (${response.statusCode})'};
      }
    } catch (e) {
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }
}
