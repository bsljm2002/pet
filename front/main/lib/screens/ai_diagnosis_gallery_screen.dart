// AI 진단 기록 갤러리 화면
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/ai_diagnosis_service.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import '../models/ai_diagnosis.dart';
import '../models/pet_profile.dart';

class AIDiagnosisGalleryScreen extends StatefulWidget {
  const AIDiagnosisGalleryScreen({super.key});

  @override
  State<AIDiagnosisGalleryScreen> createState() =>
      _AIDiagnosisGalleryScreenState();
}

class _AIDiagnosisGalleryScreenState extends State<AIDiagnosisGalleryScreen> {
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final PetService _petService = PetService();
  List<AIDiagnosis> _diagnoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  Future<void> _loadDiagnoses() async {
    try {
      print('🔍 AI 진단 기록 로드 시작 (갤러리)');

      // 현재 사용자의 모든 반려동물 가져오기
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        print('❌ 로그인된 사용자 없음');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final response = await _petService.getPetsByOwner(currentUser.id);
      if (response['success'] != true) {
        print('❌ 반려동물 목록 조회 실패');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final List<dynamic> petsData = response['pets'];
      final List<PetProfile> pets = petsData
          .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      print('✅ 반려동물 ${pets.length}마리 조회됨');

      // 각 반려동물의 AI 진단 기록 가져오기
      List<AIDiagnosis> allDiagnoses = [];
      for (var pet in pets) {
        if (pet.id != null) {
          print('🔍 반려동물 ${pet.name} (ID: ${pet.id})의 진단 기록 조회');
          final diagnoses = await _diagnosisService.loadDiagnosesFromBackend(pet.id!);
          print('✅ ${diagnoses.length}건의 진단 기록 발견');

          // petName 추가
          for (var diagnosis in diagnoses) {
            allDiagnoses.add(AIDiagnosis(
              id: diagnosis.id,
              imagePath: diagnosis.imagePath,
              diagnosisDate: diagnosis.diagnosisDate,
              petName: pet.name,
              petId: diagnosis.petId,
              diagnosis: diagnosis.diagnosis,
              description: diagnosis.description,
              severity: diagnosis.severity,
              symptoms: diagnosis.symptoms,
              recommendations: diagnosis.recommendations,
              confidence: diagnosis.confidence,
              diseaseStatus: diagnosis.diseaseStatus,
            ));
          }
        }
      }

      // 최신순 정렬
      allDiagnoses.sort((a, b) => b.diagnosisDate.compareTo(a.diagnosisDate));

      print('✅ 총 ${allDiagnoses.length}건의 AI 진단 기록 로드 완료');

      setState(() {
        _diagnoses = allDiagnoses;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ AI 진단 기록 로드 오류: $e');
      print('❌ 스택 트레이스: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDiagnosisDetail(AIDiagnosis diagnosis) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _DiagnosisDetailScreen(diagnosis: diagnosis),
      ),
    );
  }

  void _deleteDiagnosis(AIDiagnosis diagnosis) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 진단 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _diagnosisService.deleteDiagnosis(diagnosis.id);
      _loadDiagnoses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진단 기록'),
        backgroundColor: const Color(0xFF00B27A),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _diagnoses.isEmpty
              ? _buildEmptyState()
              : _buildGalleryGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '진단 기록이 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI 진단을 시작해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _diagnoses.length,
      itemBuilder: (context, index) {
        final diagnosis = _diagnoses[index];
        return _buildGalleryItem(diagnosis);
      },
    );
  }

  Widget _buildGalleryItem(AIDiagnosis diagnosis) {
    return GestureDetector(
      onTap: () => _showDiagnosisDetail(diagnosis),
      onLongPress: () => _deleteDiagnosis(diagnosis),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: diagnosis.imagePath.startsWith('http')
                    ? Image.network(
                        diagnosis.imagePath.replaceAll('localhost', '223.130.130.225'),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF00B27A),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      )
                    : Image.file(
                        File(diagnosis.imagePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),

            // 정보
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 진단명
                  Text(
                    diagnosis.diagnosis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // 반려동물 이름
                  Text(
                    diagnosis.petName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 심각도 및 날짜
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: diagnosis.getSeverityColor(),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          diagnosis.getSeverityText(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        '${diagnosis.diagnosisDate.year}.${diagnosis.diagnosisDate.month.toString().padLeft(2, '0')}.${diagnosis.diagnosisDate.day.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
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
    );
  }
}

// 진단 상세 화면
class _DiagnosisDetailScreen extends StatelessWidget {
  final AIDiagnosis diagnosis;

  const _DiagnosisDetailScreen({required this.diagnosis});

  String _formatDateTime(DateTime date) {
    return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진단 상세'),
        backgroundColor: const Color(0xFF00B27A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지
            diagnosis.imagePath.startsWith('http')
                ? Image.network(
                    diagnosis.imagePath.replaceAll('localhost', '223.130.130.225'),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00B27A),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  )
                : Image.file(
                    File(diagnosis.imagePath),
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 300,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 80,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 날짜 및 반려동물 이름
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        diagnosis.petName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3E3F),
                        ),
                      ),
                      Text(
                        _formatDateTime(diagnosis.diagnosisDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
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
