import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging 서비스
class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  /// FCM 메시지 수신 콜백
  Function(Map<String, dynamic>)? onMessageReceived;
  Function(Map<String, dynamic>)? onMessageOpenedApp;

  /// FCM 초기화
  Future<void> initialize() async {
    try {
      // 알림 권한 요청
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ FCM 알림 권한 허용됨');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('⚠️ FCM 임시 알림 권한 허용됨');
      } else {
        print('❌ FCM 알림 권한 거부됨');
        return;
      }

      // FCM 토큰 가져오기
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        print('📱 FCM 토큰: $token');
        // TODO: 서버에 토큰 전송 (AuthService에서 처리)
      }

      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        print('🔄 FCM 토큰 갱신: $token');
        // TODO: 서버에 새 토큰 전송
      });

      // 포그라운드 메시지 수신 리스너
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 포그라운드 메시지 수신: ${message.messageId}');
        _handleMessage(message);
      });

      // 백그라운드에서 알림 클릭 시 (앱이 열려있을 때)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔔 백그라운드 알림 클릭: ${message.messageId}');
        _handleMessageOpened(message);
      });

      // 앱이 종료된 상태에서 알림 클릭으로 앱 실행
      RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
      if (initialMessage != null) {
        print('🚀 앱 시작 알림: ${initialMessage.messageId}');
        _handleMessageOpened(initialMessage);
      }

      print('✅ FCM 서비스 초기화 완료');
    } catch (e) {
      print('❌ FCM 초기화 오류: $e');
    }
  }

  /// FCM 토큰 가져오기
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('❌ FCM 토큰 가져오기 오류: $e');
      return null;
    }
  }

  /// 메시지 처리 (포그라운드)
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    if (kDebugMode) {
      print('📩 메시지 데이터: $data');
      if (notification != null) {
        print('📩 알림 제목: ${notification.title}');
        print('📩 알림 내용: ${notification.body}');
      }
    }

    // 콜백 호출
    if (onMessageReceived != null) {
      onMessageReceived!(data);
    }
  }

  /// 메시지 열기 처리 (백그라운드/종료 상태)
  void _handleMessageOpened(RemoteMessage message) {
    final data = message.data;

    if (kDebugMode) {
      print('🔔 알림 클릭 데이터: $data');
    }

    // 콜백 호출
    if (onMessageOpenedApp != null) {
      onMessageOpenedApp!(data);
    }
  }

  /// 특정 토픽 구독
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('✅ 토픽 구독: $topic');
    } catch (e) {
      print('❌ 토픽 구독 오류: $e');
    }
  }

  /// 특정 토픽 구독 해제
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('✅ 토픽 구독 해제: $topic');
    } catch (e) {
      print('❌ 토픽 구독 해제 오류: $e');
    }
  }
}

/// 백그라운드 메시지 핸들러 (Top-level function 필요)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🌙 백그라운드 메시지 수신: ${message.messageId}');
  // 백그라운드에서 필요한 처리 수행
}
