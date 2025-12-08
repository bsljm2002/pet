import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// 챗봇 대화 기록 저장 서비스 (DB 저장 방식 + 로컬 fallback)
class ChatHistoryService {
  static const String _baseUrl = 'http://223.130.130.225:9075/api/v1/chatbot';
  static const String _currentSessionKey = 'current_chat_session';
  static const String _pendingSessionKey = 'pending_chat_session';
  static const String _localSessionsKey = 'chat_sessions_local';
  static const int maxSessions = 50;

  // 싱글톤
  static final ChatHistoryService _instance = ChatHistoryService._internal();
  factory ChatHistoryService() => _instance;
  ChatHistoryService._internal();

  // 현재 사용자 ID (로그인 서비스에서 설정)
  int? _currentUserId;

  // DB 사용 가능 여부
  bool _useLocalStorage = false;

  /// 사용자 ID 설정
  void setUserId(int? userId) {
    _currentUserId = userId;
  }

  /// 현재 사용자 ID 가져오기
  int? get currentUserId => _currentUserId;

  /// 모든 대화 세션 목록 가져오기
  Future<List<ChatSession>> getAllSessions() async {
    // 로컬 저장 모드이거나 사용자 ID가 없으면 로컬에서 조회
    if (_useLocalStorage || _currentUserId == null) {
      return _getLocalSessions();
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/sessions?userId=$_currentUserId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final sessions = (data['sessions'] as List)
            .map((json) => ChatSession.fromServerJson(json))
            .toList();
        return sessions;
      } else {
        print('서버 응답 오류: ${response.statusCode}, 로컬 저장 모드로 전환');
        _useLocalStorage = true;
        return _getLocalSessions();
      }
    } catch (e) {
      print('세션 목록 조회 실패: $e, 로컬 저장 모드로 전환');
      _useLocalStorage = true;
      return _getLocalSessions();
    }
  }

  /// 로컬 세션 목록 가져오기
  Future<List<ChatSession>> _getLocalSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_localSessionsKey) ?? [];
    return sessionsJson
        .map((json) => ChatSession.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  /// 특정 세션 가져오기 (메시지 포함)
  Future<ChatSession?> getSession(String sessionId) async {
    // pending 세션은 로컬에서만 조회
    if (sessionId.startsWith('pending_')) {
      return _getLocalSession(sessionId);
    }

    // 로컬 저장 모드이거나 사용자 ID가 없으면 로컬에서 조회
    if (_useLocalStorage || _currentUserId == null) {
      return _getLocalSession(sessionId);
    }

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/sessions/$sessionId?userId=$_currentUserId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ DB에서 세션 불러오기 성공: $sessionId');
        return ChatSession.fromServerDetailJson(data);
      } else {
        print('⚠️ 서버 응답 오류: ${response.statusCode}, 로컬에서 조회');
        return _getLocalSession(sessionId);
      }
    } catch (e) {
      print('❌ 세션 조회 실패: $e, 로컬에서 조회');
      return _getLocalSession(sessionId);
    }
  }

  /// 로컬 세션 가져오기
  Future<ChatSession?> _getLocalSession(String sessionId) async {
    final sessions = await _getLocalSessions();
    try {
      return sessions.firstWhere((s) => s.id == sessionId);
    } catch (e) {
      return null;
    }
  }

  /// 현재 세션 ID 가져오기
  Future<String?> getCurrentSessionId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentSessionKey);
  }

  /// 현재 세션 ID 설정
  Future<void> setCurrentSessionId(String? sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    if (sessionId == null) {
      await prefs.remove(_currentSessionKey);
    } else {
      await prefs.setString(_currentSessionKey, sessionId);
    }
  }

  /// 대기 중인 세션 정보 저장 (DB에 저장되기 전)
  Future<void> _setPendingSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSessionKey, jsonEncode(session.toJson()));
  }

  /// 대기 중인 세션 정보 가져오기
  Future<ChatSession?> _getPendingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_pendingSessionKey);
    if (json != null) {
      return ChatSession.fromJson(jsonDecode(json));
    }
    return null;
  }

  /// 대기 중인 세션 정보 삭제
  Future<void> _clearPendingSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSessionKey);
  }

  /// 새 세션 생성 (메모리에만 생성, 첫 메시지 추가 시 저장)
  Future<ChatSession> createSession({String? title}) async {
    // 임시 ID로 로컬 세션 생성
    final session = ChatSession(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? '새 대화',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await setCurrentSessionId(session.id);
    await _setPendingSession(session);
    return session;
  }

  /// 세션에 메시지 추가
  Future<void> addMessage(String sessionId, ChatMessageData message) async {
    // 로컬 저장 모드인 경우
    if (_useLocalStorage || _currentUserId == null) {
      await _addMessageLocal(sessionId, message);
      return;
    }

    // pending 세션인 경우 DB에 새 세션 생성
    if (sessionId.startsWith('pending_')) {
      final pendingSession = await _getPendingSession();
      if (pendingSession != null) {
        // 서버에 새 세션 생성 시도
        final newSession = await _createSessionOnServer(
          message.isUser
              ? (message.text.length > 30
                    ? '${message.text.substring(0, 30)}...'
                    : message.text)
              : '새 대화',
        );

        if (newSession != null) {
          // 새 세션 ID로 업데이트
          await setCurrentSessionId(newSession.id);
          await _clearPendingSession();

          // 메시지 추가
          await _addMessageOnServer(newSession.id, message);
        } else {
          // 서버 실패 시 로컬에 저장
          await _addMessageLocal(sessionId, message);
        }
      }
    } else {
      // 기존 세션에 메시지 추가
      await _addMessageOnServer(sessionId, message);
    }
  }

  /// 로컬에 메시지 추가
  Future<void> _addMessageLocal(
    String sessionId,
    ChatMessageData message,
  ) async {
    final sessions = await _getLocalSessions();
    final index = sessions.indexWhere((s) => s.id == sessionId);

    if (index != -1) {
      // 기존 세션에 메시지 추가
      final session = sessions[index];
      session.messages.add(message);
      session.updatedAt = DateTime.now();

      // 첫 번째 사용자 메시지를 제목으로 설정
      if (session.title == '새 대화' &&
          message.isUser &&
          session.messages.length <= 2) {
        session.title = message.text.length > 30
            ? '${message.text.substring(0, 30)}...'
            : message.text;
      }

      await _saveLocalSession(session);
    } else {
      // 새 세션인 경우 (아직 저장되지 않은 세션) - 첫 메시지와 함께 저장
      final newSession = ChatSession(
        id: sessionId,
        title: message.isUser
            ? (message.text.length > 30
                  ? '${message.text.substring(0, 30)}...'
                  : message.text)
            : '새 대화',
        messages: [message],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await _saveLocalSession(newSession);
    }
  }

  /// 로컬 세션 저장
  Future<void> _saveLocalSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getLocalSessions();

    // 기존 세션 찾아서 업데이트 또는 새로 추가
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      sessions[index] = session;
    } else {
      sessions.insert(0, session);
    }

    // 최대 개수 초과 시 오래된 세션 삭제
    while (sessions.length > maxSessions) {
      sessions.removeLast();
    }

    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_localSessionsKey, sessionsJson);
  }

  /// 서버에 새 세션 생성
  Future<ChatSession?> _createSessionOnServer(String title) async {
    if (_currentUserId == null) return null;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions?userId=$_currentUserId'),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: utf8.encode(jsonEncode({'title': title})),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return ChatSession.fromServerJson(data);
      }
    } catch (e) {
      print('세션 생성 실패: $e');
    }
    return null;
  }

  /// 서버에 메시지 추가
  Future<void> _addMessageOnServer(
    String sessionId,
    ChatMessageData message,
  ) async {
    if (_currentUserId == null) return;

    try {
      await http.post(
        Uri.parse(
          '$_baseUrl/sessions/$sessionId/messages?userId=$_currentUserId',
        ),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: utf8.encode(
          jsonEncode({'content': message.text, 'isUser': message.isUser}),
        ),
      );
    } catch (e) {
      print('메시지 추가 실패: $e');
    }
  }

  /// 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    // 로컬 저장 모드인 경우
    if (_useLocalStorage || _currentUserId == null) {
      await _deleteLocalSession(sessionId);
      return;
    }

    // pending 세션인 경우 로컬에서만 삭제
    if (sessionId.startsWith('pending_')) {
      await _clearPendingSession();
      final currentId = await getCurrentSessionId();
      if (currentId == sessionId) {
        await setCurrentSessionId(null);
      }
      return;
    }

    try {
      await http.delete(
        Uri.parse('$_baseUrl/sessions/$sessionId?userId=$_currentUserId'),
        headers: {'Content-Type': 'application/json'},
      );

      // 현재 세션이면 초기화
      final currentId = await getCurrentSessionId();
      if (currentId == sessionId) {
        await setCurrentSessionId(null);
      }
    } catch (e) {
      print('세션 삭제 실패: $e');
    }
  }

  /// 로컬 세션 삭제
  Future<void> _deleteLocalSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await _getLocalSessions();

    sessions.removeWhere((s) => s.id == sessionId);

    final sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_localSessionsKey, sessionsJson);

    // 현재 세션이면 초기화
    final currentId = await getCurrentSessionId();
    if (currentId == sessionId) {
      await setCurrentSessionId(null);
    }
  }

  /// 모든 세션 삭제 (로컬 캐시만 삭제)
  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSessionKey);
    await prefs.remove(_pendingSessionKey);
    await prefs.remove(_localSessionsKey);
  }
}

