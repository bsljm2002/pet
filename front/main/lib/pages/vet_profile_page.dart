import 'package:flutter/material.dart';

import '../models/vet_model.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../widgets/vet_map_widget.dart';
import 'reservation_request_page.dart';
import 'simple_consultation_page.dart';
import 'consultation_request_page.dart';

/// 수의사 프로필 상세 페이지
/// 병원과 의료진 정보를 요약해서 보여주고 예약/상담 액션으로 연결한다.
class VetProfilePage extends StatefulWidget {
  final VetModel vet;

  const VetProfilePage({super.key, required this.vet});

  @override
  State<VetProfilePage> createState() => _VetProfilePageState();
}

class _VetProfilePageState extends State<VetProfilePage> {
  final ReviewService _reviewService = ReviewService();
  List<ReviewModel> _reviews = [];
  bool _isLoadingReviews = true;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final partnerId = int.parse(widget.vet.id);
      print(
        '📋 리뷰 로딩 시작 - Partner ID: $partnerId, Partner Name: ${widget.vet.name}',
      );

      final reviews = await _reviewService.getReviewsByPartnerId(partnerId);

      print('📋 리뷰 로딩 완료 - 리뷰 개수: ${reviews.length}');

      setState(() {
        _reviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      print('❌ 리뷰 로딩 오류: $e');
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  /// 영문 요일을 한글로 변환
  String _getDayKorean(String day) {
    switch (day.toUpperCase()) {
      case 'MONDAY':
        return '월';
      case 'TUESDAY':
        return '화';
      case 'WEDNESDAY':
        return '수';
      case 'THURSDAY':
        return '목';
      case 'FRIDAY':
        return '금';
      case 'SATURDAY':
        return '토';
      case 'SUNDAY':
        return '일';
      default:
        return day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 1,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 248, 246, 240),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          foregroundColor: const Color.fromARGB(255, 0, 108, 82),
        ),
        body: Column(
          children: [
            // 탭바 (고정)
            Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: const TabBar(
                labelColor: Color.fromARGB(255, 0, 108, 82),
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color.fromARGB(255, 0, 108, 82),
                tabs: [Tab(text: '수의사 프로필')],
              ),
            ),
            // 탭 컨텐츠 (스크롤 가능)
            Expanded(
              child: TabBarView(
                children: [
                  // 수의사 프로필 탭
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 프로필 헤더
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F7F1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                offset: const Offset(0, 2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white,
                                backgroundImage: widget.vet.imageUrl.isNotEmpty
                                    ? NetworkImage(widget.vet.imageUrl)
                                    : null,
                                child: widget.vet.imageUrl.isEmpty
                                    ? const Icon(
                                        Icons.local_hospital,
                                        size: 60,
                                        color: Color(0xFF4FC59E),
                                      )
                                    : null,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.vet.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003829),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.vet.doctorName ?? '담당 수의사',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4FC59E),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.vet.rating}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF4FC59E),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.vet.distance}km',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              if (widget.vet.experience.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.work,
                                      color: Color(0xFF4FC59E),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.vet.experience,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.vet.isOpen
                                      ? const Color(0xFF4FC59E)
                                      : Colors.redAccent,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.vet.isOpen ? '현재 영업중' : '현재 휴무',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 소개
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '소개',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003829),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                                child: Text(
                                  widget.vet.description.trim().isEmpty
                                      ? '소개 정보가 등록되지 않았습니다.'
                                      : widget.vet.description.trim(),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // 학력 사항
                        if (widget.vet.education.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '학력 사항',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...widget.vet.education.map((edu) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.school,
                                          color: Color(0xFF4FC59E),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            edu,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // 전문 진료
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '전문 진료',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003829),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: widget.vet.specialties.map((
                                  specialty,
                                ) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4FC59E,
                                      ).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF4FC59E,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      specialty,
                                      style: const TextStyle(
                                        color: Color(0xFF003829),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 자격증 및 인증
                        if (widget.vet.certifications.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '자격증 및 인증',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ...widget.vet.certifications.map((cert) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.verified,
                                          color: Color(0xFF4FC59E),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            cert,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // 연락처 정보
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '연락처 정보',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003829),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.phone,
                                    color: Color(0xFF4FC59E),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    widget.vet.phone,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.place,
                                    color: Color(0xFF4FC59E),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      widget.vet.address,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 영업 시간
                        if (widget.vet.workingStartHours != null &&
                            widget.vet.workingEndHours != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '영업 시간',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F7F1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(
                                        0xFF4FC59E,
                                      ).withOpacity(0.3),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // 근무 요일
                                      if (widget
                                          .vet
                                          .workingDays
                                          .isNotEmpty) ...[
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              color: Color(0xFF4FC59E),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    '근무 요일',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Color(0xFF003829),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Wrap(
                                                    spacing: 6,
                                                    runSpacing: 6,
                                                    children: widget.vet.workingDays.map((
                                                      day,
                                                    ) {
                                                      String dayKorean =
                                                          _getDayKorean(day);
                                                      return Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 10,
                                                              vertical: 4,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: const Color(
                                                            0xFF4FC59E,
                                                          ).withOpacity(0.2),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          dayKorean,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 13,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Color(
                                                                  0xFF003829,
                                                                ),
                                                              ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                      // 근무 시간
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.access_time,
                                            color: Color(0xFF4FC59E),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  '근무 시간',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF003829),
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${widget.vet.workingStartHours} ~ ${widget.vet.workingEndHours}',
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4FC59E),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // 예약 가능 시간 (기존 availableTimes가 있을 경우에만 표시)
                        if (widget.vet.availableTimes.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '예약 가능 시간',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF003829),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: widget.vet.availableTimes.map((
                                    time,
                                  ) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: const Color(0xFF4FC59E),
                                        ),
                                      ),
                                      child: Text(
                                        time,
                                        style: const TextStyle(
                                          color: Color(0xFF4FC59E),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // 지도 섹션
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '위치',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF003829),
                                ),
                              ),
                              const SizedBox(height: 12),
                              VetMapWidget(vet: widget.vet),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 리뷰 미리보기 섹션
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '리뷰',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF003829),
                                    ),
                                  ),
                                  if (_reviews.isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        // TODO: 리뷰 전체보기 페이지로 이동
                                      },
                                      child: const Text('전체보기'),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _isLoadingReviews
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : _reviews.isEmpty
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: const Column(
                                        children: [
                                          Icon(
                                            Icons.rate_review_outlined,
                                            size: 48,
                                            color: Colors.grey,
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            '아직 작성된 리뷰가 없습니다',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      children: _reviews.take(3).map((review) {
                                        return Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey.shade300,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 16,
                                                    backgroundColor:
                                                        const Color(0xFF4FC59E),
                                                    child: Text(
                                                      review.userName[0],
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          review.userName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                        Text(
                                                          review.relativeDate,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey
                                                                .shade600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                        Icons.star,
                                                        color: Colors.amber,
                                                        size: 16,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        '${review.rating}',
                                                        style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              if (review.content != null &&
                                                  review
                                                      .content!
                                                      .isNotEmpty) ...[
                                                const SizedBox(height: 12),
                                                Text(
                                                  review.content!,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 3,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 버튼 영역
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: widget.vet.isOpen
                                      ? () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ReservationRequestPage(
                                                    vet: widget.vet,
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4FC59E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.calendar_month),
                                  label: const Text('예약하기'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SimpleConsultationPage(
                                          partner: widget.vet,
                                        ),
                                      ),
                                    );
                                  },
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4FC59E),
                                    side: const BorderSide(
                                      color: Color(0xFF4FC59E),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('간편 상담'),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
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
