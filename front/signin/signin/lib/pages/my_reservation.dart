import 'package:flutter/material.dart';

class MyReservation extends StatelessWidget {
  const MyReservation({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 예약')),
      body: const Center(child: Text('예약 내역 페이지 (구현 예정)')),
    );
  }
}
