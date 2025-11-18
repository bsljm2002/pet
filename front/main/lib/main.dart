// Flutter 앱의 메인 진입점 파일
// '숨숨루나' 반려동물 케어 애플리케이션의 루트 구성을 담당
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ai_care_screen.dart';
import 'screens/hospital_screen.dart';
import 'screens/pet_shop_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav.dart';
import 'providers/hospital_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';

// 애플리케이션 시작점
// Flutter 앱이 실행될 때 가장 먼저 호출되는 함수
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

// 앱의 최상위 위젯
// MaterialApp을 생성하고 앱 전체의 테마와 라우팅을 설정
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '숨숨루나', // 앱 타이틀
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 0, 56, 41),
      ), // 앱 전체 테마 색상 (짙은 녹색)
      home: const SplashScreen(), // 앱의 시작 화면을 스플래시 화면으로 변경
      routes: {'/main': (context) => const MainScreen()},
    );
  }
}

// 메인 화면 위젯
// 하단 네비게이션 바와 여러 화면을 관리하는 컨테이너 역할
// StatefulWidget으로 화면 전환 시 상태를 관리
class MainScreen extends StatefulWidget {
  final int initialIndex; // 초기 탭 인덱스
  final int homeTabIndex; // 홈 화면의 초기 탭 인덱스 (0: 펫 프로필, 1: 펫 일기)

  const MainScreen({super.key, this.initialIndex = 0, this.homeTabIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// MainScreen의 상태를 관리하는 State 클래스
// 현재 선택된 탭과 화면을 추적하고 전환을 처리
class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 하단 네비게이션 바 탭의 인덱스
  late int _currentIndex;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex; // 초기 인덱스 설정

    // 각 탭에 해당하는 화면들의 리스트
    // 0: 홈 (펫프로필/펫일기), 1: AI케어 (케이지/AI진단), 2: 동물병원, 3: 펫샵, 4: 설정
    _screens = [
      HomeScreen(initialTabIndex: widget.homeTabIndex),
      AiCareScreen(),
      HospitalScreen(),
      PetShopScreen(),
      SettingsScreen(),
    ];
  }

  // 하단 네비게이션 바의 탭이 눌렸을 때 호출되는 콜백 함수
  // 선택된 탭의 인덱스를 받아 현재 화면을 변경
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: false,
      ), // 상단 앱 바 (메인 화면에서는 뒤로가기 버튼 숨김)
      body: _screens[_currentIndex], // 현재 선택된 탭의 화면을 표시
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex, // 현재 선택된 탭 인덱스 전달
        onTap: _onTabTapped, // 탭 클릭 시 호출될 콜백 함수 전달
      ),
    );
  }
}
