import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/pet_profile.dart';
import '../models/vet_model.dart';
import '../models/ai_diagnosis.dart';
import '../services/pet_profile_manager.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/pet_service.dart';
import '../screens/ai_diagnosis_image_picker_screen.dart';

/// 예약 신청 페이지
/// 선택한 병원/수의사 정보를 표시하고 예약 관련 정보를 입력받는다.
class ReservationRequestPage extends StatefulWidget {
  final VetModel vet;

  const ReservationRequestPage({super.key, required this.vet});

  @override
  State<ReservationRequestPage> createState() => _ReservationRequestPageState();
}

class _ReservationRequestPageState extends State<ReservationRequestPage> {
  final _memoController = TextEditingController();
  late DateTime _focusedDay;
  DateTime? _selectedDate;
  String? _selectedSpecialty;
  String? _selectedTime;
  List<PetProfile> _petProfiles = [];
  final Set<int> _selectedPetIds = {};
  bool _isLoadingPets = true;
  String? _petLoadError;
  List<AIDiagnosis> _selectedAIDiagnosisImages = []; // AI 진단 정보 목록

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDate!;
    _selectedSpecialty = widget.vet.specialties.isNotEmpty
        ? widget.vet.specialties.first
        : null;

    // 생성된 타임슬롯에서 첫 번째 시간 선택
    final timeSlots = _generateTimeSlots();
    _selectedTime = timeSlots.isNotEmpty ? timeSlots.first : null;

