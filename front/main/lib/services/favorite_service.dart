import 'package:shared_preferences/shared_preferences.dart';

/// 즐겨찾기 관리 서비스
class FavoriteService {
  static const String _vetFavoritesKey = 'favorited_vets';
  static const String _sitterFavoritesKey = 'favorited_sitters';

  /// 수의사 즐겨찾기 목록 가져오기
  Future<Set<String>> getVetFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_vetFavoritesKey);
    return favorites?.toSet() ?? {};
  }

  /// 펫시터 즐겨찾기 목록 가져오기
  Future<Set<String>> getSitterFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? favorites = prefs.getStringList(_sitterFavoritesKey);
    return favorites?.toSet() ?? {};
  }

  /// 수의사 즐겨찾기 저장
  Future<void> saveVetFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_vetFavoritesKey, favorites.toList());
  }

  /// 펫시터 즐겨찾기 저장
  Future<void> saveSitterFavorites(Set<String> favorites) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_sitterFavoritesKey, favorites.toList());
  }

  /// 수의사 즐겨찾기 추가
  Future<void> addVetFavorite(String vetId) async {
    final favorites = await getVetFavorites();
    favorites.add(vetId);
    await saveVetFavorites(favorites);
  }

  /// 수의사 즐겨찾기 제거
  Future<void> removeVetFavorite(String vetId) async {
    final favorites = await getVetFavorites();
    favorites.remove(vetId);
    await saveVetFavorites(favorites);
  }

  /// 펫시터 즐겨찾기 추가
  Future<void> addSitterFavorite(String sitterId) async {
    final favorites = await getSitterFavorites();
    favorites.add(sitterId);
    await saveSitterFavorites(favorites);
  }

  /// 펫시터 즐겨찾기 제거
  Future<void> removeSitterFavorite(String sitterId) async {
    final favorites = await getSitterFavorites();
    favorites.remove(sitterId);
    await saveSitterFavorites(favorites);
  }

  /// 수의사가 즐겨찾기되어 있는지 확인
  Future<bool> isVetFavorited(String vetId) async {
    final favorites = await getVetFavorites();
    return favorites.contains(vetId);
  }

  /// 펫시터가 즐겨찾기되어 있는지 확인
  Future<bool> isSitterFavorited(String sitterId) async {
    final favorites = await getSitterFavorites();
    return favorites.contains(sitterId);
  }
}
