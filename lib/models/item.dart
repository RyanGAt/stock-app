class Item {
  Item({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.description,
    this.brand,
    this.category,
    this.size,
    this.colour,
    this.mainImageUrl,
  });

  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;
  final String? description;
  final String? brand;
  final String? category;
  final String? size;
  final String? colour;
  final String? mainImageUrl;

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      description: map['description'] as String?,
      brand: map['brand'] as String?,
      category: map['category'] as String?,
      size: map['size'] as String?,
      colour: map['colour'] as String?,
      mainImageUrl: map['main_image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'description': description,
      'brand': brand,
      'category': category,
      'size': size,
      'colour': colour,
      'main_image_url': mainImageUrl,
    };
  }
}
