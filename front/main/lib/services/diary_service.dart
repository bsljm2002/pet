import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/pet_diary.dart';

/// 펫 일기 데이터 관리 서비스
/// 백엔드 REST API와 연동하여 일기 저장/조회
class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  // 백엔드 API URL (Android 에뮬레이터용)
  static const String _baseUrl = 'http://223.130.130.225:9075/api/diaries';

  /// 일기 저장
  Future<Map<String, dynamic>> saveDiary(PetDiary diary) async {
    try {
      final dateStr = diary.date.toIso8601String().split('T')[0];

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'petId': diary.petId,
          'diaryDate': dateStr,
          'content': diary.content,
          'weight': diary.weight,
          'heartRate': diary.heartRate,
          'stressLevel': diary.stressLevel,
          'diseases': diary.diseases,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? '일기가 저장되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': '일기 저장 실패: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '일기 저장 실패: $e'};
    }
  }

  /// 특정 펫의 특정 날짜 일기 조회
  Future<PetDiary?> getDiary(int petId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final response = await http.get(Uri.parse('$_baseUrl/$petId/$dateStr'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['success'] == true && responseData['diary'] != null) {
          final diaryData = responseData['diary'];
          return PetDiary(
            petId: diaryData['petId'],
            date: DateTime.parse(diaryData['diaryDate']),
            content: diaryData['content'] ?? '',
            weight: diaryData['weight']?.toDouble(),
            heartRate: diaryData['heartRate'],
            stressLevel: diaryData['stressLevel'],
            diseases: diaryData['diseases'],
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 특정 펫의 모든 일기 조회
  Future<List<PetDiary>> getDiariesByPet(int petId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pet/$petId'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['success'] == true &&
            responseData['diaries'] != null) {
          final List diariesList = responseData['diaries'];
          return diariesList.map((diaryData) {
            return PetDiary(
              petId: diaryData['petId'],
              date: DateTime.parse(diaryData['diaryDate']),
              content: diaryData['content'] ?? '',
              weight: diaryData['weight']?.toDouble(),
              heartRate: diaryData['heartRate'],
              stressLevel: diaryData['stressLevel'],
              diseases: diaryData['diseases'],
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 일기 삭제
  Future<Map<String, dynamic>> deleteDiary(int diaryId) async {
    try {
      final response = await http.delete(Uri.parse('$_baseUrl/$diaryId'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': responseData['success'] ?? true,
          'message': responseData['message'] ?? '일기가 삭제되었습니다.',
        };
      } else {
        return {
          'success': false,
          'message': '일기 삭제 실패: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': '일기 삭제 실패: $e'};
    }
  }

  /// 특정 펫의 최근 30일 일기 조회
  Future<List<PetDiary>> getRecentDiaries(int petId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/pet/$petId/recent'));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['success'] == true &&
            responseData['diaries'] != null) {
          final List diariesList = responseData['diaries'];
          return diariesList.map((diaryData) {
            return PetDiary(
              petId: diaryData['petId'],
              date: DateTime.parse(diaryData['diaryDate']),
              content: diaryData['content'] ?? '',
              weight: diaryData['weight']?.toDouble(),
              heartRate: diaryData['heartRate'],
              stressLevel: diaryData['stressLevel'],
              diseases: diaryData['diseases'],
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// 특정 펫의 특정 기간 일기 조회
  Future<List<PetDiary>> getDiariesByDateRange(
    int petId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/pet/$petId/range?startDate=$startDateStr&endDate=$endDateStr',
        ),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(utf8.decode(response.bodyBytes));
        if (responseData['success'] == true &&
            responseData['diaries'] != null) {
          final List diariesList = responseData['diaries'];
          return diariesList.map((diaryData) {
            return PetDiary(
              petId: diaryData['petId'],
              date: DateTime.parse(diaryData['diaryDate']),
              content: diaryData['content'] ?? '',
              weight: diaryData['weight']?.toDouble(),
              heartRate: diaryData['heartRate'],
              stressLevel: diaryData['stressLevel'],
              diseases: diaryData['diseases'],
            );
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
