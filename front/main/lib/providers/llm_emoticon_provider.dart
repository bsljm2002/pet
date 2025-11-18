import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/llm_emoticon_request.dart';
import '../services/llm_emoticon_service.dart';
import '../services/image_upload_service.dart';

/// LLM 이모티콘 상태 관리 Provider
class LlmEmoticonProvider with ChangeNotifier {
  final LlmEmoticonService _service = LlmEmoticonService();
  final ImageUploadService _imageService = ImageUploadService();

  // 상태
  List<LlmEmoticonRequest> _emoticons = [];
  bool _isLoading = false;
  String? _errorMessage;

  // 폴링 관리
  final Map<int, Timer> _pollingTimers = {};
  static const Duration _pollingInterval = Duration(seconds: 5);

  // Getters
  List<LlmEmoticonRequest> get emoticons => _emoticons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 진행 중인 이모티콘 목록
  List<LlmEmoticonRequest> get inProgressEmoticons {
    return _emoticons.where((e) => e.isInProgress).toList();
  }

  /// 완료된 이모티콘 목록
  List<LlmEmoticonRequest> get completedEmoticons {
    return _emoticons.where((e) => e.isCompleted).toList();
  }

  /// 성공한 이모티콘 목록
  List<LlmEmoticonRequest> get succeededEmoticons {
    return _emoticons.where((e) => e.isSucceeded).toList();
  }

  /// 이모티콘 생성 (전체 플로우)
  ///
  /// 1. 이미지 업로드
  /// 2. 이모티콘 생성 요청
  /// 3. 자동 폴링 시작
  ///
  /// [userId]: 사용자 ID
  /// [imageFile]: 원본 이미지 파일
  /// [petId]: 펫 ID (선택)
  /// [promptMeta]: 프롬프트 메타데이터
  Future<LlmEmoticonRequest> createEmoticon({
    required int userId,
    required File imageFile,
    int? petId,
    Map<String, dynamic>? promptMeta,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('🚀 이모티콘 생성 시작...');

      // 1. 이미지 검증
      _imageService.validateImage(imageFile);
      print('✅ 이미지 검증 완료');

      // 2. 이미지 업로드
      print('📤 이미지 업로드 중...');
      final imageUrl = await _imageService.uploadImage(
        imageFile: imageFile,
        userId: userId,
      );
      print('✅ 이미지 업로드 완료: $imageUrl');

      // 3. 이모티콘 생성 요청
      print('🎨 이모티콘 생성 요청 중...');
      final request = await _service.createEmoticon(
        userId: userId,
        petId: petId,
        imageUrl: imageUrl,
        promptMeta:
            promptMeta ??
            {'style': 'cute', 'mood': 'happy', 'action': 'playing'},
      );
      print('✅ 이모티콘 생성 요청 완료 (ID: ${request.id})');

      // 4. 목록에 추가 (맨 앞에)
      _emoticons.insert(0, request);
      notifyListeners();

      // 5. 폴링 시작
      if (request.id != null) {
        _startPolling(request.id!);
        print('⏰ 폴링 시작 (ID: ${request.id})');
      }

      _isLoading = false;
      notifyListeners();

      return request;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ 이모티콘 생성 실패: $e');
      rethrow;
    }
  }

  /// 상태 폴링 시작
  ///
  /// 5초마다 상태를 확인하고, 완료되면 자동으로 폴링을 중지합니다.
  void _startPolling(int requestId) {
    // 기존 폴링이 있으면 중지
    _pollingTimers[requestId]?.cancel();

    print('⏰ 폴링 시작: Request ID $requestId');

    _pollingTimers[requestId] = Timer.periodic(_pollingInterval, (timer) async {
      try {
        print('🔄 상태 확인 중... (ID: $requestId)');

        // 상태 조회
        final updatedRequest = await _service.getRequestStatus(requestId);

        // 목록에서 해당 요청 찾아서 업데이트
        final index = _emoticons.indexWhere((e) => e.id == requestId);
        if (index != -1) {
          _emoticons[index] = updatedRequest;
          notifyListeners();
          print('📊 상태 업데이트: ${updatedRequest.status.displayName}');
        }

        // 완료되면 폴링 중지
        if (updatedRequest.isCompleted) {
          timer.cancel();
          _pollingTimers.remove(requestId);

          if (updatedRequest.isSucceeded) {
            print('🎉 이모티콘 생성 완료! (ID: $requestId)');
          } else {
            print(
              '😢 이모티콘 생성 실패 (ID: $requestId): ${updatedRequest.failureReason}',
            );
          }
        }
      } catch (e) {
        print('⚠️ 폴링 오류 (ID: $requestId): $e');
        // 폴링 오류는 계속 재시도
      }
    });
  }

  /// 특정 요청의 폴링 중지
  void stopPolling(int requestId) {
    _pollingTimers[requestId]?.cancel();
    _pollingTimers.remove(requestId);
    print('⏹️ 폴링 중지: Request ID $requestId');
  }

  /// 모든 폴링 중지
  void stopAllPolling() {
    for (var timer in _pollingTimers.values) {
      timer.cancel();
    }
    _pollingTimers.clear();
    print('⏹️ 모든 폴링 중지');
  }

  /// 사용자의 이모티콘 목록 로드
  Future<void> loadUserEmoticons(int userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📋 사용자 이모티콘 목록 로드 중... (userId: $userId)');

      _emoticons = await _service.getUserEmoticons(userId: userId);
      print('✅ ${_emoticons.length}개의 이모티콘 로드 완료');

      // 진행 중인 요청들에 대해 폴링 시작
      for (var emoticon in _emoticons) {
        if (emoticon.isInProgress && emoticon.id != null) {
          _startPolling(emoticon.id!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ 목록 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 펫의 이모티콘 목록 로드
  Future<void> loadPetEmoticons(int petId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      print('📋 펫 이모티콘 목록 로드 중... (petId: $petId)');

      _emoticons = await _service.getPetEmoticons(petId: petId);
      print('✅ ${_emoticons.length}개의 이모티콘 로드 완료');

      // 진행 중인 요청들에 대해 폴링 시작
      for (var emoticon in _emoticons) {
        if (emoticon.isInProgress && emoticon.id != null) {
          _startPolling(emoticon.id!);
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ 펫 목록 로드 실패: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 목록 새로고침
  Future<void> refresh(int userId) async {
    await loadUserEmoticons(userId);
  }

  /// 특정 요청 수동 새로고침
  Future<void> refreshRequest(int requestId) async {
    try {
      final updatedRequest = await _service.getRequestStatus(requestId);

      final index = _emoticons.indexWhere((e) => e.id == requestId);
      if (index != -1) {
        _emoticons[index] = updatedRequest;
        notifyListeners();
      }
    } catch (e) {
      print('❌ 요청 새로고침 실패: $e');
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // 모든 폴링 타이머 정리
    stopAllPolling();
    super.dispose();
  }
}
