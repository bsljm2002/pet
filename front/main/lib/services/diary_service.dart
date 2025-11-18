import '../models/pet_diary.dart';

/// 펫 일기 데이터 관리 서비스
/// 메모리 기반 저장소를 사용하여 일기 저장/조회
class DiaryService {
  static final DiaryService _instance = DiaryService._internal();
  factory DiaryService() => _instance;
  DiaryService._internal();

  // 메모리 기반 저장소
  final List<PetDiary> _diaries = [];

  /// 일기 저장
  Future<Map<String, dynamic>> saveDiary(PetDiary diary) async {
    try {
      // 같은 날짜, 같은 펫의 일기가 있는지 확인
      final dateStr = diary.date.toIso8601String().split('T')[0];
      final existingIndex = _diaries.indexWhere((d) {
        final dDate = d.date.toIso8601String().split('T')[0];
        return d.petId == diary.petId && dDate == dateStr;
      });

      if (existingIndex >= 0) {
        // 기존 일기 업데이트
        _diaries[existingIndex] = diary;
      } else {
        // 새 일기 추가
        _diaries.add(diary);
      }

      return {
        'success': true,
        'message': '일기가 저장되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '일기 저장 실패: $e',
      };
    }
  }

  /// 특정 펫의 특정 날짜 일기 조회
  Future<PetDiary?> getDiary(int petId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      final found = _diaries.where((d) {
        final dDate = d.date.toIso8601String().split('T')[0];
        return d.petId == petId && dDate == dateStr;
      }).toList();

      if (found.isEmpty) return null;

      return found.first;
    } catch (e) {
      return null;
    }
  }

  /// 특정 펫의 모든 일기 조회
  Future<List<PetDiary>> getDiariesByPet(int petId) async {
    try {
      final petDiaries = _diaries
          .where((d) => d.petId == petId)
          .toList();

      // 날짜 내림차순 정렬 (최신순)
      petDiaries.sort((a, b) => b.date.compareTo(a.date));

      return petDiaries;
    } catch (e) {
      return [];
    }
  }

  /// 일기 삭제
  Future<Map<String, dynamic>> deleteDiary(int petId, DateTime date) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];

      _diaries.removeWhere((d) {
        final dDate = d.date.toIso8601String().split('T')[0];
        return d.petId == petId && dDate == dateStr;
      });

      return {
        'success': true,
        'message': '일기가 삭제되었습니다.',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '일기 삭제 실패: $e',
      };
    }
  }
}
