// AI 케어 화면 위젯
// 케이지 센서 모니터링과 AI 진단 기능을 제공
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'dart:async';
import 'ai_diagnosis_gallery_screen.dart';
import '../services/ai_diagnosis_service.dart';
import '../services/pet_service.dart';
import '../services/auth_service.dart';
import '../services/sensor_service.dart';
import '../models/pet_profile.dart';
import '../models/ai_diagnosis.dart';

/// AI 케어 화면
/// 케이지 센서 데이터와 AI 진단 기능을 통합 제공
class AiCareScreen extends StatefulWidget {
  const AiCareScreen({Key? key}) : super(key: key);

  @override
  State<AiCareScreen> createState() => _AiCareScreenState();
}

class _AiCareScreenState extends State<AiCareScreen> {
  // 센서 데이터 상태 관리
  double? temperature; // 온도 (°C)
  double? humidity; // 습도 (%)
  int? airQuality; // 공기질 (CAI)

  // AI 진단 관련 변수
  final AIDiagnosisService _diagnosisService = AIDiagnosisService();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;

  // 선택된 반려동물 프로필 ID
  int? _selectedPetId;
  // 진단 부위 선택 (0: 눈, 1: 피부)
  int _selectedBodyPart = 0;

  // 반려동물 목록
  List<PetProfile> _petProfiles = [];
  bool _isPetLoading = false;

  // 온열패드/환기 제어 관련 변수
  bool _isHeaterOn = false; // 온열패드 켜짐/꺼짐
  bool _isCoolerOn = false; // 환기 켜짐/꺼짐
  bool _showHeater = true; // true: 온열패드 표시, false: 환기 표시

  // 센서 자동 업데이트 타이머
  Timer? _sensorUpdateTimer;

  // 선택된 센서 타입 (null: 선택 안함, 'temperature', 'humidity', 'air_quality')
  String? _selectedSensorType;

  // 선택된 기간 (0: 어제, 1: 일주일, 2: 한달)
  int _selectedPeriod = 0;

  // 집계 데이터
  Map<String, dynamic>? _aggregateData;

  @override
  void initState() {
    super.initState();
    _loadPetProfiles();
    _loadSensorData();
    // 20초마다 센서 데이터 자동 업데이트
    _sensorUpdateTimer = Timer.periodic(Duration(seconds: 20), (timer) {
      _loadSensorData();
    });
  }

  @override
  void dispose() {
    _sensorUpdateTimer?.cancel();
    super.dispose();
  }

  // 센서 데이터 로드
  Future<void> _loadSensorData() async {
    try {
      final sensorService = SensorService();
      final sensorData = await sensorService.getLatestSensorData();

      if (sensorData != null) {
        setState(() {
          temperature = sensorData.temperature;
          humidity = sensorData.humidity;
          airQuality = sensorData.gasRaw.toInt();
        });
        print(
          '✅ [AI케어] 센서 데이터 로드 성공: 온도=${temperature}°C, 습도=${humidity}%, 공기질=${airQuality}',
        );
      } else {
        print('⚠️ [AI케어] 센서 데이터를 불러올 수 없습니다');
      }
    } catch (e) {
      print('❌ [AI케어] 센서 데이터 로드 오류: $e');
    }
  }

  // 센서 선택 토글
  void _showSensorChart(
    String sensorType,
    String sensorLabel,
    Color sensorColor,
  ) {
    setState(() {
      // 같은 센서를 다시 클릭하면 닫기
      if (_selectedSensorType == sensorType) {
        _selectedSensorType = null;
      } else {
        _selectedSensorType = sensorType;
        // 집계 데이터 로드
        _loadAggregateData();
      }
    });
  }

  // 집계 데이터 로드
  Future<void> _loadAggregateData() async {
    try {
      final sensorService = SensorService();
      final data = await sensorService.getAggregateData();

      setState(() {
        _aggregateData = data;
      });
    } catch (e) {
      print('❌ [센서차트] 데이터 로드 오류: $e');
    }
  }

