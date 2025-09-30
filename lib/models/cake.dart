class Cake {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final int discount; // discount in percentage
  bool isFavorite;

  Cake({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.discount = 0,
    this.isFavorite = false,
  });

  double get finalPrice {
    if (discount > 0) {
      return price - (price * discount / 100);
    }
    return price;
  }

  factory Cake.fromMap(Map<String, dynamic> data, String id) {
    return Cake(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      discount: (data['discount'] ?? 0).toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'discount': discount,
    };
  }
}
