// lib/models/catalog_item.dart

/// Represents a single product entry from the Master Catalog.
/// Used for the catalog search bottom sheet.
class CatalogItem {
  final String id; // Canonical product id or name slug
  final String name;
  final String? category;
  final String? supermarket;
  final double? originalPrice;
  final String? unitLabel;
  final double? unitPrice;
  final String? endDate;

  const CatalogItem({
    required this.id,
    required this.name,
    this.category,
    this.supermarket,
    this.originalPrice,
    this.unitLabel,
    this.unitPrice,
    this.endDate,
  });

  /// Constructs a [CatalogItem] from a raw API discount map.
  factory CatalogItem.fromDiscountMap(Map<String, dynamic> map) {
    final name = map['product']?.toString() ??
        map['product_name']?.toString() ??
        'Onbekend';
    return CatalogItem(
      id: name, // Use canonical name as ID when no explicit product_id
      name: name,
      category: map['category']?.toString(),
      supermarket: map['supermarket']?.toString(),
      originalPrice: _parseDouble(map['original_price'] ?? map['old_price']),
      unitLabel: map['unit_label']?.toString(),
      unitPrice: _parseDouble(map['unit_price']),
      endDate: map['end_date']?.toString(),
    );
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
