import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/partner_reservation_model.dart';
import '../../models/pet_profile.dart';
import '../../services/pet_service.dart';

/// 반려동물 의료 보고서 화면 (의사용)
class PetMedicalReportPage extends StatefulWidget {
  final PartnerReservationModel reservation;

  const PetMedicalReportPage({super.key, required this.reservation});

  @override
  State<PetMedicalReportPage> createState() => _PetMedicalReportPageState();
}

class _PetMedicalReportPageState extends State<PetMedicalReportPage> {
  final PetService _petService = PetService();

  PetProfile? _petProfile;
  bool _isLoading = true;
  String? _errorMessage;

  // 수정 가능한 필드
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _diseaseController = TextEditingController();
  bool _hasDisease = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadPetProfile();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _loadPetProfile() async {
    if (widget.reservation.petId == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '반려동물 정보가 없습니다.';
      });
      return;
    }

    try {
      final response = await _petService.getPetById(widget.reservation.petId!);

      if (response['success'] == true && response['pet'] != null) {
        final petData = response['pet'] as Map<String, dynamic>;
        final pet = PetProfile.fromJson(petData);

        setState(() {
          _petProfile = pet;
          _weightController.text = pet.weight.toString();
          _diseaseController.text = pet.disease ?? '';
          _hasDisease = (pet.disease != null && pet.disease!.isNotEmpty);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = '반려동물 정보를 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '오류 발생: $e';
      });
    }
  }

  Future<void> _saveMedicalInfo() async {
    if (_petProfile == null) return;

    // 몸무게 유효성 검사
    final weight = double.tryParse(_weightController.text.trim());
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('올바른 몸무게를 입력해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final disease = _hasDisease ? _diseaseController.text.trim() : '';

      final response = await _petService.updatePetMedicalInfo(
        petId: _petProfile!.id!,
        weight: weight,
        disease: disease,
      );

      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (response['success'] == true) {
        setState(() {
          _petProfile = PetProfile(
            id: _petProfile!.id,
            userId: _petProfile!.userId,
            name: _petProfile!.name,
            species: _petProfile!.species,
            birthdate: _petProfile!.birthdate,
            weight: weight,
            gender: _petProfile!.gender,
            speciesDetail: _petProfile!.speciesDetail,
            imageUrl: _petProfile!.imageUrl,
            disease: disease,
          );
          _isEditing = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('의료 정보가 저장되었습니다'),
              backgroundColor: Color(0xFF4FC59E),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? '저장에 실패했습니다'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('반려동물 의료 보고서'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
        actions: [
          if (_petProfile != null && !_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: '정보 수정',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMedicalInfo,
              tooltip: '저장',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // 원래 값으로 복원
                  _weightController.text = _petProfile?.weight.toString() ?? '';
                  _diseaseController.text = _petProfile?.disease ?? '';
                  _hasDisease = (_petProfile?.disease != null &&
                                 _petProfile!.disease!.isNotEmpty);
                });
              },
              tooltip: '취소',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorState()
              : _buildReportContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadPetProfile,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportContent() {
    if (_petProfile == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 예약 정보 헤더
          _buildReservationHeader(),
          const SizedBox(height: 24),

          // 반려동물 기본 정보
          _buildSectionCard(
            title: '기본 정보',
            icon: Icons.pets,
            child: Column(
              children: [
                _buildInfoRow('이름', _petProfile!.name),
                const Divider(height: 24),
                _buildInfoRow('품종', _petProfile!.speciesDetail ?? '미등록'),
                const Divider(height: 24),
                _buildInfoRow('나이', _calculateAge()),
                const Divider(height: 24),
                _buildInfoRow('성별', _getGenderText()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 의료 정보 (수정 가능)
          _buildSectionCard(
            title: '의료 정보',
            icon: Icons.local_hospital,
            isEditable: true,
            child: Column(
              children: [
                _buildEditableWeightRow(),
                const Divider(height: 24),
                _buildEditableDiseaseRow(),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 반려동물 사진
          if (_petProfile!.imageUrl != null && _petProfile!.imageUrl!.isNotEmpty)
            _buildSectionCard(
              title: '사진',
              icon: Icons.photo,
              child: _buildPetImage(),
            ),
        ],
      ),
    );
  }

  Widget _buildReservationHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC59E), Color(0xFF3BA688)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4FC59E).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '보호자: ${widget.reservation.userName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                '예약일: ${widget.reservation.formattedDate}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.reservation.timeSlot,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    bool isEditable = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4FC59E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFF4FC59E), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              if (isEditable && _isEditing)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.edit,
                    size: 16,
                    color: Color(0xFF4FC59E),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF003829),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableWeightRow() {
    if (!_isEditing) {
      return _buildInfoRow(
        '몸무게',
        '${_petProfile!.weight}kg',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '몸무게',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: '예: 5.5',
            suffixText: 'kg',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4FC59E), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDiseaseRow() {
    if (!_isEditing) {
      return _buildInfoRow(
        '질병',
        (_petProfile!.disease != null && _petProfile!.disease!.isNotEmpty)
            ? _petProfile!.disease!
            : '없음',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '질병 유무',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: _hasDisease,
              onChanged: (value) {
                setState(() {
                  _hasDisease = value;
                  if (!value) {
                    _diseaseController.clear();
                  }
                });
              },
              activeColor: const Color(0xFF4FC59E),
            ),
          ],
        ),
        if (_hasDisease) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _diseaseController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: '질병명 및 상세 내용을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF4FC59E), width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetImage() {
    String imageUrl = _petProfile!.imageUrl!;

    // 상대 경로를 절대 경로로 변환
    if (!imageUrl.startsWith('http')) {
      imageUrl = 'http://223.130.130.225:9075$imageUrl';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('이미지를 불러올 수 없습니다'),
                ],
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Colors.grey.shade100,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  String _calculateAge() {
    final age = _petProfile!.age;
    if (age == null) return '미등록';
    return '$age세';
  }

  String _getGenderText() {
    if (_petProfile!.gender == null) return '미등록';
    switch (_petProfile!.gender) {
      case 'M':
      case 'MALE':
        return '수컷';
      case 'F':
      case 'FEMALE':
        return '암컷';
      default:
        return _petProfile!.gender!;
    }
  }
}