  // 반려동물 목록 로드
  Future<void> _loadPetProfiles() async {
    setState(() {
      _isPetLoading = true;
    });

    try {
      final currentUser = AuthService().currentUser;
      if (currentUser == null) {
        setState(() {
          _isPetLoading = false;
        });
        return;
      }

      final response = await PetService().getPetsByOwner(currentUser.id);
      if (response['success'] == true) {
        final List<dynamic> petsData = response['pets'];
        final List<PetProfile> profiles = petsData
            .map((json) => PetProfile.fromJson(json as Map<String, dynamic>))
            .toList();

        setState(() {
          _petProfiles = profiles;
          _isPetLoading = false;
          // 첫 번째 반려동물 자동 선택
          if (profiles.isNotEmpty && _selectedPetId == null) {
            _selectedPetId = profiles.first.id;
          }
        });
      } else {
        setState(() {
          _isPetLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPetLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 240),
        body: Column(
          children: [
            // 상단 탭바 (고정)
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const TabBar(
                labelColor: Color.fromARGB(255, 0, 108, 82),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color.fromARGB(255, 0, 108, 82),
                tabs: [
                  Tab(text: '케이지'),
                  Tab(text: 'AI진단'),
                ],
              ),
            ),
            // 탭별 컨텐츠 (스크롤 가능)
            Expanded(
              child: TabBarView(
                children: [
                  // 케이지 탭
                  SingleChildScrollView(child: _buildCageContent()),
                  // AI진단 탭
                  SingleChildScrollView(child: _buildAIDiagnosisContent()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 케이지 센서 컨텐츠
  Widget _buildCageContent() {
    return Column(
      children: [
        // 메인 컨트롤 영역
        Container(
          width: double.infinity,
          height: 280,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _showHeater
                  ? [
                      // 온열패드: 주황색 → 노란색
                      Color.fromARGB(255, 199, 78, 34), // 진한 주황색
                      Color.fromARGB(255, 255, 242, 189), // 밝은 노란색
                    ]
                  : [
                      // 환기: 청록색 그라데이션
                      Color.fromARGB(255, 8, 178, 93), // 진한 청록색
                      Color.fromARGB(255, 188, 247, 255), // 밝은 청록색
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 3,
                offset: Offset(0, 2),
                spreadRadius: 2,
              ),
            ],
          ),
          child: Stack(
            children: [
              // 중앙 온열패드/환기 상태 표시 (고양이 모양)
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    children: [
                      // 고양이 모양 테두리 및 배경
                      CustomPaint(
                        size: Size(240, 240),
                        painter: _CatShapeBorderPainter(
                          color: Colors.white.withValues(alpha: 0.8),
                          fillColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      // 내용
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _showHeater ? Icons.wb_sunny : Icons.ac_unit,
                              size: 80,
                              color: Colors.white,
                            ),
                            SizedBox(height: 16),
                            Text(
                              _showHeater ? '온열패드' : '환기',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              _showHeater
                                  ? (_isHeaterOn ? 'ON' : 'OFF')
                                  : (_isCoolerOn ? 'ON' : 'OFF'),
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: _showHeater
                                    ? (_isHeaterOn
                                          ? Color(0xFFFF6B6B)
                                          : Colors.grey)
                                    : (_isCoolerOn
                                          ? Color(0xFF4ECDC4)
                                          : Colors.grey),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 온열패드/환기 전환 버튼
              Positioned(
                right: 20,
                bottom: 20,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _showHeater = !_showHeater;
                    });
                  },
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _showHeater
                          ? Color(0xFFFF6B6B)
                          : Color(0xFF4ECDC4),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (_showHeater
                                      ? Color(0xFFFF6B6B)
                                      : Color(0xFF4ECDC4))
                                  .withOpacity(0.4),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(Icons.pets, color: Colors.white, size: 50),
                  ),
                ),
              ),
            ],
          ),
        ),
        // ON/OFF 컨트롤 패널
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // 온열패드 ON/OFF 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final newState = !_isHeaterOn;
                    setState(() {
                      _isHeaterOn = newState;
                    });

                    // 클라우드 서버에 제어 명령 전송
                    final sensorService = SensorService();
                    final success = await sensorService.controlHeater(
                      isOn: newState,
                    );

                    if (!success) {
                      // 실패 시 상태 되돌리기
                      setState(() {
                        _isHeaterOn = !newState;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('온열패드 제어 실패. 다시 시도해주세요.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isHeaterOn ? Color(0xFFFF6B6B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFFFF6B6B), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wb_sunny,
                          color: _isHeaterOn ? Colors.white : Color(0xFFFF6B6B),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isHeaterOn ? '온열 ON' : '온열 OFF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isHeaterOn
                                ? Colors.white
                                : Color(0xFFFF6B6B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // 환기 ON/OFF 버튼
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final newState = !_isCoolerOn;
                    setState(() {
                      _isCoolerOn = newState;
                    });

                    // 클라우드 서버에 제어 명령 전송
                    final sensorService = SensorService();
                    final success = await sensorService.controlCooler(
                      isOn: newState,
                    );

                    if (!success) {
                      // 실패 시 상태 되돌리기
                      setState(() {
                        _isCoolerOn = !newState;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('환기 제어 실패. 다시 시도해주세요.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _isCoolerOn ? Color(0xFF4ECDC4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Color(0xFF4ECDC4), width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.ac_unit,
                          color: _isCoolerOn ? Colors.white : Color(0xFF4ECDC4),
                          size: 20,
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isCoolerOn ? '환기 ON' : '환기 OFF',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isCoolerOn
                                ? Colors.white
                                : Color(0xFF4ECDC4),
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
        // 케이지 센서 헤더
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
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromARGB(255, 230, 233, 229),
              ),
            ],
          ),
        ),
        // 센서 데이터 표시
        Container(
          width: double.infinity,
          color: Colors.transparent,
          child: Column(
            children: [
              // 온도 센서
              _buildSensorCard(
                label: '온도',
                value: temperature != null
                    ? '${temperature!.toStringAsFixed(1)} °C'
                    : '--',
                color: Colors.red,
                onTap: () => _showSensorChart('temperature', '온도', Colors.red),
                isSelected: _selectedSensorType == 'temperature',
              ),
              // 습도 센서
              _buildSensorCard(
                label: '습도',
                value: humidity != null
                    ? '${humidity!.toStringAsFixed(1)} %'
                    : '--',
                color: Colors.blue,
                onTap: () => _showSensorChart('humidity', '습도', Colors.blue),
                isSelected: _selectedSensorType == 'humidity',
              ),
              // 공기질 센서
              _buildSensorCard(
                label: '공기',
                value: airQuality != null ? '$airQuality CAI' : '--',
                color: Colors.green,
                onTap: () =>
                    _showSensorChart('air_quality', '공기질', Colors.green),
                isSelected: _selectedSensorType == 'air_quality',
              ),
            ],
          ),
        ),

        // 선택된 센서의 그래프 표시
        if (_selectedSensorType != null) _buildSensorGraph(),
      ],
    );
  }

  Widget _buildSensorCard({
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80,
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
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
              SizedBox(
                width: 55,
                height: 55,
                child: Stack(
                  children: [
                    // 고양이 모양 테두리 (Stroke)
                    CustomPaint(
                      size: Size(55, 55),
                      painter: _CatShapeBorderPainter(color: color),
                    ),
                    // 중앙 텍스트
                    Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 센서 그래프 표시
  Widget _buildSensorGraph() {
    if (_aggregateData == null) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: _getSensorColor()),
        ),
      );
    }

    final averages = _aggregateData!['averages'];
    if (averages == null) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            '데이터를 불러올 수 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // 센서 타입에 맞는 데이터 가져오기
    String fieldKey;
    String unit;
    switch (_selectedSensorType) {
      case 'temperature':
        fieldKey = 'temperature';
        unit = '°C';
        break;
      case 'humidity':
        fieldKey = 'humidity';
        unit = '%';
        break;
      case 'air_quality':
        fieldKey = 'gas_raw';
        unit = 'CAI';
        break;
      default:
        return SizedBox();
    }

    final fieldData = averages[fieldKey];
    if (fieldData == null) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            '해당 센서의 데이터가 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // 선택된 기간에 맞는 데이터
    double? value;
    String periodLabel;
    switch (_selectedPeriod) {
      case 0: // 어제 (24시간)
        value = fieldData['last_day'];
        periodLabel = '어제 평균';
        break;
      case 1: // 일주일
        value = fieldData['last_week'];
        periodLabel = '일주일 평균';
        break;
      case 2: // 한달
        value = fieldData['last_month'];
        periodLabel = '한달 평균';
        break;
      default:
        return SizedBox();
    }

    if (value == null) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text(
            '해당 기간의 데이터가 없습니다',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // 모든 기간 데이터 가져오기 (비교용)
    final List<double> values = [];
    final List<String> labels = [];

    if (fieldData['last_day'] != null) {
      values.add(fieldData['last_day'].toDouble());
      labels.add('어제');
    }
    if (fieldData['last_week'] != null) {
      values.add(fieldData['last_week'].toDouble());
      labels.add('일주일');
    }
    if (fieldData['last_month'] != null) {
      values.add(fieldData['last_month'].toDouble());
      labels.add('한달');
    }

    if (values.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: Text('데이터가 없습니다', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    final sensorColor = _getSensorColor();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // 기간 선택 탭
          Row(
            children: [
              Expanded(child: _buildPeriodTab('어제', 0)),
              SizedBox(width: 8),
              Expanded(child: _buildPeriodTab('일주일', 1)),
              SizedBox(width: 8),
              Expanded(child: _buildPeriodTab('한달', 2)),
            ],
          ),
          SizedBox(height: 20),

          // 현재 값 표시 (고양이 모양)
          Center(
            child: SizedBox(
              width: 200,
              height: 220,
              child: Stack(
                children: [
                  // 고양이 모양 배경
                  CustomPaint(
                    size: Size(200, 220),
                    painter: _CatShapeBorderPainter(
                      color: Colors.transparent,
                      fillColor: sensorColor.withValues(alpha: 0.1),
                    ),
                  ),
                  // 내용
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          periodLabel,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${value.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            fontSize: 32,
                            color: sensorColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // 막대 그래프
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: (values.reduce((a, b) => a > b ? a : b) * 1.2),
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (group) =>
                        Colors.black.withValues(alpha: 0.8),
                    tooltipPadding: EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toStringAsFixed(1)} $unit',
                        TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < labels.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          );
                        }
                        return SizedBox();
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval:
                      (values.reduce((a, b) => a > b ? a : b) * 1.2) / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[300], strokeWidth: 1);
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  values.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: values[index],
                        color: sensorColor,
                        width: 40,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 기간 선택 탭 버튼
  Widget _buildPeriodTab(String label, int index) {
    final isSelected = _selectedPeriod == index;
    final sensorColor = _getSensorColor();

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? sensorColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sensorColor, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : sensorColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  /// 선택된 센서의 색상 가져오기
  Color _getSensorColor() {
    switch (_selectedSensorType) {
      case 'temperature':
        return Colors.red;
      case 'humidity':
        return Colors.blue;
      case 'air_quality':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// AI 진단 컨텐츠
  Widget _buildAIDiagnosisContent() {
    // 선택된 반려동물 찾기
    final selectedPet = _selectedPetId != null
        ? _petProfiles.firstWhere(
            (pet) => pet.id == _selectedPetId,
            orElse: () => _petProfiles.isNotEmpty
                ? _petProfiles.first
                : throw Exception('No pets available'),
          )
        : (_petProfiles.isNotEmpty ? _petProfiles.first : null);

    // 현재 선택된 모델 타입 계산
    DiagnosisModelType? selectedModelType;
    if (selectedPet != null) {
      final isDog =
          selectedPet.species.toLowerCase().contains('강아지') ||
          selectedPet.species.toLowerCase().contains('dog');

      if (isDog) {
        selectedModelType = _selectedBodyPart == 0
            ? DiagnosisModelType.dogEyes
            : DiagnosisModelType.dogSkin;
      } else {
        selectedModelType = _selectedBodyPart == 0
            ? DiagnosisModelType.catEyes
            : DiagnosisModelType.catSkin;
      }
    }

    final isModelAvailable =
        selectedPet != null &&
        selectedModelType != null &&
        AIDiagnosisService.isModelAvailable(selectedModelType);

    return Column(
      children: [
        // 반려동물 선택
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
                '반려동물 선택',
              ),
              SizedBox(height: 8),
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromARGB(255, 230, 233, 229),
              ),
            ],
          ),
        ),
        // 반려동물 리스트 컨테이너
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              if (_petProfiles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '등록된 반려동물이 없습니다.\n펫홈에서 반려동물을 추가해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _petProfiles.length,
                    itemBuilder: (context, index) {
                      final pet = _petProfiles[index];
                      final isSelected = pet.id == _selectedPetId;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPetId = pet.id;
                            _selectedImage = null; // 반려동물 변경 시 이미지 초기화
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(
                            right: index < _petProfiles.length - 1 ? 16 : 0,
                          ),
                          child: Column(
                            children: [
                              // 반려동물 이미지 (실루엣)
                              SizedBox(
                                width: 70,
                                height: 70,
                                child: PhysicalShape(
                                  clipper: _SvgMaskClipper(pet.species),
                                  color: Colors.transparent,
                                  shadowColor: isSelected
                                      ? const Color(0xFF00B27A)
                                      : Colors.grey,
                                  elevation: isSelected ? 6 : 2,
                                  child: ClipPath(
                                    clipper: _SvgMaskClipper(pet.species),
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE5E7EB),
                                        border: isSelected
                                            ? Border.all(
                                                color: const Color(0xFF00B27A),
                                                width: 3,
                                              )
                                            : null,
                                      ),
                                      child: _isValidNetworkUrl(pet.imageUrl)
                                          ? Image.network(
                                              _getFullImageUrl(pet.imageUrl),
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Center(
                                                      child: Icon(
                                                        Icons.pets,
                                                        size: 40,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                            )
                                          : Center(
                                              child: Icon(
                                                Icons.pets,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // 반려동물 이름
                              Text(
                                pet.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? const Color(0xFF00B27A)
                                      : const Color(0xFF2D3E3F),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // 진단 부위 선택 헤더
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
                '진단 부위',
              ),
              SizedBox(height: 8),
              Container(
                height: 2,
                width: double.infinity,
                color: const Color.fromARGB(255, 230, 233, 229),
              ),
            ],
          ),
        ),
        // 진단 섹션 전체 컨테이너
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // 진단 부위 선택 버튼
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBodyPart = 0;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedBodyPart == 0
                              ? const Color(0xFF00B27A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00B27A),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility,
                              color: _selectedBodyPart == 0
                                  ? Colors.white
                                  : const Color(0xFF00B27A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '눈',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _selectedBodyPart == 0
                                    ? Colors.white
                                    : const Color(0xFF00B27A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedBodyPart = 1;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedBodyPart == 1
                              ? const Color(0xFF00B27A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF00B27A),
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.healing,
                              color: _selectedBodyPart == 1
                                  ? Colors.white
                                  : const Color(0xFF00B27A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '피부',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _selectedBodyPart == 1
                                    ? Colors.white
                                    : const Color(0xFF00B27A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 이미지 선택 영역
              GestureDetector(
                onTap: _isAnalyzing ? null : _showImageSourceDialog,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _selectedImage != null
                        ? Stack(
                            children: [
                              Image.file(
                                _selectedImage!,
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                              // 재선택 힌트
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.edit,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '사진 변경',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            width: double.infinity,
                            height: 300,
                            decoration: BoxDecoration(color: Colors.grey[100]),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 80,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '사진을 선택해주세요',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '탭하여 카메라 또는 갤러리 선택',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 진단 버튼
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_selectedImage != null &&
                          !_isAnalyzing &&
                          isModelAvailable)
                      ? _performDiagnosis
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00B27A),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isAnalyzing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'AI 분석 중...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          isModelAvailable ? 'AI 진단 시작' : '모델 준비 중 (사용 불가)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // 진단 기록 보기 버튼
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AIDiagnosisGalleryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('진단 기록 보기'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00B27A),
                    side: const BorderSide(color: Color(0xFF00B27A), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 안내 섹션
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF00B27A), size: 20),
                  SizedBox(width: 8),
                  Text(
                    '진단 안내',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoItem('• 정확한 진단을 위해 밝은 곳에서 선명한 사진을 찍어주세요'),
              _buildInfoItem('• 증상이 있는 부위를 가까이에서 촬영해주세요'),
              _buildInfoItem('• AI 진단은 참고용이며, 정확한 진단은 수의사와 상담하세요'),
              _buildInfoItem('• 심각한 증상은 즉시 병원을 방문하시기 바랍니다'),
            ],
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Color(0xFF5A6C6D),
          height: 1.5,
        ),
      ),
    );
  }

  // 이미지 소스 선택 다이얼로그
  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들바
                Container(
                  margin: EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 타이틀
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    '사진 선택',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF006C52),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                // 카메라 옵션
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B27A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.camera_alt, color: Color(0xFF00B27A)),
                  ),
                  title: Text(
                    '카메라로 촬영',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _takePicture();
                  },
                ),
                // 갤러리 옵션
                ListTile(
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF00B27A).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.photo_library, color: Color(0xFF00B27A)),
                  ),
                  title: Text(
                    '갤러리에서 선택',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickFromGallery();
                  },
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // 카메라로 사진 찍기
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('카메라를 열 수 없습니다.\n권한을 확인해주세요.');
    }
  }

  // 갤러리에서 사진 선택
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorDialog('갤러리를 열 수 없습니다.\n권한을 확인해주세요.');
    }
  }

  // AI 진단 수행
  Future<void> _performDiagnosis() async {
    if (_selectedImage == null) {
      _showErrorDialog('먼저 사진을 선택해주세요.');
      return;
    }

    if (_selectedPetId == null) {
      _showErrorDialog('반려동물을 선택해주세요.');
      return;
    }

    final selectedPet = _petProfiles.firstWhere(
      (pet) => pet.id == _selectedPetId,
      orElse: () => throw Exception('선택된 반려동물을 찾을 수 없습니다.'),
    );

    // 현재 선택된 모델 타입 결정
    final isDog =
        selectedPet.species.toLowerCase().contains('강아지') ||
        selectedPet.species.toLowerCase().contains('dog');

    DiagnosisModelType modelType;
    if (isDog) {
      modelType = _selectedBodyPart == 0
          ? DiagnosisModelType.dogEyes
          : DiagnosisModelType.dogSkin;
    } else {
      modelType = _selectedBodyPart == 0
          ? DiagnosisModelType.catEyes
          : DiagnosisModelType.catSkin;
    }

    // 모델 사용 가능 여부 확인
    if (!AIDiagnosisService.isModelAvailable(modelType)) {
      _showErrorDialog(
        '${AIDiagnosisService.getModelTypeName(modelType)} 모델은 아직 준비 중입니다.',
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final diagnosis = await _diagnosisService.performDiagnosis(
        imagePath: _selectedImage!.path,
        petName: selectedPet.name,
        petId: selectedPet.id?.toString(),
        userId: selectedPet.userId,
        modelType: modelType,
        saveToBackend: true,
      );

      setState(() {
        _isAnalyzing = false;
      });

      _showDiagnosisResult(diagnosis);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      _showErrorDialog('진단 중 오류가 발생했습니다.\n$e');
    }
  }

  // 네트워크 URL 유효성 검사
  bool _isValidNetworkUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('/media/');
  }

  // 전체 이미지 URL 생성
  String _getFullImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return '';
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    if (imageUrl.startsWith('/media/')) {
      // 백엔드 서버 주소 추가
      return 'http://223.130.130.225:9075$imageUrl';
    }
    return imageUrl;
  }

  // 진단 결과 표시
  void _showDiagnosisResult(AIDiagnosis diagnosis) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DiagnosisResultSheet(diagnosis: diagnosis),
    );
  }

  // 에러 다이얼로그
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('알림'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

// 진단 결과 바텀 시트
class _DiagnosisResultSheet extends StatelessWidget {
  final AIDiagnosis diagnosis;

  const _DiagnosisResultSheet({required this.diagnosis});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 드래그 핸들
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 제목
                  const Text(
                    'AI 진단 결과',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E3F),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    diagnosis.petName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF5A6C6D),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 진단명 및 심각도
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: diagnosis.getSeverityColor().withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: diagnosis.getSeverityColor().withValues(
                          alpha: 0.3,
                        ),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: diagnosis.getSeverityColor(),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                diagnosis.getSeverityText(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '신뢰도: ${(diagnosis.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          diagnosis.diagnosis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3E3F),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          diagnosis.description,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5A6C6D),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 증상
                  _buildSection(
                    title: '관찰된 증상',
                    icon: Icons.medical_services,
                    items: diagnosis.symptoms,
                  ),

                  const SizedBox(height: 20),

                  // 권장사항
                  _buildSection(
                    title: '권장사항',
                    icon: Icons.assignment_turned_in,
                    items: diagnosis.recommendations,
                  ),

                  const SizedBox(height: 32),

                  // 닫기 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00B27A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '확인',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<String> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF00B27A), size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E3F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '• ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF5A6C6D)),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF5A6C6D),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 고양이 모양 테두리 페인터
class _CatShapeBorderPainter extends CustomPainter {
  final Color color;
  final Color? fillColor; // 내부 채우기 색상 (선택사항)

  _CatShapeBorderPainter({required this.color, this.fillColor});

  Path _getCatPath(Size size) {
    final path = Path();
    final scaleX = size.width / 302;
    final scaleY = size.height / 331;

    path.moveTo(186.347 * scaleX, 35.1901 * scaleY);
    path.cubicTo(
      172.847 * scaleX,
      32.0235 * scaleY,
      139.547 * scaleX,
      27.5901 * scaleY,
      114.347 * scaleX,
      35.1901 * scaleY,
    );
    path.cubicTo(
      108.18 * scaleX,
      26.0235 * scaleY,
      94.047 * scaleX,
      6.29012 * scaleY,
      86.847 * scaleX,
      0.690125 * scaleY,
    );
    path.cubicTo(
      76.1803 * scaleX,
      9.52346 * scaleY,
      52.547 * scaleX,
      36.8901 * scaleY,
      43.347 * scaleX,
      75.6901 * scaleY,
    );
    path.cubicTo(
      11.0136 * scaleX,
      109.19 * scaleY,
      -34.253 * scaleX,
      198.09 * scaleY,
      43.347 * scaleX,
      285.69 * scaleY,
    );
    path.cubicTo(
      56.347 * scaleX,
      300.023 * scaleY,
      94.5469 * scaleX,
      328.99 * scaleY,
      143.347 * scaleX,
      330.19 * scaleY,
    );
    path.cubicTo(
      167.014 * scaleX,
      331.19 * scaleY,
      223.047 * scaleX,
      323.69 * scaleY,
      257.847 * scaleX,
      285.69 * scaleY,
    );
    path.cubicTo(
      290.18 * scaleX,
      254.523 * scaleY,
      335.447 * scaleX,
      168.89 * scaleY,
      257.847 * scaleX,
      75.6901 * scaleY,
    );
    path.cubicTo(
      252.347 * scaleX,
      58.5235 * scaleY,
      235.847 * scaleX,
      19.4901 * scaleY,
      213.847 * scaleX,
      0.690125 * scaleY,
    );
    path.cubicTo(
      206.18 * scaleX,
      8.85679 * scaleY,
      189.947 * scaleX,
      27.1901 * scaleY,
      186.347 * scaleX,
      35.1901 * scaleY,
    );
    path.close();

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _getCatPath(size);

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

/// SVG 마스크 클리퍼 (강아지/고양이 실루엣)
class _SvgMaskClipper extends CustomClipper<Path> {
  final String species;

  _SvgMaskClipper(this.species);

  @override
  Path getClip(Size size) {
    final path = Path();

    // 강아지 또는 고양이에 따라 다른 SVG 경로 사용
    final isDog =
        species.toLowerCase().contains('강아지') ||
        species.toLowerCase().contains('dog');

    if (isDog) {
      // dog_i.svg 경로
      final scaleX = size.width / 308;
      final scaleY = size.height / 335;

      path.moveTo(189.347 * scaleX, 35.1901 * scaleY);
      path.cubicTo(
        175.847 * scaleX,
        32.0235 * scaleY,
        142.547 * scaleX,
        27.5901 * scaleY,
        117.347 * scaleX,
        35.1901 * scaleY,
      );
      path.cubicTo(
        111.18 * scaleX,
        26.0235 * scaleY,
        97.047 * scaleX,
        6.29012 * scaleY,
        89.847 * scaleX,
        0.690125 * scaleY,
      );
      path.cubicTo(
        79.1803 * scaleX,
        9.52346 * scaleY,
        55.547 * scaleX,
        36.8901 * scaleY,
        46.347 * scaleX,
        75.6901 * scaleY,
      );
      path.cubicTo(
        14.0136 * scaleX,
        109.19 * scaleY,
        -31.253 * scaleX,
        198.09 * scaleY,
        46.347 * scaleX,
        285.69 * scaleY,
      );
      path.cubicTo(
        59.347 * scaleX,
        300.023 * scaleY,
        97.5469 * scaleX,
        328.99 * scaleY,
        146.347 * scaleX,
        330.19 * scaleY,
      );
      path.cubicTo(
        170.014 * scaleX,
        331.19 * scaleY,
        226.047 * scaleX,
        323.69 * scaleY,
        260.847 * scaleX,
        285.69 * scaleY,
      );
      path.cubicTo(
        293.18 * scaleX,
        254.523 * scaleY,
        338.447 * scaleX,
        168.89 * scaleY,
        260.847 * scaleX,
        75.6901 * scaleY,
      );
      path.cubicTo(
        255.347 * scaleX,
        58.5235 * scaleY,
        238.847 * scaleX,
        19.4901 * scaleY,
        216.847 * scaleX,
        0.690125 * scaleY,
      );
      path.cubicTo(
        209.18 * scaleX,
        8.85679 * scaleY,
        192.947 * scaleX,
        27.1901 * scaleY,
        189.347 * scaleX,
        35.1901 * scaleY,
      );
      path.close();
    } else {
      // cat_i.svg 경로
      final scaleX = size.width / 302;
      final scaleY = size.height / 331;

      path.moveTo(186.347 * scaleX, 35.1901 * scaleY);
      path.cubicTo(
        172.847 * scaleX,
        32.0235 * scaleY,
        139.547 * scaleX,
        27.5901 * scaleY,
        114.347 * scaleX,
        35.1901 * scaleY,
      );
      path.cubicTo(
        108.18 * scaleX,
        26.0235 * scaleY,
        94.047 * scaleX,
        6.29012 * scaleY,
        86.847 * scaleX,
        0.690125 * scaleY,
      );
      path.cubicTo(
        76.1803 * scaleX,
        9.52346 * scaleY,
        52.547 * scaleX,
        36.8901 * scaleY,
        43.347 * scaleX,
        75.6901 * scaleY,
      );
      path.cubicTo(
        11.0136 * scaleX,
        109.19 * scaleY,
        -34.253 * scaleX,
        198.09 * scaleY,
        43.347 * scaleX,
        285.69 * scaleY,
      );
      path.cubicTo(
        56.347 * scaleX,
        300.023 * scaleY,
        94.5469 * scaleX,
        328.99 * scaleY,
        143.347 * scaleX,
        330.19 * scaleY,
      );
      path.cubicTo(
        167.014 * scaleX,
        331.19 * scaleY,
        223.047 * scaleX,
        323.69 * scaleY,
        257.847 * scaleX,
        285.69 * scaleY,
      );
      path.cubicTo(
        290.18 * scaleX,
        254.523 * scaleY,
        335.447 * scaleX,
        168.89 * scaleY,
        257.847 * scaleX,
        75.6901 * scaleY,
      );
      path.cubicTo(
        252.347 * scaleX,
        58.5235 * scaleY,
        235.847 * scaleX,
        19.4901 * scaleY,
        213.847 * scaleX,
        0.690125 * scaleY,
      );
      path.cubicTo(
        206.18 * scaleX,
        8.85679 * scaleY,
        189.947 * scaleX,
        27.1901 * scaleY,
        186.347 * scaleX,
        35.1901 * scaleY,
      );
      path.close();
    }

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
