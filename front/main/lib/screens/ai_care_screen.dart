// AI 케어 화면 위젯
// 케이지 센서 모니터링과 AI 진단 기능을 제공
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'ai_diagnosis_gallery_screen.dart';
import '../models/ai_diagnosis.dart';
import '../models/pet_profile.dart';
import '../services/ai_diagnosis_service.dart';
import '../services/pet_profile_manager.dart';

/// AI 케어 화면
/// 케이지 센서 데이터와 AI 진단 기능을 통합 제공
enum DiagnosisMode { eye, skin }

enum PetType { dog, cat }

class AiCareScreen extends StatefulWidget {
  const AiCareScreen({Key? key}) : super(key: key);

  @override
  State<AiCareScreen> createState() => _AiCareScreenState();
}

class _AiCareScreenState extends State<AiCareScreen> {
  // 현재 선택된 탭 인덱스 (0: 케이지, 1: AI진단)
  int _selectedTabIndex = 0;
  DiagnosisMode _selectedMode = DiagnosisMode.eye;
  PetType _selectedPetType = PetType.dog;

  // 센서 데이터 상태 관리
  double? temperature; // 온도 (°C)
  double? humidity; // 습도 (%)
  int? airQuality; // 공기질 (CAI)

  // AI 진단 관련 변수
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 상단 헤더 영역 - '케이지', 'AI진단' 탭
          Container(
            width: double.infinity,
            height: 30,
            color: const Color.fromARGB(255, 212, 244, 228),
            child: Row(
              children: [
                // 케이지 탭
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
                          '케이지',
                        ),
                        SizedBox(height: 4),
                        Container(
                          height: 3,
                          width: 60,
                          color: _selectedTabIndex == 0
                              ? const Color.fromARGB(255, 0, 108, 82)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
                // AI진단 탭
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
                          'AI진단',
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
            // 케이지 탭 컨텐츠
            _buildCageContent(),
          ] else ...[
            // AI진단 탭 컨텐츠
            _buildAIDiagnosisContent(),
          ],
        ],
      ),
    );
  }

  /// 케이지 센서 컨텐츠
  Widget _buildCageContent() {
    return Column(
      children: [
        // 메인 컨트롤 영역
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 0, 63, 43),
                Color.fromARGB(255, 172, 255, 230),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: Offset(0, 2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.3),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                bottom: 20,
                child: GestureDetector(
                  onTap: () {
                    print('작동 버튼 클릭됨');
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.pets, color: Color(0xFF93C5FD), size: 55),
                        SizedBox(height: 1),
                        Text(
                          '작동',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 케이지 센서 헤더
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
                '케이지 센서',
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
        // 센서 데이터 표시
        Container(
          width: double.infinity,
          height: 200,
          color: Colors.transparent,
          child: Column(
            children: [
              // 온도 센서
              _buildSensorCard(
                label: '온도',
                value: temperature != null
                    ? '${temperature!.toStringAsFixed(1)} °C'
                    : '--',
                color: Colors.red,
              ),
              // 습도 센서
              _buildSensorCard(
                label: '습도',
                value: humidity != null
                    ? '${humidity!.toStringAsFixed(1)} %'
                    : '--',
                color: Colors.blue,
              ),
              // 공기질 센서
              _buildSensorCard(
                label: '공기',
                value: airQuality != null ? '$airQuality CAI' : '--',
                color: Colors.green,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2.5),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// AI 진단 컨텐츠
  Widget _buildAIDiagnosisContent() {
    return Column(
      children: [
        // 헤더
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFD4F4E7),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'AI 진단',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00B27A),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 60,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFF00B27A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '반려동물의 사진을 찍어 AI 진단을 받아보세요',
                style: TextStyle(fontSize: 14, color: Color(0xFF5A6C6D)),
              ),
            ],
          ),
        ),

        // 진단 모드 선택 + 이미지 선택 영역
        _buildPetTypeSelector(),
        _buildModeSelector(),
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 이미지 미리보기
              _selectedImage != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.file(
                        _selectedImage!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '사진을 선택해주세요',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),

              // 카메라/갤러리 버튼
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _takePicture,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('카메라'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00B27A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isAnalyzing ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('갤러리'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF00B27A),
                          side: const BorderSide(
                            color: Color(0xFF00B27A),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
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

        const SizedBox(height: 24),

        // 진단 버튼
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (_selectedImage != null && !_isAnalyzing)
                ? _performDiagnosis
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00B27A),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: _isAnalyzing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'AI 분석 중...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'AI 진단 시작',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 24),

        // 진단 기록 보기 버튼
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIDiagnosisGalleryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('진단 기록 보기'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00B27A),
              side: const BorderSide(color: Color(0xFF00B27A), width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 안내 섹션
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF00B27A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '진단 안내',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem('• 정확한 진단을 위해 밝은 곳에서 선명한 사진을 찍어주세요'),
              _buildInfoItem('• 증상이 있는 부위를 가까이에서 촬영해주세요'),
              _buildInfoItem('• AI 진단은 참고용이며, 정확한 진단은 수의사와 상담하세요'),
              _buildInfoItem('• 심각한 증상은 즉시 병원을 방문하시기 바랍니다'),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildModeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildModeButton(DiagnosisMode.eye, '눈')),
          const SizedBox(width: 12),
          Expanded(child: _buildModeButton(DiagnosisMode.skin, '피부')),
        ],
      ),
    );
  }

  Widget _buildPetTypeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildPetTypeButton(PetType.dog, '🐕 강아지')),
          const SizedBox(width: 12),
          Expanded(child: _buildPetTypeButton(PetType.cat, '🐈 고양이')),
        ],
      ),
    );
  }

  Widget _buildPetTypeButton(PetType petType, String label) {
    final isSelected = _selectedPetType == petType;
    return GestureDetector(
      onTap: () => _handlePetTypeChange(petType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2196F3), width: 2),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF2196F3),
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePetTypeChange(PetType petType) async {
    if (_selectedPetType == petType) {
      return;
    }
    setState(() {
      _selectedPetType = petType;
    });
  }

  Widget _buildModeButton(DiagnosisMode mode, String label) {
    final isSelected = _selectedMode == mode;
    // cat_eyes 모델은 아직 준비되지 않음
    final isCatEyeUnavailable =
        _selectedPetType == PetType.cat && mode == DiagnosisMode.eye;
    final isDisabled = isCatEyeUnavailable;

    return GestureDetector(
      onTap: isDisabled ? null : () => _handleModeChange(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDisabled
              ? Colors.grey[200]
              : (isSelected ? const Color(0xFF00B27A) : Colors.white),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDisabled ? Colors.grey[400]! : const Color(0xFF00B27A),
            width: 2,
          ),
          boxShadow: [
            if (isSelected && !isDisabled)
              BoxShadow(
                color: const Color(0xFF00B27A).withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isDisabled
                      ? Colors.grey[500]
                      : (isSelected ? Colors.white : const Color(0xFF00B27A)),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              if (isCatEyeUnavailable)
                Text(
                  '(준비 중)',
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleModeChange(DiagnosisMode mode) async {
    if (_selectedMode == mode) {
      return;
    }
    // 고양이 눈 모델은 아직 준비되지 않음
    if (_selectedPetType == PetType.cat && mode == DiagnosisMode.eye) {
      _showErrorDialog('고양이 눈 진단 모델은 아직 준비 중입니다.');
      return;
    }
    setState(() {
      _selectedMode = mode;
    });
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF5A6C6D),
          height: 1.5,
        ),
      ),
    );
  }

  // 카메라로 사진 찍기
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('카메라를 열 수 없습니다.\n권한을 확인해주세요.');
    }
  }

  // 갤러리에서 사진 선택
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('갤러리를 열 수 없습니다.\n권한을 확인해주세요.');
    }
  }

  // AI 진단 수행
  Future<void> _performDiagnosis() async {
    if (_selectedImage == null) {
      _showErrorDialog('먼저 사진을 선택해주세요.');
      return;
    }

    // 모델 타입 결정
    DiagnosisModelType modelType;
    if (_selectedPetType == PetType.dog) {
      modelType = _selectedMode == DiagnosisMode.eye
          ? DiagnosisModelType.dogEyes
          : DiagnosisModelType.dogSkin;
    } else {
      // 고양이
      if (_selectedMode == DiagnosisMode.eye) {
        _showErrorDialog('고양이 눈 진단 모델은 아직 준비 중입니다.');
        return;
      }
      modelType = DiagnosisModelType.catSkin;
    }

    // 모델 사용 가능 여부 확인
    if (!AIDiagnosisService.isModelAvailable(modelType)) {
      _showErrorDialog(
        '${AIDiagnosisService.getModelTypeName(modelType)} 모델은 아직 준비 중입니다.',
      );
      return;
    }

    final profiles = PetProfileManager().getAllProfiles();
    final selectedPet = profiles.isNotEmpty ? profiles.first : null;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final diagnosis = await _diagnosisService.performDiagnosis(
        imagePath: _selectedImage!.path,
        petName: selectedPet?.name ?? '반려동물',
        petId: selectedPet?.id?.toString(),
        modelType: modelType,
      );

      if (!mounted) return;

      setState(() {
        _isAnalyzing = false;
      });

      _showDiagnosisResult(diagnosis);
    } on PlatformException catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('AI 모델 실행에 실패했습니다: ${e.message ?? '알 수 없는 오류'}');
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('진단 중 오류가 발생했습니다: $e');
    }
  }

  // 진단 결과 표시
  void _showDiagnosisResult(AIDiagnosis diagnosis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiagnosisResultSheet(diagnosis: diagnosis),
    );
  }

  // 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// 진단 결과 바텀 시트
