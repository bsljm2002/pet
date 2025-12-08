// Flutter 앱의 메인 진입점 파일
// '피터펫' 반려동물 케어 애플리케이션의 루트 구성을 담당
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kakao_map_plugin/kakao_map_plugin.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/ai_care_screen.dart';
import 'screens/hospital_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/chatbot_screen.dart';
import 'widgets/custom_app_bar.dart';
import 'widgets/custom_bottom_nav.dart';
import 'providers/hospital_provider.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'services/fcm_service.dart';

// 애플리케이션 시작점
// Flutter 앱이 실행될 때 가장 먼저 호출되는 함수
Future<void> main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: ".env");

  // Firebase 초기화 (중복 방지)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // FCM 서비스 초기화
    await FCMService().initialize();
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('⚠️ Firebase already initialized');
    } else {
      print('⚠️ Firebase initialization failed: $e');
      // Firebase 없이도 앱 실행 가능하도록 에러 무시
    }
  }

  // 카카오맵 초기화 (네이티브 앱 키 사용)
  AuthRepository.initialize(appKey: '5438432f98436b9d8fef0aad2aa7ee7c');

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
      title: '피터펫', // 앱 타이틀
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 0, 56, 41),
      ), // 앱 전체 테마 색상 (짙은 녹색)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어
        Locale('en', 'US'), // 영어
      ],
      locale: const Locale('ko', 'KR'), // 기본 언어를 한국어로 설정
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

  const MainScreen({super.key, this.initialIndex = 0});

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
    // 0: 홈 (펫프로필), 1: AI케어 (케이지/AI진단), 2: 동물병원, 3: 설정
    _screens = [
      HomeScreen(),
      AiCareScreen(),
      HospitalScreen(),
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
      // 플로팅 챗봇 버튼 (고양이 모양)
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ChatbotScreen()),
            );
          },
          child: Container(
            width: 70,
            height: 76,
            child: Stack(
              children: [
                // 강아지 모양 배경
                CustomPaint(
                  size: Size(70, 76),
                  painter: _DogShapeBorderPainter(
                    color: Colors.white,
                    fillColor: const Color.fromARGB(255, 0, 108, 82),
                  ),
                ),
                // 아이콘
                Center(
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

/// 강아지 모양 테두리 페인터
class _DogShapeBorderPainter extends CustomPainter {
  final Color color;
  final Color? fillColor;

  _DogShapeBorderPainter({required this.color, this.fillColor});

  Path _getDogPath(Size size) {
    final path = Path();
    final scaleX = size.width / 302;
    final scaleY = size.height / 325;

    // dog_i.svg 경로: M111 30.1659C123.333 25.8325 156.6 19.7659 191 30.1659...
    path.moveTo(111 * scaleX, 30.1659 * scaleY);
    path.cubicTo(
      123.333 * scaleX,
      25.8325 * scaleY,
      156.6 * scaleX,
      19.7659 * scaleY,
      191 * scaleX,
      30.1659 * scaleY,
    );
    path.cubicTo(
      193.833 * scaleX,
      22.1659 * scaleY,
      204.5 * scaleX,
      5.16587 * scaleY,
      224.5 * scaleX,
      1.16587 * scaleY,
    );
    path.cubicTo(
      244.5 * scaleX,
      -2.83413 * scaleY,
      260.833 * scaleX,
      12.1659 * scaleY,
      266.5 * scaleX,
      20.1659 * scaleY,
    );
    path.cubicTo(
      274.667 * scaleX,
      30.9992 * scaleY,
      287.3 * scaleX,
      59.3659 * scaleY,
      272.5 * scaleX,
      86.1659 * scaleY,
    );
    path.cubicTo(
      282.833 * scaleX,
      99.4992 * scaleY,
      303 * scaleX,
      136.666 * scaleY,
      301 * scaleX,
      178.666 * scaleY,
    );
    path.cubicTo(
      299.333 * scaleX,
      197.499 * scaleY,
      291.3 * scaleX,
      240.766 * scaleY,
      272.5 * scaleX,
      263.166 * scaleY,
    );
    path.cubicTo(
      261 * scaleX,
      277.499 * scaleY,
      228.6 * scaleX,
      308.766 * scaleY,
      191 * scaleX,
      319.166 * scaleY,
    );
    path.cubicTo(
      177.667 * scaleX,
      322.833 * scaleY,
      143 * scaleX,
      327.966 * scaleY,
      111 * scaleX,
      319.166 * scaleY,
    );
    path.cubicTo(
      94.6667 * scaleX,
      314.999 * scaleY,
      55.6 * scaleX,
      297.966 * scaleY,
      30 * scaleX,
      263.166 * scaleY,
    );
    path.cubicTo(
      20.3333 * scaleX,
      252.333 * scaleY,
      0.9 * scaleX,
      220.266 * scaleY,
      0.5 * scaleX,
      178.666 * scaleY,
    );
    path.cubicTo(
      0.833333 * scaleX,
      159.666 * scaleY,
      7.2 * scaleX,
      114.566 * scaleY,
      30 * scaleX,
      86.1659 * scaleY,
    );
    path.cubicTo(
      23.5 * scaleX,
      76.1659 * scaleY,
      15.5 * scaleX,
      48.9659 * scaleY,
      35.5 * scaleX,
      20.1659 * scaleY,
    );
    path.cubicTo(
      40 * scaleX,
      12.6659 * scaleY,
      54.7 * scaleX,
      -1.63412 * scaleY,
      77.5 * scaleX,
      1.16587 * scaleY,
    );
    path.cubicTo(
      85.6667 * scaleX,
      2.49921 * scaleY,
      103.8 * scaleX,
      10.1659 * scaleY,
      111 * scaleX,
      30.1659 * scaleY,
    );
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getDogPath(size);

    // 내부 채우기 (fillColor가 있는 경우)
    if (fillColor != null) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // 테두리 그리기
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
