// 홈 화면 위젯
// 반려동물 프로필 관리 및 펫 일기 화면
import 'package:flutter/material.dart';
import 'add_pet_profile_screen.dart';
import 'pet_profile_detail_screen.dart';
import 'pet_diary_screen.dart';
import '../services/pet_profile_manager.dart';
import '../models/pet_profile.dart';

/// 홈 화면
/// 반려동물 프로필 목록과 펫 일기를 표시하는 화면
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTabIndex = 0; // 0: 펫 프로필, 1: 펫 일기

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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // 등록된 펫 프로필 목록
                    ...PetProfileManager().getAllProfiles().map((profile) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _buildPetProfile(context, profile: profile),
                      );
                    }),
                    // 새로운 펫 추가 버튼
                    _buildAddPetButton(context),
                  ],
                ),
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
        setState(() {});
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE5E7EB),
              backgroundImage: profile.imageUrl != null
                  ? NetworkImage(profile.imageUrl!)
                  : null,
              child: profile.imageUrl == null
                  ? Icon(Icons.pets, size: 40, color: Colors.grey)
                  : null,
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

  /// 새로운 펫 추가 버튼
  Widget _buildAddPetButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddPetProfileScreen()),
        );
        if (result == true) {
          setState(() {});
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
