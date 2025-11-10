import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/pet_profile.dart';
import '../models/vet_model.dart';
import '../services/pet_profile_manager.dart';

/// 상담 신청 페이지
/// 병원/수의사 정보와 함께 상담 관련 정보를 입력할 수 있는 화면.
class ConsultationRequestPage extends StatefulWidget {
  final VetModel vet;

  const ConsultationRequestPage({super.key, required this.vet});

  @override
  State<ConsultationRequestPage> createState() => _ConsultationRequestPageState();
}

class _ConsultationRequestPageState extends State<ConsultationRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _topicController = TextEditingController();
  final _contentController = TextEditingController();
  final _contactController = TextEditingController();
  String _preferredContact = '전화';
  late DateTime _focusedDay;
  DateTime? _selectedDate;
  String? _selectedTime;
  late final List<PetProfile> _petProfiles;
  final Set<int> _selectedPetIds = {};

  @override
  void initState() {
    super.initState();
    Intl.defaultLocale = 'ko_KR';
    initializeDateFormatting('ko_KR', null);
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _focusedDay = _selectedDate!;
    _selectedTime =
        widget.vet.availableTimes.isNotEmpty ? widget.vet.availableTimes.first : null;
    _petProfiles = PetProfileManager().getAllProfiles();
  }

  @override
  void dispose() {
    _topicController.dispose();
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 날짜를 선택해 주세요.')),
      );
      return;
    }

    if (widget.vet.availableTimes.isNotEmpty &&
        (_selectedTime == null || _selectedTime!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 시간을 선택해 주세요.')),
      );
      return;
    }

    if (_petProfiles.isNotEmpty && _selectedPetIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('상담 받을 반려동물을 선택해 주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상담 요청이 접수되었습니다.')),
    );
    Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('상담 신청'),
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
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopicCard(),
                  const SizedBox(height: 20),
                  _buildContactMethodCard(),
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
                        '상담 요청 보내기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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

  Widget _buildPetSelectionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상담 받을 반려동물',
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

  Widget _buildTopicCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '상담 주제 및 내용',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _topicController,
            decoration: const InputDecoration(
              labelText: '상담 주제',
              hintText: '예) 식이 조절 상담, 예방접종 문의 등',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '상담 주제를 입력해 주세요.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: '상담 내용',
              hintText: '상세한 상담 내용을 작성해 주세요.',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '상담 내용을 입력해 주세요.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildContactMethodCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '희망 상담 방식',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003829),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['전화', '영상통화', '카카오톡', '이메일'].map((method) {
              final isSelected = _preferredContact == method;
              return ChoiceChip(
                label: Text(method),
                selected: isSelected,
                onSelected: (_) => setState(() => _preferredContact = method),
                selectedColor: const Color(0xFF4FC59E),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF003829),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _contactController,
            decoration: InputDecoration(
              labelText: '연락받을 ${_preferredContact == '이메일' ? '이메일' : '전화번호'}',
              border: const OutlineInputBorder(),
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? '연락처 정보를 입력해 주세요.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    final firstDay = DateTime.now();
    final lastDay = firstDay.add(const Duration(days: 30));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '희망 상담 일시',
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
          if (widget.vet.availableTimes.isNotEmpty)
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
                labelText: '상담 시간',
                border: OutlineInputBorder(),
              ),
            )
          else
            const Text(
              '상담 가능한 시간이 등록되지 않았습니다.\n병원에 직접 연락하여 시간을 조율해 주세요.',
              style: TextStyle(
                color: Colors.black54,
                height: 1.5,
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
