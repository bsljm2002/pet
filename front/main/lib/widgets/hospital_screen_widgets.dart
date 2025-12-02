import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hospital_provider.dart';
import '../models/vet_model.dart';
import '../models/sitter_model.dart';
import '../pages/vet_profile_page.dart';
import '../pages/sitter_profile_page.dart';
import '../services/favorite_service.dart';

/// 동물병원 화면에서 사용되는 위젯들을 모아둔 클래스
///
/// 수의사 검색, 필터링, 목록 표시 등의 UI 컴포넌트를 제공합니다.
/// 모든 메소드는 static으로 선언되어 인스턴스 생성 없이 사용할 수 있습니다.
class HospitalScreenWidgets {
  /// 수의사 찾기 섹션 위젯
  ///
  /// 동물 유형 선택, 진료 과목, 시간대 필터와 검색 버튼을 포함한
  /// 완전한 검색 인터페이스를 제공합니다.
  static Widget buildVetFinderSection() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPetTypeToggle(provider),
              const SizedBox(height: 20),
              _buildSpecialtySelector(provider),
              const SizedBox(height: 20),
              _buildTimeSlotSelector(provider),
              const SizedBox(height: 16),
              // 수의사 검색 버튼
              ElevatedButton(
                onPressed: () => provider.loadVets(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC59E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: provider.isLoadingVets
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '수의사 찾기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 동물 유형 선택 토글 버튼들
  static Widget _buildPetTypeToggle(HospitalProvider provider) {
    final petTypes = [
      {'label': '강아지', 'icon': Icons.pets},
      {'label': '고양이', 'icon': Icons.pets_outlined},
      {'label': '기타', 'icon': Icons.more_horiz},
    ];

    return Row(
      children: petTypes.map((pet) {
        final type = pet['label'] as String;
        final icon = pet['icon'] as IconData;
        final isSelected = provider.selectedPetType == type;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF4FC59E) : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4FC59E)
                      : Colors.grey.withOpacity(0.4),
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF4FC59E).withOpacity(0.25),
                          offset: const Offset(0, 6),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => provider.setPetType(isSelected ? null : type),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF4FC59E),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          type,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF003829),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 진료 과목 선택 드롭다운
  static Widget _buildSpecialtySelector(HospitalProvider provider) {
    final dogSpecialties = [
      '피부질환',
      '소화기/내과',
      '근골격/정형외과',
      '치과',
      '심장/호흡기',
      '신경계',
      '예방의학',
    ];

    final catSpecialties = [
      '호흡기/상부감염',
      '소화기',
      '비뇨기계',
      '피부/털',
      '치과',
      '내분비/대사',
      '행동/정신',
    ];

    final defaultSpecialties = ['내과', '외과', '피부과', '치과', '안과', '정형외과'];

    List<String> specialties;
    switch (provider.selectedPetType) {
      case '강아지':
        specialties = dogSpecialties;
        break;
      case '고양이':
        specialties = catSpecialties;
        break;
      default:
        specialties = defaultSpecialties;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.medical_services_outlined,
              color: Color(0xFF4FC59E),
            ),
            const SizedBox(width: 6),
            Text(
              provider.selectedPetType == null
                  ? '진료 과목 선택'
                  : '${provider.selectedPetType} 진료 과목',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF003829),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => provider.setSpecialty(null),
              child: const Text('전체 해제'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: specialties.map((specialty) {
            final isSelected = provider.selectedSpecialty == specialty;
            return ChoiceChip(
              label: Text(
                specialty,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF003829),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF4FC59E),
              backgroundColor: Colors.grey.shade200,
              onSelected: (_) =>
                  provider.setSpecialty(isSelected ? null : specialty),
            );
          }).toList(),
        ),
      ],
    );
  }

  static Widget _buildTimeSlotSelector(HospitalProvider provider) {
    final timeSlots = [
      {'label': '아침 09:00', 'value': '09:00', 'icon': Icons.wb_sunny},
      {'label': '아침 10:30', 'value': '10:30', 'icon': Icons.brightness_5},
      {'label': '점심 12:00', 'value': '12:00', 'icon': Icons.lunch_dining},
      {'label': '오후 13:30', 'value': '13:30', 'icon': Icons.brightness_6},
      {'label': '오후 15:00', 'value': '15:00', 'icon': Icons.wb_sunny_outlined},
      {'label': '저녁 17:30', 'value': '17:30', 'icon': Icons.nightlight_round},
      {'label': '저녁 19:00', 'value': '19:00', 'icon': Icons.nights_stay},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.schedule_outlined, color: Color(0xFF4FC59E)),
            const SizedBox(width: 6),
            const Text(
              '예약 희망 시간',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF003829),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => provider.setTimeSlot(null),
              child: const Text('전체 해제'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth < 360 ? 2 : 3;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.8,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: timeSlots.map((slot) {
                final value = slot['value'] as String;
                final label = slot['label'] as String;
                final icon = slot['icon'] as IconData;
                final isSelected = provider.selectedTimeSlot == value;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4FC59E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4FC59E)
                          : Colors.grey.withOpacity(0.3),
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4FC59E).withOpacity(0.25),
                              offset: const Offset(0, 6),
                              blurRadius: 14,
                            ),
                          ]
                        : [],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () =>
                          provider.setTimeSlot(isSelected ? null : value),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF4FC59E),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF003829),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 수의사 목록을 표시하는 위젯
  static Widget buildVetList() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingVets) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.vetsError != null) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '오류: ${provider.vetsError}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadVets(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.vets.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다.\n다른 조건으로 검색해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _VetStackedList(vets: provider.vets),
        );
      },
    );
  }

  /// 펫시터 찾기 섹션 위젯
  ///
  /// 펫시터 검색을 위한 필터와 검색 버튼을 제공합니다.
  static Widget buildSitterFinderSection() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildPetTypeToggle(provider),
              const SizedBox(height: 20),
              _buildSitterServiceSelector(provider),
              const SizedBox(height: 20),
              _buildTimeSlotSelector(provider),
              const SizedBox(height: 16),
              // 펫시터 검색 버튼
              ElevatedButton(
                onPressed: () => provider.loadSitters(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC59E),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: provider.isLoadingSitters
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        '펫시터 찾기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 펫시터 서비스 선택 섹션
  static Widget _buildSitterServiceSelector(HospitalProvider provider) {
    final services = ['방문 돌봄', '산책 서비스', '호텔/위탁', '목욕/미용', '놀이/훈련', '응급 케어'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pets, color: Color(0xFF4FC59E)),
            const SizedBox(width: 6),
            const Text(
              '펫시터 서비스',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF003829),
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => provider.setSpecialty(null),
              child: const Text('전체 해제'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: services.map((service) {
            final isSelected = provider.selectedSpecialty == service;
            return ChoiceChip(
              label: Text(
                service,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF003829),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFF4FC59E),
              backgroundColor: Colors.grey.shade200,
              onSelected: (_) =>
                  provider.setSpecialty(isSelected ? null : service),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 펫시터 목록을 표시하는 위젯
  static Widget buildSitterList() {
    return Consumer<HospitalProvider>(
      builder: (context, provider, child) {
        if (provider.isLoadingSitters) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.sittersError != null) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    '오류: ${provider.sittersError}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSitters(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.sitters.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다.\n다른 조건으로 검색해보세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: _SitterStackedList(sitters: provider.sitters),
        );
      },
    );
  }

  /// 메뉴 버튼 위젯
  static Widget buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color iconColor = const Color(0xFF003829),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color.fromARGB(255, 132, 182, 169),
            ),
          ),
        ],
      ),
    );
  }
}

