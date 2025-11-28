import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../models/partner_profile_model.dart';
import '../../services/partner_service.dart';
import '../../services/auth_service.dart';
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
    _doctorNameController = TextEditingController(
      text: profile?.doctorName ?? '',
    );
    _addressController = TextEditingController(text: profile?.address ?? '');
    _phoneController = TextEditingController(text: profile?.phone ?? '');
    _descriptionController = TextEditingController(
      text: profile?.description ?? '',
    );
    _experienceController = TextEditingController(
      text: profile?.experience ?? '',
    );

    if (profile != null) {
      _specialties = List.from(profile.specialties);
      _availableTimes = List.from(profile.availableTimes);
      _education = List.from(profile.education);
      _certifications = List.from(profile.certifications);
      _experience = profile.experience ?? '';
      _latitude = profile.latitude;
      _longitude = profile.longitude;

      // 기존 프로필 수정 시 영업시간 정보 로드
      if (currentUser != null) {
        _loadWorkingHours(int.parse(currentUser.id));
      }
    }
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
          if (userData['workingDays'] != null &&
              userData['workingDays'] is String) {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('지도에서 위치를 선택해주세요')));
      return;
    }

    // 영업시간 유효성 검사
    if (_workingDays.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('근무 요일을 선택해주세요')));
      return;
    }

    if (_workingStartTime == null || _workingEndTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('근무 시간을 설정해주세요')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // 현재 로그인한 사용자 ID 가져오기
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다')));
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
      doctorName: _doctorNameController.text.isEmpty
          ? null
          : _doctorNameController.text,
      address: _addressController.text,
      latitude: _latitude,
      longitude: _longitude,
      phone: _phoneController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      specialties: _specialties,
      availableTimes: [], // 영업시간 기반 타임슬롯 생성을 위해 비움
      education: _education,
      certifications: _certifications,
      experience: _experienceController.text.isEmpty
          ? null
          : _experienceController.text,
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
    if (success &&
        _workingDays.isNotEmpty &&
        _workingStartTime != null &&
        _workingEndTime != null) {
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
          content: Text(
            widget.existingProfile != null ? '프로필이 수정되었습니다' : '프로필이 등록되었습니다',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } else if (mounted) {
      print('저장 실패');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장에 실패했습니다')));
    }
  }

  /// 영업시간 저장
  Future<bool> _saveWorkingHours(int userId) async {
    try {
      final String startHours =
          '${_workingStartTime!.hour.toString().padLeft(2, '0')}:${_workingStartTime!.minute.toString().padLeft(2, '0')}';
      final String endHours =
          '${_workingEndTime!.hour.toString().padLeft(2, '0')}:${_workingEndTime!.minute.toString().padLeft(2, '0')}';

      final response = await http.patch(
        Uri.parse(
          'http://223.130.130.225:9075/api/v1/users/$userId/working-hours',
        ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

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
                      labelText: _partnerType == 'HOSPITAL'
                          ? '담당 수의사명 (선택)'
                          : '담당자명 (선택)',
                      border: const OutlineInputBorder(),
                    ),
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
                        side: const BorderSide(
                          color: Color(0xFF4FC59E),
                          width: 2,
                        ),
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
                          border: Border.all(
                            color: const Color(0xFF4FC59E).withOpacity(0.3),
                          ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
