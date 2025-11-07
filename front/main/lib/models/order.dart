import 'cart_item.dart';

/// 주문 내역의 개별 상품
class OrderItem {
  const OrderItem({required this.productId, required this.quantity})
    : assert(quantity > 0, 'quantity must be greater than zero');

  final String productId;
  final int quantity;

  CartItem toCartItem() => CartItem(productId: productId, quantity: quantity);
}

/// 주문 정보
class Order {
  const Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.totalPrice,
  }) : assert(totalPrice >= 0, 'totalPrice must be >= 0');

  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final int totalPrice;
}
