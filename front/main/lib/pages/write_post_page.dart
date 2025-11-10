import 'package:flutter/material.dart';

/// 게시글 작성 페이지
class WritePostPage extends StatefulWidget {
  const WritePostPage({super.key});

  @override
  State<WritePostPage> createState() => _WritePostPageState();
}

class _WritePostPageState extends State<WritePostPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final Set<String> _selectedTags = {};
  final List<String> _availableTags = [
    '자유게시판',
    '질문답변',
    '정보공유',
    '후기',
    '사료추천',
    '산책',
    '건강',
    '훈련',
    '입양'
  ];
  bool _hasImage = false;
  IconData _selectedIcon = Icons.pets;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 248, 250),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: Color.fromARGB(255, 0, 56, 41)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '글쓰기',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitPost,
            child: Text(
              '완료',
              style: TextStyle(
                color: Color.fromARGB(255, 0, 108, 82),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 태그 선택
              _buildTagSection(),
              SizedBox(height: 24),

              // 제목 입력
              _buildTitleInput(),
              SizedBox(height: 20),

              // 내용 입력
              _buildContentInput(),
              SizedBox(height: 20),

              // 이미지 추가 버튼
              _buildImageSection(),
              SizedBox(height: 20),

              // 미리보기 카드
              if (_titleController.text.isNotEmpty ||
                  _contentController.text.isNotEmpty)
                _buildPreviewCard(),
            ],
          ),
        ),
      ),
    );
  }

  /// 태그 선택 섹션
  Widget _buildTagSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.label, color: Color.fromARGB(255, 0, 108, 82), size: 20),
            SizedBox(width: 8),
            Text(
              '태그 선택',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
            ),
            SizedBox(width: 8),
            Text(
              '(최대 3개)',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedTags.remove(tag);
                  } else {
                    if (_selectedTags.length < 3) {
                      _selectedTags.add(tag);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('태그는 최대 3개까지 선택할 수 있습니다.'),
                          backgroundColor: Color.fromARGB(255, 0, 108, 82),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color.fromARGB(255, 0, 108, 82)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Color.fromARGB(255, 0, 108, 82)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Color.fromARGB(255, 0, 108, 82)
                                .withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 제목 입력
  Widget _buildTitleInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.title, color: Color.fromARGB(255, 0, 108, 82), size: 20),
            SizedBox(width: 8),
            Text(
              '제목',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
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
          child: TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: '제목을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  /// 내용 입력
  Widget _buildContentInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.article, color: Color.fromARGB(255, 0, 108, 82), size: 20),
            SizedBox(width: 8),
            Text(
              '내용',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
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
          child: TextField(
            controller: _contentController,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '내용을 입력하세요',
              hintStyle: TextStyle(color: Colors.grey[400]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 15,
              color: Color.fromARGB(255, 0, 56, 41),
              height: 1.6,
            ),
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  /// 이미지 섹션
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image, color: Color.fromARGB(255, 0, 108, 82), size: 20),
            SizedBox(width: 8),
            Text(
              '이미지',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            // 이미지 추가 버튼
            GestureDetector(
              onTap: () {
                setState(() {
                  _hasImage = !_hasImage;
                });
              },
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: _hasImage
                      ? Color.fromARGB(255, 0, 108, 82)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _hasImage
                        ? Color.fromARGB(255, 0, 108, 82)
                        : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Icon(
                  _hasImage ? Icons.check : Icons.add_photo_alternate,
                  color: _hasImage ? Colors.white : Colors.grey[400],
                  size: 40,
                ),
              ),
            ),
            if (_hasImage) ...[
              SizedBox(width: 12),
              // 아이콘 선택
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '아이콘 선택',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 0, 56, 41),
                        ),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Icons.pets,
                          Icons.park,
                          Icons.cake,
                          Icons.favorite,
                          Icons.medical_services,
                          Icons.school,
                        ].map((icon) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedIcon = icon;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _selectedIcon == icon
                                    ? Color.fromARGB(255, 212, 244, 228)
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                icon,
                                color: Color.fromARGB(255, 0, 108, 82),
                                size: 24,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// 미리보기 카드
  Widget _buildPreviewCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.preview, color: Color.fromARGB(255, 0, 108, 82), size: 20),
            SizedBox(width: 8),
            Text(
              '미리보기',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 56, 41),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color.fromARGB(255, 245, 248, 250),
                Color.fromARGB(255, 212, 244, 228),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이미지 미리보기
              if (_hasImage)
                Container(
                  width: double.infinity,
                  height: 150,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 212, 244, 228),
                        Color.fromARGB(255, 165, 230, 200),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      _selectedIcon,
                      size: 60,
                      color: Color.fromARGB(255, 0, 108, 82)
                          .withValues(alpha: 0.3),
                    ),
                  ),
                ),

              // 태그
              if (_selectedTags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _selectedTags.map((tag) {
                    return Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 0, 108, 82),
                        borderRadius: BorderRadius.circular(12),
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

              if (_selectedTags.isNotEmpty) SizedBox(height: 12),

              // 제목
              if (_titleController.text.isNotEmpty)
                Text(
                  _titleController.text,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 56, 41),
                  ),
                ),

              if (_titleController.text.isNotEmpty) SizedBox(height: 8),

              // 내용
              if (_contentController.text.isNotEmpty)
                Text(
                  _contentController.text,
                  style: TextStyle(
                    fontSize: 14,
                    color: Color.fromARGB(255, 0, 56, 41)
                        .withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 게시글 제출
  void _submitPost() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('제목을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('내용을 입력해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('태그를 최소 1개 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 게시글 데이터 생성
    final newPost = {
      'tags': _selectedTags.toList(),
      'title': _titleController.text,
      'content': _contentController.text,
      'author': '나',
      'date': DateTime.now().toString().substring(0, 10),
      'views': 0,
      'comments': 0,
      'likes': 0,
      'isLiked': false,
      'hasImage': _hasImage,
      'imageIcon': _selectedIcon,
    };

    // 게시글 반환하고 페이지 닫기
    Navigator.pop(context, newPost);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('게시글이 작성되었습니다.'),
        backgroundColor: Color.fromARGB(255, 0, 108, 82),
      ),
    );
  }
}
