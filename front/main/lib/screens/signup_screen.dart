import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kpostal/kpostal.dart';
import 'login_screen.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/fcm_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController(); // 성명
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _emailLocalController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _addressDetailController =
      TextEditingController();
  final TextEditingController _addressNoteController = TextEditingController();

  final AuthService _authService = AuthService();
  final FCMService _fcmService = FCMService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCustomDomain = false;
  bool _isPartnerSignup = false;
  bool _isEmailChecked = false; // 이메일 중복확인 여부

  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedEmailDomain;
  String? _selectedGender;
  String? _selectedPartnerType; // 파트너 타입 (HOSPITAL/SITTER)

  // 회원가입 단계 관리
  // 0: 회원 유형 선택
  // 1: 이메일 입력 및 중복확인
  // 2: 비밀번호 입력
  // 3: 비밀번호 확인
  // 4: 성명 입력
  // 5: 생년월일 입력
  // 6: 성별 선택
  // 7: 파트너 유형 선택 (파트너만)
  // 8: 추가 정보 입력 (닉네임, 법인정보, 주소 등)
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
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nicknameController.dispose();
    _postalCodeController.dispose();
    _addressController.dispose();
    _emailLocalController.dispose();
    _emailDomainController.dispose();
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
    final username = _nameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디를 입력해주세요.')),
      );
      return;
    }

    final isTaken = _authService.isUsernameTaken(username);

    if (!isTaken) {
      setState(() {
        _isEmailChecked = true;
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

  Future<void> _checkEmailDuplicate() async {
    // 이메일 입력값 검증
    if (_emailLocalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.')),
      );
      return;
    }

    String domain;
    if (_isCustomDomain) {
      if (_emailDomainController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 도메인을 입력해주세요.')),
        );
        return;
      }
      domain = _emailDomainController.text.trim();
    } else {
      if (_selectedEmailDomain == null || _selectedEmailDomain!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 도메인을 선택해주세요.')),
        );
        return;
      }
      domain = _selectedEmailDomain!;
    }

    String fullEmail = '${_emailLocalController.text.trim()}@$domain';

    // 이메일 형식 검증
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(fullEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 이메일 형식이 아닙니다.')),
      );
      return;
    }

    // 백엔드 API를 호출하여 이메일 중복 확인
    final result = await _authService.checkEmailDuplicate(fullEmail);

    if (!mounted) return;

    if (result['success'] == true) {
      bool exists = result['exists'] ?? false;

      if (exists) {
        // 이메일이 이미 존재함 (중복)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '이미 사용 중인 이메일입니다.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isEmailChecked = false;
        });
      } else {
        // 이메일 사용 가능
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? '사용 가능한 이메일입니다.'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEmailChecked = true;
        });
      }
    } else {
      // API 호출 실패
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? '이메일 확인에 실패했습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isEmailChecked = false;
      });
    }
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

  // 단계 2: 비밀번호 입력 완료 및 다음 단계로 진행
  void _proceedFromPassword() {
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요.')),
      );
      return;
    }

    if (_passwordController.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호는 8자 이상이어야 합니다.')),
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

    _changeStep(4); // 성명 입력 단계로
  }

  // 단계 1: 이메일 입력 완료 및 다음 단계로 진행
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

    // 이메일 중복확인 검증
    if (!_isEmailChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 중복확인을 해주세요.')),
      );
      return;
    }

    _changeStep(2); // 비밀번호 입력 단계로
  }

  Future<void> _handleSignup() async {
    print('=== 회원가입 시작 ===');

    // 이메일 도메인 확인
    String emailDomain;
    if (_isCustomDomain) {
      emailDomain = _emailDomainController.text.trim();
      if (emailDomain.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 도메인을 입력해주세요.')),
        );
        return;
      }
    } else {
      if (_selectedEmailDomain == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 도메인을 선택해주세요.')),
        );
        return;
      }
      emailDomain = _selectedEmailDomain!;
    }

    final fullEmail = '${_emailLocalController.text.trim()}@$emailDomain';
    print('이메일: $fullEmail');

    // 닉네임 확인 (필수)
    if (_nicknameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('닉네임을 입력해주세요.')),
      );
      return;
    }

    // 성별 확인 (필수)
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('성별을 선택해주세요.')),
      );
      return;
    }

    // 생년월일 확인 (모든 사용자 필수)
    if (_selectedYear == null ||
        _selectedMonth == null ||
        _selectedDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생년월일을 입력해주세요.')),
      );
      return;
    }

    DateTime birthdate = DateTime(
      int.parse(_selectedYear!),
      int.parse(_selectedMonth!),
      int.parse(_selectedDay!),
    );

    // 파트너: 파트너 타입, 법인명, 사업자번호 확인
    String? companyName;
    String? businessNumber;

    if (_isPartnerSignup) {
      // 파트너 타입 확인
      if (_selectedPartnerType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('파트너 유형을 선택해주세요.')),
        );
        return;
      }

      // 법인명 확인
      if (_companyNameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('법인명을 입력해주세요.')),
        );
        return;
      }

      // 사업자번호 확인
      if (_businessNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사업자번호를 입력해주세요.')),
        );
        return;
      }

      companyName = _companyNameController.text.trim();
      businessNumber = _businessNumberController.text.trim();
    }

    print('회원가입 요청 데이터:');
    print('- username: ${_nameController.text.trim()}');
    print('- nickname: ${_nicknameController.text.trim()}');
    print('- gender: $_selectedGender');
    print('- birthdate: $birthdate');
    print('- partnerType: $_selectedPartnerType');

    // 파트너 타입에 따라 UserType 결정
    UserType userType = UserType.general;
    if (_isPartnerSignup && _selectedPartnerType != null) {
      switch (_selectedPartnerType!) {
        case 'HOSPITAL':
          userType = UserType.hospital;
          break;
        case 'SITTER':
          userType = UserType.sitter;
          break;
        default:
          userType = UserType.general;
      }
    }

    // FCM 토큰 가져오기
    String? fcmToken;
    try {
      fcmToken = await _fcmService.getToken();
      print('📱 회원가입 시 FCM 토큰: $fcmToken');
    } catch (e) {
      print('⚠️ FCM 토큰 가져오기 실패: $e');
      // FCM 토큰 없이도 회원가입 진행
    }

    // 회원가입 처리
    final result = await _authService.signUp(
      username: _nameController.text.trim(),
      email: fullEmail,
      password: _passwordController.text,
      userType: userType,
      nickname: _nicknameController.text.trim(),
      gender: _selectedGender!,
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
      companyName: companyName,
      businessNumber: businessNumber,
      fcmToken: fcmToken,
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
      backgroundColor: const Color.fromARGB(255, 252, 255, 224),
      body: SafeArea(
        child: Stack(
          children: [
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
                          child: _buildCurrentStep(),
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
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
        return _buildEmailInput(); // 이메일 입력 (중복확인)
      case 2:
        return _buildPasswordInput();
      case 3:
        return _buildConfirmPasswordInput();
      case 4:
        return _buildNameInput(); // 성명 입력
      case 5:
        return _buildBirthdateInput(); // 생년월일 입력
      case 6:
        return _buildGenderInput(); // 성별 선택
      case 7:
        return _buildPartnerTypeInput(); // 파트너 유형 선택 (파트너만)
      case 8:
        return _buildAdditionalInfo(); // 추가 정보 입력
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
  // 단계 4: 성명 입력
  Widget _buildNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '성명을 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '성명',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          autofocus: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: '이름을 입력하세요',
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
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('성명을 입력해주세요.')),
                );
                return;
              }
              _changeStep(5); // 생년월일 입력 단계로
            },
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

  // 단계 1: 이메일 입력 및 중복확인
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
                onChanged: (_) {
                  setState(() {
                    _isEmailChecked = false; // 이메일 변경 시 중복확인 초기화
                  });
                },
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
                      onChanged: (_) {
                        setState(() {
                          _isEmailChecked = false;
                        });
                      },
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
                          value: domain == '직접 입력' ? null : domain,
                          child: Text(domain),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _isEmailChecked = false;
                          if (value == null) {
                            _isCustomDomain = true;
                            _selectedEmailDomain = null;
                            _emailDomainController.clear();
                          } else {
                            _isCustomDomain = false;
                            _selectedEmailDomain = value;
                          }
                        });
                      },
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // 중복확인 버튼
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            onPressed: _checkEmailDuplicate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _isEmailChecked
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF3BA688),
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
              _isEmailChecked ? '확인완료' : '중복확인',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
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

  // 단계 8: 추가 정보 입력 (닉네임, 법인정보, 주소)
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

        // 닉네임 (필수)
        const Text(
          '닉네임 *',
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

        // 법인정보 (파트너만)
        if (_isPartnerSignup) ...[
          const Text(
            '법인명 *',
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
            '사업자번호 *',
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
          const SizedBox(height: 24),
        ],

        // 주소 (선택)
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
            onPressed: () {
              print('🔥🔥🔥 회원가입 버튼 클릭됨! 🔥🔥🔥');
              _handleSignup();
            },
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

  // 단계 5: 생년월일 입력
  Widget _buildBirthdateInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '생년월일을 입력하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '생년월일 *',
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
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              if (_selectedYear == null ||
                  _selectedMonth == null ||
                  _selectedDay == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('생년월일을 선택해주세요.')),
                );
                return;
              }
              _changeStep(6); // 성별 선택 단계로
            },
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

  // 단계 6: 성별 선택
  Widget _buildGenderInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '성별을 선택하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '성별 *',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGender,
              hint: const Text(
                '성별을 선택하세요',
                style: TextStyle(color: Color(0xFFB0B8B8)),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('남성')),
                DropdownMenuItem(value: 'FEMALE', child: Text('여성')),
                DropdownMenuItem(value: 'OTHER', child: Text('기타')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
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
            onPressed: () {
              if (_selectedGender == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('성별을 선택해주세요.')),
                );
                return;
              }
              // 파트너인 경우 파트너 유형 선택 단계로, 일반 사용자는 추가 정보 입력 단계로
              if (_isPartnerSignup) {
                _changeStep(7); // 파트너 유형 선택 단계로
              } else {
                _changeStep(8); // 추가 정보 입력 단계로
              }
            },
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

  // 단계 7: 파트너 유형 선택 (파트너만)
  Widget _buildPartnerTypeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(
          child: Text(
            '파트너 유형을 선택하세요',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E3F),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Text(
          '파트너 유형 *',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF5A6C6D),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPartnerType,
              hint: const Text(
                '파트너 유형을 선택하세요',
                style: TextStyle(color: Color(0xFFB0B8B8)),
              ),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'HOSPITAL', child: Text('펫닥터 (동물병원)')),
                DropdownMenuItem(value: 'SITTER', child: Text('펫시터')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedPartnerType = value;
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
            onPressed: () {
              if (_selectedPartnerType == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('파트너 유형을 선택해주세요.')),
                );
                return;
              }
              _changeStep(8); // 추가 정보 입력 단계로
            },
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
}
