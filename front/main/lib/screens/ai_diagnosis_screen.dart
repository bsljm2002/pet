// AI 진단 화면 위젯
// AI 기반 반려동물 건강 진단 기능
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ai_diagnosis_service.dart';
import '../models/ai_diagnosis.dart';
import '../services/pet_profile_manager.dart';
import 'ai_diagnosis_gallery_screen.dart';

// AI 진단 화면
// 반려동물의 증상, 행동, 사진 등을 분석하여 AI 기반 건강 상태 진단 제공
class AiDiagnosisScreen extends StatefulWidget {
  const AiDiagnosisScreen({super.key});

  @override
  State<AiDiagnosisScreen> createState() => _AiDiagnosisScreenState();
}

class _AiDiagnosisScreenState extends State<AiDiagnosisScreen> {
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  bool _isAnalyzing = false;

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

    final profiles = PetProfileManager().getAllProfiles();
    if (profiles.isEmpty) {
      _showErrorDialog('등록된 반려동물이 없습니다.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final diagnosis = await _diagnosisService.performDiagnosis(
        imagePath: _selectedImage!.path,
        petName: profiles.first.name,
        petId: profiles.first.id,
      );

      setState(() {
        _isAnalyzing = false;
      });

      _showDiagnosisResult(diagnosis);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('진단 중 오류가 발생했습니다.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 헤더
            _buildHeader(),

            // 이미지 선택 영역
            _buildImageSection(),

            const SizedBox(height: 24),

            // 진단 버튼
            _buildDiagnosisButton(),

            const SizedBox(height: 24),

            // 진단 기록 보기 버튼
            _buildGalleryButton(),

            const SizedBox(height: 24),

            // 안내 섹션
            _buildInfoSection(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // 헤더
  Widget _buildHeader() {
    return Container(
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
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF5A6C6D),
            ),
          ),
        ],
      ),
    );
  }

  // 이미지 섹션
  Widget _buildImageSection() {
    return Container(
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
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
    );
  }

  // 진단 버튼
  Widget _buildDiagnosisButton() {
    return Container(
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  // 갤러리 버튼
  Widget _buildGalleryButton() {
    return Container(
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
          side: const BorderSide(
            color: Color(0xFF00B27A),
            width: 2,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // 안내 섹션
  Widget _buildInfoSection() {
    return Container(
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
              Icon(
                Icons.info_outline,
                color: Color(0xFF00B27A),
                size: 20,
              ),
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
    );
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
                  const Text(
                    'AI 진단 결과',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                    ),
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

                  // 진단명 및 심각도
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: diagnosis.getSeverityColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: diagnosis.getSeverityColor().withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: diagnosis.getSeverityColor(),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                diagnosis.getSeverityText(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '신뢰도: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          diagnosis.diagnosis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3E3F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          diagnosis.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5A6C6D),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 증상
                  _buildSection(
                    title: '관찰된 증상',
                    icon: Icons.medical_services,
                    items: diagnosis.symptoms,
                  ),

                  const SizedBox(height: 20),

                  // 권장사항
                  _buildSection(
                    title: '권장사항',
                    icon: Icons.assignment_turned_in,
                    items: diagnosis.recommendations,
                  ),

                  const SizedBox(height: 32),

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
            Icon(
              icon,
              color: const Color(0xFF00B27A),
              size: 20,
            ),
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
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5A6C6D),
                  ),
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
