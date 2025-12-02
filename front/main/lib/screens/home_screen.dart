// 홈 화면 위젯
// 반려동물 프로필 관리 화면
import 'package:flutter/material.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import 'add_pet_profile_screen.dart';
import 'pet_profile_detail_screen.dart';
import '../models/pet_profile.dart';

/// 홈 화면
/// 반려동물 프로필 목록을 표시하는 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    _loadPetProfiles(); // 화면 로드 시 펫 목록 조회
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 240),
        body: Column(
          children: [
            // 상단 탭바 (고정)
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const TabBar(
                labelColor: Color.fromARGB(255, 0, 108, 82),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color.fromARGB(255, 0, 108, 82),
                tabs: [Tab(text: '펫홈')],
              ),
            ),
            // 탭별 컨텐츠 (스크롤 가능)
            Expanded(
              child: TabBarView(
                children: [
                  // 펫홈 탭
                  SingleChildScrollView(child: _buildPetProfileContent()),
                  // 일기 탭 (추후 구현)
                  SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          '일기 기능은 추후 구현 예정입니다.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 펫 프로필 컨텐츠
  Widget _buildPetProfileContent() {
    return Column(
      children: [
        // 나의 반려동물 헤더
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
                '나의 반려동물',
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
          child: Column(
            children: [
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
                Column(
                  children: [
                    ..._petProfiles.map((profile) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildPetProfile(context, profile: profile),
                      );
                    }),
                    // 새로운 펫 추가 버튼
                    _buildAddPetButton(context),
                  ],
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 프로필 이미지
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                color: Color(0xFFE5E7EB),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
                child: _isValidNetworkUrl(profile.imageUrl)
                    ? Image.network(
                        _getFullImageUrl(profile.imageUrl),
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.pets,
                              size: 45,
                              color: Colors.grey,
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Icon(Icons.pets, size: 45, color: Colors.grey),
                      ),
              ),
            ),
            // 펫 정보
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 108, 82),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      profile.speciesDetail ?? profile.species,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '몸무게: ${profile.weight}kg',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            // 화살표 아이콘
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 유효한 네트워크 URL인지 확인
  bool _isValidNetworkUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/media/');
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color.fromARGB(255, 255, 255, 255),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 추가 아이콘
            Container(
              width: 100,
              height: 50,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
              alignment: Alignment.center,
              child: Icon(Icons.add, size: 40, color: Color(0xFF3BA688)),
            ),
            // 텍스트
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Text(
                  '새 반려동물 추가',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3BA688),
                  ),
                ),
              ),
            ),
            // 화살표 아이콘
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFF3BA688),
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
