// 즐겨찾기 페이지
// 사용자가 즐겨찾기한 수의사와 펫시터를 관리하는 페이지
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/favorite_service.dart';
import '../providers/hospital_provider.dart';
import '../models/vet_model.dart';
import '../models/sitter_model.dart';
import '../pages/vet_profile_page.dart';
import '../pages/sitter_profile_page.dart';

/// 즐겨찾기 페이지
/// 수의사/펫시터 탭으로 구분하여 즐겨찾기한 파트너를 표시
class MyFavoritesPage extends StatefulWidget {
  const MyFavoritesPage({Key? key}) : super(key: key);

  @override
  State<MyFavoritesPage> createState() => _MyFavoritesPageState();
}

class _MyFavoritesPageState extends State<MyFavoritesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FavoriteService _favoriteService = FavoriteService();
  Set<String> _favoritedVets = {};
  Set<String> _favoritedSitters = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  /// 즐겨찾기 목록 로드
  Future<void> _loadFavorites() async {
    final vets = await _favoriteService.getVetFavorites();
    final sitters = await _favoriteService.getSitterFavorites();
    setState(() {
      _favoritedVets = vets;
      _favoritedSitters = sitters;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 246, 240),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF3BA688)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '즐겨찾기',
          style: TextStyle(
            color: Color(0xFF3BA688),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF3BA688),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF3BA688),
          tabs: const [
            Tab(text: '수의사'),
            Tab(text: '펫시터'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 수의사 즐겨찾기 탭
          _buildFavoritesList(isVet: true),
          // 펫시터 즐겨찾기 탭
          _buildFavoritesList(isVet: false),
        ],
      ),
    );
  }

  /// 즐겨찾기 목록 빌더
  Widget _buildFavoritesList({required bool isVet}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        final favoriteIds = isVet ? _favoritedVets : _favoritedSitters;

        if (favoriteIds.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isVet
                      ? '즐겨찾기한 수의사가 없습니다'
                      : '즐겨찾기한 펫시터가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isVet
                      ? '수의사 프로필에서 하트를 눌러\n즐겨찾기에 추가하세요'
                      : '펫시터 프로필에서 하트를 눌러\n즐겨찾기에 추가하세요',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // 즐겨찾기된 수의사 또는 펫시터 필터링
        final favorites = isVet
            ? provider.vets.where((vet) => favoriteIds.contains(vet.id)).toList()
            : provider.sitters.where((sitter) => favoriteIds.contains(sitter.id)).toList();

        if (favorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '즐겨찾기한 항목을 불러올 수 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: favorites.length,
          itemBuilder: (context, index) {
            if (isVet) {
              final vet = favorites[index] as VetModel;
              return _buildVetCard(vet);
            } else {
              final sitter = favorites[index] as SitterModel;
              return _buildSitterCard(sitter);
            }
          },
        );
      },
    );
  }

  /// 수의사 카드
  Widget _buildVetCard(VetModel vet) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VetProfilePage(vet: vet),
          ),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFE6F7F1),
              backgroundImage: vet.imageUrl.isNotEmpty
                  ? NetworkImage(vet.imageUrl) as ImageProvider
                  : null,
              child: vet.imageUrl.isEmpty
                  ? const Icon(
                      Icons.local_hospital_outlined,
                      color: Color(0xFF4FC59E),
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vet.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vet.doctorName ?? '담당 수의사 미정',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4FC59E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vet.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 즐겨찾기 해제 버튼
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Color(0xFFFF6B9D),
              ),
              onPressed: () async {
                await _favoriteService.removeVetFavorite(vet.id);
                setState(() {
                  _favoritedVets.remove(vet.id);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('즐겨찾기에서 제거되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 펫시터 카드
  Widget _buildSitterCard(SitterModel sitter) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SitterProfilePage(sitter: sitter),
          ),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 프로필 이미지
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFFE6F7F1),
              backgroundImage: sitter.imageUrl.isNotEmpty
                  ? NetworkImage(sitter.imageUrl) as ImageProvider
                  : null,
              child: sitter.imageUrl.isEmpty
                  ? const Icon(
                      Icons.person_outline,
                      color: Color(0xFF4FC59E),
                      size: 30,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sitter.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sitter.sitterName} 펫시터',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF4FC59E),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sitter.address,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // 즐겨찾기 해제 버튼
            IconButton(
              icon: const Icon(
                Icons.favorite,
                color: Color(0xFFFF6B9D),
              ),
              onPressed: () async {
                await _favoriteService.removeSitterFavorite(sitter.id);
                setState(() {
                  _favoritedSitters.remove(sitter.id);
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('즐겨찾기에서 제거되었습니다'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
