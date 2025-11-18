// 커뮤니티 화면 위젯
// 사용자들이 정보를 공유하고 소통하는 게시판 기능
import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../pages/write_post_page.dart';
import '../pages/my_posts_page.dart';

/// 커뮤니티 화면
/// 게시글 목록, 작성, 댓글 등의 커뮤니티 기능 제공
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final Set<String> _selectedTags = {}; // 선택된 태그들
  final List<String> _availableTags = [
    '자유게시판',
    '질문답변',
    '정보공유',
    '후기',
    '사료추천',
    '산책',
    '건강',
    '훈련',
    '입양',
  ];
  final List<Map<String, dynamic>> _myPosts = []; // 내가 작성한 게시글
  bool _showPageIndicator = false; // 페이지 인디케이터 표시 여부
  Timer? _hideTimer; // 자동 숨김 타이머

  @override
  void dispose() {
    _pageController.dispose();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 248, 250),
      body: Stack(
        children: [
          // 메인 콘텐츠 - 세로 스크롤 카드
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _showPageIndicator = true;
              });

              // 기존 타이머 취소
              _hideTimer?.cancel();

              // 1초 후 인디케이터 숨김
              _hideTimer = Timer(Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    _showPageIndicator = false;
                  });
                }
              });
            },
            itemCount: _getFilteredPosts().length,
            itemBuilder: (context, index) {
              final post = _getFilteredPosts()[index];
              return _buildFullScreenPostCard(post);
            },
          ),

          // 상단 헤더 (반투명)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.95),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    CustomAppBar(showBackButton: true),
                    _buildUserProfile(),
                    _buildTagFilter(),
                  ],
                ),
              ),
            ),
          ),

          // 내 게시글 플로팅 버튼
          Positioned(
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToMyPosts,
              backgroundColor: Colors.white,
              heroTag: 'my_posts',
              child: Icon(Icons.person, color: Color.fromARGB(255, 0, 108, 82)),
            ),
          ),

          // 글쓰기 플로팅 버튼
          Positioned(
            bottom: 50,
            right: 20,
            child: FloatingActionButton(
              onPressed: _goToWritePost,
              backgroundColor: Color.fromARGB(255, 0, 108, 82),
              heroTag: 'write',
              child: Icon(Icons.edit, color: Colors.white),
            ),
          ),

          // 페이지 인디케이터 (스크롤 시에만 표시)
          if (_showPageIndicator)
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _showPageIndicator ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 200),
                  child: _buildPageIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 샘플 게시글 데이터
  List<Map<String, dynamic>> _getSamplePosts() {
    return [
      {
        'tags': ['자유게시판', '산책'],
        'title': '우리 강아지 산책 코스 추천해주세요!',
        'content': '집 근처에 좋은 산책 코스를 찾고 있어요. 강아지가 좋아할 만한 곳 추천 부탁드립니다.',
        'author': '댕댕이사랑',
        'date': '2024.01.15',
        'views': 152,
        'comments': 23,
        'likes': 45,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.park,
      },
      {
        'tags': ['질문답변', '사료추천'],
        'title': '고양이 사료 추천 부탁드립니다',
        'content': '1살 된 고양이 키우는데 어떤 사료가 좋을까요? 경험 있으신 분들 조언 부탁드려요.',
        'author': '냥이집사',
        'date': '2024.01.15',
        'views': 89,
        'comments': 15,
        'likes': 12,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.pets,
      },
      {
        'tags': ['정보공유', '건강'],
        'title': '반려동물 건강검진 꿀팁',
        'content': '정기적인 건강검진이 중요해요. 제가 알고 있는 팁들을 공유합니다.',
        'author': '펫전문가',
        'date': '2024.01.14',
        'views': 234,
        'comments': 34,
        'likes': 78,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.medical_services,
      },
      {
        'tags': ['후기'],
        'title': '동물병원 다녀온 후기',
        'content': '강남에 있는 동물병원 다녀왔는데 정말 친절하고 좋았어요!',
        'author': '귀요미맘',
        'date': '2024.01.14',
        'views': 345,
        'comments': 56,
        'likes': 123,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.local_hospital,
      },
      {
        'tags': ['자유게시판'],
        'title': '오늘 우리 강아지 생일이에요 🎂',
        'content': '3살이 되었어요. 모두 축하해주세요!',
        'author': '행복한집사',
        'date': '2024.01.13',
        'views': 567,
        'comments': 89,
        'likes': 234,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.cake,
      },
      {
        'tags': ['훈련', '정보공유'],
        'title': '강아지 기본 훈련법',
        'content': '앉아, 기다려 등 기본 훈련 방법을 공유합니다.',
        'author': '훈련사',
        'date': '2024.01.13',
        'views': 423,
        'comments': 67,
        'likes': 189,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.school,
      },
      {
        'tags': ['입양', '자유게시판'],
        'title': '입양 6개월 후기',
        'content': '유기견 입양한지 6개월 되었어요. 정말 행복합니다!',
        'author': '사랑둥이',
        'date': '2024.01.12',
        'views': 678,
        'comments': 112,
        'likes': 345,
        'isLiked': false,
        'hasImage': true,
        'imageIcon': Icons.favorite,
      },
    ];
  }

  /// 필터링된 게시글 가져오기
  List<Map<String, dynamic>> _getFilteredPosts() {
    final allPosts = [..._getSamplePosts(), ..._myPosts];

    if (_selectedTags.isEmpty) {
      return allPosts;
    } else {
      return allPosts.where((post) {
        final postTags = post['tags'] as List<String>;
        return postTags.any((tag) => _selectedTags.contains(tag));
      }).toList();
    }
  }

  /// 게시글 작성 페이지로 이동
  void _goToWritePost() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => WritePostPage()),
    );

    if (!mounted) return;

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _myPosts.insert(0, result);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('게시글이 작성되었습니다!'),
          backgroundColor: Color.fromARGB(255, 0, 108, 82),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// 내 게시글 페이지로 이동
  void _goToMyPosts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyPostsPage(myPosts: _myPosts)),
    );
  }

  /// 팔로우한 친구 목록 섹션
  Widget _buildUserProfile() {
    // 샘플 친구 데이터
    final friends = [
      {'name': '댕댕이사랑', 'color': Color.fromARGB(255, 0, 108, 82)},
      {'name': '냥이집사', 'color': Color.fromARGB(255, 255, 152, 0)},
      {'name': '펫전문가', 'color': Color.fromARGB(255, 33, 150, 243)},
      {'name': '귀요미맘', 'color': Color.fromARGB(255, 233, 30, 99)},
      {'name': '행복한집사', 'color': Color.fromARGB(255, 156, 39, 176)},
    ];

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: friends.length,
        itemBuilder: (context, index) {
          final friend = friends[index];
          return GestureDetector(
            onTap: () {
              // 친구 프로필로 이동
            },
            child: Container(
              margin: EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          friend['color'] as Color,
                          (friend['color'] as Color).withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(Icons.person, color: Colors.white, size: 28),
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

  /// 태그 필터
  Widget _buildTagFilter() {
    return Container(
      height: 50,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Color.fromARGB(255, 0, 108, 82),
            size: 20,
          ),
          SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableTags.length,
              itemBuilder: (context, index) {
                final tag = _availableTags[index];
                final isSelected = _selectedTags.contains(tag);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Color.fromARGB(255, 0, 108, 82)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Color.fromARGB(255, 0, 108, 82)
                            : Colors.grey[300]!,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedTags.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _selectedTags.clear();
                });
              },
            ),
        ],
      ),
    );
  }

  /// 풀스크린 게시글 카드 (인스타/쇼츠 스타일)
  Widget _buildFullScreenPostCard(Map<String, dynamic> post) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지 (제목~내용 영역)
          if (post['hasImage'] == true)
            Positioned(
              top: 210,
              left: 0,
              right: 0,
              bottom: 190,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 212, 244, 228),
                      Color.fromARGB(255, 212, 244, 228),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    post['imageIcon'] as IconData,
                    size: 200,
                    color: Color.fromARGB(
                      255,
                      0,
                      108,
                      82,
                    ).withValues(alpha: 0.2),
                  ),
                ),
              ),
            )
          else
            Positioned(
              top: 200,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromARGB(255, 245, 248, 250),
                      Color.fromARGB(255, 212, 244, 228),
                    ],
                  ),
                ),
              ),
            ),

          // 상단 그라데이션 오버레이
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 하단 그라데이션 오버레이
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 400,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 제목 오버레이 (상단)
          Positioned(
            top: -20,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.only(top: 200),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 (반투명 배경)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        post['title'] as String,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 56, 41),
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 하단 작성자 정보 및 액션 (화면 하단 고정)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 0,
                  right: 0,
                  bottom: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 내용 (반투명 배경)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        post['content'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          color: Color.fromARGB(255, 0, 56, 41),
                          height: 1.6,
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 작성자 정보
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: Color.fromARGB(255, 0, 108, 82),
                                  size: 26,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post['author'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      post['date'] as String,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            blurRadius: 4,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          // 태그들
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (post['tags'] as List<String>).map((tag) {
                              return Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(
                                    255,
                                    0,
                                    108,
                                    82,
                                  ).withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  '#$tag',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 16),
                          // 액션 버튼들 (가로 배치)
                          Row(
                            children: [
                              _buildActionButtonOverlay(
                                Icons.favorite,
                                post['likes'] as int,
                                post['isLiked'] as bool,
                              ),
                              SizedBox(width: 24),
                              _buildActionButtonOverlay(
                                Icons.comment,
                                post['comments'] as int,
                                false,
                              ),
                              SizedBox(width: 24),
                              _buildActionButtonOverlay(
                                Icons.share,
                                0,
                                false,
                                showCount: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 오버레이용 액션 버튼 (흰색, 그림자 포함)
  Widget _buildActionButtonOverlay(
    IconData icon,
    int count,
    bool isActive, {
    bool showCount = true,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.red : Colors.white,
            size: 28,
          ),
        ),
        if (showCount) ...[
          SizedBox(width: 6),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 페이지 인디케이터
  Widget _buildPageIndicator() {
    final totalPages = _getFilteredPosts().length;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalPages > 5 ? 5 : totalPages, (index) {
          int displayIndex;
          if (totalPages <= 5) {
            displayIndex = index;
          } else if (_currentPage < 2) {
            displayIndex = index;
          } else if (_currentPage > totalPages - 3) {
            displayIndex = totalPages - 5 + index;
          } else {
            displayIndex = _currentPage - 2 + index;
          }

          return Container(
            width: 6,
            height: displayIndex == _currentPage ? 24 : 6,
            margin: EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: displayIndex == _currentPage
                  ? Color.fromARGB(255, 0, 108, 82)
                  : Colors.grey[400],
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
      ),
    );
  }
}
