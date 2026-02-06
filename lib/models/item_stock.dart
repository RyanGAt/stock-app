class ItemStock {
  ItemStock({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.size,
  });

  final String id;
  final String itemId;
  final String userId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? size;

  factory ItemStock.fromMap(Map<String, dynamic> map) {
    return ItemStock(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      userId: map['user_id'] as String,
      quantity: map['quantity'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      size: map['size'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'user_id': userId,
      'quantity': quantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'size': size,
    };
  }
}
