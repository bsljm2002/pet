import 'package:flutter/material.dart';

class MyContacts extends StatelessWidget {
  const MyContacts({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('연락처')),
      body: const Center(child: Text('연락처 페이지 (구현 예정)')),
    );
  }
}
