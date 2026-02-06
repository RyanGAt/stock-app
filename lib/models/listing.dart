class Listing {
  Listing({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.platform,
    required this.listedPrice,
    required this.listedDate,
    required this.status,
    required this.createdAt,
    this.sourceUrl,
    this.size,
  });

  final String id;
  final String itemId;
  final String userId;
  final String platform;
  final num listedPrice;
  final DateTime listedDate;
  final String status;
  final DateTime createdAt;
  final String? sourceUrl;
  final String? size;

  factory Listing.fromMap(Map<String, dynamic> map) {
    return Listing(
      id: map['id'] as String,
      itemId: map['item_id'] as String,
      userId: map['user_id'] as String,
      platform: map['platform'] as String,
      listedPrice: map['listed_price'] as num,
      listedDate: DateTime.parse(map['listed_date'] as String),
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      sourceUrl: map['source_url'] as String?,
      size: map['size'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'user_id': userId,
      'platform': platform,
      'listed_price': listedPrice,
      'listed_date': listedDate.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'source_url': sourceUrl,
      'size': size,
    };
  }
}
