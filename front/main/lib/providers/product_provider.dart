import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// 쇼핑몰 전용 더미 데이터 공급자
class ProductProvider extends ChangeNotifier {
  ProductProvider();

  final List<Product> _products = [
    Product(
      id: 'p-dog-food-01',
      name: '프리미엄 강아지 사료 3kg',
      category: '사료/간식',
      price: 35000,
      originalPrice: 45000,
      rating: 4.8,
      reviews: 1234,
      petTargets: ['강아지'],
      isBest: true,
      isRecommended: true,
    ),
    Product(
      id: 'p-cat-feeder-01',
      name: '고양이 자동 급식기',
      category: '기타',
      price: 89000,
      originalPrice: 120000,
      rating: 4.9,
      reviews: 856,
      petTargets: ['고양이'],
      isBest: true,
      isRecommended: false,
    ),
    Product(
      id: 'p-dog-harness-01',
      name: '반려견 산책 가슴줄',
      category: '미용/케어 도구',
      price: 18000,
      rating: 4.7,
      reviews: 542,
      petTargets: ['강아지'],
      isBest: true,
      isRecommended: true,
    ),
    Product(
      id: 'p-cat-scratch-01',
      name: '고양이 스크래처 타워',
      category: '하우스',
      price: 32000,
      rating: 4.8,
      reviews: 672,
      petTargets: ['고양이'],
      isRecommended: true,
    ),
    Product(
      id: 'p-dog-snack-set-01',
      name: '강아지 간식 모음 세트',
      category: '사료/간식',
      price: 25000,
      rating: 4.6,
      reviews: 431,
      petTargets: ['강아지'],
      isRecommended: true,
    ),
    Product(
      id: 'p-pet-shampoo-01',
      name: '반려동물 저자극 샴푸',
      category: '미용/케어 도구',
      price: 15000,
      rating: 4.7,
      reviews: 389,
      petTargets: ['강아지', '고양이', '공용'],
      isRecommended: true,
    ),
    Product(
      id: 'p-subscription-01',
      name: '월간 펫케어 구독 서비스',
      category: '구독 서비스',
      price: 59000,
      rating: 4.5,
      reviews: 128,
      petTargets: ['공용'],
      isRecommended: true,
    ),
    Product(
      id: 'p-goods-01',
      name: '펫 라이프스타일 굿즈 세트',
      category: '굿즈',
      price: 42000,
      rating: 4.4,
      reviews: 203,
      petTargets: ['공용'],
    ),
    Product(
      id: 'p-cat-toy-01',
      name: '고양이 인터랙티브 장난감',
      category: '장난감',
      price: 28000,
      rating: 4.6,
      reviews: 512,
      petTargets: ['고양이'],
    ),
    Product(
      id: 'p-dog-pad-01',
      name: '애견 배변패드 100매',
      category: '위생용품',
      price: 28000,
      rating: 4.5,
      reviews: 455,
      petTargets: ['강아지'],
      isRecommended: true,
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);

  Product? findById(String id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  List<String> get categories {
    final unique = <String>{};
    for (final product in _products) {
      unique.add(product.category);
    }
    final result = unique.toList()..sort();
    result.insert(0, '전체');
    return result;
  }

  List<Product> getBestProducts({String petType = '강아지', String query = ''}) {
    return _filterProducts(
      _products.where((product) => product.isBest),
      petType: petType,
      query: query,
    );
  }

  List<Product> getRecommendedProducts({
    String petType = '강아지',
    String query = '',
  }) {
    return _filterProducts(
      _products.where((product) => product.isRecommended),
      petType: petType,
      query: query,
    );
  }

  List<Product> getProductsByCategory(
    String category, {
    String petType = '강아지',
    String query = '',
  }) {
    return _filterProducts(
      _products.where((product) => category == '전체' || product.category == category),
      petType: petType,
      query: query,
    );
  }

  List<Product> _filterProducts(
    Iterable<Product> source, {
    required String petType,
    required String query,
  }) {
    return source
        .where((product) => product.supportsPet(petType))
        .where((product) => product.matchesQuery(query))
        .toList(growable: false);
  }
}