    _loadPetProfiles();
  }

  /// 근무 시간 기반으로 30분 간격 타임슬롯 생성
  List<String> _generateTimeSlots() {
    print('🕐 [DEBUG] 타임슬롯 생성 시작');
    print('  - availableTimes: ${widget.vet.availableTimes}');
    print('  - workingStartHours: ${widget.vet.workingStartHours}');
    print('  - workingEndHours: ${widget.vet.workingEndHours}');
    print('  - workingDays: ${widget.vet.workingDays}');

    // 1. availableTimes가 있으면 그것을 우선 사용
    if (widget.vet.availableTimes.isNotEmpty) {
      print('  ✅ availableTimes 사용: ${widget.vet.availableTimes}');
      return widget.vet.availableTimes;
    }

    // 2. workingStartHours와 workingEndHours가 있으면 타임슬롯 생성
    if (widget.vet.workingStartHours != null &&
        widget.vet.workingEndHours != null &&
        widget.vet.workingStartHours!.isNotEmpty &&
        widget.vet.workingEndHours!.isNotEmpty) {
      List<String> timeSlots = [];

      try {
        print('  ✅ 영업시간 기반 타임슬롯 생성 중...');
        // 시작/종료 시간 파싱 (예: "09:00")
        final startParts = widget.vet.workingStartHours!.split(':');
        final endParts = widget.vet.workingEndHours!.split(':');

        int startHour = int.parse(startParts[0]);
        int startMinute = int.parse(startParts[1]);
        int endHour = int.parse(endParts[0]);
        int endMinute = int.parse(endParts[1]);

        print('  - 시작: $startHour:$startMinute, 종료: $endHour:$endMinute');

        // 시작 시간부터 종료 시간까지 30분 간격으로 생성
        DateTime current = DateTime(2000, 1, 1, startHour, startMinute);
        DateTime end = DateTime(2000, 1, 1, endHour, endMinute);

        while (current.isBefore(end)) {
          String hourStr = current.hour.toString().padLeft(2, '0');
          String minuteStr = current.minute.toString().padLeft(2, '0');
          timeSlots.add('$hourStr:$minuteStr');

          // 30분 추가
          current = current.add(const Duration(minutes: 30));
        }

        print('  ✅ 생성된 타임슬롯 (${timeSlots.length}개): $timeSlots');
        return timeSlots;
      } catch (e) {
        print('  ❌ [ERROR] 타임슬롯 생성 오류: $e');
      }
    }

    // 3. 둘 다 없으면 기본 시간대 제공
    print('  ⚠️ 기본 시간대 사용');
    return ['09:00', '10:00', '11:00', '14:00', '15:00', '16:00', '17:00'];
  }

  /// 백엔드에서 실제 펫 데이터 로드
  Future<void> _loadPetProfiles() async {
    setState(() {
      _isLoadingPets = true;
      _petLoadError = null;
    });

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoadingPets = false;
          _petLoadError = '로그인이 필요합니다.';
        });
        return;
      }

      print('🔍 [DEBUG] 펫 목록 로드 시작 - 사용자 ID: ${currentUser.id}');

      final response = await PetService().getPetsByOwner(
        currentUser.id.toString(),
      );

      print('🔍 [DEBUG] 펫 목록 응답: $response');

      if (response['success'] == true) {
        final List<dynamic> petsData = response['pets'];
        final List<PetProfile> profiles = petsData
            .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [DEBUG] 로드된 펫 수: ${profiles.length}');
        profiles.forEach((pet) {
          print('  - ${pet.name} (ID: ${pet.id})');
        });

        setState(() {
          _petProfiles = profiles;
          _isLoadingPets = false;
        });
      } else {
        setState(() {
          _isLoadingPets = false;
          _petLoadError = response['message'] ?? '펫 목록을 불러올 수 없습니다.';
        });
      }
    } catch (e) {
      print('❌ [ERROR] 펫 목록 로드 오류: $e');
      setState(() {
        _isLoadingPets = false;
        _petLoadError = '네트워크 오류: $e';
      });
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _togglePetSelection(int? petId) {
    if (petId == null) return;
    setState(() {
      if (_selectedPetIds.contains(petId)) {
        _selectedPetIds.remove(petId);
      } else {
        _selectedPetIds.add(petId);
      }
    });
  }

  Future<void> _submit() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약 날짜를 선택해 주세요.')));
      return;
    }

    if (_selectedTime == null || _selectedTime!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약 시간을 선택해 주세요.')));
      return;
    }

    if (_petProfiles.isNotEmpty && _selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('진료 받을 반려동물을 선택해 주세요.')));
      return;
    }

    // 로그인 사용자 확인
    final currentUser = AuthService().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 선택된 모든 펫에 대해 예약 생성
      final selectedPets = _selectedPetIds.isNotEmpty
          ? _selectedPetIds.toList()
          : [_petProfiles.first.id!];

      print('🔍 [DEBUG] 선택된 펫 수: ${selectedPets.length}');
      print('🔍 [DEBUG] 선택된 펫 ID 목록: $selectedPets');

      // 날짜와 시간 조합
      final dateTimeStr =
          '${DateFormat('yyyy-MM-dd').format(_selectedDate!)}T${_selectedTime!}:00.000+09:00';

      // Specialty를 백엔드 enum으로 매핑 (VetSpecialty enum)
      String? vetSpecialtyEnum = _mapSpecialtyToEnum(_selectedSpecialty);

      int successCount = 0;
      int failCount = 0;
      List<String> failedPetNames = [];

      // 각 펫에 대해 개별 예약 생성
      for (int petId in selectedPets) {
        // 해당 펫의 이름 찾기
        final petProfile = _petProfiles.firstWhere(
          (p) => p.id == petId,
          orElse: () => _petProfiles.first,
        );
        final petName = petProfile.name;

        // 예약 내용: 사용자가 입력한 메모만 포함
        String content = _memoController.text.trim();

        // 백엔드 API 호출
        final url = Uri.parse('${ApiService.baseUrl}/reservations');
        final requestBody = {
          'partner_id': int.parse(widget.vet.id),
          'user_id': currentUser.id,
          'user_type': 'HOSPITAL',
          'vet_specialties': vetSpecialtyEnum != null
              ? [vetSpecialtyEnum]
              : ['GENERAL'],
          'pets_id': petId,
          'visit_date_time': dateTimeStr, // 방문 예약 시간 (사용자가 선택한 날짜/시간)
          'resv_urls': _selectedAIDiagnosisImages.map((d) => d.imagePath).toList(), // AI 진단 이미지 URL 목록
          'ai_diagnoses': _selectedAIDiagnosisImages.map((d) => d.toJson()).toList(), // AI 진단 정보
          'resv_content': content,
        };

        print('🔍 [DEBUG] 예약 생성 요청 (펫: $petName, ID: $petId): $requestBody');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        print('🔍 [DEBUG] 응답 상태 (펫: $petName): ${response.statusCode}');
        print('🔍 [DEBUG] 응답 내용: ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 200) {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          if (responseData['ok'] == true) {
            successCount++;
            print('✅ [SUCCESS] $petName 예약 성공');
          } else {
            failCount++;
            failedPetNames.add(petName);
            print(
              '❌ [FAIL] $petName 예약 실패: ${responseData['error']} - ${responseData['message']}',
            );
          }
        } else {
          failCount++;
          failedPetNames.add(petName);
          print('❌ [FAIL] $petName 예약 실패: 상태 코드 ${response.statusCode}');
        }
      }

      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      // 결과 메시지 표시
      if (successCount > 0 && failCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ 총 ${successCount}마리의 예약이 성공적으로 접수되었습니다!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (successCount > 0 && failCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '⚠️ ${successCount}마리 성공, ${failCount}마리 실패\n실패: ${failedPetNames.join(", ")}',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 모든 예약이 실패했습니다.\n실패: ${failedPetNames.join(", ")}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      Navigator.of(context).pop();

      print('❌ [ERROR] 예약 생성 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ 예약 요청 중 오류 발생: $e')));
    }
  }

  // Specialty 한글명을 백엔드 enum으로 매핑
  String? _mapSpecialtyToEnum(String? specialty) {
    if (specialty == null) return null;

    final Map<String, String> specialtyMap = {
      '내과': 'INTERNAL_MEDICINE',
      '외과': 'SURGERY',
      '치과': 'DENTISTRY',
      '피부과': 'DERMATOLOGY',
      '안과': 'OPHTHALMOLOGY',
      '정형외과': 'ORTHOPEDICS',
      '신경과': 'NEUROLOGY',
      '종양학': 'ONCOLOGY',
      '심장학': 'CARDIOLOGY',
      '응급의료': 'EMERGENCY_MEDICINE',
      '예방접종': 'VACCINATION',
      '일반진료': 'GENERAL',
    };

    return specialtyMap[specialty] ?? 'GENERAL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 224),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 255, 224),
        foregroundColor: const Color.fromARGB(255, 0, 108, 82),
        title: const Text('방문예약', style: TextStyle(fontSize: 20)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VetHeader(vet: widget.vet),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildPetSelectionCard(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildScheduleCard(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildSpecialtyCard(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildMemoCard(),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildAIDiagnosisImagesCard(),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4FC59E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    '예약 요청 보내기',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 달력 날짜 셀 빌더 (발바닥 모양)
  Widget _buildCalendarDay(DateTime date, bool isSelected, bool isToday) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 (선택된 날짜 또는 오늘 날짜인 경우 발바닥 모양)
          if (isSelected || isToday)
            CustomPaint(
              size: const Size(40, 40),
              painter: _PawMarkPainter(
                color: isSelected
                    ? const Color(0xFF4FC59E)
                    : const Color(0xFF4FC59E).withOpacity(0.3),
              ),
            ),
          // 날짜 텍스트
          Text(
            '${date.day}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? Colors.white
                  : (isToday ? const Color(0xFF4FC59E) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    final firstDay = DateTime.now();
    final lastDay = firstDay.add(const Duration(days: 60));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '예약 일시',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime(firstDay.year, firstDay.month, firstDay.day),
            lastDay: DateTime(lastDay.year, lastDay.month, lastDay.day),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(color: Colors.transparent),
              selectedDecoration: BoxDecoration(color: Colors.transparent),
              weekendTextStyle: TextStyle(color: Colors.redAccent),
            ),
            calendarBuilders: CalendarBuilders(
              defaultBuilder: (context, date, _) {
                return _buildCalendarDay(date, false, false);
              },
              selectedBuilder: (context, date, _) {
                return _buildCalendarDay(date, true, false);
              },
              todayBuilder: (context, date, _) {
                final isSelected = isSameDay(_selectedDate, date);
                return _buildCalendarDay(date, isSelected, true);
              },
            ),
            calendarFormat: CalendarFormat.month,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTime,
            items: _generateTimeSlots()
                .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                .toList(),
            onChanged: (value) => setState(() => _selectedTime = value),
            decoration: const InputDecoration(
              labelText: '예약 시간',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// 반려동물 선택 카드 위젯 (한 줄에 4개)
  Widget _buildPetCard(PetProfile profile, bool isSelected) {
    String imageUrl = profile.imageUrl ?? '';

    // 상대 경로를 절대 경로로 변환
    if (imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://223.130.130.225:9075$imageUrl';
      print('🔍 [DEBUG] 상대 경로 변환: ${profile.imageUrl} -> $imageUrl');
    }

    // 디버그: 이미지 URL 출력
    print('🔍 [DEBUG] Pet: ${profile.name}, ImageUrl: $imageUrl');

    return GestureDetector(
      onTap: () => _togglePetSelection(profile.id),
      child: Container(
        width: 70, // 한 줄에 4개 들어가도록 더 축소 (80 -> 70)
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FC59E)
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1.5,
          ),
          color: isSelected
              ? const Color(0xFF4FC59E).withOpacity(0.1)
              : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.12 : 0.04),
              blurRadius: isSelected ? 6 : 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 이미지 영역
            Stack(
              children: [
                Container(
                  height: 70, // 70x70으로 축소
                  width: 70,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    color: const Color(0xFFE6F7F1),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print(
                                '❌ [ERROR] 이미지 로드 실패 (${profile.name}): $error',
                              );
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.pets,
                                      size: 30,
                                      color: Color(0xFF4FC59E),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) {
                                print('✅ [DEBUG] 이미지 로드 완료 (${profile.name})');
                                return child;
                              }
                              final progress =
                                  loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : 0.0;
                              print(
                                '⏳ [DEBUG] 이미지 로딩 중 (${profile.name}): ${(progress * 100).toStringAsFixed(0)}%',
                              );
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF4FC59E),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.pets,
                                  size: 30,
                                  color: Color(0xFF4FC59E),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                // 선택 체크마크
                if (isSelected)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4FC59E),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
            // 이름 영역
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              child: Text(
                profile.name,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF003829) : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '진료 받을 반려동물',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              const SizedBox(width: 8),
              if (_isLoadingPets)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingPets)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '반려동물 정보를 불러오는 중...',
                style: TextStyle(color: Color(0xFF2B8C6C), height: 1.5),
                textAlign: TextAlign.center,
              ),
            )
          else if (_petLoadError != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '❌ $_petLoadError',
                    style: const TextStyle(color: Colors.red, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _loadPetProfiles,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('다시 시도'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC59E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (_petProfiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '등록된 반려동물 프로필이 없습니다.\n홈 화면에서 프로필을 추가해 주세요.',
                style: TextStyle(color: Color(0xFF2B8C6C), height: 1.5),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _petProfiles.map((profile) {
                final isSelected = _selectedPetIds.contains(profile.id);
                return _buildPetCard(profile, isSelected);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSpecialtyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '진료 희망 항목',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _selectedSpecialty,
            items: widget.vet.specialties
                .map(
                  (specialty) => DropdownMenuItem(
                    value: specialty,
                    child: Text(specialty),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedSpecialty = value),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '추가 메모',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _memoController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '증상이나 전달하고 싶은 내용을 작성해 주세요.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  /// AI 진단 이미지 첨부 카드
  Widget _buildAIDiagnosisImagesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'AI 진단 이미지 첨부',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              TextButton.icon(
                onPressed: _selectedPetIds.isEmpty
                    ? null
                    : _selectAIDiagnosisImages,
                icon: Icon(
                  _selectedAIDiagnosisImages.isEmpty
                      ? Icons.add_photo_alternate
                      : Icons.edit,
                  size: 18,
                ),
                label: Text(
                  _selectedAIDiagnosisImages.isEmpty ? '선택' : '변경',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00B27A),
                ),
              ),
            ],
          ),
          if (_selectedPetIds.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '먼저 진료 받을 반려동물을 선택해주세요',
                style: TextStyle(
                  color: Color(0xFFE65100),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else if (_selectedAIDiagnosisImages.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AI 진단 기록의 이미지를 선택하여 수의사에게 전달할 수 있습니다',
                style: TextStyle(
                  color: Color(0xFF2B8C6C),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Text(
                  '선택된 이미지: ${_selectedAIDiagnosisImages.length}개',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF00B27A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _selectedAIDiagnosisImages.map((diagnosis) {
                    return Container(
                      width: (MediaQuery.of(context).size.width - 80) / 4,
                      height: (MediaQuery.of(context).size.width - 80) / 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00B27A),
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: diagnosis.imagePath.startsWith('http')
                            ? Image.network(
                                diagnosis.imagePath,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(diagnosis.imagePath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                  );
                                },
                              ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// AI 진단 이미지 선택
  Future<void> _selectAIDiagnosisImages() async {
    final result = await Navigator.push<List<AIDiagnosis>?>(
      context,
      MaterialPageRoute(
        builder: (context) => AIDiagnosisImagePickerScreen(
          selectedPetIds: _selectedPetIds.toList(),
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAIDiagnosisImages = result;
      });
    }
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _VetHeader extends StatelessWidget {
  final VetModel vet;

  const _VetHeader({required this.vet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFE6F7F1),
            backgroundImage: vet.imageUrl.isNotEmpty
                ? NetworkImage(vet.imageUrl)
                : null,
            child: vet.imageUrl.isNotEmpty
                ? null
                : const Icon(
                    Icons.local_hospital_outlined,
                    color: Color(0xFF4FC59E),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vet.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  vet.doctorName ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4FC59E),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${vet.rating}점'),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text('${vet.distance}km'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 발바닥 모양을 그리는 CustomPainter
class _PawMarkPainter extends CustomPainter {
  final Color color;

  _PawMarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // mark.svg의 path를 40x40 크기에 맞게 스케일 조정
    final scaleX = size.width / 353;
    final scaleY = size.height / 342;
    final offsetY = -size.height * 0.2; // 위로 20% 이동

    // 첫 번째 path (우측 상단 발가락)
    path.moveTo(350.751 * scaleX, 110.68 * scaleY + offsetY);
    path.cubicTo(
      348.418 * scaleX,
      98.5128 * scaleY + offsetY,
      335.951 * scaleX,
      77.4795 * scaleY + offsetY,
      304.751 * scaleX,
      90.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      273.551 * scaleX,
      103.88 * scaleY + offsetY,
      266.751 * scaleX,
      137.18 * scaleY + offsetY,
      267.251 * scaleX,
      152.18 * scaleY + offsetY,
    );
    path.cubicTo(
      267.084 * scaleX,
      163.513 * scaleY + offsetY,
      271.951 * scaleX,
      186.88 * scaleY + offsetY,
      292.751 * scaleX,
      189.68 * scaleY + offsetY,
    );
    path.cubicTo(
      318.751 * scaleX,
      193.18 * scaleY + offsetY,
      333.751 * scaleX,
      175.18 * scaleY + offsetY,
      342.251 * scaleX,
      161.18 * scaleY + offsetY,
    );
    path.cubicTo(
      349.051 * scaleX,
      149.98 * scaleY + offsetY,
      350.751 * scaleX,
      140.513 * scaleY + offsetY,
      350.751 * scaleX,
      137.18 * scaleY + offsetY,
    );
    path.cubicTo(
      351.81 * scaleX,
      131.346 * scaleY + offsetY,
      353.292 * scaleX,
      117.88 * scaleY + offsetY,
      350.751 * scaleX,
      110.68 * scaleY + offsetY,
    );
    path.close();

    // 두 번째 path (중앙 상단 발가락)
    path.moveTo(256.751 * scaleX, 7.17951 * scaleY + offsetY);
    path.cubicTo(
      247.584 * scaleX,
      -0.487154 * scaleY + offsetY,
      224.051 * scaleX,
      -7.92049 * scaleY + offsetY,
      203.251 * scaleX,
      23.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      182.451 * scaleX,
      55.2795 * scaleY + offsetY,
      189.584 * scaleX,
      87.5128 * scaleY + offsetY,
      195.751 * scaleX,
      99.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      201.251 * scaleX,
      112.346 * scaleY + offsetY,
      217.551 * scaleX,
      134.68 * scaleY + offsetY,
      238.751 * scaleX,
      122.68 * scaleY + offsetY,
    );
    path.cubicTo(
      259.951 * scaleX,
      110.68 * scaleY + offsetY,
      271.584 * scaleX,
      86.0128 * scaleY + offsetY,
      274.751 * scaleX,
      75.1795 * scaleY + offsetY,
    );
    path.cubicTo(
      276.918 * scaleX,
      67.3462 * scaleY + offsetY,
      279.951 * scaleX,
      48.2795 * scaleY + offsetY,
      274.751 * scaleX,
      34.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      269.551 * scaleX,
      21.0795 * scaleY + offsetY,
      260.584 * scaleX,
      10.6795 * scaleY + offsetY,
      256.751 * scaleX,
      7.17951 * scaleY + offsetY,
    );
    path.close();

    // 세 번째 path (좌측 상단 발가락)
    path.moveTo(125.751 * scaleX, 1.67951 * scaleY + offsetY);
    path.cubicTo(
      114.251 * scaleX,
      -1.32049 * scaleY + offsetY,
      88.951 * scaleX,
      1.07951 * scaleY + offsetY,
      79.751 * scaleX,
      34.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      70.551 * scaleX,
      68.2795 * scaleY + offsetY,
      88.9177 * scaleX,
      99.3462 * scaleY + offsetY,
      99.251 * scaleX,
      110.68 * scaleY + offsetY,
    );
    path.cubicTo(
      105.584 * scaleX,
      118.68 * scaleY + offsetY,
      122.751 * scaleX,
      132.28 * scaleY + offsetY,
      140.751 * scaleX,
      122.68 * scaleY + offsetY,
    );
    path.cubicTo(
      158.751 * scaleX,
      113.08 * scaleY + offsetY,
      165.584 * scaleX,
      84.6795 * scaleY + offsetY,
      166.751 * scaleX,
      71.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      166.751 * scaleX,
      59.0128 * scaleY + offsetY,
      163.451 * scaleX,
      30.4795 * scaleY + offsetY,
      150.251 * scaleX,
      17.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      137.051 * scaleX,
      4.87951 * scaleY + offsetY,
      128.418 * scaleX,
      1.67951 * scaleY + offsetY,
      125.751 * scaleX,
      1.67951 * scaleY + offsetY,
    );
    path.close();

    // 네 번째 path (좌측 발가락)
    path.moveTo(21.751 * scaleX, 87.1795 * scaleY + offsetY);
    path.cubicTo(
      13.751 * scaleX,
      89.0128 * scaleY + offsetY,
      -1.64897 * scaleX,
      99.1795 * scaleY + offsetY,
      0.75103 * scaleX,
      125.18 * scaleY + offsetY,
    );
    path.cubicTo(
      3.15103 * scaleX,
      151.18 * scaleY + offsetY,
      12.4177 * scaleX,
      164.68 * scaleY + offsetY,
      16.751 * scaleX,
      168.18 * scaleY + offsetY,
    );
    path.cubicTo(
      26.0844 * scaleX,
      178.513 * scaleY + offsetY,
      49.951 * scaleX,
      196.38 * scaleY + offsetY,
      70.751 * scaleX,
      185.18 * scaleY + offsetY,
    );
    path.cubicTo(
      91.551 * scaleX,
      173.98 * scaleY + offsetY,
      87.0844 * scaleX,
      140.513 * scaleY + offsetY,
      82.251 * scaleX,
      125.18 * scaleY + offsetY,
    );
    path.cubicTo(
      78.751 * scaleX,
      116.346 * scaleY + offsetY,
      67.651 * scaleX,
      97.0795 * scaleY + offsetY,
      51.251 * scaleX,
      90.6795 * scaleY + offsetY,
    );
    path.cubicTo(
      34.851 * scaleX,
      84.2795 * scaleY + offsetY,
      24.751 * scaleX,
      85.6795 * scaleY + offsetY,
      21.751 * scaleX,
      87.1795 * scaleY + offsetY,
    );
    path.close();

    // 다섯 번째 path (메인 발바닥)
    path.moveTo(245.751 * scaleX, 174.68 * scaleY + offsetY);
    path.cubicTo(
      239.918 * scaleX,
      166.18 * scaleY + offsetY,
      220.651 * scaleX,
      147.98 * scaleY + offsetY,
      190.251 * scaleX,
      143.18 * scaleY + offsetY,
    );
    path.cubicTo(
      180.418 * scaleX,
      142.513 * scaleY + offsetY,
      158.751 * scaleX,
      142.28 * scaleY + offsetY,
      150.751 * scaleX,
      146.68 * scaleY + offsetY,
    );
    path.cubicTo(
      140.751 * scaleX,
      152.18 * scaleY + offsetY,
      133.251 * scaleX,
      150.18 * scaleY + offsetY,
      112.251 * scaleX,
      171.68 * scaleY + offsetY,
    );
    path.cubicTo(
      110.251 * scaleX,
      174.68 * scaleY + offsetY,
      105.951 * scaleX,
      181.58 * scaleY + offsetY,
      104.751 * scaleX,
      185.18 * scaleY + offsetY,
    );
    path.cubicTo(
      103.551 * scaleX,
      188.78 * scaleY + offsetY,
      89.251 * scaleX,
      203.013 * scaleY + offsetY,
      82.251 * scaleX,
      209.68 * scaleY + offsetY,
    );
    path.cubicTo(
      73.9177 * scaleX,
      216.513 * scaleY + offsetY,
      56.651 * scaleX,
      236.18 * scaleY + offsetY,
      54.251 * scaleX,
      260.18 * scaleY + offsetY,
    );
    path.cubicTo(
      51.851 * scaleX,
      284.18 * scaleY + offsetY,
      64.251 * scaleX,
      306.18 * scaleY + offsetY,
      70.751 * scaleX,
      314.18 * scaleY + offsetY,
    );
    path.cubicTo(
      77.751 * scaleX,
      324.013 * scaleY + offsetY,
      99.751 * scaleX,
      343.08 * scaleY + offsetY,
      131.751 * scaleX,
      340.68 * scaleY + offsetY,
    );
    path.cubicTo(
      137.251 * scaleX,
      340.013 * scaleY + offsetY,
      150.951 * scaleX,
      337.98 * scaleY + offsetY,
      161.751 * scaleX,
      335.18 * scaleY + offsetY,
    );
    path.cubicTo(
      172.551 * scaleX,
      332.38 * scaleY + offsetY,
      188.918 * scaleX,
      334.013 * scaleY + offsetY,
      195.751 * scaleX,
      335.18 * scaleY + offsetY,
    );
    path.cubicTo(
      202.584 * scaleX,
      337.013 * scaleY + offsetY,
      219.551 * scaleX,
      340.68 * scaleY + offsetY,
      232.751 * scaleX,
      340.68 * scaleY + offsetY,
    );
    path.cubicTo(
      249.251 * scaleX,
      340.68 * scaleY + offsetY,
      272.751 * scaleX,
      332.68 * scaleY + offsetY,
      288.751 * scaleX,
      307.18 * scaleY + offsetY,
    );
    path.cubicTo(
      304.751 * scaleX,
      281.68 * scaleY + offsetY,
      299.751 * scaleX,
      254.18 * scaleY + offsetY,
      296.251 * scaleX,
      239.68 * scaleY + offsetY,
    );
    path.cubicTo(
      293.451 * scaleX,
      228.08 * scaleY + offsetY,
      275.751 * scaleX,
      209.846 * scaleY + offsetY,
      267.251 * scaleX,
      202.18 * scaleY + offsetY,
    );
    path.cubicTo(
      262.418 * scaleX,
      198.18 * scaleY + offsetY,
      251.351 * scaleX,
      187.08 * scaleY + offsetY,
      245.751 * scaleX,
      174.68 * scaleY + offsetY,
    );
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
