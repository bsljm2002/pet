import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class PetService {
  static final PetService _instance = PetService._internal();
  factory PetService() => _instance;
  PetService._internal();

  static const String baseUrl = "http://192.168.70.107:9075/api/v1/pets";

  /// 펫 프로필 등록 API 호출
  Future<Map<String, dynamic>> createPet({
    required String userId,
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
  Future<Map<String, dynamic>> getPetsByOwner(String userId) async {
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

  /// 펫 이미지 업로드
  Future<Map<String, dynamic>> uploadPetImage(
    String ownerId,
    File imageFile,
  ) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/image'));

      // ownerId 파라미터 추가
      request.fields['ownerId'] = ownerId;

      // 이미지 파일 추가 (확장자에 따라 Content-Type 자동 설정)
      String? mimeType;
      String ext = imageFile.path.split('.').last.toLowerCase();
      if (ext == 'jpg' || ext == 'jpeg') {
        mimeType = 'image/jpeg';
      } else if (ext == 'png') {
        mimeType = 'image/png';
      } else {
        mimeType = 'image/jpeg'; // 기본값
      }

      var multipartFile = await http.MultipartFile.fromPath(
        'file',
        imageFile.path,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      print("업로드 파일 경로: ${imageFile.path}");
      print("파일 확장자: $ext, MIME 타입: $mimeType");

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print("이미지 업로드 응답 코드: ${response.statusCode}");
      print("이미지 업로드 응답 내용: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {"success": true, "imageUrl": data["data"]["imageUrl"]};
        } else {
          return {"success": false, "message": data["message"]};
        }
      } else {
        String errorMsg = "이미지 업로드 실패 (${response.statusCode})";
        try {
          final errorData = jsonDecode(response.body);
          errorMsg += ": ${errorData['message'] ?? response.body}";
        } catch (e) {
          errorMsg += ": ${response.body}";
        }
        return {"success": false, "message": errorMsg};
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }

  /// 개별 펫 조회
  Future<Map<String, dynamic>> getPetById(int petId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$petId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {"success": true, "pet": data["data"]};
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

  /// 펫 프로필 삭제
  Future<Map<String, dynamic>> deletePet(int petId) async {
    try {
      print("삭제 요청: Pet ID = $petId");
      print("삭제 URL: $baseUrl/$petId");

      final response = await http.delete(
        Uri.parse('$baseUrl/$petId'),
        headers: {"Content-Type": "application/json"},
      );

      print("삭제 응답 코드: ${response.statusCode}");
      print("삭제 응답 내용: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["ok"] == true) {
          return {"success": true, "message": "펫 프로필이 삭제되었습니다."};
        } else {
          return {"success": false, "message": data["message"]};
        }
      } else {
        return {"success": false, "message": "삭제 실패 (${response.statusCode})"};
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }
}
