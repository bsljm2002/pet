import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String baseUrl =
      "http://192.168.70.107:9075/api/v1/users"; // 백엔드 URL (Android 에뮬레이터용)

  User? _currentUser;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // 회원가입 요청
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    required UserType userType,
    String? nickname,
    String? gender,
    DateTime? birthdate,
    String? address,
    String? addressDetail,
    String? addressNote,
    String? companyName,
    String? businessNumber,
  }) async {
    // 백엔드 엔드포인트: POST /api/v1/users
    final url = Uri.parse(baseUrl);

    // 백엔드 UserSignupReq DTO에 맞춰 매핑
    // userType을 대문자로 변환 (GENERAL, HOSPITAL, SITTER 등)
    String backendUserType = userType.toString().split('.').last.toUpperCase();

    final body = jsonEncode({
      "userType": backendUserType,
      "username": username,
      "nickname": nickname ?? username, // nickname이 필수이므로 기본값 설정
      "email": email,
      "password": password,
      "gender": gender ?? "MALE", // 필수 필드이므로 기본값 설정
      "birthdate": birthdate?.toIso8601String().split('T')[0], // yyyy-MM-dd 형식
      "address": address,
      // 백엔드는 tin (사업자번호)를 받음
      "tin": businessNumber,
      // 파트너 타입별 추가 필드 (필요시 null로 전송)
      "caCategorical": null, // "DOG", "CAT", "BOTH" 중 하나
      "vetSpecialty": null, // 병원 전용
      "petsitterWork": null, // 펫시터 전용
      "workingDays": null,
      "workingStartHours": null,
      "workingEndHours": null,
    });

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      // 백엔드 응답: 201 Created 상태 코드
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 백엔드 응답 형식: {"ok": true, "data": {"id": 1}, "error": null, "message": null}
        if (data["ok"] == true) {
          return {
            "success": true,
            "message": "회원가입 성공",
            "userId": data["data"]["id"],
          };
        } else {
          return {"success": false, "message": data["message"] ?? "회원가입 실패"};
        }
      } else {
        // 에러 응답 처리
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "회원가입 실패 (${response.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }

  // 로그인 요청
  // 💡 파라미터명은 username이지만, 실제로는 이메일 값을 받아서 백엔드에 email로 전송합니다
  Future<Map<String, dynamic>> login({
    required String username, // ← 이메일 값을 받습니다 (파라미터명만 username)
    required String password,
  }) async {
    // 1. URL 생성 (baseUrl에 /login 추가)
    final url = Uri.parse("$baseUrl/login");

    try {
      // 2. HTTP POST 요청
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": username, // ✅ 백엔드는 "email" 필드를 기대합니다!
          "password": password,
        }),
      );

      // 3. 응답 처리
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // 백엔드 응답 형식: {"ok": true, "data": {...사용자정보...}}
        if (data["ok"] == true) {
          // 사용자 정보를 User 객체로 변환
          final userData = data["data"];
          _currentUser = User(
            id: userData["id"].toString(),
            username: userData["username"],
            email: userData["email"],
            password: "", // 비밀번호는 저장하지 않음
            nickname: userData["nickname"],
            gender: userData["gender"],
            userType: UserType.values.firstWhere(
              (e) =>
                  e.toString().split('.').last.toUpperCase() ==
                  userData["userType"],
              orElse: () => UserType.general,
            ),
          );

          return {"success": true, "message": "로그인 성공", "user": _currentUser};
        } else {
          return {"success": false, "message": data["message"] ?? "로그인 실패"};
        }
      } else if (response.statusCode == 400) {
        // 400 Bad Request: 이메일/비밀번호 오류
        final errorData = jsonDecode(response.body);
        return {
          "success": false,
          "message": errorData["message"] ?? "이메일 또는 비밀번호가 일치하지 않습니다.",
        };
      } else {
        // 기타 서버 오류
        return {"success": false, "message": "서버 오류가 발생했습니다."};
      }
    } catch (e) {
      // 네트워크 오류
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }

  Future<void> logout() async {
    _currentUser = null;
  }

  // 아이디 중복 확인 (임시 - 항상 사용 가능으로 반환)
  // TODO: 백엔드에 아이디 중복 확인 API 추가 필요
  bool isUsernameTaken(String username) {
    // 임시로 항상 false 반환 (사용 가능)
    // 추후 백엔드 API 연동 필요
    return false;
  }

  // 이메일 중복 확인
  Future<Map<String, dynamic>> checkEmailDuplicate(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/check-email?email=${Uri.encodeComponent(email)}'),
        headers: {"Content-Type": "application/json; charset=UTF-8"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // 백엔드 응답 형식: {"ok": true, "data": {"exists": true/false}, "error": null, "message": null}
        if (data["ok"] == true) {
          bool exists = data["data"]["exists"];
          return {
            "success": true,
            "exists": exists,
            "message": exists ? "이미 사용 중인 이메일입니다." : "사용 가능한 이메일입니다.",
          };
        } else {
          return {"success": false, "message": data["message"] ?? "이메일 확인 실패"};
        }
      } else {
        return {
          "success": false,
          "message": "이메일 확인 실패 (${response.statusCode})",
        };
      }
    } catch (e) {
      return {"success": false, "message": "네트워크 오류: $e"};
    }
  }
}
