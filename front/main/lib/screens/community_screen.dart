// 커뮤니티 화면 위젯
// 사용자들이 정보를 공유하고 소통하는 게시판 기능
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';

/// 커뮤니티 화면
/// 게시글 목록, 작성, 댓글 등의 커뮤니티 기능 제공
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _selectedCategory = '전체'; // 선택된 카테고리
  final List<String> _categories = ['전체', '자유게시판', '질문/답변', '정보공유', '후기'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(showBackButton: true),
      body: Column(
        children: [
          // 커뮤니티 헤더
          _buildCommunityHeader(),

          // 카테고리 탭
          _buildCategoryTabs(),

          // 게시글 목록
          Expanded(child: _buildPostList()),
        ],
      ),
      // 글쓰기 플로팅 버튼
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: 글쓰기 화면으로 이동
          _showWritePostDialog();
        },
        backgroundColor: Color.fromARGB(255, 0, 108, 82),
        icon: Icon(Icons.edit, color: Colors.white),
        label: Text(
          '글쓰기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// 커뮤니티 헤더
  Widget _buildCommunityHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 212, 244, 228),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.forum,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                '커뮤니티',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 108, 82),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '반려동물과 함께하는 이야기를 나눠보세요',
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
        ],
      ),
    );
  }

  /// 카테고리 탭
  Widget _buildCategoryTabs() {
    return Container(
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 4),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? Color.fromARGB(255, 0, 108, 82)
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
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
    );
  }

  /// 게시글 목록
  Widget _buildPostList() {
    // 샘플 게시글 데이터
    final samplePosts = [
      {
        'category': '자유게시판',
        'title': '우리 강아지 산책 코스 추천해주세요!',
        'author': '댕댕이사랑',
        'date': '2024.01.15',
        'views': 152,
        'comments': 23,
        'likes': 45,
      },
      {
        'category': '질문/답변',
        'title': '고양이 사료 추천 부탁드립니다',
        'author': '냥이집사',
        'date': '2024.01.15',
        'views': 89,
        'comments': 15,
        'likes': 12,
      },
      {
        'category': '정보공유',
        'title': '반려동물 건강검진 꿀팁 공유합니다',
        'author': '펫전문가',
        'date': '2024.01.14',
        'views': 234,
        'comments': 34,
        'likes': 78,
      },
      {
        'category': '후기',
        'title': '동물병원 다녀온 후기 (사진 多)',
        'author': '귀요미맘',
        'date': '2024.01.14',
        'views': 345,
        'comments': 56,
        'likes': 123,
      },
      {
        'category': '자유게시판',
        'title': '오늘 우리 강아지 생일이에요 🎂',
        'author': '행복한집사',
        'date': '2024.01.13',
        'views': 567,
        'comments': 89,
        'likes': 234,
      },
    ];

    return ListView.builder(
      padding: EdgeInsets.all(8),
      itemCount: samplePosts.length,
      itemBuilder: (context, index) {
        final post = samplePosts[index];
        return _buildPostCard(post);
      },
    );
  }

  /// 게시글 카드
  Widget _buildPostCard(Map<String, dynamic> post) {
    return GestureDetector(
      onTap: () {
        // TODO: 게시글 상세 화면으로 이동
        _showPostDetail(post);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 카테고리 태그
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 212, 244, 228),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                post['category'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Color.fromARGB(255, 0, 108, 82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 10),

            // 제목
            Text(
              post['title'] as String,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),

            // 작성자 및 정보
            Row(
              children: [
                // 작성자 아이콘
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  post['author'] as String,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                SizedBox(width: 12),
                Text(
                  post['date'] as String,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                Spacer(),

                // 조회수, 댓글, 좋아요
                _buildInfoBadge(Icons.visibility, post['views'] as int),
                SizedBox(width: 8),
                _buildInfoBadge(
                  Icons.comment,
                  post['comments'] as int,
                  color: Color.fromARGB(255, 0, 108, 82),
                ),
                SizedBox(width: 8),
                _buildInfoBadge(
                  Icons.favorite,
                  post['likes'] as int,
                  color: Colors.red[400]!,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 정보 뱃지 (조회수, 댓글, 좋아요)
  Widget _buildInfoBadge(IconData icon, int count, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color ?? Colors.grey[600]),
        SizedBox(width: 2),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 12,
            color: color ?? Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 글쓰기 다이얼로그
  void _showWritePostDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          '글쓰기',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('게시글 작성 기능은 준비 중입니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '확인',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 108, 82),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 게시글 상세 다이얼로그
  void _showPostDetail(Map<String, dynamic> post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 212, 244, 228),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                post['category'] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Color.fromARGB(255, 0, 108, 82),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                post['title'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    post['author'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 12),
                  Text(
                    post['date'] as String,
                    style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Text(
                '게시글 상세 내용이 여기에 표시됩니다.\n\n상세 화면은 추후 구현 예정입니다.',
                style: TextStyle(fontSize: 14, height: 1.6),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '닫기',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 108, 82),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
