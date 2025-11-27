import 'package:flutter/material.dart';
import 'hospital_settings_screen.dart';
import 'hospital_reservation_screen.dart';
import 'partner_consultations_screen.dart';
import 'partner_chat_rooms_screen.dart';
import 'partner_profile_form_screen.dart';
import '../../services/auth_service.dart';
import '../../services/partner_service.dart';
import '../../models/partner_profile_model.dart';

class HospitalHomeScreen extends StatefulWidget {
  const HospitalHomeScreen({super.key});

  @override
  State<HospitalHomeScreen> createState() => _HospitalHomeScreenState();
}

class _HospitalHomeScreenState extends State<HospitalHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HospitalMainPage(),
    const HospitalReservationScreen(),
    const PartnerConsultationsScreen(),
    const PartnerChatRoomsScreen(),
    const HospitalSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3BA688),
        unselectedItemColor: const Color(0xFF5A6C6D),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: '예약 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            label: '상담 관리',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: '채팅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class HospitalMainPage extends StatefulWidget {
  const HospitalMainPage({super.key});

  @override
  State<HospitalMainPage> createState() => _HospitalMainPageState();
}

class _HospitalMainPageState extends State<HospitalMainPage> {
  final PartnerService _partnerService = PartnerService();
  final AuthService _authService = AuthService();
  PartnerProfileModel? _partnerProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPartnerProfile();
  }

  Future<void> _loadPartnerProfile() async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final partners = await _partnerService.getMyPartners(int.parse(currentUser.id));
      if (partners.isNotEmpty) {
        setState(() {
          _partnerProfile = partners.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('프로필 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 영문 요일을 한글로 변환
  String _getDayKorean(String day) {
    switch (day.toUpperCase()) {
      case 'MONDAY':
        return '월';
      case 'TUESDAY':
        return '화';
      case 'WEDNESDAY':
        return '수';
      case 'THURSDAY':
        return '목';
      case 'FRIDAY':
        return '금';
      case 'SATURDAY':
        return '토';
      case 'SUNDAY':
        return '일';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('펫닥터 (동물병원) 홈'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 프로필 헤더
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    backgroundImage: _partnerProfile?.imageUrl != null && _partnerProfile!.imageUrl!.isNotEmpty
                        ? NetworkImage(_partnerProfile!.imageUrl!)
                        : null,
                    child: _partnerProfile?.imageUrl == null || _partnerProfile!.imageUrl!.isEmpty
                        ? const Icon(
                            Icons.local_hospital,
                            size: 60,
                            color: Color(0xFF4FC59E),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _partnerProfile?.name ?? currentUser?.nickname ?? currentUser?.username ?? '병원명 미등록',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _partnerProfile?.doctorName ?? currentUser?.username ?? '담당 수의사',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4FC59E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${_partnerProfile?.rating ?? 0.0}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (_partnerProfile?.experience != null && _partnerProfile!.experience!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.work, color: Color(0xFF4FC59E), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          _partnerProfile!.experience!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: (_partnerProfile?.isOpen ?? true)
                          ? const Color(0xFF4FC59E)
                          : Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      (_partnerProfile?.isOpen ?? true) ? '현재 영업중' : '현재 휴무',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 소개
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '소개',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Text(
                      _partnerProfile?.description?.trim().isEmpty ?? true
                          ? '소개 정보가 등록되지 않았습니다.\n프로필 등록 버튼을 눌러 정보를 입력하세요.'
                          : _partnerProfile!.description!.trim(),
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: _partnerProfile?.description?.trim().isEmpty ?? true
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 학력 사항
            if (_partnerProfile?.education != null && _partnerProfile!.education.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '학력 사항',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._partnerProfile!.education.map((edu) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.school,
                              color: Color(0xFF4FC59E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                edu,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 자격증 및 인증
            if (_partnerProfile?.certifications != null && _partnerProfile!.certifications.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '자격증 및 인증',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._partnerProfile!.certifications.map((cert) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.verified,
                              color: Color(0xFF4FC59E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cert,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 전문 진료
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '전문 진료',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _partnerProfile?.specialties != null && _partnerProfile!.specialties.isNotEmpty
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _partnerProfile!.specialties.map((specialty) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4FC59E).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF4FC59E).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                specialty,
                                style: const TextStyle(
                                  color: Color(0xFF003829),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            '전문 진료 정보가 등록되지 않았습니다.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 연락처 정보
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '연락처 정보',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Color(0xFF4FC59E)),
                      const SizedBox(width: 12),
                      Text(
                        _partnerProfile?.phone ?? '전화번호 미등록',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.place, color: Color(0xFF4FC59E)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _partnerProfile?.address ?? '주소 미등록',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 영업 시간
            if (_partnerProfile?.workingStartHours != null && _partnerProfile!.workingEndHours != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '영업 시간',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F7F1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF4FC59E).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          // 근무 요일
                          if (_partnerProfile!.workingDays.isNotEmpty) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  color: Color(0xFF4FC59E),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        '근무 요일',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF003829),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: _partnerProfile!.workingDays.map((day) {
                                          String dayKorean = _getDayKorean(day);
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF4FC59E).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              dayKorean,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF003829),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],
                          // 근무 시간
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Color(0xFF4FC59E),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '근무 시간',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF003829),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_partnerProfile!.workingStartHours} ~ ${_partnerProfile!.workingEndHours}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4FC59E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 예약 가능 시간
            if (_partnerProfile?.availableTimes != null && _partnerProfile!.availableTimes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '예약 가능 시간',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _partnerProfile!.availableTimes.map((time) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC59E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            time,
                            style: const TextStyle(
                              color: Color(0xFF003829),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PartnerProfileFormScreen(
                existingProfile: _partnerProfile,
                initialPartnerType: 'HOSPITAL', // 병원 타입으로 명시
              ),
            ),
          );
          if (result == true) {
            _loadPartnerProfile();
          }
        },
        backgroundColor: const Color(0xFF4FC59E),
        icon: Icon(_partnerProfile == null ? Icons.add : Icons.edit),
        label: Text(_partnerProfile == null ? '프로필 등록' : '프로필 수정'),
      ),
    );
  }
}
