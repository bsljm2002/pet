# 가이드 4: VetService 생성

## 📁 파일 생성

파일: `lib/services/vet_service.dart`

## 📋 전체 코드 (복사-붙여넣기)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class VetService {
  static const String baseUrl = 'http://10.0.2.2:9075/api/v1';

  static String getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    return 'http://10.0.2.2:9075$imageUrl';
  }

  static Future<Map<String, dynamic>> getPartners(String userType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/partners?user_type=$userType'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': jsonResponse['success'] ?? true,
          'data': jsonResponse['data'],
        };
      } else {
        throw Exception('파트너 목록을 불러오는데 실패했습니다');
      }
    } catch (e) {
      print('파트너 조회 오류: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createReservation({
    required int userId,
    required int partnerId,
    required String serviceCategorical,
    required int petId,
    String? content,
    String? vetSpecialty,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        'userId': userId,
        'partnerId': partnerId,
        'serviceCategorical': serviceCategorical,
        'petId': petId,
      };

      if (content != null) requestBody['reservationContent'] = content;
      if (vetSpecialty != null) requestBody['vetSpecialtyCsv'] = vetSpecialty;

      final response = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {'success': jsonResponse['success'] ?? true, 'data': jsonResponse['data']};
      } else {
        throw Exception('예약 생성에 실패했습니다');
      }
    } catch (e) {
      print('예약 생성 오류: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getMyReservations({
    required int userId,
    String? serviceType,
  }) async {
    try {
      String url = '$baseUrl/reservations/mine?userId=$userId';
      if (serviceType != null) url += '&serviceType=$serviceType';

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {'success': jsonResponse['success'] ?? true, 'data': jsonResponse['data']};
      } else {
        throw Exception('예약 목록을 불러오는데 실패했습니다');
      }
    } catch (e) {
      print('예약 목록 조회 오류: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
```

## 📌 다음 단계

가이드5에서 Provider 수정 방법을 확인하세요!