class _DiagnosisResultSheet extends StatelessWidget {
  final AIDiagnosis diagnosis;

  const _DiagnosisResultSheet({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 제목
                  Row(
                    children: [
                      Icon(
                        diagnosis.isNormal
                            ? Icons.check_circle
                            : Icons.warning_rounded,
                        color: diagnosis.getStatusColor(),
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'AI 진단 결과',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3E3F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnosis.petName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5A6C6D),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 메인 진단 결과 카드
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: diagnosis.getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: diagnosis.getStatusColor().withValues(
                          alpha: 0.3,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        // 상태 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: diagnosis.getStatusColor(),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            diagnosis.getStatusText(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 진단명
                        Text(
                          diagnosis.diagnosis,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: diagnosis.getStatusColor(),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // 설명
                        Text(
                          diagnosis.description,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF5A6C6D),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        // 신뢰도 표시 (질병 의심일 때만)
                        if (diagnosis.hasAbnormality) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.psychology,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '신뢰도: ${(diagnosis.confidence * 100).toStringAsFixed(1)}%',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 증상 (질병 의심일 때만)
                  if (diagnosis.hasAbnormality) ...[
                    _buildSection(
                      title: '예상 증상',
                      icon: Icons.medical_services,
                      items: diagnosis.symptoms,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 권장사항
                  _buildSection(
                    title: diagnosis.isNormal ? '건강 유지 팁' : '권장사항',
                    icon: Icons.assignment_turned_in,
                    items: diagnosis.recommendations,
                  ),

                  const SizedBox(height: 16),

                  // 안내 문구
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'AI 진단은 참고용이며, 정확한 진단은 수의사와 상담하세요.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 닫기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B27A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00B27A), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E3F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5A6C6D)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A6C6D),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
