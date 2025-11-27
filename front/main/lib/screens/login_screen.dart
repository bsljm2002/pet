import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'partner/hospital_home_screen.dart';
import 'partner/sitter_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  // 로그인 단계 관리
  // 0: 직접 로그인 버튼
  // 1: 이메일 입력
  // 2: 비밀번호 입력
  int _loginStep = 0;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // 슬라이드 애니메이션 (아래에서 위로)
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 1.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 페이드 애니메이션
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // 초기 화면을 보이게 하기 위해 애니메이션을 완료 상태로 설정
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 애니메이션과 함께 단계 전환
  Future<void> _changeStep(int newStep) async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    // 0.8초 대기
    await Future.delayed(const Duration(milliseconds: 800));

    // 단계 변경
    setState(() {
      _loginStep = newStep;
    });

    // 애니메이션 실행 (아래에서 올라옴)
    await _animationController.forward(from: 0.0);

    // 애니메이션 완료 후 상태 유지
    setState(() {
      _isAnimating = false;
    });
  }

  // 직접 로그인 버튼 클릭
  void _startDirectLogin() {
    _changeStep(1);
  }

  // 이메일 확인 및 다음 단계로 진행
  void _proceedToPassword() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      return;
    }

    // 이메일 형식 검증
    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(_emailController.text.trim())) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('올바른 이메일 형식이 아닙니다.')));
      return;
    }

    _changeStep(2);
  }

  // 뒤로가기
  void _goBack() {
    if (_loginStep == 2) {
      _passwordController.clear();
      _changeStep(1);
    } else if (_loginStep == 1) {
      _emailController.clear();
      _changeStep(0);
    }
  }

  Future<void> _handleLogin() async {
    // 입력값 검증
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이메일을 입력해주세요.')));
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('비밀번호를 입력해주세요.')));
      return;
    }

    // 로그인 처리 (이메일로 로그인)
    final result = await _authService.login(
      username: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (result['success']) {
      // 로그인 성공 - 사용자 타입에 따라 다른 화면으로 이동
      if (mounted) {
        final user = result['user'] as User?;

        if (user != null) {
          // 사용자 타입에 따라 분기
          switch (user.userType) {
            case UserType.hospital:
              // 펫닥터 (동물병원) 전용 화면
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const HospitalHomeScreen(),
                ),
              );
              break;
            case UserType.sitter:
              // 펫시터 전용 화면
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const SitterHomeScreen(),
                ),
              );
              break;
            default:
              // 일반 사용자 - 메인 화면으로 이동
              Navigator.pushReplacementNamed(context, '/main');
          }
        } else {
          // user 정보가 없으면 기본 메인 화면으로
          Navigator.pushReplacementNamed(context, '/main');
        }
      }
    } else {
      // 로그인 실패
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 224), // 민트/연한 그린 배경색
      body: SafeArea(
        child: Stack(
          children: [
            // 메인 콘텐츠
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                    vertical: 40.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 로고 영역
                      SvgPicture.asset(
                        'assets/icons/rogo.svg',
                        width: 120,
                        height: 120,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF3BA688),
                          BlendMode.srcIn,
                        ),
                      ),

                      const SizedBox(height: 40),

                      // 단계별 콘텐츠 표시 (애니메이션 적용)
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: _loginStep == 0
                              ? _buildInitialScreen()
                              : _loginStep == 1
                              ? _buildEmailInputScreen()
                              : _buildPasswordInputScreen(),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 회원가입 링크 (초기 화면에만 표시)
                      if (_loginStep == 0)
                        Center(
                          child: Column(
                            children: [
                              const Text(
                                '계정이 없으신가요?',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF5A6C6D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SignupScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  '회원가입',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF3BA688),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 왼쪽 상단 뒤로가기 버튼 (_loginStep이 0이 아닐 때만 표시)
            if (_loginStep > 0)
              Positioned(
                top: 16,
                left: 16,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF3BA688),
                    size: 28,
                  ),
                  onPressed: _goBack,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 초기 화면: 직접 로그인 버튼
  Widget _buildInitialScreen() {
    return Column(
      children: [
        // 직접 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _startDirectLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BA688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '직접 로그인',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // 이메일 입력 화면
  Widget _buildEmailInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        const Center(
          child: Text(
            '이메일을 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // 이메일 라벨
        const Text(
          '이메일',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 이메일 입력 필드
        TextField(
          controller: _emailController,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => _proceedToPassword(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: 'example@email.com',
            hintStyle: const TextStyle(color: Color(0xFFB0B8B8)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 다음 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedToPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BA688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '다음',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  // 비밀번호 입력 화면
  Widget _buildPasswordInputScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목
        const Center(
          child: Text(
            '비밀번호를 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // 비밀번호 라벨
        const Text(
          '비밀번호',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // 비밀번호 입력 필드
        TextField(
          controller: _passwordController,
          obscureText: true,
          autofocus: true,
          onSubmitted: (_) => _handleLogin(),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 로그인 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BA688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '로그인',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // 되돌아가기 텍스트 버튼
        Center(
          child: TextButton(
            onPressed: () {
              _emailController.clear();
              _passwordController.clear();
              _changeStep(0);
            },
            child: const Text(
              '되돌아가기',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5A6C6D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
