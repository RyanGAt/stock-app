class Sale {
  Sale({
    required this.id,
    required this.userId,
    required this.createdAt,
    this.stockId,
    this.itemId,
    this.size,
    this.platform,
    this.listingId,
    this.salePrice,
    this.fees,
    this.shippingCost,
    this.soldDate,
  });

  final String id;
  final String userId;
  final DateTime createdAt;
  final String? stockId;
  final String? itemId;
  final String? size;
  final String? platform;
  final String? listingId;
  final num? salePrice;
  final num? fees;
  final num? shippingCost;
  final DateTime? soldDate;

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      stockId: map['stock_id'] as String?,
      itemId: map['item_id'] as String?,
      size: map['size'] as String?,
      platform: map['platform'] as String?,
      listingId: map['listing_id'] as String?,
      salePrice: map['sale_price'] as num?,
      fees: map['fees'] as num?,
      shippingCost: map['shipping_cost'] as num?,
      soldDate: map['sold_date'] == null
          ? null
          : DateTime.parse(map['sold_date'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'stock_id': stockId,
      'item_id': itemId,
      'size': size,
      'platform': platform,
      'listing_id': listingId,
      'sale_price': salePrice,
      'fees': fees,
      'shipping_cost': shippingCost,
      'sold_date': soldDate?.toIso8601String(),
    };
  }
}
