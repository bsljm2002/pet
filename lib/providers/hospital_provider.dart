import 'package:flutter/material.dart';
import '../models/vet_model.dart';
import '../models/reservation_model.dart';
import '../services/api_service.dart';

/// 동물병원 관련 데이터를 관리하는 Provider 클래스
///
/// 수의사 목록, 예약 목록, 필터링 등의 상태를 관리합니다.
/// ChangeNotifier를 상속받아 상태 변경 시 UI에 알림을 전달합니다.
class HospitalProvider with ChangeNotifier {
  // 수의사 목록 관련
  List<VetModel> _vets = [];
  bool _isLoadingVets = false;
  String? _vetsError;

  // 예약 목록 관련
  List<ReservationModel> _reservations = [];
  bool _isLoadingReservations = false;
  String? _reservationsError;

  // 필터 관련
  String? _selectedPetType;
  String? _selectedSpecialty;
  String? _selectedTimeSlot;

  // Getters
  List<VetModel> get vets => _vets;
  bool get isLoadingVets => _isLoadingVets;
  String? get vetsError => _vetsError;

  List<ReservationModel> get reservations => _reservations;
  bool get isLoadingReservations => _isLoadingReservations;
  String? get reservationsError => _reservationsError;

  String? get selectedPetType => _selectedPetType;
  String? get selectedSpecialty => _selectedSpecialty;
  String? get selectedTimeSlot => _selectedTimeSlot;

  /// 페이지네이션: 현재 페이지에 맞는 데이터를 계산하여 설정
  // void _updatePageData() {
  //   final startIndex = _currentPage * _itemsPerPage;
  //   final endIndex = (startIndex + _itemsPerPage).clamp(0, _allVets.length);

  //   _vets = _allVets.sublist(startIndex, endIndex);
  //   _hasNextPage = endIndex < _allVets.length;
  //   _hasPreviousPage = _currentPage > 0;

  //   notifyListeners();
  // }

  // /// 다음 페이지로 이동
  // ///
  // /// 다음 페이지가 있을 때만 페이지를 증가시키고 데이터를 업데이트합니다.
  // void nextPage() {
  //   if (_hasNextPage) {
  //     _currentPage++;
  //     _updatePageData();
  //   }
  // }

  // /// 이전 페이지로 이동
  // ///
  // /// 이전 페이지가 있을 때만 페이지를 감소시키고 데이터를 업데이트합니다.
  // void previousPage() {
  //   if (_hasPreviousPage) {
  //     _currentPage--;
  //     _updatePageData();
  //   }
  // }

  // /// 특정 페이지로 이동
  // ///
  // /// Parameters:
  // ///   [page] - 이동할 페이지 번호 (0부터 시작)
  // void goToPage(int page) {
  //   if (page >= 0 && page < totalPages) {
  //     _currentPage = page;
  //     _updatePageData();
  //   }
  // }

  // /// 첫 번째 페이지로 이동
  // void goToFirstPage() {
  //   _currentPage = 0;
  //   _updatePageData();
  // }

  // 필터 설정
  void setPetType(String? petType) {
    _selectedPetType = petType;
    notifyListeners();
    loadVets(); // 필터 변경 시 자동으로 수의사 목록 재로드
  }

  void setSpecialty(String? specialty) {
    _selectedSpecialty = specialty;
    notifyListeners();
    loadVets();
  }

  void setTimeSlot(String? timeSlot) {
    _selectedTimeSlot = timeSlot;
    notifyListeners();
    loadVets();
  }

  /// 수의사 목록 로드
  ///
  /// API에서 수의사 목록을 가져와서 필터링 조건에 맞게 표시합니다.
  Future<void> loadVets() async {
    _isLoadingVets = true;
    _vetsError = null;
    notifyListeners();

    try {
      _vets = await ApiService.getVets(
        petType: _selectedPetType,
        specialty: _selectedSpecialty,
        timeSlot: _selectedTimeSlot,
      );
    } catch (e) {
      _vetsError = e.toString();
      _vets = [];
    } finally {
      _isLoadingVets = false;
      notifyListeners();
    }
  }

  // 예약 목록 로드
  Future<void> loadReservations() async {
    _isLoadingReservations = true;
    _reservationsError = null;
    notifyListeners();

    try {
      _reservations = await ApiService.getMyReservations();
    } catch (e) {
      _reservationsError = e.toString();
    } finally {
      _isLoadingReservations = false;
      notifyListeners();
    }
  }

  // 예약 생성
  Future<bool> createReservation(ReservationModel reservation) async {
    try {
      bool success = await ApiService.createReservation(reservation);
      if (success) {
        // 예약 성공 시 목록 새로고침
        await loadReservations();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  // 필터 초기화
  void clearFilters() {
    _selectedPetType = null;
    _selectedSpecialty = null;
    _selectedTimeSlot = null;
    notifyListeners();
    loadVets();
  }
}
