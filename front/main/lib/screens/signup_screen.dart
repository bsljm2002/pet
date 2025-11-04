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

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController(); // 우편번호
  final TextEditingController _addressController = TextEditingController(); // 전체 주소
  final TextEditingController _emailLocalController = TextEditingController();
  final TextEditingController _emailDomainController = TextEditingController();
  final TextEditingController _verificationCodeController =
      TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessNumberController =
      TextEditingController();
  final TextEditingController _addressDetailController =
      TextEditingController(); // 상세 주소
  final TextEditingController _addressNoteController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isCustomDomain = false;
  bool _isVerificationSent = false;
  bool _isVerified = false;
  bool _isPartnerSignup = false; // 파트너 회원가입 여부

  String? _selectedYear;
  String? _selectedMonth;
  String? _selectedDay;
  String? _selectedEmailDomain;

  final List<String> _emailDomains = [
    'naver.com',
    'gmail.com',
    'daum.net',
    'kakao.com',
    'nate.com',
    '\uc9c1\uc811 \uc785\ub825',
  ];

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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

  void _sendVerificationCode() {
    // TODO: 인증 코드 전송 로직
    setState(() {
      _isVerificationSent = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('인증 코드가 전송되었습니다.')));
  }

  void _verifyCode() {
    // TODO: 인증 코드 확인 로직
    setState(() {
      _isVerified = true;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('이메일 인증이 완료되었습니다.')));
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isTaken ? '이미 사용 중인 아이디입니다.' : '사용 가능한 아이디입니다.',
        ),
        backgroundColor: isTaken ? Colors.red : Colors.green,
      ),
    );
  }

  // 주소 검색 기능
  Future<void> _searchAddress() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KpostalView(
          callback: (Kpostal result) {
            setState(() {
              // 우편번호 저장
              _postalCodeController.text = result.postCode;
              // 도로명 주소가 있으면 도로명 주소, 없으면 지번 주소 사용
              _addressController.text = result.address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _handleSignup() async {
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

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호가 일치하지 않습니다.')),
      );
      return;
    }

    if (_emailLocalController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일을 입력해주세요.')),
      );
      return;
    }

    // 이메일 도메인 확인
    String emailDomain;
    if (_isCustomDomain) {
      if (_emailDomainController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이메일 도메인을 입력해주세요.')),
        );
        return;
      }
      emailDomain = _emailDomainController.text.trim();
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

    // 이메일 인증 확인
    if (!_isVerified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일 인증을 완료해주세요.')),
      );
      return;
    }

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
      birthdate =
          DateTime(int.parse(_selectedYear!), int.parse(_selectedMonth!), int.parse(_selectedDay!));
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
      // 회원가입 성공
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'])),
        );
        // 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } else {
      // 회원가입 실패
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
                    '회원가입',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // 회원 유형 선택 버튼
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isPartnerSignup = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: !_isPartnerSignup
                              ? const Color(0xFF3BA688)
                              : Colors.white,
                          foregroundColor: !_isPartnerSignup
                              ? Colors.white
                              : const Color(0xFF5A6C6D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: !_isPartnerSignup
                                  ? const Color(0xFF3BA688)
                                  : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPartnerSignup
                              ? const Color(0xFF3BA688)
                              : Colors.white,
                          foregroundColor: _isPartnerSignup
                              ? Colors.white
                              : const Color(0xFF5A6C6D),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: _isPartnerSignup
                                  ? const Color(0xFF3BA688)
                                  : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
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

                // 아이디 섹션
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '아이디',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF5A6C6D),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: ElevatedButton(
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
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 비밀번호
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
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
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

                // 비밀번호 확인
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
                const Text(
                  '이메일',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6C6D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // 이메일 입력
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _emailLocalController,
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
                                hintText: '도메인 입력',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB0B8B8),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                              ),
                              keyboardType: TextInputType.text,
                            )
                          : DropdownButtonFormField<String>(
                              value: _selectedEmailDomain,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: '선택',
                                hintStyle: const TextStyle(
                                  color: Color(0xFFB0B8B8),
                                ),
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
                const SizedBox(height: 8),

                const SizedBox(width: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _isVerified ? null : _sendVerificationCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isVerified
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
                      _isVerified ? '인증완료' : '인증받기',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 인증 코드 입력 섹션 (인증 코드 전송 후 표시)
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
                            hintText: '인증 코드 입력',
                            hintStyle: const TextStyle(
                              color: Color(0xFFB0B8B8),
                            ),
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
                          '인증 확인',
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

                // 생년월일 또는 법인정보 (회원 유형에 따라 다르게 표시)
                if (!_isPartnerSignup) ...[
                  // 일반 사용자: 생년월일
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
                            hintStyle:
                                const TextStyle(color: Color(0xFFB0B8B8)),
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
                            final year =
                                (DateTime.now().year - index).toString();
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
                            hintStyle:
                                const TextStyle(color: Color(0xFFB0B8B8)),
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
                            final month =
                                (index + 1).toString().padLeft(2, '0');
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
                            hintStyle:
                                const TextStyle(color: Color(0xFFB0B8B8)),
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
                            return DropdownMenuItem(
                                value: day, child: Text(day));
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
                  // 파트너: 법인명
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
                      hintText: '법인명을 입력하세요',
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
                  // 사업자번호
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
                      hintText: '사업자번호를 입력하세요 (예: 123-45-67890)',
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

                // 주소 섹션
                const Text(
                  '주소',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6C6D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),

                // 우편번호와 주소찾기 버튼
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _postalCodeController,
                        readOnly: true, // 읽기 전용으로 설정
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
                          horizontal: 20,
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

                // 전체 주소
                TextField(
                  controller: _addressController,
                  readOnly: true, // 읽기 전용으로 설정
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: '주소찾기 버튼을 눌러주세요',
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

                // 상세주소
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

                // 참고사항
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

                const SizedBox(height: 24),

                // 로그인 링크
                Center(
                  child: Column(
                    children: [
                      const Text(
                        '이미 계정이 있나요?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5A6C6D),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                          '로그인',
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
}
