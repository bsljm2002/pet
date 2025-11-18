// LLM 이모티콘 생성 페이지
// AI를 활용한 맞춤형 이모티콘 자동 생성 기능
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/llm_emoticon_provider.dart';
import '../services/image_save_service.dart';

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
  final TextEditingController _promptController = TextEditingController();
  String? _selectedEmotion; // 선택된 감정

  // 샘플 반려동물 목록 (나중에 실제 API로 대체)
  final List<Map<String, String>> _samplePets = [
    {'id': '1', 'name': '멍멍이', 'type': '강아지'},
    {'id': '2', 'name': '야옹이', 'type': '고양이'},
  ];

  // 감정 목록
  final List<Map<String, String>> _emotions = [
    {'label': '기쁨/웃음', 'emoji': '😄', 'value': 'joy'},
    {'label': '행복/미소', 'emoji': '😊', 'value': 'happy'},
    {'label': '사랑/하트', 'emoji': '😍', 'value': 'love'},
    {'label': '놀람', 'emoji': '😲', 'value': 'surprised'},
    {'label': '분노/화남', 'emoji': '😠', 'value': 'angry'},
    {'label': '당황', 'emoji': '😰', 'value': 'flustered'},
    {'label': '부끄러움', 'emoji': '😳', 'value': 'shy'},
    {'label': '졸림', 'emoji': '😴', 'value': 'sleepy'},
    {'label': '지루함', 'emoji': '😑', 'value': 'bored'},
    {'label': '까칠', 'emoji': '😒', 'value': 'grumpy'},
    {'label': '허세', 'emoji': '😎', 'value': 'cool'},
    {'label': '응원', 'emoji': '💪', 'value': 'cheering'},
    {'label': '감사', 'emoji': '🙏', 'value': 'thankful'},
    {'label': '의문/궁금', 'emoji': '🤔', 'value': 'curious'},
    {'label': '악동/장난기', 'emoji': '😜', 'value': 'playful'},
    {'label': '심쿵', 'emoji': '💓', 'value': 'excited'},
    {'label': '허걱/쇼크', 'emoji': '😱', 'value': 'shocked'},
    {'label': '좌절', 'emoji': '😞', 'value': 'disappointed'},
    {'label': '감탄/칭찬', 'emoji': '👏', 'value': 'impressed'},
    {'label': '감격/눈물', 'emoji': '😭', 'value': 'moved'},
    {'label': '무념/무표정', 'emoji': '😐', 'value': 'neutral'},
    {'label': '허탈', 'emoji': '😔', 'value': 'deflated'},
    {'label': '긴장', 'emoji': '😬', 'value': 'nervous'},
    {'label': '진심/진지', 'emoji': '🧐', 'value': 'serious'},
    {'label': '개그', 'emoji': '🤪', 'value': 'funny'},
    {'label': '부들부들', 'emoji': '😤', 'value': 'trembling'},
    {'label': '기대함/반짝반짝', 'emoji': '✨', 'value': 'anticipating'},
    {'label': '최면/멍~', 'emoji': '😵', 'value': 'dazed'},
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

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

              // 감정 선택 섹션
              _buildEmotionSelector(),
              SizedBox(height: 30),

              // 프롬프트 입력 섹션
              _buildPromptSection(),
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
                    '동물 사진을 선택하고 원하는 스타일을 입력하면 AI가 동물 이모티콘을 만들어드려요!',
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

  /// 감정 선택 섹션
  Widget _buildEmotionSelector() {
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
              Text(
                '감정 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 0, 108, 82),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '필수',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 255, 243, 224),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Color.fromARGB(255, 255, 152, 0),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '이모티콘에 표현될 감정을 선택해주세요',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 77, 61, 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _emotions.map((emotion) {
              final isSelected = _selectedEmotion == emotion['value'];
              return GestureDetector(
                onTap: () {
                  // 이미 선택된 감정을 다시 클릭해도 선택 해제되지 않음 (1개 필수 선택)
                  setState(() {
                    _selectedEmotion = emotion['value'];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Color.fromARGB(255, 0, 108, 82)
                        : Color.fromARGB(255, 248, 250, 252),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Color.fromARGB(255, 0, 108, 82)
                          : Colors.grey[300]!,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emotion['emoji']!, style: TextStyle(fontSize: 16)),
                      SizedBox(width: 6),
                      Text(
                        emotion['label']!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Color.fromARGB(255, 0, 56, 41),
                        ),
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

  /// 프롬프트 입력 섹션
  Widget _buildPromptSection() {
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
              Text(
                '추가 설명',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 0, 56, 41),
                ),
              ),
              SizedBox(width: 8),
              Text(
                '(선택)',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 232, 245, 233),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Color.fromARGB(255, 0, 108, 82),
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '예: "풍선을 들고 있는", "선글라스를 쓴", "꽃을 물고 있는"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 1, 87, 55),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          TextField(
            controller: _promptController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText:
                  '감정 외 추가로 표현하고 싶은 요소를 입력하세요...\n예: 풍선 들고, 선글라스 착용, 꽃 물고 등',
              suffixText: '(선택사항)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Color.fromARGB(255, 0, 108, 82),
                  width: 2,
                ),
              ),
              filled: true,
              fillColor: Color.fromARGB(255, 248, 250, 252),
              contentPadding: EdgeInsets.all(16),
            ),
            style: TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 0, 56, 41),
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
    final canGenerate =
        _selectedImage != null &&
        _selectedPetId != null &&
        _selectedEmotion != null;

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
                    _selectedEmotion = null;
                    _promptController.clear();
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

      // 선택된 펫 정보 가져오기
      final selectedPet = _samplePets.firstWhere(
        (pet) => pet['id'] == _selectedPetId,
      );

      // 선택된 감정 정보 가져오기
      final selectedEmotion = _emotions.firstWhere(
        (emotion) => emotion['value'] == _selectedEmotion,
      );

      // 프롬프트 메타데이터 구성
      final promptMeta = {
        'petName': selectedPet['name'],
        'petType': selectedPet['type'],
        'emotion': _selectedEmotion,
        'emotionLabel': selectedEmotion['label'],
        'customPrompt': _promptController.text.trim(),
      };

      final result = await provider.createEmoticon(
        userId: userId,
        petId: int.parse(_selectedPetId!),
        imageFile: _selectedImage!,
        promptMeta: promptMeta,
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
      // Show loading indicator
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이미지 저장 중...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Save image to gallery
      final success = await ImageSaveService().saveImageFromUrl(
        imageUrl: _generatedImageUrl!,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('갤러리에 저장되었습니다!'),
              ],
            ),
            backgroundColor: Color.fromARGB(255, 0, 108, 82),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        // 저장 후 초기화
        setState(() {
          _generatedImageUrl = null;
          _selectedImage = null;
          _selectedPetId = null;
          _selectedEmotion = null;
          _promptController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('저장에 실패했습니다. 권한을 확인해주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류가 발생했습니다: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
