// lib/models/watchlist_item.dart

/// Represents a user's tracked product, optionally enriched with the
/// best current nearby deal price.
class WatchlistItem {
  final String productId; // Canonical name or id stored in the backend
  final String productName;
  final double? currentPrice;
  final double? originalPrice;
  final String? storeName;
  final bool hasActiveDeal;

  const WatchlistItem({
    required this.productId,
    required this.productName,
    this.currentPrice,
    this.originalPrice,
    this.storeName,
    this.hasActiveDeal = false,
  });

  /// Constructs a minimal [WatchlistItem] from a bare product name string
  /// (backwards compatible with the current `List<String>` API response).
  factory WatchlistItem.fromProductName(String name) {
    return WatchlistItem(productId: name, productName: name);
  }

  /// Constructs a [WatchlistItem] from a full discount API map, enriching
  /// the product name with live deal data.
  factory WatchlistItem.fromEnrichedMap(Map<String, dynamic> map) {
    final name = map['product']?.toString() ??
        map['product_name']?.toString() ??
        'Onbekend';
    final price = _parseDouble(map['price']);
    final oldPrice = _parseDouble(map['old_price']);
    return WatchlistItem(
      productId: name,
      productName: name,
      currentPrice: price,
      originalPrice: oldPrice,
      storeName: map['supermarket']?.toString(),
      hasActiveDeal: price != null,
    );
  }

  /// Merges a bare watchlist entry with an optional matching discount deal.
  WatchlistItem enrichWith(Map<String, dynamic>? deal) {
    if (deal == null) return this;
    final price = _parseDouble(deal['price']);
    final oldPrice = _parseDouble(deal['old_price']);
    return WatchlistItem(
      productId: productId,
      productName: productName,
      currentPrice: price,
      originalPrice: oldPrice,
      storeName: deal['supermarket']?.toString(),
      hasActiveDeal: price != null,
    );
  }

  /// Percentage discount, 0 if no deal or no old price.
  int get discountPercent {
    if (currentPrice == null || originalPrice == null || originalPrice == 0) {
      return 0;
    }
    return (((originalPrice! - currentPrice!) / originalPrice!) * 100).round();
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
