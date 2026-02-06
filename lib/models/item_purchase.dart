class ItemPurchase {
  ItemPurchase({
    required this.id,
    required this.purchaseId,
    required this.itemId,
    required this.userId,
    required this.quantity,
    required this.unitPrice,
    required this.createdAt,
    required this.addedToStock,
    this.size,
  });

  final String id;
  final String purchaseId;
  final String itemId;
  final String userId;
  final int quantity;
  final num unitPrice;
  final DateTime createdAt;
  final bool addedToStock;
  final String? size;

  factory ItemPurchase.fromMap(Map<String, dynamic> map) {
    return ItemPurchase(
      id: map['id'] as String,
      purchaseId: map['purchase_id'] as String,
      itemId: map['item_id'] as String,
      userId: map['user_id'] as String,
      quantity: map['quantity'] as int,
      unitPrice: map['unit_price'] as num,
      createdAt: DateTime.parse(map['created_at'] as String),
      addedToStock: map['added_to_stock'] as bool? ?? false,
      size: map['size'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchase_id': purchaseId,
      'item_id': itemId,
      'user_id': userId,
      'quantity': quantity,
      'unit_price': unitPrice,
      'created_at': createdAt.toIso8601String(),
      'added_to_stock': addedToStock,
      'size': size,
    };
  }
}
