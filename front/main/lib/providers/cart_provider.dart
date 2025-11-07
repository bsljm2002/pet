import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import 'product_provider.dart';

/// 장바구니와 주문 내역을 관리하는 Provider
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  final List<Order> _orders = [
    Order(
      id: 'o-20240101',
      createdAt: DateTime(2024, 1, 8, 10, 30),
      items: const [
        OrderItem(productId: 'p-dog-food-01', quantity: 1),
        OrderItem(productId: 'p-dog-pad-01', quantity: 2),
      ],
      totalPrice: 35000 + 28000 * 2,
    ),
    Order(
      id: 'o-20231212',
      createdAt: DateTime(2023, 12, 12, 19, 45),
      items: const [
        OrderItem(productId: 'p-cat-feeder-01', quantity: 1),
      ],
      totalPrice: 89000,
    ),
  ];

  UnmodifiableListView<CartItem> get items =>
      UnmodifiableListView<CartItem>(_items.values);

  bool get isEmpty => _items.isEmpty;

  int get totalQuantity =>
      _items.values.fold<int>(0, (sum, item) => sum + item.quantity);

  List<Order> get orders => List.unmodifiable(_orders);

  void addItem(Product product, {int quantity = 1}) {
    final existing = _items[product.id];
    final newQuantity = (existing?.quantity ?? 0) + quantity;
    _items[product.id] = CartItem(productId: product.id, quantity: newQuantity);
    notifyListeners();
  }

  void setQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (quantity <= 0) {
      _items.remove(productId);
    } else {
      _items[productId] =
          _items[productId]!.copyWith(quantity: quantity.clamp(1, 99));
    }
    notifyListeners();
  }

  void increaseQuantity(String productId) {
    final current = _items[productId];
    if (current == null) return;
    setQuantity(productId, current.quantity + 1);
  }

  void decreaseQuantity(String productId) {
    final current = _items[productId];
    if (current == null) return;
    setQuantity(productId, current.quantity - 1);
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clearCart() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  int calculateTotal(ProductProvider productProvider) {
    return _items.values.fold<int>(0, (sum, item) {
      final product = productProvider.findById(item.productId);
      if (product == null) return sum;
      return sum + product.price * item.quantity;
    });
  }

  Future<void> checkout(ProductProvider productProvider) async {
    if (_items.isEmpty) {
      return;
    }
    final total = calculateTotal(productProvider);
    if (total <= 0) return;

    final order = Order(
      id: _generateOrderId(),
      createdAt: DateTime.now(),
      items: _items.values
          .map(
            (item) => OrderItem(
              productId: item.productId,
              quantity: item.quantity,
            ),
          )
          .toList(growable: false),
      totalPrice: total,
    );

    _orders.insert(0, order);
    _items.clear();
    notifyListeners();
  }

  void purchaseNow(Product product, {int quantity = 1}) {
    if (quantity <= 0) return;

    final order = Order(
      id: _generateOrderId(),
      createdAt: DateTime.now(),
      items: [
        OrderItem(productId: product.id, quantity: quantity),
      ],
      totalPrice: product.price * quantity,
    );

    _orders.insert(0, order);
    notifyListeners();
  }

  String _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'o-$timestamp';
  }
}

