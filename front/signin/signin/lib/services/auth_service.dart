// 인증 서비스 - 임시로 메모리에 사용자 데이터를 저장
// 실제 배포 시에는 백엔드 API와 연동 필요

import '../models/user.dart';

class AuthService {
  // 싱글톤 패턴
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 임시 사용자 저장소 (메모리)
  final List<User> _users = [];

  // 현재 로그인한 사용자
  User? _currentUser;

  // 현재 로그인한 사용자 getter
  User? get currentUser => _currentUser;

  // 로그인 상태 확인
  bool get isLoggedIn => _currentUser != null;

  // 회원가입
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
    String? gender,
    DateTime? birthdate,
    String? address,
    String? addressDetail,
    String? addressNote,
    required UserType userType,
    String? companyName,
    String? businessNumber,
  }) async {
    // 이메일 중복 체크
    if (_users.any((user) => user.email == email)) {
      return {
        'success': false,
        'message': '이미 사용 중인 이메일입니다.',
      };
    }

    // 아이디 중복 체크
    if (_users.any((user) => user.username == username)) {
      return {
        'success': false,
        'message': '이미 사용 중인 아이디입니다.',
      };
    }

    // 새 사용자 생성
    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: username,
      email: email,
      password: password, // 실제로는 해시화 필요
      gender: gender,
      birthdate: birthdate,
      address: address,
      addressDetail: addressDetail,
      addressNote: addressNote,
      userType: userType,
      companyName: companyName,
      businessNumber: businessNumber,
    );

    _users.add(newUser);

    return {
      'success': true,
      'message': '회원가입이 완료되었습니다.',
      'user': newUser,
    };
  }

  // 로그인
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    // 사용자 찾기
    try {
      final user = _users.firstWhere(
        (user) => user.username == username && user.password == password,
      );

      _currentUser = user;

      return {
        'success': true,
        'message': '로그인 성공',
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '아이디 또는 비밀번호가 일치하지 않습니다.',
      };
    }
  }

  // 로그아웃
  Future<void> logout() async {
    _currentUser = null;
  }

  // 아이디 중복 확인
  bool isUsernameTaken(String username) {
    return _users.any((user) => user.username == username);
  }

  // 이메일 중복 확인
  bool isEmailTaken(String email) {
    return _users.any((user) => user.email == email);
  }

  // 모든 사용자 목록 (디버깅용)
  List<User> getAllUsers() {
    return List.unmodifiable(_users);
  }

  // 사용자 정보 업데이트
  Future<Map<String, dynamic>> updateUser(User updatedUser) async {
    final index = _users.indexWhere((user) => user.id == updatedUser.id);

    if (index == -1) {
      return {
        'success': false,
        'message': '사용자를 찾을 수 없습니다.',
      };
    }

    _users[index] = updatedUser;

    if (_currentUser?.id == updatedUser.id) {
      _currentUser = updatedUser;
    }

    return {
      'success': true,
      'message': '사용자 정보가 업데이트되었습니다.',
      'user': updatedUser,
    };
  }
}
