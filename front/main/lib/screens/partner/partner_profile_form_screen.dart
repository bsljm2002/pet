import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../models/partner_profile_model.dart';
import '../../services/partner_service.dart';
import '../../services/auth_service.dart';
import '../../services/image_upload_service.dart';
import '../../widgets/location_picker_widget.dart';

/// 파트너 프로필 등록/수정 화면
class PartnerProfileFormScreen extends StatefulWidget {
  final PartnerProfileModel? existingProfile;
  final String? initialPartnerType; // 초기 파트너 타입 (HOSPITAL 또는 SITTER)

  const PartnerProfileFormScreen({
    Key? key,
    this.existingProfile,
    this.initialPartnerType,
  }) : super(key: key);

  @override
  State<PartnerProfileFormScreen> createState() =>
      _PartnerProfileFormScreenState();
}

class _PartnerProfileFormScreenState extends State<PartnerProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final PartnerService _partnerService = PartnerService();
  final AuthService _authService = AuthService();

  late TextEditingController _nameController;
  late TextEditingController _doctorNameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _experienceController;

  String _partnerType = 'HOSPITAL';
  List<String> _specialties = [];
  List<String> _availableTimes = [];
  List<String> _education = [];
  List<String> _certifications = [];
  String _experience = '';

  // 영업시간 정보
  Set<String> _workingDays = {}; // 근무 요일
  TimeOfDay? _workingStartTime; // 근무 시작 시간
  TimeOfDay? _workingEndTime; // 근무 종료 시간

  // 위치 정보
  double? _latitude;
  double? _longitude;

  // 이미지 정보
  File? _selectedImageFile;
  String? _selectedImageUrl;
  final ImagePicker _imagePicker = ImagePicker();

  // 갤러리 이미지 정보 (최대 8개)
  List<File> _galleryImageFiles = [];
  List<String> _galleryImageUrls = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    final profile = widget.existingProfile;
    final currentUser = _authService.currentUser;

    // 사용자 타입에 따라 파트너 타입 결정 (우선순위: 기존프로필 > 초기타입 > 사용자타입)
    if (profile != null) {
      _partnerType = profile.partnerType;
    } else if (widget.initialPartnerType != null) {
      // 명시적으로 전달된 파트너 타입 사용
      _partnerType = widget.initialPartnerType!;
    } else if (currentUser != null) {
      // 신규 등록 시 사용자 타입으로 파트너 타입 결정
      if (currentUser.userType.name == 'HOSPITAL') {
        _partnerType = 'HOSPITAL';
      } else if (currentUser.userType.name == 'SITTER') {
        _partnerType = 'SITTER';
      }
    }

    _nameController = TextEditingController(text: profile?.name ?? '');
    _doctorNameController = TextEditingController(text: profile?.doctorName ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _descriptionController = TextEditingController(text: profile?.description ?? '');
    _experienceController = TextEditingController(text: profile?.experience ?? '');

    if (profile != null) {
      _specialties = List.from(profile.specialties);
      _availableTimes = List.from(profile.availableTimes);
      _education = List.from(profile.education);
      _certifications = List.from(profile.certifications);
      _experience = profile.experience ?? '';
      _latitude = profile.latitude;
      _longitude = profile.longitude;
      _selectedImageUrl = profile.imageUrl;
      _galleryImageUrls = List.from(profile.galleryImages);

      // 기존 프로필 수정 시 영업시간 정보 로드
      if (currentUser != null) {
        _loadWorkingHours(int.parse(currentUser.id));
      }
    }
  }

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
          _selectedImageUrl = pickedFile.path;
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF4FC59E)),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4FC59E)),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImageFile != null || _selectedImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('이미지 제거'),
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

  /// 갤러리 이미지 추가 메서드
  Future<void> _pickGalleryImage(ImageSource source) async {
    if (_galleryImageFiles.length + _galleryImageUrls.length >= 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 8개까지 추가할 수 있습니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _galleryImageFiles.add(File(pickedFile.path));
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

  /// 갤러리 이미지 소스 선택 다이얼로그
  void _showGalleryImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF4FC59E)),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGalleryImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF4FC59E)),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickGalleryImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// 갤러리 이미지 제거
  void _removeGalleryImage(int index, bool isFile) {
    setState(() {
      if (isFile) {
        _galleryImageFiles.removeAt(index);
      } else {
        _galleryImageUrls.removeAt(index);
      }
    });
  }

  /// 영업시간 정보 로드 (기존 프로필 수정 시)
  Future<void> _loadWorkingHours(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://223.130.130.225:9075/api/v1/users/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final userData = data['data'];

        if (userData != null) {
          // workingDays 파싱
          if (userData['workingDays'] != null && userData['workingDays'] is String) {
            final days = (userData['workingDays'] as String).split(',');
            setState(() {
              _workingDays = days.map((d) => d.trim()).toSet();
            });
          }

          // workingStartHours 파싱
          if (userData['workingStartHours'] != null) {
            final parts = (userData['workingStartHours'] as String).split(':');
            if (parts.length >= 2) {
              setState(() {
                _workingStartTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              });
            }
          }

          // workingEndHours 파싱
          if (userData['workingEndHours'] != null) {
            final parts = (userData['workingEndHours'] as String).split(':');
            if (parts.length >= 2) {
              setState(() {
                _workingEndTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              });
            }
          }
        }
      }
    } catch (e) {
      print('영업시간 로드 오류: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _doctorNameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  /// 지도에서 위치 선택
  Future<void> _selectLocation() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LocationPickerWidget(
          initialLatitude: _latitude,
          initialLongitude: _longitude,
          initialAddress: _addressController.text,
          onLocationSelected: (latitude, longitude, address) {
            setState(() {
              _latitude = latitude;
              _longitude = longitude;
              _addressController.text = address;
            });
          },
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도에서 위치를 선택해주세요')),
      );
      return;
    }

    // 영업시간 유효성 검사
    if (_workingDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('근무 요일을 선택해주세요')),
      );
      return;
    }

    if (_workingStartTime == null || _workingEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('근무 시간을 설정해주세요')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 현재 로그인한 사용자 ID 가져오기
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final userId = int.parse(currentUser.id);

    print('=== 프로필 저장 시작 ===');
    print('이름: ${_nameController.text}');
    print('주소: ${_addressController.text}');
    print('위치: $_latitude, $_longitude');
    print('전화번호: ${_phoneController.text}');
    print('userId: $userId (${currentUser.username})');

    // 이미지 업로드 (있는 경우)
    String? uploadedImageUrl;
    if (_selectedImageFile != null) {
      try {
        print('이미지 업로드 중...');
        final imageService = ImageUploadService();
        uploadedImageUrl = await imageService.uploadImage(
          imageFile: _selectedImageFile!,
          userId: userId,
        );
        print('이미지 업로드 성공: $uploadedImageUrl');
      } catch (e) {
        print('이미지 업로드 실패: $e');
        // 이미지 업로드 실패해도 프로필은 등록하도록 함
      }
    } else if (_selectedImageUrl != null) {
      // 기존 이미지 URL 유지
      uploadedImageUrl = _selectedImageUrl;
    }

    // 갤러리 이미지 업로드
    List<String> uploadedGalleryUrls = List.from(_galleryImageUrls);
    if (_galleryImageFiles.isNotEmpty) {
      try {
        print('갤러리 이미지 업로드 중... (${_galleryImageFiles.length}개)');
        final imageService = ImageUploadService();
        for (var imageFile in _galleryImageFiles) {
          final url = await imageService.uploadImage(
            imageFile: imageFile,
            userId: userId,
          );
          uploadedGalleryUrls.add(url);
          print('갤러리 이미지 업로드 성공: $url');
        }
      } catch (e) {
        print('갤러리 이미지 업로드 실패: $e');
        // 갤러리 이미지 업로드 실패해도 프로필은 등록하도록 함
      }
    }

    // 신규 등록 시 중복 확인
    if (widget.existingProfile == null) {
      print('중복 프로필 확인 중...');
      final existingProfiles = await _partnerService.getMyPartners(userId);
      if (existingProfiles.isNotEmpty) {
        print('기존 프로필 ${existingProfiles.length}개 발견');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('이미 등록된 프로필이 있습니다. 기존 프로필을 수정해주세요.'),
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {
          _isLoading = false;
        });
        Navigator.of(context).pop(false);
        return;
      }
    }

    final profile = PartnerProfileModel(
      id: widget.existingProfile?.id,
      partnerType: _partnerType,
      name: _nameController.text,
      doctorName: _doctorNameController.text.isEmpty ? null : _doctorNameController.text,
      address: _addressController.text,
      latitude: _latitude,
      longitude: _longitude,
      phone: _phoneController.text,
      imageUrl: uploadedImageUrl,
      galleryImages: uploadedGalleryUrls,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      specialties: _specialties,
      availableTimes: [], // 영업시간 기반 타임슬롯 생성을 위해 비움
      education: _education,
      certifications: _certifications,
      experience: _experienceController.text.isEmpty ? null : _experienceController.text,
      userId: userId,
    );

    bool success = false;
    int? savedPartnerId;

    if (widget.existingProfile != null) {
      // 수정
      print('기존 프로필 수정 모드 (partnerId: ${widget.existingProfile!.id})');
      final result = await _partnerService.updatePartner(
        widget.existingProfile!.id!,
        profile,
      );
      success = result != null;
      if (success) {
        savedPartnerId = result!.id;
        print('프로필 수정 성공: partnerId = $savedPartnerId');
      } else {
        print('프로필 수정 실패');
      }
    } else {
      // 신규 등록
      print('신규 프로필 등록 모드');
      savedPartnerId = await _partnerService.createPartner(profile);
      success = savedPartnerId != null;
      if (success) {
        print('프로필 등록 성공: partnerId = $savedPartnerId');
      } else {
        print('프로필 등록 실패');
      }
    }

    // 영업시간 저장 (User 엔티티 업데이트)
    if (success && _workingDays.isNotEmpty && _workingStartTime != null && _workingEndTime != null) {
      print('영업시간 저장 중...');
      final workingHoursSuccess = await _saveWorkingHours(userId);
      if (!workingHoursSuccess) {
        print('영업시간 저장 실패 (파트너 프로필은 저장됨)');
      }
    }

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      print('저장 완료, 화면으로 돌아갑니다');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingProfile != null
              ? '프로필이 수정되었습니다'
              : '프로필이 등록되었습니다'),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      print('저장 실패');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('저장에 실패했습니다')),
      );
    }
  }

  /// 영업시간 저장
  Future<bool> _saveWorkingHours(int userId) async {
    try {
      final String startHours = '${_workingStartTime!.hour.toString().padLeft(2, '0')}:${_workingStartTime!.minute.toString().padLeft(2, '0')}';
      final String endHours = '${_workingEndTime!.hour.toString().padLeft(2, '0')}:${_workingEndTime!.minute.toString().padLeft(2, '0')}';

      final response = await http.patch(
        Uri.parse('http://223.130.130.225:9075/api/v1/users/$userId/working-hours'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'workingDays': _workingDays.toList(),
          'workingStartHours': startHours,
          'workingEndHours': endHours,
        }),
      );

      print('영업시간 저장 응답 코드: ${response.statusCode}');
      print('영업시간 저장 응답: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('영업시간 저장 오류: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingProfile != null ? '프로필 수정' : '프로필 등록'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // 기본 정보
                  const Text(
                    '기본 정보',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 서비스명/담당자명과 프로필 이미지를 한 줄에 배치
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽: 입력 필드들
                      Expanded(
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: _partnerType == 'HOSPITAL' ? '병원명' : '서비스명',
                                border: const OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return '필수 항목입니다';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _doctorNameController,
                              decoration: InputDecoration(
                                labelText: _partnerType == 'HOSPITAL' ? '담당 수의사명 (선택)' : '담당자명 (선택)',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // 오른쪽: 프로필 이미지
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 100,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 240, 240, 240),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _selectedImageFile != null || _selectedImageUrl != null
                                  ? const Color(0xFF4FC59E)
                                  : const Color.fromARGB(255, 200, 200, 200),
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: _selectedImageFile != null
                                ? Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                  )
                                : (_selectedImageUrl != null && _selectedImageUrl!.startsWith('http'))
                                    ? Image.network(
                                        _selectedImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Center(
                                            child: Icon(
                                              Icons.add_a_photo,
                                              size: 40,
                                              color: Color.fromARGB(255, 180, 180, 180),
                                            ),
                                          );
                                        },
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.add_a_photo,
                                          size: 40,
                                          color: Color.fromARGB(255, 180, 180, 180),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '주소',
                      border: OutlineInputBorder(),
                      hintText: '지도에서 위치를 선택하세요',
                    ),
                    readOnly: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '필수 항목입니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // 지도에서 위치 선택 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _selectLocation,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4FC59E),
                        side: const BorderSide(color: Color(0xFF4FC59E), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.map),
                      label: Text(
                        _latitude != null && _longitude != null
                            ? '위치 변경하기'
                            : '지도에서 위치 선택',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // 선택된 위치 표시
                  if (_latitude != null && _longitude != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F7F1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4FC59E).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4FC59E),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '위치 선택 완료: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF003829),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: '전화번호',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '필수 항목입니다';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _experienceController,
                    decoration: const InputDecoration(
                      labelText: '경력',
                      border: OutlineInputBorder(),
                      hintText: '예: 10년',
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 진료 과목 / 제공 서비스
                  Text(
                    _partnerType == 'HOSPITAL' ? '진료 과목' : '제공 서비스',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _partnerType == 'HOSPITAL'
                        ? [
                            _buildSpecialtyChip('내과'),
                            _buildSpecialtyChip('외과'),
                            _buildSpecialtyChip('치과'),
                            _buildSpecialtyChip('피부과'),
                            _buildSpecialtyChip('안과'),
                            _buildSpecialtyChip('정형외과'),
                            _buildSpecialtyChip('신경과'),
                            _buildSpecialtyChip('종양학'),
                            _buildSpecialtyChip('심장학'),
                            _buildSpecialtyChip('응급의료'),
                            _buildSpecialtyChip('예방접종'),
                            _buildSpecialtyChip('일반진료'),
                          ]
                        : [
                            _buildSpecialtyChip('산책 서비스'),
                            _buildSpecialtyChip('방문 돌봄'),
                            _buildSpecialtyChip('목욕/미용'),
                            _buildSpecialtyChip('호텔 위탁'),
                            _buildSpecialtyChip('놀이 케어'),
                            _buildSpecialtyChip('대형견 케어'),
                            _buildSpecialtyChip('고양이 케어'),
                            _buildSpecialtyChip('24시간 케어'),
                          ],
                  ),
                  const SizedBox(height: 24),

                  // 영업 시간
                  const Text(
                    '영업 시간',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 근무 요일 선택
                  const Text(
                    '근무 요일',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildDayChip('MONDAY', '월'),
                      _buildDayChip('TUESDAY', '화'),
                      _buildDayChip('WEDNESDAY', '수'),
                      _buildDayChip('THURSDAY', '목'),
                      _buildDayChip('FRIDAY', '금'),
                      _buildDayChip('SATURDAY', '토'),
                      _buildDayChip('SUNDAY', '일'),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 근무 시간대
                  const Text(
                    '근무 시간대',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF003829),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeSelector(
                          label: '시작 시간',
                          time: _workingStartTime,
                          onTap: () => _selectTime(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimeSelector(
                          label: '종료 시간',
                          time: _workingEndTime,
                          onTap: () => _selectTime(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 자격증
                  const Text(
                    '자격증 및 인증',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _partnerType == 'HOSPITAL'
                        ? [
                            _buildCertificationChip('수의사 면허'),
                            _buildCertificationChip('동물병원 개설 허가증'),
                            _buildCertificationChip('반려동물 행동 전문가'),
                            _buildCertificationChip('종양학 전문의'),
                            _buildCertificationChip('피부과 전문의'),
                          ]
                        : [
                            _buildCertificationChip('반려동물관리사 1급'),
                            _buildCertificationChip('반려동물행동교정사'),
                            _buildCertificationChip('펫시터 자격증'),
                            _buildCertificationChip('애견훈련사'),
                            _buildCertificationChip('고양이행동전문가'),
                            _buildCertificationChip('응급처치 자격증'),
                          ],
                  ),
                  const SizedBox(height: 24),

                  // 소개
                  const Text(
                    '소개',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: '소개글',
                      border: const OutlineInputBorder(),
                      hintText: _partnerType == 'HOSPITAL'
                          ? '병원 및 진료 서비스에 대한 소개를 입력하세요'
                          : '펫시터 서비스에 대한 소개를 입력하세요',
                    ),
                    maxLines: 5,
                  ),
                  const SizedBox(height: 24),

                  // 갤러리 사진
                  const Text(
                    '갤러리 사진',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '최대 8개까지 추가할 수 있습니다',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 갤러리 이미지 그리드
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _galleryImageFiles.length + _galleryImageUrls.length + 1,
                    itemBuilder: (context, index) {
                      // 추가 버튼
                      if (index == _galleryImageFiles.length + _galleryImageUrls.length) {
                        if (_galleryImageFiles.length + _galleryImageUrls.length >= 8) {
                          return const SizedBox.shrink();
                        }
                        return GestureDetector(
                          onTap: _showGalleryImageSourceDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 32,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '추가',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // 기존 URL 이미지 표시
                      if (index < _galleryImageUrls.length) {
                        return Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF4FC59E),
                                  width: 2,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _galleryImageUrls[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Icon(Icons.error),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeGalleryImage(index, false),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      // 새로 추가된 파일 이미지 표시
                      final fileIndex = index - _galleryImageUrls.length;
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(0xFF4FC59E),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(
                                _galleryImageFiles[fileIndex],
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeGalleryImage(fileIndex, true),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 저장 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC59E),
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        widget.existingProfile != null ? '수정하기' : '등록하기',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// 진료과목 선택 칩
  Widget _buildSpecialtyChip(String specialty) {
    final isSelected = _specialties.contains(specialty);
    return FilterChip(
      label: Text(specialty),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _specialties.add(specialty);
          } else {
            _specialties.remove(specialty);
          }
        });
      },
      selectedColor: const Color(0xFF4FC59E).withOpacity(0.3),
      checkmarkColor: const Color(0xFF003829),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003829) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 요일 선택 칩
  Widget _buildDayChip(String dayValue, String dayLabel) {
    final isSelected = _workingDays.contains(dayValue);
    return FilterChip(
      label: Text(dayLabel),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _workingDays.add(dayValue);
          } else {
            _workingDays.remove(dayValue);
          }
        });
      },
      selectedColor: const Color(0xFF4FC59E).withOpacity(0.3),
      checkmarkColor: const Color(0xFF003829),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003829) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// 시간 선택기
  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime
          ? (_workingStartTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_workingEndTime ?? const TimeOfDay(hour: 18, minute: 0)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4FC59E),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _workingStartTime = picked;
        } else {
          _workingEndTime = picked;
        }
      });
    }
  }

  /// 시간 선택 위젯
  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              color: time != null ? const Color(0xFF4FC59E) : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    time != null
                        ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}'
                        : '선택하세요',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: time != null ? Colors.black87 : Colors.grey,
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

  /// 자격증 선택 칩
  Widget _buildCertificationChip(String certification) {
    final isSelected = _certifications.contains(certification);
    return FilterChip(
      label: Text(certification),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _certifications.add(certification);
          } else {
            _certifications.remove(certification);
          }
        });
      },
      selectedColor: const Color(0xFF4FC59E).withOpacity(0.3),
      checkmarkColor: const Color(0xFF003829),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF003829) : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
