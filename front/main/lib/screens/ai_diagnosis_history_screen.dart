// AI 진단 기록 화면
import 'package:flutter/material.dart';
import '../models/pet_profile.dart';
import '../models/ai_diagnosis.dart';
import '../services/ai_diagnosis_service.dart';

/// AI 진단 기록 화면
class AIDiagnosisHistoryScreen extends StatefulWidget {
  final PetProfile profile;

  const AIDiagnosisHistoryScreen({Key? key, required this.profile})
      : super(key: key);

  @override
  State<AIDiagnosisHistoryScreen> createState() =>
      _AIDiagnosisHistoryScreenState();
}

class _AIDiagnosisHistoryScreenState extends State<AIDiagnosisHistoryScreen> {
  List<AIDiagnosis> _aiDiagnoses = [];
  bool _isLoading = true;
  final AIDiagnosisService _aiDiagnosisService = AIDiagnosisService();

  @override
  void initState() {
    super.initState();
    _loadAIDiagnoses();
  }

  /// AI 진단 기록 로드
  Future<void> _loadAIDiagnoses() async {
    if (widget.profile.id == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      print('🔍 AI 진단 기록 로드 시작: petId=${widget.profile.id}');
      final diagnoses = await _aiDiagnosisService.loadDiagnosesFromBackend(
        widget.profile.id!,
      );
      print('✅ AI 진단 기록 로드 완료: ${diagnoses.length}건');
      setState(() {
        _aiDiagnoses = diagnoses;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ AI 진단 기록 로드 오류: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 252, 255, 224),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 252, 255, 224),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: const Color.fromARGB(255, 0, 108, 82),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'AI 진단 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            SizedBox(height: 4),
            Container(
              height: 3,
              width: 120,
              color: const Color.fromARGB(255, 0, 108, 82),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4FC59E),
              ),
            )
          : _aiDiagnoses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medical_information_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '아직 AI 진단 기록이 없습니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'AI 케어 메뉴에서 진단을 받아보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 헤더 정보
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.pets,
                              size: 40,
                              color: Color(0xFF4FC59E),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.profile.name,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '총 ${_aiDiagnoses.length}건의 진단 기록',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),

                      // 진단 기록 리스트
                      ..._aiDiagnoses.map((diagnosis) {
                        return _buildAIDiagnosisCard(diagnosis);
                      }).toList(),
                    ],
                  ),
                ),
    );
  }

  /// AI 진단 카드
  Widget _buildAIDiagnosisCard(AIDiagnosis diagnosis) {
    // 심각도에 따른 색상
    Color severityColor;
    String severityText;
    if (diagnosis.severity == 'high') {
      severityColor = Colors.red;
      severityText = '주의';
    } else if (diagnosis.severity == 'medium') {
      severityColor = Colors.orange;
      severityText = '의심';
    } else if (diagnosis.severity == 'none') {
      severityColor = Colors.green;
      severityText = '정상';
    } else {
      severityColor = Colors.grey;
      severityText = '경미';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지
          if (diagnosis.imagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: Container(
                height: 200,
                width: double.infinity,
                color: Colors.grey.shade200,
                child: Image.network(
                  diagnosis.imagePath.replaceAll('localhost', '223.130.130.225'),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ 이미지 로드 실패: ${diagnosis.imagePath}');
                    print('❌ 오류: $error');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image,
                            size: 60,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            '이미지를 불러올 수 없습니다',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4FC59E),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 내용
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 진단명 및 상태
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        diagnosis.diagnosis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003829),
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severityText,
                        style: TextStyle(
                          fontSize: 13,
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // 날짜
                Text(
                  _formatDate(diagnosis.diagnosisDate),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 12),

                // 설명
                Text(
                  diagnosis.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),

                // 상세보기 버튼
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      _showAIDiagnosisDetailDialog(diagnosis);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF4FC59E),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text(
                      '상세 보기',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// AI 진단 상세 다이얼로그
  void _showAIDiagnosisDetailDialog(AIDiagnosis diagnosis) {
    // 심각도에 따른 색상
    Color severityColor;
    String severityText;
    if (diagnosis.severity == 'high') {
      severityColor = Colors.red;
      severityText = '주의';
    } else if (diagnosis.severity == 'medium') {
      severityColor = Colors.orange;
      severityText = '의심';
    } else if (diagnosis.severity == 'none') {
      severityColor = Colors.green;
      severityText = '정상';
    } else {
      severityColor = Colors.grey;
      severityText = '경미';
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: BoxConstraints(maxWidth: 450, maxHeight: 700),
          padding: EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 헤더
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        diagnosis.diagnosis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF003829),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        severityText,
                        style: TextStyle(
                          fontSize: 13,
                          color: severityColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      _formatDate(diagnosis.diagnosisDate),
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Divider(),
                SizedBox(height: 16),

                // 진단 설명
                Text(
                  '진단 설명',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF003829),
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    diagnosis.description,
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                ),
                SizedBox(height: 16),

                // 증상
                if (diagnosis.symptoms.isNotEmpty) ...[
                  Text(
                    '주요 증상',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  SizedBox(height: 8),
                  ...diagnosis.symptoms.map((symptom) => Padding(
                        padding: EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Text(symptom, style: TextStyle(fontSize: 14)),
                            ),
                          ],
                        ),
                      )),
                  SizedBox(height: 16),
                ],

                // 권장사항
                if (diagnosis.recommendations.isNotEmpty) ...[
                  Text(
                    '권장 사항',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF003829),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF4FC59E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: diagnosis.recommendations
                          .map((rec) => Padding(
                                padding: EdgeInsets.only(bottom: 6),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 18,
                                      color: Color(0xFF4FC59E),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(rec, style: TextStyle(fontSize: 14)),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                ],

                // 신뢰도
                SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      '신뢰도: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${(diagnosis.confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4FC59E),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
