import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/pet_profile.dart';
import '../models/vet_model.dart';
import '../services/pet_profile_manager.dart';

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
  late final List<PetProfile> _petProfiles;
  final Set<String> _selectedPetIds = {};

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDate!;
    _selectedSpecialty =
        widget.vet.specialties.isNotEmpty ? widget.vet.specialties.first : null;
    _selectedTime =
        widget.vet.availableTimes.isNotEmpty ? widget.vet.availableTimes.first : null;
    _petProfiles = PetProfileManager().getAllProfiles();
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  void _togglePetSelection(String petId) {
    setState(() {
      if (_selectedPetIds.contains(petId)) {
        _selectedPetIds.remove(petId);
      } else {
        _selectedPetIds.add(petId);
      }
    });
  }

  void _submit() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 날짜를 선택해 주세요.')),
      );
      return;
    }

    if (_selectedTime == null || _selectedTime!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 시간을 선택해 주세요.')),
      );
      return;
    }

    if (_petProfiles.isNotEmpty && _selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('진료 받을 반려동물을 선택해 주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('예약 요청이 접수되었습니다.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 신청'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _VetHeader(vet: widget.vet),
            const SizedBox(height: 24),
            _buildPetSelectionCard(),
            const SizedBox(height: 20),
            _buildScheduleCard(),
            const SizedBox(height: 20),
            _buildSpecialtyCard(),
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
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF4FC59E).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF4FC59E),
                shape: BoxShape.circle,
              ),
              weekendTextStyle: const TextStyle(color: Colors.redAccent),
            ),
            calendarFormat: CalendarFormat.month,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedTime,
            items: widget.vet.availableTimes
                .map(
                  (time) => DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  ),
                )
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

  Widget _buildPetSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '진료 받을 반려동물',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          if (_petProfiles.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F7F1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '등록된 반려동물 프로필이 없습니다.\n홈 화면에서 프로필을 추가해 주세요.',
                style: TextStyle(
                  color: Color(0xFF2B8C6C),
                  height: 1.5,
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _petProfiles.map((profile) {
                final isSelected = _selectedPetIds.contains(profile.id);
                final imageUrl = profile.imageUrl ?? '';
                ImageProvider? avatarImage;
                if (imageUrl.isNotEmpty) {
                  avatarImage = NetworkImage(imageUrl);
                }
                return FilterChip(
                  avatar: CircleAvatar(
                    backgroundColor: const Color(0xFFE6F7F1),
                    backgroundImage: avatarImage,
                    child: avatarImage == null
                        ? const Icon(Icons.pets, color: Color(0xFF4FC59E))
                        : null,
                  ),
                  label: Text(profile.name),
                  selected: isSelected,
                  onSelected: (_) => _togglePetSelection(profile.id),
                  selectedColor: const Color(0xFF4FC59E).withOpacity(0.2),
                  checkmarkColor: const Color(0xFF4FC59E),
                  labelStyle: TextStyle(
                    color: isSelected ? const Color(0xFF2B8C6C) : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF4FC59E)
                          : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                );
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
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: const Color(0xFFE6F7F1),
          backgroundImage: vet.imageUrl.isNotEmpty ? NetworkImage(vet.imageUrl) : null,
          child: vet.imageUrl.isNotEmpty
              ? null
              : const Icon(Icons.local_hospital_outlined, color: Color(0xFF4FC59E)),
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
    );
  }
}
