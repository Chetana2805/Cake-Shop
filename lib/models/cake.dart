class Cake {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> ingredients; // <-- new field


  Cake({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.ingredients, // <-- include in constructor
  });


  factory Cake.fromMap(Map<String, dynamic> data, String id) {
    return Cake(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []), // <-- parse array
    );
  }


  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'ingredients': ingredients, // <-- store array
    };
  }
}
