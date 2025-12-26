// 동물병원 예약 화면 위젯
// 반려동물 병원 예약 및 관리 기능
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../pages/my_reservation.dart';
import '../pages/my_consultations_page.dart';
import '../pages/chat_rooms_page.dart';
import '../pages/my_favorites_page.dart';
import '../widgets/hospital_screen_widgets.dart';
import '../providers/hospital_provider.dart';

// 동물병원 예약 화면
// 근처 동물병원 검색, 예약 생성, 예약 내역 관리 기능 제공
class HospitalScreen extends StatefulWidget {
  const HospitalScreen({super.key});

  @override
  State<HospitalScreen> createState() => _HospitalScreenState();
}

class _HospitalScreenState extends State<HospitalScreen> {
  @override
  void initState() {
    super.initState();
    // 화면 로드 시 데이터 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HospitalProvider>().loadVets();
      context.read<HospitalProvider>().loadSitters();
      context.read<HospitalProvider>().loadReservations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            // 상단 탭바
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const TabBar(
                labelColor: Color(0xFF3BA688),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFF3BA688),
                tabs: [
                  Tab(text: '수의사 찾기'),
                  Tab(text: '펫시터 찾기'),
                ],
              ),
            ),
            // 각 탭에 맞는 화면
            Expanded(
              child: TabBarView(
                children: [
                  // 1️⃣ 수의사 찾기 탭
                  Container(
                    color: const Color.fromARGB(255, 248, 246, 240), // 배경색
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 상단 메뉴 버튼들
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.calendar_today,
                                label: '내 예약',
                                iconColor: const Color.fromARGB(
                                  255,
                                  255,
                                  217,
                                  113,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyReservation(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.contacts,
                                label: '내 상담',
                                iconColor: const Color.fromARGB(
                                  255,
                                  138,
                                  208,
                                  255,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyConsultationsPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.favorite,
                                label: '즐겨찾기',
                                iconColor: const Color.fromARGB(
                                  255,
                                  253,
                                  180,
                                  255,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyFavoritesPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 수의사 찾기 필터 섹션
                        HospitalScreenWidgets.buildVetFinderSection(),

                        // 수의사 목록 섹션
                        HospitalScreenWidgets.buildVetList(),
                      ],
                    ),
                  ),

                  // 2️⃣ 펫시터 찾기 탭
                  Container(
                    color: const Color.fromARGB(255, 248, 246, 240), // 배경색
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 상단 메뉴 버튼들
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.calendar_today,
                                label: '내 예약',
                                iconColor: const Color.fromARGB(
                                  255,
                                  255,
                                  217,
                                  113,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyReservation(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.chat_bubble_outline,
                                label: '채팅',
                                iconColor: const Color.fromARGB(
                                  255,
                                  117,
                                  119,
                                  255,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ChatRoomsPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              HospitalScreenWidgets.buildMenuButton(
                                context,
                                icon: Icons.favorite,
                                label: '즐겨찾기',
                                iconColor: const Color.fromARGB(
                                  255,
                                  253,
                                  180,
                                  255,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MyFavoritesPage(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 펫시터 찾기 필터 섹션
                        HospitalScreenWidgets.buildSitterFinderSection(),

                        // 펫시터 목록 섹션
                        HospitalScreenWidgets.buildSitterList(),
                      ],
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
