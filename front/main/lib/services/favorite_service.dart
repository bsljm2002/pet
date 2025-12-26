import 'package:shared_preferences/shared_preferences.dart';

/// 즐겨찾기 관리 서비스
class FavoriteService {
  // userId별로 별도의 즐겨찾기 키 생성
  String _getVetFavoritesKey(String userId) => 'favorited_vets_$userId';
  String _getSitterFavoritesKey(String userId) => 'favorited_sitters_$userId';

  /// 수의사 즐겨찾기 목록 가져오기
  Future<Set<String>> getVetFavorites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getVetFavoritesKey(userId);
    final List<String>? favorites = prefs.getStringList(key);
    return favorites?.toSet() ?? {};
  }

  /// 펫시터 즐겨찾기 목록 가져오기
  Future<Set<String>> getSitterFavorites(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSitterFavoritesKey(userId);
    final List<String>? favorites = prefs.getStringList(key);
    return favorites?.toSet() ?? {};
  }

  /// 수의사 즐겨찾기 저장
  Future<void> saveVetFavorites(String userId, Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getVetFavoritesKey(userId);
    await prefs.setStringList(key, favorites.toList());
  }

  /// 펫시터 즐겨찾기 저장
  Future<void> saveSitterFavorites(String userId, Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getSitterFavoritesKey(userId);
    await prefs.setStringList(key, favorites.toList());
  }

  /// 수의사 즐겨찾기 추가
  Future<void> addVetFavorite(String userId, String vetId) async {
    final favorites = await getVetFavorites(userId);
    favorites.add(vetId);
    await saveVetFavorites(userId, favorites);
  }

  /// 수의사 즐겨찾기 제거
  Future<void> removeVetFavorite(String userId, String vetId) async {
    final favorites = await getVetFavorites(userId);
    favorites.remove(vetId);
    await saveVetFavorites(userId, favorites);
  }

  /// 펫시터 즐겨찾기 추가
  Future<void> addSitterFavorite(String userId, String sitterId) async {
    final favorites = await getSitterFavorites(userId);
    favorites.add(sitterId);
    await saveSitterFavorites(userId, favorites);
  }

  /// 펫시터 즐겨찾기 제거
  Future<void> removeSitterFavorite(String userId, String sitterId) async {
    final favorites = await getSitterFavorites(userId);
    favorites.remove(sitterId);
    await saveSitterFavorites(userId, favorites);
  }

  /// 수의사가 즐겨찾기되어 있는지 확인
  Future<bool> isVetFavorited(String userId, String vetId) async {
    final favorites = await getVetFavorites(userId);
    return favorites.contains(vetId);
  }

  /// 펫시터가 즐겨찾기되어 있는지 확인
  Future<bool> isSitterFavorited(String userId, String sitterId) async {
    final favorites = await getSitterFavorites(userId);
    return favorites.contains(sitterId);
  }
}
