// lib/models/watchlist_item.dart

/// Represents a user's tracked product, optionally enriched with the
/// best current nearby deal price.
class WatchlistItem {
  final String productId; // Canonical name or id stored in the backend
  final String productName;
  final double? currentPrice;
  final double? originalPrice;
  final String? storeName;
  final String? unitLabel;
  final String? endDate;
  final bool hasActiveDeal;
  final DateTime? lastNotifiedAt;

  const WatchlistItem({
    required this.productId,
    required this.productName,
    this.currentPrice,
    this.originalPrice,
    this.storeName,
    this.unitLabel,
    this.endDate,
    this.hasActiveDeal = false,
    this.lastNotifiedAt,
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
    final oldPrice = _parseDouble(map['original_price'] ?? map['old_price']);
    return WatchlistItem(
      productId: name,
      productName: name,
      currentPrice: price,
      originalPrice: oldPrice,
      storeName: map['supermarket']?.toString(),
      unitLabel: map['unit_label']?.toString(),
      endDate: map['end_date']?.toString(),
      hasActiveDeal: price != null,
    );
  }

  /// Merges a bare watchlist entry with an optional matching discount deal.
  WatchlistItem enrichWith(Map<String, dynamic>? deal) {
    if (deal == null) return this;
    final price = _parseDouble(deal['price']);
    final oldPrice = _parseDouble(deal['original_price'] ?? deal['old_price']);
    return WatchlistItem(
      productId: productId,
      productName: productName,
      currentPrice: price,
      originalPrice: oldPrice,
      storeName: deal['supermarket']?.toString(),
      unitLabel: deal['unit_label']?.toString(),
      endDate: deal['end_date']?.toString(),
      hasActiveDeal: price != null,
      lastNotifiedAt: lastNotifiedAt,
    );
  }

  WatchlistItem copyWith({
    String? productId,
    String? productName,
    double? currentPrice,
    double? originalPrice,
    String? storeName,
    String? unitLabel,
    String? endDate,
    bool? hasActiveDeal,
    DateTime? lastNotifiedAt,
  }) {
    return WatchlistItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      currentPrice: currentPrice ?? this.currentPrice,
      originalPrice: originalPrice ?? this.originalPrice,
      storeName: storeName ?? this.storeName,
      unitLabel: unitLabel ?? this.unitLabel,
      endDate: endDate ?? this.endDate,
      hasActiveDeal: hasActiveDeal ?? this.hasActiveDeal,
      lastNotifiedAt: lastNotifiedAt ?? this.lastNotifiedAt,
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
