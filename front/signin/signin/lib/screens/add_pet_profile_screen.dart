// 펫 프로필 생성 화면
// 새로운 반려동물의 프로필을 등록하는 페이지
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';

/// 새로운 펫 프로필 추가 화면
///
/// 반려동물의 정보를 입력받아 새로운 프로필을 생성
/// - 프로필 이미지 선택
/// - 이름, 생년월일, 품종, 알고 있는 질환 입력
/// - 성별 선택
/// - ABTI 테스트 진행
class AddPetProfileScreen extends StatefulWidget {
  const AddPetProfileScreen({Key? key}) : super(key: key);

  @override
  State<AddPetProfileScreen> createState() => _AddPetProfileScreenState();
}

class _AddPetProfileScreenState extends State<AddPetProfileScreen> {
  // 텍스트 입력 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();

  // 선택된 프로필 이미지 URL (임시)
  String? _selectedImageUrl;

  // 선택된 성별 ('Man' 또는 'Woman')
  String? _selectedGender;

  // 선택된 반려동물 종류 ('dog' 또는 'cat')
  String? _selectedSpecies;

  // 선택된 품종
  String? _selectedBreed;

  // 선택된 질환
  String? _selectedDisease;

  // 강아지 품종 리스트
  final List<String> _dogBreeds = [
    '말티즈',
    '푸들',
    '치와와',
    '포메라니안',
    '요크셔테리어',
    '시츄',
    '비글',
    '웰시코기',
    '골든 리트리버',
    '시바견',
    '믹스견',
    '기타',
  ];

  // 고양이 품종 리스트
  final List<String> _catBreeds = [
    '코리안 숏헤어',
    '페르시안',
    '러시안 블루',
    '스코티시 폴드',
    '브리티시 숏헤어',
    '샴',
    '메인쿤',
    '뱅갈',
    '아비시니안',
    '노르웨이 숲',
    '믹스묘',
    '기타',
  ];

