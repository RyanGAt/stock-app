class ItemCost {
  ItemCost({
    required this.itemId,
    required this.userId,
    required this.totalPurchasedQty,
    required this.avgUnitCost,
  });

  final String itemId;
  final String userId;
  final int totalPurchasedQty;
  final num avgUnitCost;

  factory ItemCost.fromMap(Map<String, dynamic> map) {
    return ItemCost(
      itemId: map['item_id'] as String,
      userId: map['user_id'] as String,
      totalPurchasedQty: map['total_purchased_qty'] as int,
      avgUnitCost: map['avg_unit_cost'] as num,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'item_id': itemId,
      'user_id': userId,
      'total_purchased_qty': totalPurchasedQty,
      'avg_unit_cost': avgUnitCost,
    };
  }
}
