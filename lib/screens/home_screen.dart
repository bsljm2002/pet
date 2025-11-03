// 홈 화면 위젯
// 반려동물 케어 시스템의 메인 대시보드
// 케이지 센서 데이터, 작동 제어, 펫 프로필 관리 기능 제공
import 'package:flutter/material.dart';

// 홈 화면 위젯
// 앱의 메인 화면으로 다음 기능들을 제공:
// 1. 케이지 센서 모니터링 (온도, 습도, 공기질)
// 2. IoT 디바이스 작동 제어
// 3. 반려동물 프로필 관리
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // 상단 헤더 - 'Home' 제목과 밑줄
          Container(
            width: double.infinity,
            height: 30,
            color: const Color.fromARGB(255, 212, 244, 228),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 108, 82),
                    fontSize: 16,
                  ),
                  'Home',
                ),
                SizedBox(height: 4),
                // 제목 밑줄
                Container(
                  height: 3,
                  width: 80,
                  color: const Color.fromARGB(255, 0, 108, 82),
                ),
              ],
            ),
          ),
          // 메인 컨트롤 영역 - IoT 디바이스 상태 표시 및 제어
          Container(
            width: double.infinity,
            height: 350,
            decoration: BoxDecoration(
              // 그라데이션 배경 (짙은 녹색에서 연한 청록색으로)
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.fromARGB(255, 0, 63, 43), // 시작 색 (짙은 녹색)
                  Color.fromARGB(255, 172, 255, 230), // 끝 색 (연한 청록색)
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 3,
                  offset: Offset(0, 2),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                // 중앙의 큰 반투명 원형 - 디바이스 상태 표시 영역
                Center(
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.3), // 반투명 흰색
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                  ),
                ),
                // 오른쪽 하단 작동 제어 버튼
                // IoT 디바이스 ON/OFF 제어 버튼
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: 실제 IoT 디바이스 제어 로직 구현
                      print('작동 버튼 클릭됨');
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, color: Color(0xFF93C5FD), size: 55),
                          SizedBox(height: 1),
                          Text(
                            '작동',
                            style: TextStyle(
                              color: Color(0xFF93C5FD),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 섹션 구분선 - '케이지 센서' 헤더
          Container(
            width: double.infinity,
            height: 50,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 108, 82),
                    fontSize: 16,
                  ),
                  '케이지 센서',
                ),
                SizedBox(height: 8),
                // 구분선
                Container(
                  height: 2,
                  width: double.infinity,
                  color: const Color.fromARGB(255, 230, 233, 229),
                ),
              ],
            ),
          ),
          // 센서 데이터 표시 영역 - 온도, 습도, 공기질
          Container(
            width: double.infinity,
            height: 200,
            color: Colors.transparent,
            child: Column(
              children: [
                // 온도 센서 카드
                // 실시간 케이지 내부 온도를 섭씨로 표시
                Container(
                  width: double.infinity,
                  height: 55,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 온도 아이콘 (빨간색 원형 뱃지)
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              '온도',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ),
                        // 온도 값 표시 (예시: 23.5°C)
                        Text(
                          '23.5 °C',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 습도 센서 카드
                // 실시간 케이지 내부 습도를 퍼센트로 표시
                Container(
                  width: double.infinity,
                  height: 55,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 습도 아이콘 (파란색 원형 뱃지)
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.blue, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              '습도',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        // 습도 값 표시 (예시: 39.5%)
                        Text(
                          '39.5 %',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // 공기질 센서 카드
                // CAI (통합대기환경지수) 값으로 공기질 표시
                Container(
                  width: double.infinity,
                  height: 55,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 공기질 아이콘 (녹색 원형 뱃지)
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.green, width: 2.5),
                          ),
                          child: Center(
                            child: Text(
                              '공기',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                        // 공기질 값 표시 (CAI 지수)
                        Text(
                          '52 CAI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 섹션 구분선 - '펫 프로필' 헤더
          Container(
            width: double.infinity,
            height: 50,
            color: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 108, 82),
                    fontSize: 16,
                  ),
                  '펫 프로필',
                ),
                SizedBox(height: 8),
                // 구분선
                Container(
                  height: 2,
                  width: double.infinity,
                  color: const Color.fromARGB(255, 230, 233, 229),
                ),
              ],
            ),
          ),
          // 펫 프로필 가로 스크롤 영역
          // 등록된 반려동물들의 프로필을 가로로 스크롤하며 표시
          Container(
            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            width: double.infinity,
            color: Colors.transparent,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal, // 가로 스크롤 설정
              child: Row(
                children: [
                  // 반려동물 1 프로필
                  _buildPetProfile(
                    context,
                    imageUrl: 'https://picsum.photos/200',
                    petName: '뽀비',
                  ),
                  SizedBox(width: 20),
                  // 반려동물 2 프로필
                  _buildPetProfile(
                    context,
                    imageUrl: 'https://picsum.photos/201',
                    petName: '쫑이',
                  ),
                  SizedBox(width: 20),
                  // 반려동물 3 프로필
                  _buildPetProfile(
                    context,
                    imageUrl: 'https://picsum.photos/202',
                    petName: '돌멩이',
                  ),
                  SizedBox(width: 20),
                  // 새로운 펫 추가 버튼
                  _buildAddPetButton(context),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 펫 프로필 카드 위젯 생성 메서드
  ///
  /// 반려동물의 프로필 이미지와 이름을 원형 카드로 표시
  /// 클릭 시 해당 반려동물의 상세 정보 페이지로 이동
  ///
  /// [imageUrl] - 반려동물 프로필 이미지 URL
  /// [petName] - 반려동물 이름
  Widget _buildPetProfile(
    BuildContext context, {
    required String imageUrl,
    required String petName,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: 펫 상세 정보 페이지로 이동 기능 구현
        print('$petName 프로필 클릭됨');
      },
      child: Column(
        children: [
          // 원형 프로필 이미지
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFE5E7EB),
              backgroundImage: NetworkImage(imageUrl), // 네트워크에서 이미지 로드
            ),
          ),
          SizedBox(height: 8),
          // 반려동물 이름 표시
          Text(
            petName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 0, 108, 82),
            ),
          ),
        ],
      ),
    );
  }

  /// 새로운 펫 추가 버튼 위젯
  ///
  /// '+' 아이콘이 있는 원형 버튼
  /// 클릭 시 새로운 반려동물 등록 페이지로 이동
  Widget _buildAddPetButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: 새로운 펫 프로필 추가 페이지로 이동 기능 구현
        print('새로운 펫 프로필 추가 버튼 클릭됨');
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) => AddPetScreen()),
        // );
      },
      child: Column(
        children: [
          // '+' 아이콘 버튼
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Color(0xFFD1D5DB), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add, size: 40, color: Color(0xFF9CA3AF)),
          ),
          SizedBox(height: 8),
          // 'Member' 텍스트
          Text(
            'Member',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