  // 질환 리스트
  final List<String> _diseases = [
    '없음',
    '피부 질환',
    '관절염',
    '심장 질환',
    '신장 질환',
    '당뇨',
    '알레르기',
    '치아 질환',
    '비만',
    '기타',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _breedController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 상단 앱바
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 254, 254, 254),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 207, 229, 218),
              Colors.white,
              const Color.fromARGB(255, 254, 254, 254),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Column(
          children: [
            // 프로필 등록 컨텐츠
            Expanded(child: SingleChildScrollView(child: _buildProfileTab())),
            // 하단 등록 버튼
            _buildRegisterButton(),
          ],
        ),
      ),
    );
  }

  /// 펫 프로필 등록 탭
  Widget _buildProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 신규 생성 섹션 헤더
          _buildSectionHeader('신규 생성'),
          SizedBox(height: 20),
          // 펫 종류 선택 (강아지/고양이)
          _buildSpeciesSelector(),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 왼쪽: 입력 필드들
              Expanded(
                child: Column(
                  children: [
                    _buildInputField('펫 이름', _nameController),
                    SizedBox(height: 12),
                    _buildInputField('펫 생년월일', _birthdayController),
                    SizedBox(height: 12),
                    _buildBreedDropdown(),
                    SizedBox(height: 12),
                    _buildDiseaseDropdown(),
                  ],
                ),
              ),
              SizedBox(width: 20),
              // 오른쪽: 프로필 이미지 (펫 이름 라벨 높이에서 시작)
              GestureDetector(
                onTap: () {
                  // TODO: 이미지 선택 기능 구현
                  print('이미지 선택 클릭');
                },
                child: Container(
                  width: 100,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(
                      color: const Color.fromARGB(255, 200, 200, 200),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.add,
                    size: 40,
                    color: const Color.fromARGB(255, 180, 180, 180),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          // 펫 성별 섹션
          _buildSectionHeader('펫 성별'),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderButton('Man', Icons.male, Colors.blue),
              SizedBox(width: 40),
              _buildGenderButton('Man', Icons.female, Colors.red),
            ],
          ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(String title) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 2,
          width: double.infinity,
          color: const Color.fromARGB(255, 0, 108, 82),
        ),
      ],
    );
  }

  /// 입력 필드
  Widget _buildInputField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
          ),
        ),
      ],
    );
  }

  /// 펫 종류 선택 (강아지/고양이)
  Widget _buildSpeciesSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 강아지 선택
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpecies = 'dog';
              _selectedBreed = null; // 종류 변경 시 품종 초기화
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedSpecies == 'dog'
                  ? const Color.fromARGB(255, 0, 108, 82)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 0, 108, 82),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pets,
                  color: _selectedSpecies == 'dog'
                      ? Colors.white
                      : const Color.fromARGB(255, 0, 108, 82),
                ),
                SizedBox(width: 8),
                Text(
                  '강아지',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedSpecies == 'dog'
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 108, 82),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 20),
        // 고양이 선택
        GestureDetector(
          onTap: () {
            setState(() {
              _selectedSpecies = 'cat';
              _selectedBreed = null; // 종류 변경 시 품종 초기화
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            decoration: BoxDecoration(
              color: _selectedSpecies == 'cat'
                  ? const Color.fromARGB(255, 0, 108, 82)
                  : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color.fromARGB(255, 0, 108, 82),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.pets,
                  color: _selectedSpecies == 'cat'
                      ? Colors.white
                      : const Color.fromARGB(255, 0, 108, 82),
                ),
                SizedBox(width: 8),
                Text(
                  '고양이',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _selectedSpecies == 'cat'
                        ? Colors.white
                        : const Color.fromARGB(255, 0, 108, 82),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 품종 선택 드롭다운
  Widget _buildBreedDropdown() {
    // 선택된 종에 따라 품종 리스트 결정
    List<String> breedList = _selectedSpecies == 'dog' ? _dogBreeds : _catBreeds;
    String label = _selectedSpecies == 'dog' ? '강아지 품종' : '고양이 품종';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: _selectedSpecies == null
              ? null
              : () {
                  _showBreedPicker(breedList);
                },
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: _selectedSpecies == null
                  ? Colors.grey.shade200
                  : Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedBreed ?? (_selectedSpecies == null ? '먼저 종을 선택하세요' : '품종을 선택하세요'),
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedBreed != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 질환 선택 드롭다운
  Widget _buildDiseaseDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '펫 알고있는 질환',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            _showDiseasePicker();
          },
          child: Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDisease ?? '질환을 선택하세요',
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedDisease != null ? Colors.black87 : Colors.grey,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 품종 선택 다이얼로그
  void _showBreedPicker(List<String> breedList) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '품종 선택',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 108, 82),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: breedList.length,
            itemBuilder: (context, index) {
              final breed = breedList[index];
              return ListTile(
                title: Text(breed),
                onTap: () {
                  setState(() {
                    _selectedBreed = breed;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// 질환 선택 다이얼로그
  void _showDiseasePicker() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '질환 선택',
          style: TextStyle(
            color: const Color.fromARGB(255, 0, 108, 82),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _diseases.length,
            itemBuilder: (context, index) {
              final disease = _diseases[index];
              return ListTile(
                title: Text(disease),
                onTap: () {
                  setState(() {
                    _selectedDisease = disease;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  /// 성별 선택 버튼
  Widget _buildGenderButton(String label, IconData icon, Color color) {
    bool isSelected = _selectedGender == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = label;
        });
      },
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: isSelected ? 4 : 2),
              color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            ),
            child: Icon(icon, size: 40, color: color),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 프로필 등록 버튼
  Widget _buildRegisterButton() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      child: ElevatedButton(
        onPressed: () {
          // 필수 입력 확인
          if (_nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('펫 이름을 입력해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // 프로필 저장
          final profile = PetProfile(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: _nameController.text.trim(),
            imageUrl: _selectedImageUrl,
            birthday: _birthdayController.text.trim(),
            breed: _selectedBreed,
            disease: _selectedDisease,
            gender: _selectedGender,
          );

          // 프로필 매니저에 추가
          PetProfileManager().addProfile(profile);

          // 성공 메시지 표시
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${profile.name} 프로필이 등록되었습니다!'),
              backgroundColor: const Color.fromARGB(255, 0, 108, 82),
            ),
          );

          // 이전 화면으로 돌아가기 (true를 반환하여 새로고침 알림)
          Navigator.pop(context, true);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 0, 108, 82),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          '프로필 등록',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
