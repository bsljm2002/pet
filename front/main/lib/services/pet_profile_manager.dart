// 펫 프로필 관리 서비스
// 간단한 메모리 기반 프로필 저장소 (추후 데이터베이스로 교체 가능)
import '../models/pet_profile.dart';

class PetProfileManager {
  // 싱글톤 패턴
  static final PetProfileManager _instance = PetProfileManager._internal();
  factory PetProfileManager() => _instance;
  PetProfileManager._internal();

  // 펫 프로필 목록
  final List<PetProfile> _profiles = [];

  // 모든 프로필 가져오기
  List<PetProfile> getAllProfiles() {
    return List.unmodifiable(_profiles);
  }

  // 프로필 추가
  void addProfile(PetProfile profile) {
    _profiles.add(profile);
  }

  // 프로필 업데이트
  void updateProfile(String id, PetProfile updatedProfile) {
    final index = _profiles.indexWhere((p) => p.id == id);
    if (index != -1) {
      _profiles[index] = updatedProfile;
    }
  }

  // 프로필 삭제
  void deleteProfile(String id) {
    _profiles.removeWhere((p) => p.id == id);
  }

  // ID로 프로필 찾기
  PetProfile? getProfileById(String id) {
    try {
      return _profiles.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }
}
