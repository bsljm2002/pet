/// 쇼핑몰 제품 정보 모델
class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.rating,
    required this.reviews,
    required this.petTargets,
    this.isBest = false,
    this.isRecommended = false,
  }) : assert(petTargets.isNotEmpty, 'petTargets must contain at least one entry');

  final String id;
  final String name;
  final String category;
  final int price;
  final int? originalPrice;
  final double rating;
  final int reviews;
  final List<String> petTargets;
  final bool isBest;
  final bool isRecommended;

  /// 할인율을 정수 퍼센트로 반환
  int? get discountRate {
    if (originalPrice == null || originalPrice == 0 || originalPrice == price) {
      return null;
    }
    final rate = ((originalPrice! - price) / originalPrice! * 100).round();
    return rate > 0 ? rate : null;
  }

  bool supportsPet(String petType) {
    if (petType == '강아지') {
      return petTargets.contains('강아지') || petTargets.contains('공용');
    }
    if (petType == '고양이') {
      return petTargets.contains('고양이') || petTargets.contains('공용');
    }
    return true;
  }

  bool matchesQuery(String query) {
    if (query.isEmpty) {
      return true;
    }
    final lowerQuery = query.toLowerCase();
    return name.toLowerCase().contains(lowerQuery) ||
        category.toLowerCase().contains(lowerQuery);
  }
}
