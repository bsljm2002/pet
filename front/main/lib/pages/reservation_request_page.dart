import 'package:flutter/material.dart';

import '../models/vet_model.dart';

/// 예약 신청 페이지
/// 선택한 병원/수의사 정보를 표시하고 예약 관련 정보를 입력받는다.
class ReservationRequestPage extends StatefulWidget {
  final VetModel vet;

  const ReservationRequestPage({super.key, required this.vet});

  @override
  State<ReservationRequestPage> createState() => _ReservationRequestPageState();
}

class _ReservationRequestPageState extends State<ReservationRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _petNameController = TextEditingController();
  final _memoController = TextEditingController();
  String? _selectedSpecialty;
  String? _selectedTime;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedSpecialty =
        widget.vet.specialties.isNotEmpty ? widget.vet.specialties.first : null;
    _selectedTime =
        widget.vet.availableTimes.isNotEmpty ? widget.vet.availableTimes.first : null;
  }

  @override
  void dispose() {
    _petNameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

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
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '반려동물 정보',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _petNameController,
                    decoration: const InputDecoration(
                      labelText: '반려동물 이름',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? '반려동물 이름을 입력해 주세요.' : null,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '진료 희망 항목',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedSpecialty,
                    items: widget.vet.specialties
                        .map((specialty) => DropdownMenuItem(
                              value: specialty,
                              child: Text(specialty),
                            ))
                        .toList(),
                    onChanged: (value) => setState(() => _selectedSpecialty = value),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '예약 일시',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            _selectedDate == null
                                ? '예약 날짜 선택'
                                : '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedTime,
                          items: widget.vet.availableTimes
                              .map((time) => DropdownMenuItem(
                                    value: time,
                                    child: Text(time),
                                  ))
                              .toList(),
                          onChanged: (value) => setState(() => _selectedTime = value),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: '시간',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '추가 메모',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _memoController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText: '증상이나 전달하고 싶은 내용을 작성해 주세요.',
                      border: OutlineInputBorder(),
                    ),
                  ),
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
          ],
        ),
      ),
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
