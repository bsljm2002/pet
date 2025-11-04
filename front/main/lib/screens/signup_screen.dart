import 'package:flutter/material.dart';
import 'package:kpostal/kpostal.dart';
import 'login_screen.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailLocalController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _addressDetailController =
      TextEditingController();
  final TextEditingController _addressNoteController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCustomDomain = false;
  bool _isVerificationSent = false;
  bool _isVerified = false;
  bool _isPartnerSignup = false;
  bool _isIdChecked = false; // 중복확인 여부

  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedEmailDomain;

  // 회원가입 단계 관리
  // 0: 회원 유형 선택
  // 1: 아이디 입력
  // 2: 비밀번호 입력
  // 3: 비밀번호 확인
  // 4: 이메일 입력 및 인증
  // 5: 추가 정보 입력 (생년월일/법인정보, 주소 등)
  int _signupStep = 0;

  // 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isAnimating = false;

  final List<String> _emailDomains = [
    'naver.com',
    'gmail.com',
    'daum.net',
    'kakao.com',
    'nate.com',
    '직접 입력',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _emailLocalController.dispose();
    _emailDomainController.dispose();
    _verificationCodeController.dispose();
    _companyNameController.dispose();
    _businessNumberController.dispose();
    _addressDetailController.dispose();
    _addressNoteController.dispose();
    super.dispose();
  }

  // 애니메이션과 함께 단계 전환
  Future<void> _changeStep(int newStep) async {
    if (_isAnimating) return;

    setState(() {
      _isAnimating = true;
    });

    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _signupStep = newStep;
    });

    await _animationController.forward(from: 0.0);

    setState(() {
      _isAnimating = false;
    });
  }

  // 뒤로가기
  void _goBack() {
    if (_signupStep > 0) {
      _changeStep(_signupStep - 1);
    }
  }

  void _checkIdDuplicate() {
    final username = _idController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요.')),
      );
      return;
    }

    final isTaken = _authService.isUsernameTaken(username);

    if (!isTaken) {
      setState(() {
        _isIdChecked = true;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTaken ? '이미 사용 중인 아이디입니다.' : '사용 가능한 아이디입니다.',
        ),
        backgroundColor: isTaken ? Colors.red : Colors.green,
      ),
    );
  }

  void _sendVerificationCode() {
    setState(() {
      _isVerificationSent = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('인증 코드가 전송되었습니다.')),
    );
  }

  void _verifyCode() {
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이메일 인증이 완료되었습니다.')),
    );
  }

  Future<void> _searchAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          callback: (Kpostal result) {
            setState(() {
              _postalCodeController.text = result.postCode;
              _addressController.text = result.address;
            });
          },
        ),
      ),
    );
  }

  // 단계 1: 아이디 입력 완료 및 다음 단계로 진행
  void _proceedFromId() {
    if (_idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요.')),
      );
      return;
    }

    if (!_isIdChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디 중복확인을 해주세요.')),
      );
      return;
    }

    _changeStep(2); // 비밀번호 입력 단계로
  }

  // 단계 2: 비밀번호 입력 완료 및 다음 단계로 진행
  void _proceedFromPassword() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 6자 이상이어야 합니다.')),
      );
      return;
    }

    _changeStep(3); // 비밀번호 확인 단계로
  }

  // 단계 3: 비밀번호 확인 완료 및 다음 단계로 진행
  void _proceedFromConfirmPassword() {
    if (_confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호 확인을 입력해주세요.')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    _changeStep(4); // 이메일 입력 단계로
  }

  // 단계 4: 이메일 입력 완료 및 다음 단계로 진행
  void _proceedFromEmail() {
    if (_emailLocalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.')),
      );
      return;
    }

    // 이메일 도메인 확인
    if (!_isCustomDomain && _selectedEmailDomain == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 도메인을 선택해주세요.')),
      );
      return;
    }

    if (_isCustomDomain && _emailDomainController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 도메인을 입력해주세요.')),
      );
      return;
    }

    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 완료해주세요.')),
      );
      return;
    }

    _changeStep(5); // 추가 정보 입력 단계로
  }

  Future<void> _handleSignup() async {
    // 이메일 도메인 확인
    String emailDomain;
    if (_isCustomDomain) {
      emailDomain = _emailDomainController.text.trim();
    } else {
      emailDomain = _selectedEmailDomain!;
    }

    final fullEmail = '${_emailLocalController.text.trim()}@$emailDomain';

    // 생년월일 또는 법인 정보 확인
    DateTime? birthdate;
    String? companyName;
    String? businessNumber;

    if (!_isPartnerSignup) {
      // 일반 사용자: 생년월일 확인
      if (_selectedYear == null ||
          _selectedMonth == null ||
          _selectedDay == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('생년월일을 입력해주세요.')),
        );
        return;
      }
      birthdate = DateTime(
        int.parse(_selectedYear!),
        int.parse(_selectedMonth!),
        int.parse(_selectedDay!),
      );
    } else {
      // 파트너: 법인명과 사업자번호 확인
      if (_companyNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('법인명을 입력해주세요.')),
        );
        return;
      }
      if (_businessNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사업자번호를 입력해주세요.')),
        );
        return;
      }
      companyName = _companyNameController.text.trim();
      businessNumber = _businessNumberController.text.trim();
    }

    // 회원가입 처리
    final result = await _authService.signUp(
      username: _idController.text.trim(),
      email: fullEmail,
      password: _passwordController.text,
      nickname: _nicknameController.text.trim().isNotEmpty
          ? _nicknameController.text.trim()
          : null,
      birthdate: birthdate,
      address: _addressController.text.trim().isNotEmpty
          ? _addressController.text.trim()
          : null,
      addressDetail: _addressDetailController.text.trim().isNotEmpty
          ? _addressDetailController.text.trim()
          : null,
      addressNote: _addressNoteController.text.trim().isNotEmpty
          ? _addressNoteController.text.trim()
          : null,
      userType: _isPartnerSignup ? UserType.seller : UserType.general,
      companyName: companyName,
      businessNumber: businessNumber,
    );

    if (result['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8D8D0),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 80),

                    // 로고 영역
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '숨숨\n루나',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3BA688),
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // 단계별 콘텐츠 표시 (애니메이션 적용)
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildCurrentStep(),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // 뒤로가기 버튼
            if (_signupStep > 0)
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

  Widget _buildCurrentStep() {
    switch (_signupStep) {
      case 0:
        return _buildUserTypeSelection();
      case 1:
        return _buildIdInput();
      case 2:
        return _buildPasswordInput();
      case 3:
        return _buildConfirmPasswordInput();
      case 4:
        return _buildEmailInput();
      case 5:
        return _buildAdditionalInfo();
      default:
        return const SizedBox.shrink();
    }
  }

  // 단계 0: 회원 유형 선택
  Widget _buildUserTypeSelection() {
    return Column(
      children: [
        const Text(
          '회원가입',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3E3F),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '회원 유형을 선택해주세요',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPartnerSignup = false;
                  });
                  _changeStep(1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BA688),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  '일반 사용자',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isPartnerSignup = true;
                  });
                  _changeStep(1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BA688),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                ),
                child: const Text(
                  '파트너',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          },
          child: const Text(
            '이미 계정이 있나요? 로그인',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF3BA688),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // 단계 1: 아이디 입력
  Widget _buildIdInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '아이디를 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '아이디',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _idController,
                autofocus: true,
                onChanged: (_) {
                  setState(() {
                    _isIdChecked = false;
                  });
                },
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
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _checkIdDuplicate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3BA688),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              child: const Text(
                '중복확인',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedFromId,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 단계 2: 비밀번호 입력
  Widget _buildPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const Text(
          '비밀번호',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofocus: true,
          onSubmitted: (_) => _proceedFromPassword(),
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF7A8C8D),
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedFromPassword,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 단계 3: 비밀번호 확인
  Widget _buildConfirmPasswordInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '비밀번호를 다시 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '비밀번호 확인',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          autofocus: true,
          onSubmitted: (_) => _proceedFromConfirmPassword(),
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: const Color(0xFF7A8C8D),
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedFromConfirmPassword,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 단계 4: 이메일 입력 및 인증
  Widget _buildEmailInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const Text(
          '이메일',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _emailLocalController,
                autofocus: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '이메일',
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
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              "@",
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF5A6C6D),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: _isCustomDomain
                  ? TextField(
                      controller: _emailDomainController,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '도메인',
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
                    )
                  : DropdownButtonFormField<String>(
                      value: _selectedEmailDomain,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: '선택',
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
                      items: _emailDomains.map((domain) {
                        return DropdownMenuItem(
                          value: domain,
                          child: Text(domain),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          if (value == '직접 입력') {
                            _isCustomDomain = true;
                            _selectedEmailDomain = null;
                            _emailDomainController.clear();
                          } else {
                            _selectedEmailDomain = value;
                          }
                        });
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _isVerified ? null : _sendVerificationCode,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _isVerified ? const Color(0xFFCCCCCC) : const Color(0xFF3BA688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 14,
              ),
            ),
            child: Text(
              _isVerified ? '인증완료' : '인증받기',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        if (_isVerificationSent && !_isVerified) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _verificationCodeController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '인증 코드',
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
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BA688),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _proceedFromEmail,
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 단계 5: 추가 정보 입력 (생년월일/법인정보, 주소, 닉네임)
  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '추가 정보를 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),

        // 닉네임 (선택사항)
        const Text(
          '닉네임 (선택)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nicknameController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '닉네임',
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

        // 생년월일 또는 법인정보
        if (!_isPartnerSignup) ...[
          const Text(
            '생년월일',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5A6C6D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedYear,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '년',
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
                  items: List.generate(100, (index) {
                    final year = (DateTime.now().year - index).toString();
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedYear = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMonth,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '월',
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
                  items: List.generate(12, (index) {
                    final month = (index + 1).toString().padLeft(2, '0');
                    return DropdownMenuItem(
                      value: month,
                      child: Text(month),
                    );
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedMonth = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedDay,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '일',
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
                  items: List.generate(31, (index) {
                    final day = (index + 1).toString().padLeft(2, '0');
                    return DropdownMenuItem(value: day, child: Text(day));
                  }),
                  onChanged: (value) {
                    setState(() {
                      _selectedDay = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ] else ...[
          const Text(
            '법인명',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5A6C6D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _companyNameController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: '법인명',
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
          const Text(
            '사업자번호',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5A6C6D),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _businessNumberController,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              hintText: '123-45-67890',
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
            keyboardType: TextInputType.number,
          ),
        ],

        const SizedBox(height: 24),

        // 주소 (선택사항)
        const Text(
          '주소 (선택)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _postalCodeController,
                readOnly: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: '우편번호',
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
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _searchAddress,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3BA688),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: const Text(
                '주소찾기',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '주소',
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
        const SizedBox(height: 12),
        TextField(
          controller: _addressDetailController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '상세주소',
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
        const SizedBox(height: 12),
        TextField(
          controller: _addressNoteController,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '참고사항',
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

        const SizedBox(height: 40),

        // 회원가입 버튼
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _handleSignup,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3BA688),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '회원가입',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
