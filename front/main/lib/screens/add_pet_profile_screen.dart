// 펫 프로필 생성 화면
// 새로운 반려동물의 프로필을 등록하는 페이지
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/pet_profile.dart';
import '../services/pet_profile_manager.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import 'abti_test_screen.dart';

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
  final TextEditingController _weightController = TextEditingController();

  String? _selectedAbtiType;

  // 선택된 프로필 이미지 URL (임시)
  String? _selectedImageUrl;

  // 선택된 이미지 파일
  File? _selectedImageFile;
  final ImagePicker _imagePicker = ImagePicker();

  // 선택된 성별 ('MALE' 또는 'FEMALE')
  String? _selectedGender;

  // 선택된 반려동물 종류 ('DOG' 또는 'CAT')
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

  /// 이미지 선택 메서드
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
          _selectedImageUrl = pickedFile.path; // 로컬 파일 경로를 임시로 저장
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 선택 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 이미지 선택 소스 선택 다이얼로그
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF4FC59E)),
                title: Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF4FC59E)),
                title: Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImageFile != null)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('이미지 제거'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImageFile = null;
                      _selectedImageUrl = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthdayController.dispose();
    _breedController.dispose();
    _diseaseController.dispose();
    _weightController.dispose();
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
                    _buildInputField('펫 이름', _nameController, isRequired: true),
                    SizedBox(height: 12),
                    _buildInputField('펫 생년월일', _birthdayController, isRequired: true),
                    SizedBox(height: 12),
                    _buildWeightInputField(),
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
                onTap: _showImageSourceDialog,
                child: Container(
                  width: 100,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.8),
                    border: Border.all(
                      color: _selectedImageFile != null
                          ? const Color(0xFF4FC59E)
                          : const Color.fromARGB(255, 200, 200, 200),
                      width: 2,
                    ),
                    image: _selectedImageFile != null
                        ? DecorationImage(
                            image: FileImage(_selectedImageFile!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImageFile == null
                      ? Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: const Color.fromARGB(255, 180, 180, 180),
                        )
                      : null,
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
          // 펫 성별 섹션
          _buildSectionHeader('펫 성별', isRequired: true),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGenderButton('MALE', Icons.male, Colors.blue),
              SizedBox(width: 40),
              _buildGenderButton('FEMALE', Icons.female, Colors.red),
            ],
          ),
          SizedBox(height: 30),
          // ABTI 테스트 섹션
          _buildSectionHeader('ABTI 테스트', isRequired: true),
          SizedBox(height: 20),
          _buildAbtiTestSection(),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  /// 섹션 헤더
  Widget _buildSectionHeader(String title, {bool isRequired = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
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
  Widget _buildInputField(String label, TextEditingController controller, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (isRequired) ...[
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
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

  /// 몸무게 입력 필드
  Widget _buildWeightInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '펫 몸무게',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: TextField(
            controller: _weightController,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: OutlineInputBorder(borderSide: BorderSide.none),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              hintText: '예: 5.5',
              suffixText: 'kg',
              suffixStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
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
    List<String> breedList = _selectedSpecies == 'dog'
        ? _dogBreeds
        : _catBreeds;
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
                  _selectedBreed ??
                      (_selectedSpecies == null ? '먼저 종을 선택하세요' : '품종을 선택하세요'),
                  style: TextStyle(
                    fontSize: 14,
                    color: _selectedBreed != null
                        ? Colors.black87
                        : Colors.grey,
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
                    color: _selectedDisease != null
                        ? Colors.black87
                        : Colors.grey,
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

  /// ABTI 테스트 섹션
  Widget _buildAbtiTestSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedAbtiType != null
              ? const Color.fromARGB(255, 0, 108, 82)
              : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (_selectedAbtiType != null) ...[
            // ABTI 결과 표시
            Icon(
              Icons.check_circle,
              size: 48,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
            SizedBox(height: 12),
            Text(
              '테스트 완료',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'ABTI 유형: $_selectedAbtiType',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbtiTestScreen(
                      petName: _nameController.text.trim(),
                      currentAbtiType: _selectedAbtiType,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedAbtiType = result;
                  });
                }
              },
              icon: Icon(Icons.refresh),
              label: Text('다시 테스트하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ] else ...[
            // 테스트 시작 안내
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12),
            Text(
              'ABTI 테스트를 진행해주세요',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8),
            Text(
              '반려동물의 성향을 파악하여\n맞춤형 케어를 제공합니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AbtiTestScreen(
                      petName: _nameController.text.trim(),
                    ),
                  ),
                );
                if (result != null) {
                  setState(() {
                    _selectedAbtiType = result;
                  });
                }
              },
              icon: Icon(Icons.play_arrow),
              label: Text('테스트 시작하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
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
        onPressed: () async {
          // ===== 1. 입력 검증 =====
          if (_nameController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('펫 이름을 입력해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_selectedSpecies == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('강아지 또는 고양이를 선택해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_birthdayController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('생년월일을 입력해주세요. (예: 2020-05-15)'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_weightController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('몸무게를 입력해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          double? weight;
          try {
            weight = double.parse(_weightController.text.trim());
            if (weight <= 0) {
              throw FormatException('양수여야 합니다');
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('몸무게는 0보다 큰 숫자로 입력해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_selectedGender == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('성별을 선택해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          if (_selectedAbtiType == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('ABTI 테스트를 완료해주세요.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }

          // ===== 2. 로딩 표시 =====
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(255, 0, 108, 82),
                ),
              ),
            ),
          );

          try {
            // ===== 3. 로그인 사용자 확인 =====
            final authService = AuthService();
            if (!authService.isLoggedIn || authService.currentUser == null) {
              Navigator.pop(context); // 로딩 닫기
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('로그인이 필요합니다.'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            final userId = int.parse(authService.currentUser!.id);

            // ===== 4. API 호출 =====
            final result = await PetService().createPet(
              userId: userId, // 실제 로그인한 사용자 ID 사용
              name: _nameController.text.trim(),
              species: _selectedSpecies!.toUpperCase(), // "dog" -> "DOG", "cat" -> "CAT"
              birthdate: _birthdayController.text.trim(), // "yyyy-MM-dd"
              weight: weight,
              abitTypeCode: _selectedAbtiType!, // "ENFP" 등
              gender: _selectedGender!, // "MALE" 또는 "FEMALE"
              speciesDetail: _selectedBreed, // 품종 (선택사항)
              imageUrl: _selectedImageUrl, // 이미지 URL (선택사항)
            );

            // ===== 5. 로딩 닫기 =====
            Navigator.pop(context);

            // ===== 6. 결과 처리 =====
            if (result['success'] == true) {
              // 성공
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${_nameController.text.trim()} 프로필이 등록되었습니다!'),
                  backgroundColor: const Color.fromARGB(255, 0, 108, 82),
                ),
              );
              Navigator.pop(context, true); // 이전 화면으로 돌아가기
            } else {
              // 실패
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(result['message'] ?? '등록 실패'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            // ===== 7. 오류 처리 =====
            Navigator.pop(context); // 로딩 닫기
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('오류가 발생했습니다: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
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
