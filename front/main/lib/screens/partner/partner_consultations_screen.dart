import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/consultation_record.dart';
import '../../services/consultation_service.dart';
import '../../services/auth_service.dart';
import '../../services/partner_service.dart';
import 'partner_consultation_detail_screen.dart';

/// 파트너용 상담 관리 화면
/// 파트너가 받은 상담 목록을 확인하고 답변할 수 있는 화면
class PartnerConsultationsScreen extends StatefulWidget {
  const PartnerConsultationsScreen({super.key});

  @override
  State<PartnerConsultationsScreen> createState() => _PartnerConsultationsScreenState();
}

class _PartnerConsultationsScreenState extends State<PartnerConsultationsScreen> {
  final ConsultationService _consultationService = ConsultationService();
  final AuthService _authService = AuthService();
  final PartnerService _partnerService = PartnerService();

  List<ConsultationRecord> _consultations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _filterStatus = 'ALL'; // ALL, PENDING, ANSWERED

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _errorMessage = '로그인이 필요합니다.';
          _isLoading = false;
        });
        return;
      }

      // 파트너 정보 조회
      final partners = await _partnerService.getMyPartners(int.parse(currentUser.id));
      if (partners.isEmpty) {
        setState(() {
          _errorMessage = '파트너 프로필이 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final partnerId = partners.first.id;
      if (partnerId == null) {
        setState(() {
          _errorMessage = '파트너 ID를 찾을 수 없습니다.';
          _isLoading = false;
        });
        return;
      }

      final consultations = await _consultationService.getPartnerConsultations(partnerId);

      setState(() {
        _consultations = consultations;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 상담 목록 로딩 오류: $e');
      setState(() {
        _errorMessage = '상담 내역을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  List<ConsultationRecord> get _filteredConsultations {
    if (_filterStatus == 'ALL') {
      return _consultations;
    } else if (_filterStatus == 'PENDING') {
      return _consultations.where((c) => c.status == 'PENDING').toList();
    } else if (_filterStatus == 'ANSWERED') {
      return _consultations.where((c) => c.status == 'ANSWERED').toList();
    }
    return _consultations;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('상담 관리'),
        backgroundColor: const Color(0xFF4FC59E),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConsultations,
          ),
        ],
      ),
      body: Column(
        children: [
          // 필터 탭
          _buildFilterTabs(),

          // 상담 목록
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          _buildFilterChip('전체', 'ALL'),
          const SizedBox(width: 8),
          _buildFilterChip('답변 대기', 'PENDING'),
          const SizedBox(width: 8),
          _buildFilterChip('답변 완료', 'ANSWERED'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    final isSelected = _filterStatus == status;
    final count = status == 'ALL'
        ? _consultations.length
        : _consultations.where((c) => c.status == status).length;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _filterStatus = status;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4FC59E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF4FC59E) : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF4FC59E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4FC59E),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConsultations,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC59E),
                foregroundColor: Colors.white,
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_filteredConsultations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _filterStatus == 'PENDING'
                  ? '답변 대기 중인 상담이 없습니다'
                  : _filterStatus == 'ANSWERED'
                      ? '답변 완료한 상담이 없습니다'
                      : '상담 내역이 없습니다',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '고객이 상담을 요청하면 여기에 표시됩니다',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConsultations,
      color: const Color(0xFF4FC59E),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredConsultations.length,
        itemBuilder: (context, index) {
          final consultation = _filteredConsultations[index];
          return _buildConsultationCard(consultation);
        },
      ),
    );
  }

  Widget _buildConsultationCard(ConsultationRecord consultation) {
    final statusColor = _getStatusColor(consultation.status);
    final isPending = consultation.status == 'PENDING';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isPending ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPending ? const Color(0xFFFFA726).withOpacity(0.5) : Colors.transparent,
          width: isPending ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PartnerConsultationDetailScreen(
                consultation: consultation,
              ),
            ),
          );
          // 상세 페이지에서 답변 후 돌아오면 목록 새로고침
          if (result == true) {
            _loadConsultations();
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더: 사용자 이름 & 상태
              Row(
                children: [
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.notification_important,
                        color: Color(0xFFFFA726),
                        size: 20,
                      ),
                    ),
                  if (isPending) const SizedBox(width: 12),
                  Icon(
                    Icons.person,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      consultation.userName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isPending ? FontWeight.bold : FontWeight.w600,
                        color: const Color(0xFF003829),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      consultation.statusDescription,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 주제
              Text(
                consultation.subject,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // 내용 미리보기
              Text(
                consultation.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // 하단: 반려동물 종류 & 날짜
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F7F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.pets,
                          size: 14,
                          color: Color(0xFF4FC59E),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          consultation.petType,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF2B8C6C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('yyyy.MM.dd HH:mm').format(consultation.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const Spacer(),
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA726),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '답변 필요',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFA726);
      case 'ANSWERED':
        return const Color(0xFF4FC59E);
      case 'CLOSED':
        return const Color(0xFF78909C);
      case 'CANCELLED':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }
}
