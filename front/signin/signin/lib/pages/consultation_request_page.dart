import 'package:flutter/material.dart';

import '../models/vet_model.dart';

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
  final _petNameController = TextEditingController();
  final _topicController = TextEditingController();
  final _contactController = TextEditingController();
  String _preferredContact = '전화';
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;

  @override
  void dispose() {
    _petNameController.dispose();
    _topicController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 14, minute: 0),
    );
    if (picked != null) {
      setState(() => _preferredTime = picked);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('상담 요청이 접수되었습니다.')),
    );
    Navigator.of(context).pop();
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
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '상담 정보',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  const SizedBox(height: 16),
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
                  const Text(
                    '희망 상담 방식',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                  const SizedBox(height: 20),
                  const Text(
                    '희망 상담 시간',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            _preferredDate == null
                                ? '날짜 선택'
                                : '${_preferredDate!.year}-${_preferredDate!.month.toString().padLeft(2, '0')}-${_preferredDate!.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.schedule),
                          label: Text(
                            _preferredTime == null
                                ? '시간 선택'
                                : '${_preferredTime!.hour.toString().padLeft(2, '0')}:${_preferredTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
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
