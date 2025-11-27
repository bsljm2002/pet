// Firebase 설정 파일
// FlutterFire CLI로 생성됨 - 수동 편집 시 주의
// Project: dogfootcatfoot-1f17f

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// 현재 플랫폼에 맞는 Firebase 설정을 제공하는 클래스
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Android 설정
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDogfootcatfoot_android_key', // TODO: 실제 API 키로 교체
    appId: '1:114808593420:android:dogfootcatfoot1f17f',
    messagingSenderId: '114808593420',
    projectId: 'dogfootcatfoot-1f17f',
    storageBucket: 'dogfootcatfoot-1f17f.firebasestorage.app',
  );

  // iOS 설정
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDogfootcatfoot_ios_key', // TODO: 실제 API 키로 교체
    appId: '1:114808593420:ios:dogfootcatfoot1f17f',
    messagingSenderId: '114808593420',
    projectId: 'dogfootcatfoot-1f17f',
    storageBucket: 'dogfootcatfoot-1f17f.firebasestorage.app',
    iosBundleId: 'com.example.signin',
  );

  // Web 설정
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDogfootcatfoot_web_key', // TODO: 실제 API 키로 교체
    appId: '1:114808593420:web:dogfootcatfoot1f17f',
    messagingSenderId: '114808593420',
    projectId: 'dogfootcatfoot-1f17f',
    authDomain: 'dogfootcatfoot-1f17f.firebaseapp.com',
    storageBucket: 'dogfootcatfoot-1f17f.firebasestorage.app',
  );

  // macOS 설정
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDogfootcatfoot_macos_key', // TODO: 실제 API 키로 교체
    appId: '1:114808593420:macos:dogfootcatfoot1f17f',
    messagingSenderId: '114808593420',
    projectId: 'dogfootcatfoot-1f17f',
    storageBucket: 'dogfootcatfoot-1f17f.firebasestorage.app',
    iosBundleId: 'com.example.signin',
  );

  // Windows 설정
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDogfootcatfoot_windows_key', // TODO: 실제 API 키로 교체
    appId: '1:114808593420:windows:dogfootcatfoot1f17f',
    messagingSenderId: '114808593420',
    projectId: 'dogfootcatfoot-1f17f',
    storageBucket: 'dogfootcatfoot-1f17f.firebasestorage.app',
  );
}
