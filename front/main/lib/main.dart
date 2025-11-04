// Flutter 앱의 메인 진입점 파일
// '숨숨루나' 반려동물 케어 애플리케이션의 루트 구성을 담당
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pet_diary_screen.dart';
import 'screens/ai_diagnosis_screen.dart';
import 'screens/hospital_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav.dart';
import 'providers/hospital_provider.dart';

// 애플리케이션 시작점
// Flutter 앱이 실행될 때 가장 먼저 호출되는 함수
void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HospitalProvider()),
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
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

// MainScreen의 상태를 관리하는 State 클래스
// 현재 선택된 탭과 화면을 추적하고 전환을 처리
class _MainScreenState extends State<MainScreen> {
  // 현재 선택된 하단 네비게이션 바 탭의 인덱스
  int _currentIndex = 0;

  // 각 탭에 해당하는 화면들의 리스트
  // 0: 홈, 1: 펫 일기, 2: AI 진단, 3: 동물병원, 4: 설정
  final List<Widget> _screens = [
    HomeScreen(),
    PetDiaryScreen(),
    AiDiagnosisScreen(),
    HospitalScreen(),
    SettingsScreen(),
  ];

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
      appBar: CustomAppBar(), // 상단 앱 바
      body: _screens[_currentIndex], // 현재 선택된 탭의 화면을 표시
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex, // 현재 선택된 탭 인덱스 전달
        onTap: _onTabTapped, // 탭 클릭 시 호출될 콜백 함수 전달
      ),
    );
  }
}
