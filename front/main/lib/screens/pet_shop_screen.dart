import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product.dart';
import '../pages/cart_page.dart';
import '../pages/order_history_page.dart';
import '../pages/product_detail_page.dart';
import '../pages/product_list_page.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';

/// 펫 쇼핑몰 화면
/// 반려동물 용품 쇼핑 기능
class PetShopScreen extends StatefulWidget {
  const PetShopScreen({super.key});

  @override
  State<PetShopScreen> createState() => _PetShopScreenState();
}

class _PetShopScreenState extends State<PetShopScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedPetType = '강아지';
  String _selectedCategory = '전체';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = context.watch<ProductProvider>();
    final cartProvider = context.watch<CartProvider>();
    final searchQuery = _searchController.text.trim();
    final filteredProducts = productProvider.getProductsByCategory(
      _selectedCategory,
      petType: _selectedPetType,
      query: searchQuery,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('펫 쇼핑몰'),
        backgroundColor: const Color.fromARGB(255, 0, 108, 82),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '구매 내역',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: '장바구니',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CartPage()),
                  );
                },
              ),
              if (!cartProvider.isEmpty)
                Positioned(
                  right: 10,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${cartProvider.totalQuantity}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 검색 섹션
            _buildSearchSection(),
            const SizedBox(height: 16),

            // 반려동물 타입 필터
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPetTypeFilter(),
            ),
            const SizedBox(height: 16),

            // 카테고리 섹션
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCategorySection(),
            ),
            const SizedBox(height: 24),

            // 추천 상품
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildProductsList(
                context,
                filteredProducts,
                cartProvider,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '찾고 싶은 상품을 입력하세요',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(
              color: Color.fromARGB(255, 0, 108, 82),
              width: 2,
            ),
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildPetTypeFilter() {
    final petTypes = ['강아지', '고양이'];

    return Wrap(
      spacing: 12,
      children: petTypes.map((type) {
        final isSelected = _selectedPetType == type;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: (_) => setState(() {
            _selectedPetType = type;
          }),
          selectedColor: const Color.fromARGB(255, 0, 108, 82),
          labelStyle: TextStyle(
            color: isSelected
                ? Colors.white
                : const Color.fromARGB(255, 0, 56, 41),
            fontWeight: FontWeight.w600,
          ),
          backgroundColor: const Color.fromARGB(255, 212, 244, 228),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySection() {
    final categories = [
      {'icon': Icons.all_inclusive, 'label': '전체'},
      {'icon': Icons.restaurant, 'label': '사료/간식'},
      {'icon': Icons.self_improvement, 'label': '위생용품'},
      {'icon': Icons.toys, 'label': '장난감'},
      {'icon': Icons.spa, 'label': '미용/케어 도구'},
      {'icon': Icons.house, 'label': '하우스'},
      {'icon': Icons.medical_services, 'label': '건강용품'},
      {'icon': Icons.star, 'label': '굿즈'},
      {'icon': Icons.subscriptions, 'label': '구독 서비스'},
      {'icon': Icons.more_horiz, 'label': '기타'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '카테고리',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final label = categories[index]['label'] as String;
              return _buildCategoryItem(
                icon: categories[index]['icon'] as IconData,
                label: label,
                isSelected: label == _selectedCategory,
                onTap: () {
                  setState(() {
                    _selectedCategory = label;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 0, 108, 82)
                    : const Color.fromARGB(255, 212, 244, 228),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 30,
                color: isSelected ? Colors.white : const Color.fromARGB(255, 0, 108, 82),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color.fromARGB(255, 0, 56, 41)
                    : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList(
    BuildContext context,
    List<Product> products,
    CartProvider cartProvider,
  ) {
    if (products.isEmpty) {
      return _buildEmptyState('조건에 맞는 상품이 없어요.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '추천 상품',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 0, 56, 41),
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildGridProductCard(
            context,
            products[index],
            cartProvider,
          ),
        ),
      ],
    );
  }

  Widget _buildGridProductCard(
    BuildContext context,
    Product product,
    CartProvider cartProvider,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(productId: product.id),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상품 이미지
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.shopping_bag,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (product.discountRate != null) ...[
                    Text(
                      '${product.discountRate}% 할인',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    _formatPrice(product.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (product.originalPrice != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatPrice(product.originalPrice!),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(
                        '${product.rating}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${product.reviews})',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        cartProvider.addItem(product);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name}이 장바구니에 담겼어요.'),
                          ),
                        );
                      },
                      child: const Text('장바구니'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Text(
        message,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  String _formatPrice(int value) {
    final formatted = value
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
    return '$formatted원';
  }
}
