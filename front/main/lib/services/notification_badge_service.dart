import 'package:shared_preferences/shared_preferences.dart';

/// 미확인 알림 카운트 관리 서비스
class NotificationBadgeService {
  static final NotificationBadgeService _instance = NotificationBadgeService._internal();
  factory NotificationBadgeService() => _instance;
  NotificationBadgeService._internal();

  static const String _reservationCountKey = 'unread_reservation_count';
  static const String _consultationCountKey = 'unread_consultation_count';

  /// 미확인 예약 개수 가져오기
  Future<int> getReservationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reservationCountKey) ?? 0;
    } catch (e) {
      print('❌ 예약 카운트 조회 실패: $e');
      return 0;
    }
  }

  /// 미확인 상담 개수 가져오기
  Future<int> getConsultationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_consultationCountKey) ?? 0;
    } catch (e) {
      print('❌ 상담 카운트 조회 실패: $e');
      return 0;
    }
  }

  /// 미확인 예약 개수 증가
  Future<void> incrementReservationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_reservationCountKey) ?? 0;
      await prefs.setInt(_reservationCountKey, currentCount + 1);
      print('✅ 예약 카운트 증가: ${currentCount + 1}');
    } catch (e) {
      print('❌ 예약 카운트 증가 실패: $e');
    }
  }

  /// 미확인 상담 개수 증가
  Future<void> incrementConsultationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int currentCount = prefs.getInt(_consultationCountKey) ?? 0;
      await prefs.setInt(_consultationCountKey, currentCount + 1);
      print('✅ 상담 카운트 증가: ${currentCount + 1}');
    } catch (e) {
      print('❌ 상담 카운트 증가 실패: $e');
    }
  }

  /// 미확인 예약 개수 리셋 (페이지 확인 시)
  Future<void> resetReservationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reservationCountKey, 0);
      print('✅ 예약 카운트 리셋');
    } catch (e) {
      print('❌ 예약 카운트 리셋 실패: $e');
    }
  }

  /// 미확인 상담 개수 리셋 (페이지 확인 시)
  Future<void> resetConsultationCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_consultationCountKey, 0);
      print('✅ 상담 카운트 리셋');
    } catch (e) {
      print('❌ 상담 카운트 리셋 실패: $e');
    }
  }

  /// 모든 카운트 리셋
  Future<void> resetAllCounts() async {
    await resetReservationCount();
    await resetConsultationCount();
  }
}
