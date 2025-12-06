import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';

/// 펫시터 실시간 위치 추적 서비스
/// Firebase Realtime Database를 활용하여 펫시터와 사용자 간 위치 공유
class LocationTrackingService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<Position>? _positionStreamSubscription;
  String? _currentTrackingId;

  /// 위치 권한 요청 및 확인
  Future<bool> requestLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스가 활성화되어 있는지 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ 위치 서비스가 비활성화되어 있습니다.');
      return false;
    }

    // 위치 권한 확인
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ 위치 권한이 거부되었습니다.');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⚠️ 위치 권한이 영구적으로 거부되었습니다.');
      return false;
    }

    print('✅ 위치 권한이 허용되었습니다.');
    return true;
  }

  /// 펫시터 위치 추적 시작 (의뢰 수락 시)
  /// [reservationId] 예약 ID
  /// [sitterId] 펫시터 ID
  Future<void> startTracking(int reservationId, int sitterId) async {
    // 이미 추적 중이면 중지
    if (_positionStreamSubscription != null) {
      await stopTracking();
    }

    // 위치 권한 확인
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      throw Exception('위치 권한이 필요합니다.');
    }

    _currentTrackingId = 'reservation_$reservationId';

    print('📍 위치 추적 시작: $_currentTrackingId');

    // 위치 스트림 설정 (10초마다 업데이트)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // 10미터 이상 이동 시 업데이트
    );

    // 실시간 위치 추적 시작
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _updateLocationToFirebase(reservationId, sitterId, position);
      },
      onError: (error) {
        print('❌ 위치 추적 오류: $error');
      },
    );

    // 초기 위치 즉시 업데이트
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );
      await _updateLocationToFirebase(reservationId, sitterId, currentPosition);
    } catch (e) {
      print('⚠️ 초기 위치 가져오기 실패: $e');
    }
  }

  /// Firebase에 위치 정보 업데이트 (펫시터 위치)
  Future<void> _updateLocationToFirebase(
    int reservationId,
    int sitterId,
    Position position,
  ) async {
    try {
      final locationData = {
        'sitterId': sitterId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': ServerValue.timestamp,
        'speed': position.speed,
        'heading': position.heading,
      };

      await _database
          .child('location_tracking')
          .child('reservation_$reservationId')
          .child('sitter')
          .set(locationData);

      print('📍 펫시터 위치 업데이트: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      print('❌ Firebase 위치 업데이트 실패: $e');
    }
  }

  /// 펫시터 위치 추적 중지 (작업 완료 시)
  Future<void> stopTracking() async {
    if (_positionStreamSubscription != null) {
      await _positionStreamSubscription!.cancel();
      _positionStreamSubscription = null;
      print('🛑 위치 추적 중지');
    }

    // Firebase에서 위치 데이터 삭제
    if (_currentTrackingId != null) {
      try {
        await _database
            .child('location_tracking')
            .child(_currentTrackingId!)
            .remove();
        print('🗑️ Firebase 위치 데이터 삭제: $_currentTrackingId');
      } catch (e) {
        print('⚠️ Firebase 위치 데이터 삭제 실패: $e');
      }
      _currentTrackingId = null;
    }
  }

  /// 특정 예약의 펫시터 위치 실시간 스트림
  /// [reservationId] 예약 ID
  Stream<Map<String, dynamic>?> getSitterLocationStream(int reservationId) {
    return _database
        .child('location_tracking')
        .child('reservation_$reservationId')
        .child('sitter')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return null;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return {
        'sitterId': data['sitterId'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'accuracy': data['accuracy'],
        'timestamp': data['timestamp'],
        'speed': data['speed'],
        'heading': data['heading'],
      };
    });
  }

  /// 특정 예약의 사용자(고객) 위치 실시간 스트림
  /// [reservationId] 예약 ID
  Stream<Map<String, dynamic>?> getUserLocationStream(int reservationId) {
    return _database
        .child('location_tracking')
        .child('reservation_$reservationId')
        .child('user')
        .onValue
        .map((event) {
      if (event.snapshot.value == null) {
        return null;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>;
      return {
        'userId': data['userId'],
        'latitude': data['latitude'],
        'longitude': data['longitude'],
        'accuracy': data['accuracy'],
        'timestamp': data['timestamp'],
      };
    });
  }

  /// 사용자 위치 Firebase에 업데이트 (1회성)
  Future<void> updateUserLocation(
    int reservationId,
    double latitude,
    double longitude, {
    int? userId,
  }) async {
    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': ServerValue.timestamp,
        if (userId != null) 'userId': userId,
      };

      await _database
          .child('location_tracking')
          .child('reservation_$reservationId')
          .child('user')
          .set(locationData);

      print('📍 사용자 위치 Firebase 업데이트 완료: $latitude, $longitude');
      print('📍 경로: location_tracking/reservation_$reservationId/user');
    } catch (e) {
      print('❌ 사용자 위치 업데이트 실패: $e');
      rethrow;
    }
  }

  /// 현재 위치 한 번만 가져오기 (사용자 위치 표시용)
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        return null;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      return position;
    } catch (e) {
      print('❌ 현재 위치 가져오기 실패: $e');
      return null;
    }
  }

  /// 서비스 정리
  void dispose() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    _currentTrackingId = null;
  }
}