/// 대화 세션 모델
class ChatSession {
  final String id;
  String title;
  final List<ChatMessageData> messages;
  final DateTime createdAt;
  DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 로컬 JSON에서 생성
  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'],
      title: json['title'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessageData.fromJson(m))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// 서버 응답(목록)에서 생성
  factory ChatSession.fromServerJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'].toString(),
      title: json['title'] ?? '새 대화',
      messages: [], // 목록에서는 메시지 포함 안함
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  /// 서버 응답(상세)에서 생성
  factory ChatSession.fromServerDetailJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'].toString(),
      title: json['title'] ?? '새 대화',
      messages:
          (json['messages'] as List?)
              ?.map((m) => ChatMessageData.fromServerJson(m))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 대화 히스토리를 OpenAI 형식으로 변환
  List<Map<String, String>> toConversationHistory() {
    return messages
        .map(
          (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
        )
        .toList();
  }

  /// 마지막 메시지 텍스트 (최대 50자)
  String get lastMessage {
    if (messages.isEmpty) return '';
    final lastMsg = messages.last.text;
    if (lastMsg.length > 50) {
      return '${lastMsg.substring(0, 50)}...';
    }
    return lastMsg;
  }

  /// 메시지 개수
  int get messageCount => messages.length;
}

/// 대화 메시지 모델
class ChatMessageData {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageData({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  /// 로컬 JSON에서 생성
  factory ChatMessageData.fromJson(Map<String, dynamic> json) {
    return ChatMessageData(
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  /// 서버 응답에서 생성
  factory ChatMessageData.fromServerJson(Map<String, dynamic> json) {
    return ChatMessageData(
      text: json['content'] ?? '',
      isUser: json['isUser'] ?? false,
      timestamp: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
