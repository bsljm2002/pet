// LLM 이모티콘 생성 페이지
// AI를 활용한 맞춤형 이모티콘 자동 생성 기능
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/llm_emoticon_provider.dart';

/// LLM 이모티콘 생성 페이지
/// 반려동물 사진 업로드 및 AI 이모티콘 생성 기능 제공
class LlmEmoticonCreatePage extends StatefulWidget {
  const LlmEmoticonCreatePage({super.key});

  @override
  State<LlmEmoticonCreatePage> createState() => _LlmEmoticonCreatePageState();
}

class _LlmEmoticonCreatePageState extends State<LlmEmoticonCreatePage> {
  File? _selectedImage;
  String? _selectedPetId;
  String? _generatedImageUrl; // 생성된 이미지 URL
  final ImagePicker _picker = ImagePicker();

  // 샘플 반려동물 목록 (나중에 실제 API로 대체)
  final List<Map<String, String>> _samplePets = [
    {'id': '1', 'name': '멍멍이', 'type': '강아지'},
    {'id': '2', 'name': '야옹이', 'type': '고양이'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 245, 248, 250),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          '이모티콘 생성',
          style: TextStyle(
            color: Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color.fromARGB(255, 0, 56, 41)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타이틀 섹션
              _buildTitleSection(),
              SizedBox(height: 30),

              // 이미지 선택 섹션
              _buildImageSection(),
              SizedBox(height: 30),

              // 반려동물 선택 섹션
              _buildPetSelector(),
              SizedBox(height: 30),

              // 생성 버튼
              _buildGenerateButton(),
              SizedBox(height: 30),

              // 생성된 이미지 표시 섹션
              if (_generatedImageUrl != null) _buildGeneratedImageSection(),
              if (_generatedImageUrl != null) SizedBox(height: 30),

              // 진행 중인 이모티콘 섹션
              _buildInProgressSection(),
            ],
          ),
        ),
      ),
    );
  }

  /// 타이틀 섹션
  Widget _buildTitleSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 212, 244, 228),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Color.fromARGB(255, 0, 108, 82),
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI 이모티콘 생성',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 56, 41),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '우리 아이만의 특별한 이모티콘',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 243, 224),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Color.fromARGB(255, 255, 152, 0),
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '반려동물 사진을 선택하면 AI가 자동으로 귀여운 이모티콘을 만들어드려요!',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color.fromARGB(255, 77, 61, 0),
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

  /// 이미지 선택 섹션
  Widget _buildImageSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '사진 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 16),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 248, 250, 252),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.fromARGB(255, 0, 108, 82).withValues(alpha: 0.2),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 64,
                          color: Color.fromARGB(
                            255,
                            0,
                            108,
                            82,
                          ).withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '사진 선택하기',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(
                              255,
                              0,
                              108,
                              82,
                            ).withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '갤러리에서 반려동물 사진을 선택해주세요',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// 반려동물 선택 섹션
  Widget _buildPetSelector() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '반려동물 선택',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 56, 41),
            ),
          ),
          SizedBox(height: 16),
          // TODO: 실제 반려동물 목록 API 연동
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _samplePets.map((pet) {
              final isSelected = _selectedPetId == pet['id'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPetId = pet['id'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color.fromARGB(255, 0, 108, 82)
                        : Color.fromARGB(255, 248, 250, 252),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected
                          ? Color.fromARGB(255, 0, 108, 82)
                          : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets,
                        color: isSelected
                            ? Colors.white
                            : Color.fromARGB(255, 0, 108, 82),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pet['name']!,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : Color.fromARGB(255, 0, 56, 41),
                            ),
                          ),
                          Text(
                            pet['type']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// 생성 버튼
  Widget _buildGenerateButton() {
    final provider = Provider.of<LlmEmoticonProvider>(context);
    final canGenerate = _selectedImage != null && _selectedPetId != null;

    return Container(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canGenerate && !provider.isLoading
            ? _generateEmoticon
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromARGB(255, 0, 108, 82),
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: provider.isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '생성 중...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  SizedBox(width: 12),
                  Text(
                    '이모티콘 생성하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// 생성된 이미지 섹션
  Widget _buildGeneratedImageSection() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '생성 완료!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // 생성된 이미지
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.fromARGB(255, 0, 108, 82).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                _generatedImageUrl!,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                      color: Color.fromARGB(255, 0, 108, 82),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 8),
                        Text('이미지 로드 실패'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 20),

          // 저장 버튼
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveEmoticon,
                  icon: Icon(Icons.download, color: Colors.white),
                  label: Text(
                    '이모티콘 저장하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 0, 108, 82),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _generatedImageUrl = null;
                  });
                },
                icon: Icon(
                  Icons.refresh,
                  color: Color.fromARGB(255, 0, 108, 82),
                ),
                label: Text(
                  '새로 생성',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 108, 82),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Color.fromARGB(255, 0, 108, 82),
                      width: 2,
                    ),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 진행 중인 이모티콘 섹션
  Widget _buildInProgressSection() {
    final provider = Provider.of<LlmEmoticonProvider>(context);
    final inProgress = provider.inProgressEmoticons;

    if (inProgress.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hourglass_empty,
                color: Color.fromARGB(255, 0, 108, 82),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '생성 중인 이모티콘',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...inProgress.take(3).map((emoticon) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 248, 250, 252),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color.fromARGB(255, 0, 108, 82).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // 로딩 애니메이션
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 0, 108, 82),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${emoticon.id}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color.fromARGB(255, 0, 56, 41),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'AI가 열심히 만들고 있어요...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 이미지 선택
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  /// 이모티콘 생성
  Future<void> _generateEmoticon() async {
    if (_selectedImage == null || _selectedPetId == null) return;

    final provider = Provider.of<LlmEmoticonProvider>(context, listen: false);

    try {
      // TODO: 실제 사용자 ID 가져오기
      final userId = 1;

      final result = await provider.createEmoticon(
        userId: userId,
        petId: int.parse(_selectedPetId!),
        imageFile: _selectedImage!,
      );

      if (mounted) {
        // 생성된 이미지 URL 저장
        setState(() {
          _generatedImageUrl = result.generatedImageUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('이모티콘 생성 완료!'),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 0, 108, 82),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('생성 실패: $e')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  /// 이모티콘 저장
  Future<void> _saveEmoticon() async {
    if (_generatedImageUrl == null) return;

    try {
      // TODO: 실제 저장 로직 구현 (갤러리에 저장 등)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('이모티콘이 저장되었습니다!'),
            ],
          ),
          backgroundColor: Color.fromARGB(255, 0, 108, 82),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

      // 저장 후 초기화
      setState(() {
        _generatedImageUrl = null;
        _selectedImage = null;
        _selectedPetId = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('저장 실패: $e')),
            ],
          ),
          backgroundColor: Colors.red[600],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}
