class CartItem {
  final String cakeId;
  final int quantity;

  CartItem({required this.cakeId, required this.quantity});

  Map<String, dynamic> toMap() {
    return {'cakeId': cakeId, 'quantity': quantity};
  }
}