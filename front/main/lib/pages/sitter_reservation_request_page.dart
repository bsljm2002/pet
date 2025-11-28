import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/pet_profile.dart';
import '../models/sitter_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/pet_service.dart';
import '../widgets/location_picker_widget.dart';

/// 펫시터 예약 신청 페이지
/// 선택한 펫시터 정보를 표시하고 예약 관련 정보(위치, 날짜/시간, 업무)를 입력받는다.
class SitterReservationRequestPage extends StatefulWidget {
  final SitterModel sitter;

  const SitterReservationRequestPage({super.key, required this.sitter});

  @override
  State<SitterReservationRequestPage> createState() =>
      _SitterReservationRequestPageState();
}

class _SitterReservationRequestPageState
    extends State<SitterReservationRequestPage> {
  final _memoController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedService;
  String? _selectedTime;
  List<PetProfile> _petProfiles = [];
  final Set<int> _selectedPetIds = {};
  bool _isLoadingPets = false;
  String? _petLoadError;
  double? _selectedLatitude;
  double? _selectedLongitude;

  @override
  void initState() {
    super.initState();
    print('🎬 [INIT] ========== SitterReservationRequestPage 시작 ==========');
    print('🎬 [INIT] Sitter ID: ${widget.sitter.id}');
    print('🎬 [INIT] Sitter Name: ${widget.sitter.name}');
    print('🎬 [INIT] Sitter Services: ${widget.sitter.services}');
    print('🎬 [INIT] Sitter Available Times: ${widget.sitter.availableTimes}');

    try {
      print('🎬 [INIT] 로케일 초기화 시작');
      // 한국어 로케일 초기화
      initializeDateFormatting('ko_KR');
      print('🎬 [INIT] 로케일 초기화 완료');

      print('🎬 [INIT] 날짜 설정 시작');
      // 초기 날짜 설정
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day);
      print('🎬 [INIT] 선택된 날짜: $_selectedDate');

      print('🎬 [INIT] 서비스 선택 시작');
      _selectedService = widget.sitter.services.isNotEmpty
          ? widget.sitter.services.first
          : null;
      print('🎬 [INIT] 선택된 서비스: $_selectedService');

      print('🎬 [INIT] 타임슬롯 생성 시작');
      // 생성된 타임슬롯에서 첫 번째 시간 선택
      final timeSlots = _generateTimeSlots();
      print('🎬 [INIT] 생성된 타임슬롯: $timeSlots');
      _selectedTime = timeSlots.isNotEmpty ? timeSlots.first : null;
      print('🎬 [INIT] 선택된 시간: $_selectedTime');

      print('🎬 [INIT] PostFrameCallback 등록');
      // 펫 데이터 로드
      WidgetsBinding.instance.addPostFrameCallback((_) {
        print('🎬 [INIT] PostFrameCallback 실행 - 펫 로딩 시작');
        _loadPetProfiles();
      });

      print('🎬 [INIT] initState 완료');
    } catch (e, stackTrace) {
      print('❌ [INIT ERROR] initState 중 오류 발생: $e');
      print('❌ [INIT ERROR] StackTrace: $stackTrace');
    }
  }

  /// 가능한 시간 기반으로 타임슬롯 생성 (파트너의 업무 시간 반영)
  List<String> _generateTimeSlots() {
    // availableTimes에서 유효한 시간 형식만 필터링 (HH:MM 형식)
    final validTimes = widget.sitter.availableTimes
        .where((time) => time.contains(':') && time.split(':').length == 2)
        .toList();

    // 유효한 시간이 있으면 사용 (파트너가 설정한 업무 시간만 표시)
    if (validTimes.isNotEmpty) {
      return validTimes;
    }

    // availableTimes가 비어있거나 유효하지 않은 경우에만 기본값 제공
    // 기본값: 09:00 ~ 18:00 (일반적인 업무 시간)
    return [
      '09:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
    ];
  }

  /// 백엔드에서 실제 펫 데이터 로드
  Future<void> _loadPetProfiles() async {
    if (!mounted) return;

    setState(() {
      _isLoadingPets = true;
      _petLoadError = null;
    });

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        if (!mounted) return;
        setState(() {
          _isLoadingPets = false;
          _petLoadError = '로그인이 필요합니다.';
        });
        return;
      }

      print('🔍 [DEBUG] 펫 목록 로드 시작 - 사용자 ID: ${currentUser.id}');

      // 타임아웃 설정 (10초)
      final response = await PetService()
          .getPetsByOwner(currentUser.id.toString())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw TimeoutException('펫 데이터 로드 시간 초과');
            },
          );

      print('🔍 [DEBUG] 펫 목록 응답: $response');

      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> petsData = response['pets'] ?? [];
        final List<PetProfile> profiles = petsData
            .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ [DEBUG] 로드된 펫 수: ${profiles.length}');
        for (var pet in profiles) {
          print('  - ${pet.name} (ID: ${pet.id})');
        }

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
    } on TimeoutException catch (e) {
      print('⏱️ [TIMEOUT] 펫 목록 로드 타임아웃: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPets = false;
        _petLoadError = '서버 응답 시간 초과. 다시 시도해주세요.';
      });
    } catch (e) {
      print('❌ [ERROR] 펫 목록 로드 오류: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPets = false;
        _petLoadError = '네트워크 오류: $e';
      });
    }
  }

  @override
  void dispose() {
    _memoController.dispose();
    _locationController.dispose();
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

  void _onLocationSelected(double latitude, double longitude, String address) {
    setState(() {
      _selectedLatitude = latitude;
      _selectedLongitude = longitude;
      _locationController.text = address;
    });
    print('📍 [DEBUG] 위치 선택됨: $address ($latitude, $longitude)');
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

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서비스 위치를 선택해 주세요.')));
      return;
    }

    if (_petProfiles.isNotEmpty && _selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('돌봄을 받을 반려동물을 선택해 주세요.')));
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

      // 날짜와 시간 조합 - OffsetDateTime 형식
      // 예: 2025-11-26T14:00:00+09:00
      String dateTimeStr;

      if (_selectedTime == null ||
          _selectedTime!.isEmpty ||
          !_selectedTime!.contains(':')) {
        // 시간이 "협의 가능" 같은 텍스트인 경우 기본값 사용
        final visitDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          9, // 기본 9시
          0,
        );
        // 백엔드 형식: yyyy-MM-dd'T'HH:mm:ss.SSSXXX (밀리초 필수)
        dateTimeStr =
            '${DateFormat('yyyy-MM-dd').format(visitDateTime)}T${DateFormat('HH:mm:ss').format(visitDateTime)}.000+09:00';
        print('⚠️ [WARN] 시간이 유효하지 않아 기본값(09:00) 사용: $_selectedTime');
      } else {
        final timeParts = _selectedTime!.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);

        final visitDateTime = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          hour,
          minute,
        );

        // 백엔드 형식: yyyy-MM-dd'T'HH:mm:ss.SSSXXX (밀리초 필수)
        dateTimeStr =
            '${DateFormat('yyyy-MM-dd').format(visitDateTime)}T${DateFormat('HH:mm:ss').format(visitDateTime)}.000+09:00';
      }

      print('🔍 [DEBUG] 생성된 예약 시간: $dateTimeStr');

      // Service를 백엔드 PetsitterWork enum으로 매핑
      String? petsitterWorkEnum = _mapServiceToEnum(_selectedService);

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
          'partner_id': int.parse(widget.sitter.id),
          'user_id': int.parse(currentUser.id.toString()),
          'user_type': 'SITTER',
          'petsitter_works': petsitterWorkEnum != null
              ? [petsitterWorkEnum]
              : ['ALL'],
          'pets_id': petId,
          'visit_date_time': dateTimeStr, // 방문 예약 시간 (사용자가 선택한 날짜/시간)
          'resv_urls': [],
          'resv_content': content,
        };

        print('🔍 [DEBUG] 예약 생성 요청 (펫: $petName, ID: $petId)');
        print('🔍 [DEBUG] URL: $url');
        print('🔍 [DEBUG] Request Body: ${json.encode(requestBody)}');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(requestBody),
        );

        print('🔍 [DEBUG] 응답 상태 (펫: $petName): ${response.statusCode}');
        print('🔍 [DEBUG] 응답 내용: ${utf8.decode(response.bodyBytes)}');

        if (response.statusCode == 200) {
          final responseData = json.decode(utf8.decode(response.bodyBytes));
          // ApiResponse 형식: {ok: true, data: {...}}
          if (responseData['ok'] == true) {
            successCount++;
            final reservationId = responseData['data']?['reservation_id'];
            print('✅ [SUCCESS] $petName 예약 성공 (ID: $reservationId)');
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
          final errorBody = utf8.decode(response.bodyBytes);
          print('❌ [FAIL] $petName 예약 실패: 상태 코드 ${response.statusCode}');
          print('❌ [FAIL] 오류 상세: $errorBody');
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

  // Service 한글명을 백엔드 PetsitterWork enum으로 매핑
  String? _mapServiceToEnum(String? service) {
    if (service == null) return null;

    final Map<String, String> serviceMap = {
      '산책': 'WALK',
      '이동/동행': 'TRANSPORT',
      '위생관리': 'HYGIENE',
      '전체': 'ALL',
    };

    return serviceMap[service] ?? 'ALL';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('펫시터 예약 신청'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SitterHeader(sitter: widget.sitter),
            const SizedBox(height: 24),
            _buildPetSelectionCard(),
            const SizedBox(height: 20),
            _buildLocationCard(),
            const SizedBox(height: 20),
            _buildScheduleCard(),
            const SizedBox(height: 20),
            _buildServiceCard(),
            const SizedBox(height: 20),
            _buildMemoCard(),
            const SizedBox(height: 28),
            SizedBox(
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
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
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
          // 날짜 선택
          GestureDetector(
            onTap: () async {
              final now = DateTime.now();
              final firstDate = DateTime(now.year, now.month, now.day);
              final lastDate = firstDate.add(const Duration(days: 60));

              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? firstDate,
                firstDate: firstDate,
                lastDate: lastDate,
                locale: const Locale('ko', 'KR'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF4FC59E),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF003829),
                      ),
                    ),
                    child: child!,
                  );
                },
              );

              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Color(0xFF4FC59E)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDate != null
                          ? DateFormat(
                              'yyyy년 MM월 dd일 (E)',
                              'ko_KR',
                            ).format(_selectedDate!)
                          : '날짜를 선택해주세요',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null
                            ? Colors.black87
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 시간 선택
          DropdownButtonFormField<String>(
            initialValue: _selectedTime,
            items: _generateTimeSlots()
                .map((time) => DropdownMenuItem(value: time, child: Text(time)))
                .toList(),
            onChanged: (value) => setState(() => _selectedTime = value),
            decoration: const InputDecoration(
              labelText: '예약 시간',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.access_time, color: Color(0xFF4FC59E)),
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
        width: 70,
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
                  height: 70,
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
                '돌봄 받을 반려동물',
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
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _petProfiles.map((profile) {
                  final isSelected = _selectedPetIds.contains(profile.id);
                  return _buildPetCard(profile, isSelected);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
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
                '서비스 위치',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003829),
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              hintText: '주소를 입력해주세요 (예: 강남구 테헤란로 123)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF4FC59E)),
            ),
            maxLines: 2,
            minLines: 1,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_locationController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('주소를 먼저 입력해주세요')),
                  );
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => LocationPickerWidget(
                      initialAddress: _locationController.text.trim(),
                      initialLatitude: _selectedLatitude,
                      initialLongitude: _selectedLongitude,
                      onLocationSelected: (lat, lng, address) {
                        _onLocationSelected(lat, lng, address);
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4FC59E),
                side: const BorderSide(color: Color(0xFF4FC59E)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.map),
              label: const Text('지도에서 위치 확인'),
            ),
          ),
          if (_selectedLatitude != null && _selectedLongitude != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F1),
                  borderRadius: BorderRadius.circular(8),
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
                        '위치 확인됨: ${_selectedLatitude!.toStringAsFixed(6)}, ${_selectedLongitude!.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF003829),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildServiceCard() {
    // 백엔드 PetsitterWork enum에 맞는 서비스 목록
    final allServices = ['산책', '이동/동행', '위생관리', '전체'];

    // 펫시터가 제공하는 서비스를 상단에, 나머지를 하단에 배치
    final sitterServices = widget.sitter.services;
    final otherServices = allServices
        .where((s) => !sitterServices.contains(s))
        .toList();
    final orderedServices = [...sitterServices, ...otherServices];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요청 서비스',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedService,
            items: orderedServices.map((service) {
              final isProvided = sitterServices.contains(service);
              return DropdownMenuItem(
                value: service,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isProvided)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4FC59E),
                        size: 18,
                      ),
                    if (isProvided) const SizedBox(width: 8),
                    Text(
                      service,
                      style: TextStyle(
                        color: isProvided ? Colors.black : Colors.grey[600],
                        fontWeight: isProvided
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedService = value),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              helperText: '✓ 표시는 이 펫시터가 제공하는 서비스입니다',
              helperMaxLines: 2,
            ),
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
            '추가 요청사항',
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
              hintText: '특별히 주의해야 할 사항이나 요청사항을 작성해 주세요.',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class _SitterHeader extends StatelessWidget {
  final SitterModel sitter;

  const _SitterHeader({required this.sitter});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE6F7F1),
          backgroundImage: sitter.imageUrl.isNotEmpty
              ? NetworkImage(sitter.imageUrl)
              : null,
          child: sitter.imageUrl.isNotEmpty
              ? null
              : const Icon(Icons.person, color: Color(0xFF4FC59E)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                sitter.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${sitter.sitterName} 펫시터',
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
                  Text('${sitter.rating}점'),
                  const SizedBox(width: 12),
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${sitter.distance}km'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
