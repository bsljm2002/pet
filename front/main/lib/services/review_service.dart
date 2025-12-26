import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';

/// 리뷰 서비스
class ReviewService {
  static const String baseUrl = 'http://223.130.130.225:9075/api/v1/reviews';

  /// 파트너별 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByPartnerId(int partnerId) async {
    try {
      final url = Uri.parse('$baseUrl/partner/$partnerId');
      final response = await http.get(url);

      print('리뷰 목록 조회 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> reviewList = jsonData['data'];
          return reviewList.map((json) => ReviewModel.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('리뷰 목록 조회 에러: $e');
      return [];
    }
  }

  /// 리뷰 작성
  Future<Map<String, dynamic>> createReview({
    required int partnerId,
    required int userId,
    required int reservationId,
    required double rating,
    String? content,
  }) async {
    try {
      print('📝 리뷰 작성 요청:');
      print('  - partnerId: $partnerId');
      print('  - userId: $userId');
      print('  - reservationId: $reservationId');
      print('  - rating: $rating');
      print('  - content: $content');

      final url = Uri.parse(baseUrl);
      final requestBody = {
        'partnerId': partnerId,
        'userId': userId,
        'reservationId': reservationId,
        'rating': rating,
        'content': content,
      };

      print('  - Request Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(requestBody),
      );

      print('📨 리뷰 작성 응답: ${response.statusCode}');
      print('📨 응답 본문: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true) {
          return {'success': true, 'message': '리뷰가 작성되었습니다.'};
        } else {
          return {
            'success': false,
            'message': jsonData['message'] ?? '리뷰 작성에 실패했습니다.',
          };
        }
      } else {
        // 모든 에러 응답 처리
        try {
          final Map<String, dynamic> jsonData = jsonDecode(
            utf8.decode(response.bodyBytes),
          );
          final errorMessage =
              jsonData['message'] ?? jsonData['error'] ?? '알 수 없는 오류가 발생했습니다.';
          return {
            'success': false,
            'message': '[${response.statusCode}] $errorMessage',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                '서버 오류 (${response.statusCode}): ${utf8.decode(response.bodyBytes)}',
          };
        }
      }
    } catch (e, stackTrace) {
      print('❌ 리뷰 작성 에러: $e');
      print('❌ Stack trace: $stackTrace');
      return {'success': false, 'message': '네트워크 오류: $e'};
    }
  }

  /// 리뷰 수정
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required double rating,
    String? content,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/$reviewId');
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'rating': rating, 'content': content}),
      );

      print('리뷰 수정 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true) {
          return {'success': true, 'message': '리뷰가 수정되었습니다.'};
        }
      }

      return {'success': false, 'message': '리뷰 수정에 실패했습니다.'};
    } catch (e) {
      print('리뷰 수정 에러: $e');
      return {'success': false, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  /// 리뷰 삭제
  Future<Map<String, dynamic>> deleteReview(int reviewId) async {
    try {
      final url = Uri.parse('$baseUrl/$reviewId');
      final response = await http.delete(url);

      print('리뷰 삭제 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        return {'success': true, 'message': '리뷰가 삭제되었습니다.'};
      }

      return {'success': false, 'message': '리뷰 삭제에 실패했습니다.'};
    } catch (e) {
      print('리뷰 삭제 에러: $e');
      return {'success': false, 'message': '네트워크 오류가 발생했습니다.'};
    }
  }

  /// 사용자별 리뷰 목록 조회
  Future<List<ReviewModel>> getReviewsByUserId(int userId) async {
    try {
      final url = Uri.parse('$baseUrl/user/$userId');
      final response = await http.get(url);

      print('사용자 리뷰 목록 조회 응답: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (jsonData['ok'] == true && jsonData['data'] != null) {
          final List<dynamic> reviewList = jsonData['data'];
          return reviewList.map((json) => ReviewModel.fromJson(json)).toList();
        }
      }

      return [];
    } catch (e) {
      print('사용자 리뷰 목록 조회 에러: $e');
      return [];
    }
  }
}
