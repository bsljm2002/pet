// AI 진단 이미지 선택 화면
// 예약 시 첨부할 AI 진단 이미지를 선택하는 화면
import 'package:flutter/material.dart';
import 'dart:io';
import '../services/ai_diagnosis_service.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import '../models/ai_diagnosis.dart';
import '../models/pet_profile.dart';

class AIDiagnosisImagePickerScreen extends StatefulWidget {
  /// 선택한 반려동물 ID 리스트 (예약에서 선택한 반려동물들)
  final List<int> selectedPetIds;

  const AIDiagnosisImagePickerScreen({
    super.key,
    required this.selectedPetIds,
  });

  @override
  State<AIDiagnosisImagePickerScreen> createState() =>
      _AIDiagnosisImagePickerScreenState();
}

class _AIDiagnosisImagePickerScreenState
    extends State<AIDiagnosisImagePickerScreen> {
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final PetService _petService = PetService();
  List<AIDiagnosis> _diagnoses = [];
  final Set<String> _selectedImagePaths = {};
  final List<AIDiagnosis> _selectedDiagnoses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDiagnoses();
  }

  /// 선택된 반려동물들의 AI 진단 기록 로드
  Future<void> _loadDiagnoses() async {
    try {
      print('🔍 AI 진단 기록 로드 시작 (이미지 선택)');
      print('  - 선택된 반려동물 IDs: ${widget.selectedPetIds}');

      if (widget.selectedPetIds.isEmpty) {
        print('❌ 선택된 반려동물이 없음');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // 선택된 반려동물들의 정보 가져오기
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
      final List<PetProfile> allPets = petsData
          .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
          .toList();

      // 선택된 반려동물들만 필터링
      final selectedPets = allPets
          .where((pet) => widget.selectedPetIds.contains(pet.id))
          .toList();

      print('✅ 선택된 반려동물 ${selectedPets.length}마리 조회됨');

      // 각 반려동물의 AI 진단 기록 가져오기
      List<AIDiagnosis> allDiagnoses = [];
      for (var pet in selectedPets) {
        if (pet.id != null) {
          print('🔍 반려동물 ${pet.name} (ID: ${pet.id})의 진단 기록 조회');
          final diagnoses =
              await _diagnosisService.loadDiagnosesFromBackend(pet.id!);
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
            ));
          }
        }
      }

      // 날짜 순으로 정렬 (최신순)
      allDiagnoses.sort((a, b) => b.diagnosisDate.compareTo(a.diagnosisDate));

      setState(() {
        _diagnoses = allDiagnoses;
        _isLoading = false;
      });

      print('✅ 총 ${allDiagnoses.length}건의 AI 진단 기록 로드 완료');
    } catch (e) {
      print('❌ AI 진단 기록 로드 중 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 이미지 선택/해제 토글
  void _toggleImageSelection(AIDiagnosis diagnosis) {
    setState(() {
      if (_selectedImagePaths.contains(diagnosis.imagePath)) {
        _selectedImagePaths.remove(diagnosis.imagePath);
        _selectedDiagnoses.removeWhere((d) => d.imagePath == diagnosis.imagePath);
      } else {
        _selectedImagePaths.add(diagnosis.imagePath);
        _selectedDiagnoses.add(diagnosis);
      }
    });
  }

  /// 선택 완료
  void _confirmSelection() {
    if (_selectedDiagnoses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 1개 이상의 이미지를 선택해주세요'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, _selectedDiagnoses);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00B27A),
        elevation: 0,
        title: const Text(
          'AI 진단 이미지 선택',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: Text(
              '완료 (${_selectedImagePaths.length})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF00B27A),
              ),
            )
          : _diagnoses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'AI 진단 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI 케어에서 진단을 먼저 받아보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _diagnoses.length,
                  itemBuilder: (context, index) {
                    final diagnosis = _diagnoses[index];
                    final isSelected =
                        _selectedImagePaths.contains(diagnosis.imagePath);

                    return GestureDetector(
                      onTap: () => _toggleImageSelection(diagnosis),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFF00B27A),
                                  width: 3,
                                )
                              : null,
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
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: diagnosis.imagePath.startsWith('http')
                                        ? Image.network(
                                            diagnosis.imagePath,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                            },
                                          )
                                        : Image.file(
                                            File(diagnosis.imagePath),
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Icon(
                                                  Icons.broken_image,
                                                  size: 48,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                            },
                                          ),
                                  ),
                                  // 선택 체크마크
                                  if (isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF00B27A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // 진단 정보
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 반려동물 이름
                                  Text(
                                    diagnosis.petName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF00B27A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  // 진단명
                                  Text(
                                    diagnosis.diagnosis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  // 날짜
                                  Text(
                                    '${diagnosis.diagnosisDate.year}.${diagnosis.diagnosisDate.month.toString().padLeft(2, '0')}.${diagnosis.diagnosisDate.day.toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
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
}
