import 'package:flutter/material.dart';
import 'sitter_settings_screen.dart';
import 'sitter_reservation_screen.dart';
import 'partner_chat_rooms_screen.dart';
import 'partner_profile_form_screen.dart';
import '../../services/auth_service.dart';
import '../../services/partner_service.dart';
import '../../services/notification_badge_service.dart';
import '../../services/fcm_service.dart';
import '../../models/partner_profile_model.dart';

class SitterHomeScreen extends StatefulWidget {
  const SitterHomeScreen({super.key});

  @override
  State<SitterHomeScreen> createState() => _SitterHomeScreenState();
}

class _SitterHomeScreenState extends State<SitterHomeScreen> {
  int _currentIndex = 0;
  final NotificationBadgeService _badgeService = NotificationBadgeService();
  final FCMService _fcmService = FCMService();

  int _reservationBadgeCount = 0;

  final List<Widget> _pages = [
    const SitterMainPage(),
    const SitterReservationScreen(),
    const PartnerChatRoomsScreen(),
    const SitterSettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadBadgeCounts();
    _setupFCMListeners();
  }

  @override
  void dispose() {
    _fcmService.onMessageReceived = null;
    super.dispose();
  }

  /// 뱃지 카운트 로드
  Future<void> _loadBadgeCounts() async {
    final reservationCount = await _badgeService.getReservationCount();

    setState(() {
      _reservationBadgeCount = reservationCount;
    });
  }

  /// FCM 리스너 설정 (새 예약 시 뱃지 증가)
  void _setupFCMListeners() {
    _fcmService.onMessageReceived = (data) {
      // 새 예약 알림
      if (data['type'] == 'new_reservation') {
        _badgeService.incrementReservationCount();
        _loadBadgeCounts();
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // 예약 관리 페이지로 이동 시 뱃지 리셋
            if (index == 1) {
              _badgeService.resetReservationCount();
              _loadBadgeCounts();
            }
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3BA688),
        unselectedItemColor: const Color(0xFF5A6C6D),
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(
            icon: _buildBadgeIcon(Icons.calendar_month, _reservationBadgeCount),
            label: '예약 관리',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: '채팅'),
          const BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }

  /// 뱃지가 있는 아이콘 생성
  Widget _buildBadgeIcon(IconData icon, int count) {
    if (count == 0) {
      return Icon(icon);
    }

    return Badge(
      label: Text(count > 99 ? '99+' : count.toString()),
      backgroundColor: Colors.red,
      textColor: Colors.white,
      child: Icon(icon),
    );
  }
}

class SitterMainPage extends StatefulWidget {
  const SitterMainPage({super.key});

  @override
  State<SitterMainPage> createState() => _SitterMainPageState();
}

class _SitterMainPageState extends State<SitterMainPage> {
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
    print('=== 프로필 로드 시작 ===');

    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      print('로그인된 사용자 없음');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    print('현재 사용자 ID: ${currentUser.id}');
    print('현재 사용자 이름: ${currentUser.username}');

    try {
      final userId = int.parse(currentUser.id);
      print('API 호출: getMyPartners(userId: $userId)');

      final partners = await _partnerService.getMyPartners(userId);

      print('API 응답: ${partners.length}개의 파트너 프로필');

      if (partners.isNotEmpty) {
        print('첫 번째 프로필 정보:');
        print('  - ID: ${partners.first.id}');
        print('  - 이름: ${partners.first.name}');
        print('  - 주소: ${partners.first.address}');
        print('  - 전화번호: ${partners.first.phone}');
        print(
          '  - 위치: ${partners.first.latitude}, ${partners.first.longitude}',
        );

        setState(() {
          _partnerProfile = partners.first;
          _isLoading = false;
        });
        print('프로필 로드 완료');
      } else {
        print('등록된 프로필 없음');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('프로필 로드 오류: $e');
      print('스택 트레이스: $stackTrace');
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

  /// 이미지 확대 보기 다이얼로그
  void _showImageDialog(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(0),
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.white,
                              size: 64,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('펫시터 홈'),
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
                    backgroundImage:
                        _partnerProfile?.imageUrl != null &&
                            _partnerProfile!.imageUrl!.isNotEmpty
                        ? NetworkImage(_partnerProfile!.imageUrl!)
                        : null,
                    child:
                        _partnerProfile?.imageUrl == null ||
                            _partnerProfile!.imageUrl!.isEmpty
                        ? const Icon(
                            Icons.pets,
                            size: 60,
                            color: Color(0xFF4FC59E),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _partnerProfile?.name ??
                        currentUser?.nickname ??
                        currentUser?.username ??
                        '펫시터명 미등록',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _partnerProfile?.doctorName ??
                        currentUser?.username ??
                        '담당자',
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
                      (_partnerProfile?.isOpen ?? true) ? '현재 서비스 가능' : '현재 휴무',
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
                        color:
                            _partnerProfile?.description?.trim().isEmpty ?? true
                            ? Colors.grey.shade600
                            : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 갤러리 사진
            if (_partnerProfile?.galleryImages != null &&
                _partnerProfile!.galleryImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '갤러리',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF003829),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _partnerProfile!.galleryImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImageDialog(_partnerProfile!.galleryImages, index),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4FC59E).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: Image.network(
                                _partnerProfile!.galleryImages[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

            // 자격증 및 경력
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '자격증 및 경력',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_partnerProfile?.experience != null &&
                      _partnerProfile!.experience!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.work,
                            color: Color(0xFF4FC59E),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '경력: ${_partnerProfile!.experience}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_partnerProfile?.certifications != null &&
                      _partnerProfile!.certifications.isNotEmpty)
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
                    })
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        '자격증 및 경력 정보가 등록되지 않았습니다.',
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

            // 희망 서비스
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '희망 서비스',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _partnerProfile?.specialties != null &&
                          _partnerProfile!.specialties.isNotEmpty
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _partnerProfile!.specialties.map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF4FC59E,
                                ).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(
                                    0xFF4FC59E,
                                  ).withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                service,
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
                            '희망 서비스가 등록되지 않았습니다.',
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

            // 서비스 시간
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '서비스 시간',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _partnerProfile?.availableTimes != null &&
                          _partnerProfile!.availableTimes.isNotEmpty
                      ? Wrap(
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
                            '서비스 시간 정보가 등록되지 않았습니다.',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
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
                initialPartnerType: 'SITTER', // 펫시터 타입으로 명시
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
