import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/sensor_service.dart';

/// 센서 데이터 차트 화면
class SensorChartScreen extends StatefulWidget {
  final String sensorType; // 'temperature', 'humidity', 'air_quality'
  final String sensorLabel; // '온도', '습도', '공기질'
  final Color sensorColor;

  const SensorChartScreen({
    Key? key,
    required this.sensorType,
    required this.sensorLabel,
    required this.sensorColor,
  }) : super(key: key);

  @override
  State<SensorChartScreen> createState() => _SensorChartScreenState();
}

class _SensorChartScreenState extends State<SensorChartScreen> {
  int _selectedPeriod = 0; // 0: 어제(24시간), 1: 일주일, 2: 한달
  Map<String, dynamic>? _aggregateData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAggregateData();
  }

  Future<void> _loadAggregateData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sensorService = SensorService();
      final data = await sensorService.getAggregateData();

      setState(() {
        _aggregateData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ [센서차트] 데이터 로드 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.sensorLabel} 그래프'),
        backgroundColor: widget.sensorColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 기간 선택 탭
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildPeriodTab('어제', 0),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodTab('일주일', 1),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: _buildPeriodTab('한달', 2),
                ),
              ],
            ),
          ),

          // 차트 영역
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: widget.sensorColor,
                    ),
                  )
                : _aggregateData == null
                    ? Center(
                        child: Text(
                          '데이터를 불러올 수 없습니다',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : Padding(
                        padding: EdgeInsets.all(16),
                        child: _buildChart(),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index) {
    final isSelected = _selectedPeriod == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? widget.sensorColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: widget.sensorColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : widget.sensorColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    if (_aggregateData == null) return SizedBox();

    final averages = _aggregateData!['averages'];
    if (averages == null) return SizedBox();

    // 센서 타입에 맞는 데이터 가져오기
    String fieldKey;
    String unit;
    switch (widget.sensorType) {
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
    if (fieldData == null) return SizedBox();

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
      return Center(
        child: Text(
          '해당 기간의 데이터가 없습니다',
          style: TextStyle(color: Colors.grey[600]),
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
      return Center(
        child: Text(
          '데이터가 없습니다',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        // 현재 값 표시
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: widget.sensorColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                periodLabel,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${value.toStringAsFixed(1)} $unit',
                style: TextStyle(
                  fontSize: 36,
                  color: widget.sensorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 32),

        // 막대 그래프
        Expanded(
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: (values.reduce((a, b) => a > b ? a : b) * 1.2),
              minY: 0,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (group) => Colors.black.withValues(alpha: 0.8),
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
                      if (value.toInt() >= 0 && value.toInt() < labels.length) {
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
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (values.reduce((a, b) => a > b ? a : b) * 1.2) / 5,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  );
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
                      color: widget.sensorColor,
                      width: 40,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
