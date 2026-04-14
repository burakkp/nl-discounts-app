// lib/models/catalog_item.dart

/// Represents a single product entry from the Master Catalog.
/// Used for the catalog search bottom sheet.
class CatalogItem {
  final String id; // Canonical product id or name slug
  final String name;
  final String? category;
  final String? supermarket; // Non-null only when sourced from a discount record

  const CatalogItem({
    required this.id,
    required this.name,
    this.category,
    this.supermarket,
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
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogItem && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
