import 'package:flutter/material.dart';

/// 커뮤니티 화면
/// 반려동물 관련 게시글, 정보 공유 커뮤니티
class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티'),
        backgroundColor: const Color.fromARGB(255, 0, 108, 82),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 섹션
              _buildHeaderSection(),
              const SizedBox(height: 24),

              // 카테고리 탭
              _buildCategoryTabs(),
              const SizedBox(height: 24),

              // 인기 게시글
              _buildPopularPosts(),
              const SizedBox(height: 24),

              // 최근 게시글
              _buildRecentPosts(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 게시글 작성 페이지로 이동
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('게시글 작성 기능 준비 중입니다')));
        },
        backgroundColor: const Color.fromARGB(255, 0, 108, 82),
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 0, 108, 82),
            Color.fromARGB(255, 0, 150, 115),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.forum, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '반려동물 커뮤니티',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '경험과 정보를 공유해보세요',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['전체', '일상', '질문', '정보', '자랑', '병원후기'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: index == 0,
              onSelected: (selected) {
                // 카테고리 필터링 로직
              },
              selectedColor: const Color.fromARGB(255, 212, 244, 228),
              labelStyle: TextStyle(
                color: index == 0
                    ? const Color.fromARGB(255, 0, 108, 82)
                    : Colors.grey[700],
                fontWeight: index == 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPopularPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 인기 게시글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          title: '우리 강아지 처음으로 미용했어요!',
          author: '멍멍맘',
          category: '자랑',
          likes: 245,
          comments: 32,
          time: '2시간 전',
        ),
        _buildPostCard(
          title: '고양이 사료 추천 부탁드려요',
          author: '냥냥파파',
          category: '질문',
          likes: 189,
          comments: 47,
          time: '5시간 전',
        ),
      ],
    );
  }

  Widget _buildRecentPosts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📝 최근 게시글',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
        ),
        const SizedBox(height: 12),
        _buildPostCard(
          title: '반려견 건강검진 주기는 얼마나 되나요?',
          author: '초보집사',
          category: '질문',
          likes: 12,
          comments: 8,
          time: '30분 전',
        ),
        _buildPostCard(
          title: '마포 24시 동물병원 후기 공유합니다',
          author: '쿠키맘',
          category: '병원후기',
          likes: 34,
          comments: 15,
          time: '1시간 전',
        ),
        _buildPostCard(
          title: '우리 고양이 오늘 생일이에요 🎂',
          author: '냥이러버',
          category: '일상',
          likes: 56,
          comments: 21,
          time: '3시간 전',
        ),
      ],
    );
  }

  Widget _buildPostCard({
    required String title,
    required String author,
    required String category,
    required int likes,
    required int comments,
    required String time,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // 게시글 상세 페이지로 이동
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$title 게시글 보기')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 212, 244, 228),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color.fromARGB(255, 0, 108, 82),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    time,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: Color.fromARGB(255, 212, 244, 228),
                    child: Icon(
                      Icons.person,
                      size: 14,
                      color: Color.fromARGB(255, 0, 108, 82),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    author,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$likes',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '$comments',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
