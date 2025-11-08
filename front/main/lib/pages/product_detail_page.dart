import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import 'cart_page.dart';

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.productId});

  final String productId;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();

    final product = productProvider.findById(widget.productId);
    if (product == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('상품 상세'),
        ),
        body: const Center(
          child: Text('상품 정보를 찾을 수 없습니다.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('상품 상세'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroImage(),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildRating(product),
            const SizedBox(height: 12),
            _buildPriceSection(product),
            const SizedBox(height: 12),
            _buildPetTags(product),
            const SizedBox(height: 24),
            const Text(
              '상품 설명',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _buildDescription(product),
              style: const TextStyle(height: 1.4),
            ),
            const SizedBox(height: 32),
            _buildQuantitySelector(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, product, cartProvider),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 212, 244, 228),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.shopping_bag,
          size: 100,
          color: Color.fromARGB(255, 0, 108, 82),
        ),
      ),
    );
  }

  Widget _buildRating(Product product) {
    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 20),
        const SizedBox(width: 4),
        Text(
          '${product.rating}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        Text(
          '(${product.reviews}개의 리뷰)',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPriceSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (product.discountRate != null) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${product.discountRate}% OFF',
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              _formatPrice(product.price),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 108, 82),
              ),
            ),
          ],
        ),
        if (product.originalPrice != null) ...[
          const SizedBox(height: 4),
          Text(
            _formatPrice(product.originalPrice!),
            style: const TextStyle(
              color: Colors.grey,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPetTags(Product product) {
    return Wrap(
      spacing: 8,
      children: product.petTargets
          .map(
            (target) => Chip(
              label: Text(target),
              backgroundColor: const Color.fromARGB(255, 212, 244, 228),
            ),
          )
          .toList(),
    );
  }

  String _buildDescription(Product product) {
    return '카테고리: ${product.category}\n'
        '선호 고객: ${product.petTargets.join(', ')}\n\n'
        '이 상품은 반려동물의 라이프스타일에 맞춰 엄선된 추천 제품입니다. '
        '꾸준한 사랑을 받고 있는 인기 상품으로, 현재 ${product.discountRate != null ? '${product.discountRate}% 할인과 함께 ' : ''}판매 중입니다. '
        '구매 후 ${product.reviews}명의 반려인들이 높은 만족도를 남겨주셨어요!';
  }

  Widget _buildQuantitySelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          '수량 선택',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: _quantity > 1
                  ? () => setState(() {
                        _quantity -= 1;
                      })
                  : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Text(
              '$_quantity',
              style: const TextStyle(fontSize: 16),
            ),
            IconButton(
              onPressed: () => setState(() {
                _quantity += 1;
              }),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Product product,
    CartProvider cartProvider,
  ) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  cartProvider.addItem(product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('장바구니에 ${product.name}이(가) 담겼어요.'),
                    ),
                  );
                },
                child: const Text('장바구니 담기'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  cartProvider.purchaseNow(product, quantity: _quantity);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('구매가 완료되었습니다.'),
                      action: SnackBarAction(
                        label: '구매내역 보기',
                        onPressed: () {
                          Navigator.of(context).pushNamed('/orders');
                        },
                      ),
                    ),
                  );
                },
                child: Text('${_formatPrice(product.price * _quantity)} 바로 구매'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(int value) {
    final formatted = value
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (match) => '${match[1]},');
    return '$formatted원';
  }
}

