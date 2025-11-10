import 'dart:convert';
import 'package:http/http.dart' as http;

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  static const String baseUrl = "http://10.0.2.2:9075/api/v1/pets";

  /// 펫 프로필 등록 API 호출
  Future<Map<String, dynamic>> createPet({
    required int userId,
    required String name,
    required String species, // "DOG" or "CAT"
    required String birthdate, // "yyyy-MM-dd"
    required double weight, // 몸무게 (kg)
    required String abitTypeCode, // ABTI코드
    required String gender, // 성별
    String? speciesDetail, // 품
    String? imageUrl, // 나중에 구현
  }) async {
    final url = Uri.parse(baseUrl);

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "name": name,
          "species": species,
          "birthdate": birthdate,
          "weight": weight,
          "abitTypeCode": abitTypeCode,
          "gender": gender,
          "speciesDetail": speciesDetail,
          "imageUrl": imageUrl, // null이면 백엔드에서 처리
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {
            "success": true,
            "message": "펫 프로필이 등록되었습니다.",
            "petId": data["data"]["id"],
          };
        } else {
          return {
            "success": false,
            "message": data["message"] ?? "펫 프로필 등록 실패",
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "서버 오류 (${response.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }

  /// 사용자의 펫 목록 조회
  Future<Map<String, dynamic>> getPetsByOwner(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl?ownerId=$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {"success": true, "pets": data["data"] as List};
        } else {
          return {"success": false, "message": data["message"]};
        }
      } else {
        return {"success": false, "message": "조회 실패 (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }
}
