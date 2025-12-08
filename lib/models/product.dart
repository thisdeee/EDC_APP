class Product {
  final String id;
  final String name;
  final double price;
  final String category;
  final String? imageUrl;
  final String? description;
  final int? stock;
  final bool isUsingSalePage;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.imageUrl,
    this.description,
    this.stock,
    this.isUsingSalePage = false,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Extract description and image from descriptions array if available
    String? description;
    String? descriptionImage;
    if (json['descriptions'] != null && json['descriptions'] is List) {
      final descriptions = json['descriptions'] as List;
      if (descriptions.isNotEmpty && descriptions[0] is Map) {
        description = descriptions[0]['title']?.toString();
        descriptionImage = descriptions[0]['image']?.toString();
      }
    }

    // Get image filename
    String? imageFilename = json['image']?.toString();

    // If no main image, try description image
    if ((imageFilename == null || imageFilename.isEmpty) &&
        descriptionImage != null) {
      imageFilename = descriptionImage;
    }

    // Build full URL - store just the filename, will try multiple paths when loading
    String? imageUrl;
    if (imageFilename != null && imageFilename.isNotEmpty) {
      if (imageFilename.startsWith('http')) {
        imageUrl = imageFilename;
      } else {
        // Store filename with marker to try multiple paths
        imageUrl = imageFilename;
      }
    }

    return Product(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Product',
      price: _parsePrice(json['price'] ?? 0),
      category: json['unit']?.toString() ?? 'Unit', // Use unit as category
      imageUrl: imageUrl,
      description: description,
      stock: json['amount'] as int? ?? json['amountAll'] as int?,
      isUsingSalePage: json['isUsingSalePage'] as bool? ?? false,
    );
  }

  static double _parsePrice(dynamic price) {
    if (price is num) return price.toDouble();
    if (price is String) return double.tryParse(price) ?? 0.0;
    return 0.0;
  }
}

class CartItem {
  final Product product;
  int qty;
  CartItem({required this.product, this.qty = 1});

  double get lineTotal => qty * product.price;
}
