import 'package:flutter/material.dart';

/// 내 게시글 페이지
class MyPostsPage extends StatefulWidget {
  final List<Map<String, dynamic>> myPosts;

  const MyPostsPage({super.key, required this.myPosts});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  String _sortBy = '최신순'; // 정렬 방식

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 248, 250),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 56, 41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '내 게시글',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.sort, color: Color.fromARGB(255, 0, 108, 82)),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '최신순',
                child: Text('최신순'),
              ),
              PopupMenuItem(
                value: '인기순',
                child: Text('인기순'),
              ),
              PopupMenuItem(
                value: '댓글많은순',
                child: Text('댓글많은순'),
              ),
            ],
          ),
        ],
      ),
      body: widget.myPosts.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: _getSortedPosts().length,
              itemBuilder: (context, index) {
                final post = _getSortedPosts()[index];
                return _buildPostCard(post, index);
              },
            ),
    );
  }

  /// 정렬된 게시글 가져오기
  List<Map<String, dynamic>> _getSortedPosts() {
    final posts = List<Map<String, dynamic>>.from(widget.myPosts);

    switch (_sortBy) {
      case '최신순':
        posts.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
        break;
      case '인기순':
        posts.sort((a, b) => (b['likes'] as int).compareTo(a['likes'] as int));
        break;
      case '댓글많은순':
        posts.sort(
            (a, b) => (b['comments'] as int).compareTo(a['comments'] as int));
        break;
    }

    return posts;
  }

  /// 빈 상태 위젯
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 212, 244, 228),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.article_outlined,
              size: 60,
              color: Color.fromARGB(255, 0, 108, 82),
            ),
          ),
          SizedBox(height: 24),
          Text(
            '작성한 게시글이 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 8),
          Text(
            '첫 게시글을 작성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 게시글 카드
  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 이미지 영역
          if (post['hasImage'] == true)
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.fromARGB(255, 212, 244, 228),
                    Color.fromARGB(255, 165, 230, 200),
                  ],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Icon(
                  post['imageIcon'] as IconData,
                  size: 80,
                  color: Color.fromARGB(255, 0, 108, 82).withValues(alpha: 0.3),
                ),
              ),
            ),

          // 게시글 정보
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 태그들
                if (post['tags'] != null && (post['tags'] as List).isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: (post['tags'] as List<String>).map((tag) {
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color.fromARGB(255, 212, 244, 228),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '#$tag',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color.fromARGB(255, 0, 108, 82),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (post['tags'] != null && (post['tags'] as List).isNotEmpty)
                  SizedBox(height: 12),

                // 제목
                Text(
                  post['title'] as String,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 56, 41),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 8),

                // 내용
                Text(
                  post['content'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 16),

                // 통계 및 날짜
                Row(
                  children: [
                    Icon(Icons.calendar_today,
                        size: 14, color: Colors.grey[500]),
                    SizedBox(width: 4),
                    Text(
                      post['date'] as String,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    Spacer(),
                    _buildStatBadge(Icons.visibility, post['views'] as int),
                    SizedBox(width: 12),
                    _buildStatBadge(Icons.comment, post['comments'] as int,
                        color: Color.fromARGB(255, 0, 108, 82)),
                    SizedBox(width: 12),
                    _buildStatBadge(Icons.favorite, post['likes'] as int,
                        color: Colors.red[400]),
                  ],
                ),
                SizedBox(height: 12),

                // 액션 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editPost(post, index),
                        icon: Icon(Icons.edit,
                            size: 18, color: Color.fromARGB(255, 0, 108, 82)),
                        label: Text(
                          '수정',
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 108, 82),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Color.fromARGB(255, 0, 108, 82),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _deletePost(index),
                        icon: Icon(Icons.delete, size: 18, color: Colors.red),
                        label: Text(
                          '삭제',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 통계 뱃지
  Widget _buildStatBadge(IconData icon, int count, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey[600]),
        SizedBox(width: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 13,
            color: color ?? Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// 게시글 수정
  void _editPost(Map<String, dynamic> post, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '게시글 수정',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('게시글 수정 기능은 준비 중입니다.'),
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

  /// 게시글 삭제
  void _deletePost(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '게시글 삭제',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text('정말 이 게시글을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '취소',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                widget.myPosts.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('게시글이 삭제되었습니다.'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: Text(
              '삭제',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
