/// 장바구니에 담긴 상품과 수량 정보
class CartItem {
  const CartItem({
    required this.productId,
    required this.quantity,
  }) : assert(quantity > 0, 'quantity must be greater than zero');

  final String productId;
  final int quantity;

  CartItem copyWith({String? productId, int? quantity}) {
    return CartItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
    );
  }
}

