import 'package:flutter/material.dart';
import 'seller_settings_screen.dart';

class SellerHomeScreen extends StatefulWidget {
  const SellerHomeScreen({super.key});

  @override
  State<SellerHomeScreen> createState() => _SellerHomeScreenState();
}

class _SellerHomeScreenState extends State<SellerHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SellerMainPage(),
    const SellerSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF3BA688),
        unselectedItemColor: const Color(0xFF5A6C6D),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }
}

class SellerMainPage extends StatelessWidget {
  const SellerMainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8D8D0),
      appBar: AppBar(
        title: const Text('펫샵 (판매자) 홈'),
        backgroundColor: const Color(0xFF3BA688),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.store,
                size: 60,
                color: Color(0xFF3BA688),
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              '펫샵 (판매자) 전용 페이지',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E3F),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '상품 관리 기능이 추가될 예정입니다',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF5A6C6D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
