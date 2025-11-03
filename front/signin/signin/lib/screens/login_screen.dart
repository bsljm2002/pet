import 'package:flutter/material.dart';
import 'signup_screen.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    // 입력값 검증
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요.')),
      );
      return;
    }

    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.')),
      );
      return;
    }

    // 로그인 처리
    final result = await _authService.login(
      username: _idController.text.trim(),
      password: _passwordController.text,
    );

    if (result['success']) {
      // 로그인 성공 - 메인 화면으로 이동
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
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
      backgroundColor: const Color(0xFFB8D8D0), // 민트/연한 그린 배경색
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // 제목
                const Center(
                  child: Text(
                    '로그인',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // 아이디 라벨
                const Text(
                  '아이디',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6C6D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // 아이디 입력 필드
                TextField(
                  controller: _idController,
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

                const SizedBox(height: 40),

                // 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3BA688), // 진한 그린
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      '로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 다른 방법으로 로그인하기
                const Center(
                  child: Text(
                    '다른 방법으로 로그인하기',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF7A8C8D),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 소셜 로그인 버튼들
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google 로그인
                    _buildSocialLoginButton(
                      icon: Icons.g_mobiledata,
                      label: 'G',
                      onPressed: () {
                        // TODO: Google 로그인
                      },
                    ),
                    const SizedBox(width: 16),
                    // Facebook 로그인
                    _buildSocialLoginButton(
                      icon: Icons.facebook,
                      label: 'f',
                      onPressed: () {
                        // TODO: Facebook 로그인
                      },
                    ),
                    const SizedBox(width: 16),
                    // Twitter 로그인
                    _buildSocialLoginButton(
                      icon: Icons.tag,
                      label: 't',
                      onPressed: () {
                        // TODO: Twitter 로그인
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // 회원가입 링크
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
                              builder: (context) => const SignupScreen(),
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

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Text(
          label,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF5A6C6D),
          ),
        ),
      ),
    );
  }
}