class _SitterStackedList extends StatefulWidget {
  final List<SitterModel> sitters;

  const _SitterStackedList({required this.sitters});

  @override
  State<_SitterStackedList> createState() => _SitterStackedListState();
}

class _SitterStackedListState extends State<_SitterStackedList>
    with SingleTickerProviderStateMixin {
  int _expandedIndex = 0;
  Set<String> _favoritedSitters = {}; // 즐겨찾기된 펫시터 ID 목록
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.sitters.isNotEmpty ? 0 : -1;
    _loadFavorites();
  }

  /// 즐겨찾기 목록 로드
  Future<void> _loadFavorites() async {
    final favorites = await _favoriteService.getSitterFavorites();
    setState(() {
      _favoritedSitters = favorites;
    });
  }

  @override
  void didUpdateWidget(covariant _SitterStackedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expandedIndex >= widget.sitters.length) {
      _expandedIndex = widget.sitters.isNotEmpty
          ? widget.sitters.length - 1
          : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.sitters.length,
      itemBuilder: (context, index) {
        final sitter = widget.sitters[index];
        final bool isExpanded = index == _expandedIndex;

        return GestureDetector(
          onTap: () => setState(() => _expandedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isExpanded ? 24 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(48),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isExpanded ? 0.16 : 0.06),
                  offset: const Offset(0, 10),
                  blurRadius: isExpanded ? 24 : 12,
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isExpanded ? 28 : 24,
                        backgroundColor: const Color(0xFFE6F7F1),
                        backgroundImage: (sitter.imageUrl.isNotEmpty)
                            ? NetworkImage(sitter.imageUrl) as ImageProvider
                            : null,
                        onBackgroundImageError: (sitter.imageUrl.isNotEmpty)
                            ? (exception, stackTrace) {
                                // 이미지 로드 실패 시 기본 아이콘 표시
                              }
                            : null,
                        child: sitter.imageUrl.isEmpty
                            ? Icon(
                                Icons.person_outline,
                                color: const Color(0xFF4FC59E),
                                size: isExpanded ? 26 : 22,
                              )
                            : null,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sitter.name,
                              style: TextStyle(
                                fontSize: isExpanded ? 21 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003829),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${sitter.sitterName} 펫시터',
                              style: TextStyle(
                                fontSize: isExpanded ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4FC59E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isExpanded ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (sitter.isAvailable
                                        ? const Color(0xFF4FC59E)
                                        : Colors.redAccent)
                                    .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sitter.isAvailable ? '예약가능' : '휴무',
                            style: TextStyle(
                              color: sitter.isAvailable
                                  ? const Color(0xFF2B8C6C)
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final isFavorited = _favoritedSitters.contains(
                            sitter.id,
                          );
                          if (isFavorited) {
                            await _favoriteService.removeSitterFavorite(
                              sitter.id,
                            );
                            setState(() {
                              _favoritedSitters.remove(sitter.id);
                            });
                          } else {
                            await _favoriteService.addSitterFavorite(sitter.id);
                            setState(() {
                              _favoritedSitters.add(sitter.id);
                            });
                          }
                        },
                        child: Icon(
                          _favoritedSitters.contains(sitter.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favoritedSitters.contains(sitter.id)
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            sitter.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          sitter.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          '${sitter.rating} | 경력 ${sitter.experience}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: sitter.services.map((service) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC59E).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            service,
                            style: const TextStyle(
                              color: Color(0xFF4FC59E),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        sitter.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => SitterProfilePage(sitter: sitter),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC59E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('상세보기'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _VetStackedList extends StatefulWidget {
  final List<VetModel> vets;

  const _VetStackedList({required this.vets});

  @override
  State<_VetStackedList> createState() => _VetStackedListState();
}

class _VetStackedListState extends State<_VetStackedList>
    with SingleTickerProviderStateMixin {
  int _expandedIndex = 0;
  Set<String> _favoritedVets = {}; // 즐겨찾기된 수의사 ID 목록
  final FavoriteService _favoriteService = FavoriteService();

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.vets.isNotEmpty ? 0 : -1;
    _loadFavorites();
  }

  /// 즐겨찾기 목록 로드
  Future<void> _loadFavorites() async {
    final favorites = await _favoriteService.getVetFavorites();
    setState(() {
      _favoritedVets = favorites;
    });
  }

  @override
  void didUpdateWidget(covariant _VetStackedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_expandedIndex >= widget.vets.length) {
      _expandedIndex = widget.vets.isNotEmpty ? widget.vets.length - 1 : -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 32),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.vets.length,
      itemBuilder: (context, index) {
        final vet = widget.vets[index];
        final bool isExpanded = index == _expandedIndex;

        return GestureDetector(
          onTap: () => setState(() => _expandedIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeInOut,
            margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isExpanded ? 24 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isExpanded ? 0.16 : 0.06),
                  offset: const Offset(0, 10),
                  blurRadius: isExpanded ? 24 : 12,
                ),
              ],
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isExpanded ? 28 : 24,
                        backgroundColor: const Color(0xFFE6F7F1),
                        backgroundImage: (vet.imageUrl.isNotEmpty)
                            ? NetworkImage(vet.imageUrl) as ImageProvider
                            : null,
                        onBackgroundImageError: (vet.imageUrl.isNotEmpty)
                            ? (exception, stackTrace) {
                                // 이미지 로드 실패 시 기본 아이콘 표시
                              }
                            : null,
                        child: vet.imageUrl.isEmpty
                            ? Icon(
                                Icons.local_hospital_outlined,
                                color: const Color(0xFF4FC59E),
                                size: isExpanded ? 26 : 22,
                              )
                            : null,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vet.name,
                              style: TextStyle(
                                fontSize: isExpanded ? 21 : 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF003829),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              vet.doctorName ?? '담당 수의사 미정',
                              style: TextStyle(
                                fontSize: isExpanded ? 16 : 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4FC59E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: isExpanded ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (vet.isOpen
                                        ? const Color(0xFF4FC59E)
                                        : Colors.redAccent)
                                    .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            vet.isOpen ? '영업중' : '휴무',
                            style: TextStyle(
                              color: vet.isOpen
                                  ? const Color(0xFF2B8C6C)
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () async {
                          final isFavorited = _favoritedVets.contains(vet.id);
                          if (isFavorited) {
                            await _favoriteService.removeVetFavorite(vet.id);
                            setState(() {
                              _favoritedVets.remove(vet.id);
                            });
                          } else {
                            await _favoriteService.addVetFavorite(vet.id);
                            setState(() {
                              _favoritedVets.add(vet.id);
                            });
                          }
                        },
                        child: Icon(
                          _favoritedVets.contains(vet.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favoritedVets.contains(vet.id)
                              ? const Color(0xFFFF6B9D)
                              : Colors.grey.shade400,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.place, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            vet.address,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 18, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          vet.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: vet.specialties.map((specialty) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4FC59E).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            specialty,
                            style: const TextStyle(
                              color: Color(0xFF4FC59E),
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => VetProfilePage(vet: vet),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC59E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 46),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.info_outline, size: 18),
                        label: const Text('상세보기'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
