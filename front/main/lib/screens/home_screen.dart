// 홈 화면 위젯
// 반려동물 프로필 관리 및 펫 일기 화면
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import 'add_pet_profile_screen.dart';
import 'pet_profile_detail_screen.dart';
import 'pet_diary_screen.dart';
import '../services/pet_profile_manager.dart';
import '../models/pet_profile.dart';

/// 홈 화면
/// 반려동물 프로필 목록과 펫 일기를 표시하는 화면
class HomeScreen extends StatefulWidget {
  final int initialTabIndex; // 초기 탭 인덱스 (0: 펫 프로필, 1: 펫 일기)

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedTabIndex; // 0: 펫 프로필, 1: 펫 일기

  List<PetProfile> _petProfiles = []; // 펫 목록 데이터
  bool _isLoading = true; // 로딩 상태
  String? _errorMessage; // 에러 메세지

  Future<void> _loadPetProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 현재 로그인 한 사용자 확인
      final currentUser = AuthService().currentUser;

      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "로그인이 필요합니다. 냥!";
        });
        return;
      }
      // 백엔드 API호
      final response = await PetService().getPetsByOwner(currentUser.id);

      if (response['success'] == true) {
        // 성공: JSON 데이터를 PetProfile 객체로 변환
        final List<dynamic> petsData = response['pets'];
        final List<PetProfile> profiles = petsData
            .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _petProfiles = profiles;
          _isLoading = false;
        });
      } else {
        // 실패: 에러 메시지 설정
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? '펫 목록을 불러오지 못했습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '네트워크 오류: $e';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.initialTabIndex; // 초기 탭 설정
    _loadPetProfiles(); // 화면 로드 시 펫 목록 조회
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 상단 헤더 - 펫 프로필 / 펫 일기 탭
          Container(
            width: double.infinity,
            height: 30,
            color: const Color.fromARGB(255, 212, 244, 228),
            child: Row(
              children: [
                // 펫 프로필 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 0;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 108, 82),
                            fontSize: 16,
                            fontWeight: _selectedTabIndex == 0
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          '펫 프로필',
                        ),
                        SizedBox(height: 3),
                        Container(
                          height: 3,
                          width: 80,
                          color: _selectedTabIndex == 0
                              ? const Color.fromARGB(255, 0, 108, 82)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                // 펫 일기 탭
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = 1;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 108, 82),
                            fontSize: 16,
                            fontWeight: _selectedTabIndex == 1
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          '펫 일기',
                        ),
                        SizedBox(height: 3),
                        Container(
                          height: 3,
                          width: 60,
                          color: _selectedTabIndex == 1
                              ? const Color.fromARGB(255, 0, 108, 82)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 선택된 탭에 따라 컨텐츠 표시
          if (_selectedTabIndex == 0) ...[
            // 펫 프로필 탭 컨텐츠
            _buildPetProfileContent(),
          ] else ...[
            // 펫 일기 탭 컨텐츠
            PetDiaryContent(),
          ],
        ],
      ),
    );
  }

  /// 펫 프로필 컨텐츠
  Widget _buildPetProfileContent() {
    return Column(
      children: [
        // 펫 프로필 섹션
        Container(
          width: double.infinity,
          height: 50,
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                style: TextStyle(
                  color: const Color.fromARGB(255, 0, 108, 82),
                  fontSize: 16,
                ),
                '펫 프로필',
              ),
              SizedBox(height: 8),
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromARGB(255, 230, 233, 229),
              ),
            ],
          ),
        ),

        // 펫 프로필 리스트
        Container(
          padding: EdgeInsets.all(16),
          width: double.infinity,
          color: Colors.transparent,
          child: Column(
            children: [
              SizedBox(height: 20),
              // 로딩 중일 때
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: CircularProgressIndicator(
                    color: Color.fromARGB(255, 0, 108, 82),
                  ),
                )
              // 에러가 있을 때
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              // 정상적으로 데이터를 불러왔을 때
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    // 한 줄에 4개 표시, spacing 고려
                    final itemWidth = (constraints.maxWidth - (3 * 20)) / 4;
                    return Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.start,
                      children: [
                        ..._petProfiles.map((profile) {
                          return SizedBox(
                            width: itemWidth,
                            child: _buildPetProfile(context, profile: profile),
                          );
                        }),
                        // 새로운 펫 추가 버튼
                        SizedBox(
                          width: itemWidth,
                          child: _buildAddPetButton(context),
                        ),
                      ],
                    );
                  },
                ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  /// 펫 프로필 카드 위젯
  Widget _buildPetProfile(BuildContext context, {required PetProfile profile}) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PetProfileDetailScreen(profile: profile),
          ),
        );
        await _loadPetProfiles();
      },
      child: Column(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: PhysicalShape(
              clipper: _SvgMaskClipper(profile.species),
              color: Colors.transparent,
              shadowColor: Colors.black,
              elevation: 3,
              child: ClipPath(
                clipper: _SvgMaskClipper(profile.species),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Color(0xFFE5E7EB),
                  child: _isValidNetworkUrl(profile.imageUrl)
                      ? Image.network(
                          _getFullImageUrl(profile.imageUrl),
                          fit: BoxFit.cover,
                          width: 80,
                          height: 80,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.pets, size: 40, color: Colors.grey),
                            );
                          },
                        )
                      : Center(
                          child: Icon(Icons.pets, size: 40, color: Colors.grey),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            profile.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 0, 108, 82),
            ),
          ),
        ],
      ),
    );
  }

  /// 유효한 네트워크 URL인지 확인
  bool _isValidNetworkUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/media/');
  }

  /// 이미지 URL을 전체 경로로 변환
  String _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/media/')) {
      // 백엔드 서버 주소 추가 (Android 에뮬레이터: 10.0.2.2)
      return 'http://10.0.2.2:9075$url';
    }
    return url;
  }

  /// 새로운 펫 추가 버튼
  Widget _buildAddPetButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPetProfileScreen()),
        );
        if (result == true) {
          await _loadPetProfiles();
        }
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Color(0xFFD1D5DB), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add, size: 40, color: Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 8),
          Text(
            'Member',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

/// 펫 일기 컨텐츠 (별도 위젯으로 분리)
class PetDiaryContent extends StatelessWidget {
  const PetDiaryContent({super.key});

  @override
  Widget build(BuildContext context) {
    // PetDiaryScreen의 내용을 그대로 표시
    // PetDiaryScreen의 Scaffold를 제외한 body 부분만 사용
    return PetDiaryScreen();
  }
}

/// SVG 모양으로 이미지를 마스킹하는 CustomClipper
class _SvgMaskClipper extends CustomClipper<Path> {
  final String species;

  _SvgMaskClipper(this.species);

  @override
  Path getClip(Size size) {
    final path = Path();
    final speciesLower = species.toLowerCase();

    // 80x80 크기에 맞게 스케일 조정
    final scaleX = size.width / 302;
    final scaleY = size.height / 325;

    if (speciesLower.contains('dog') || speciesLower.contains('개')) {
      // 개 프레임 경로 (dog_i.svg의 path)
      path.moveTo(111 * scaleX, 30.1659 * scaleY);
      path.cubicTo(123.333 * scaleX, 25.8325 * scaleY, 156.6 * scaleX, 19.7659 * scaleY, 191 * scaleX, 30.1659 * scaleY);
      path.cubicTo(193.833 * scaleX, 22.1659 * scaleY, 204.5 * scaleX, 5.16587 * scaleY, 224.5 * scaleX, 1.16587 * scaleY);
      path.cubicTo(244.5 * scaleX, -2.83413 * scaleY, 260.833 * scaleX, 12.1659 * scaleY, 266.5 * scaleX, 20.1659 * scaleY);
      path.cubicTo(274.667 * scaleX, 30.9992 * scaleY, 287.3 * scaleX, 59.3659 * scaleY, 272.5 * scaleX, 86.1659 * scaleY);
      path.cubicTo(282.833 * scaleX, 99.4992 * scaleY, 303 * scaleX, 136.666 * scaleY, 301 * scaleX, 178.666 * scaleY);
      path.cubicTo(299.333 * scaleX, 197.499 * scaleY, 291.3 * scaleX, 240.766 * scaleY, 272.5 * scaleX, 263.166 * scaleY);
      path.cubicTo(261 * scaleX, 277.499 * scaleY, 228.6 * scaleX, 308.766 * scaleY, 191 * scaleX, 319.166 * scaleY);
      path.cubicTo(177.667 * scaleX, 322.833 * scaleY, 143 * scaleX, 327.966 * scaleY, 111 * scaleX, 319.166 * scaleY);
      path.cubicTo(94.6667 * scaleX, 314.999 * scaleY, 55.6 * scaleX, 297.966 * scaleY, 30 * scaleX, 263.166 * scaleY);
      path.cubicTo(20.3333 * scaleX, 252.333 * scaleY, 0.9 * scaleX, 220.266 * scaleY, 0.5 * scaleX, 178.666 * scaleY);
      path.cubicTo(0.833333 * scaleX, 159.666 * scaleY, 7.2 * scaleX, 114.566 * scaleY, 30 * scaleX, 86.1659 * scaleY);
      path.cubicTo(23.5 * scaleX, 76.1659 * scaleY, 15.5 * scaleX, 48.9659 * scaleY, 35.5 * scaleX, 20.1659 * scaleY);
      path.cubicTo(40 * scaleX, 12.6659 * scaleY, 54.7 * scaleX, -1.63412 * scaleY, 77.5 * scaleX, 1.16587 * scaleY);
      path.cubicTo(85.6667 * scaleX, 2.49921 * scaleY, 103.8 * scaleX, 10.1659 * scaleY, 111 * scaleX, 30.1659 * scaleY);
    } else {
      // 고양이 프레임 경로 (cat_i.svg의 path)
      final catScaleY = size.height / 331;
      path.moveTo(186.347 * scaleX, 35.1901 * catScaleY);
      path.cubicTo(172.847 * scaleX, 32.0235 * catScaleY, 139.547 * scaleX, 27.5901 * catScaleY, 114.347 * scaleX, 35.1901 * catScaleY);
      path.cubicTo(108.18 * scaleX, 26.0235 * catScaleY, 94.047 * scaleX, 6.29012 * catScaleY, 86.847 * scaleX, 0.690125 * catScaleY);
      path.cubicTo(76.1803 * scaleX, 9.52346 * catScaleY, 52.547 * scaleX, 36.8901 * catScaleY, 43.347 * scaleX, 75.6901 * catScaleY);
      path.cubicTo(11.0136 * scaleX, 109.19 * catScaleY, -34.253 * scaleX, 198.09 * catScaleY, 43.347 * scaleX, 285.69 * catScaleY);
      path.cubicTo(56.347 * scaleX, 300.023 * catScaleY, 94.5469 * scaleX, 328.99 * catScaleY, 143.347 * scaleX, 330.19 * catScaleY);
      path.cubicTo(167.014 * scaleX, 331.19 * catScaleY, 223.047 * scaleX, 323.69 * catScaleY, 257.847 * scaleX, 285.69 * catScaleY);
      path.cubicTo(290.18 * scaleX, 254.523 * catScaleY, 335.447 * scaleX, 168.89 * catScaleY, 257.847 * scaleX, 75.6901 * catScaleY);
      path.cubicTo(252.347 * scaleX, 58.5235 * catScaleY, 235.847 * scaleX, 19.4901 * catScaleY, 213.847 * scaleX, 0.690125 * catScaleY);
      path.cubicTo(206.18 * scaleX, 8.85679 * catScaleY, 189.947 * scaleX, 27.1901 * catScaleY, 186.347 * scaleX, 35.1901 * catScaleY);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

