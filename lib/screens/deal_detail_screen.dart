// lib/screens/deal_detail_screen.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class DealDetailScreen extends StatelessWidget {
  final Map<String, dynamic> deal;

  const DealDetailScreen({super.key, required this.deal});

  double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final name = deal['product']?.toString() ??
        deal['product_name']?.toString() ??
        'Onbekend';
    final imageUrl = deal['image_url']?.toString();
    final store = deal['supermarket']?.toString() ?? '';
    final price = _parseDouble(deal['price']);
    final oldPrice = _parseDouble(deal['original_price'] ?? deal['old_price']);
    final unitLabel = deal['unit_label']?.toString();
    final endDate = deal['end_date']?.toString();
    final dealLabel = deal['deal_label']?.toString();
    final description = deal['description']?.toString();

    // Multi-tier bundle options: [{qty: 4, price: 7.99}, {qty: 6, price: 10.99}]
    final rawOptions = deal['deal_options'];
    final List<Map<String, dynamic>> dealOptions = (rawOptions is List)
        ? rawOptions.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'deal_image_${deal['product_slug'] ?? name}',
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(40),
                  child: imageUrl != null
                      ? Image.network(imageUrl, fit: BoxFit.contain)
                      : const Icon(Icons.shopping_basket, size: 100, color: AppColors.outlineVariant),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Store badge + validity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          store.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      if (endDate != null)
                        Text(
                          'Geldig t/m $endDate',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Product name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSurface,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Price / deal label section ──────────────────────────────
                  if (dealOptions.length > 1) ...[
                    // Multi-tier bundle: show all options as cards
                    const Text(
                      'Aanbieding opties',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...dealOptions.map((opt) {
                      final qty = opt['qty'];
                      final optPrice = _parseDouble(opt['price']);
                      final isHighlighted = optPrice == price;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? AppColors.primaryContainer.withValues(alpha: 0.15)
                              : AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isHighlighted ? AppColors.primary : AppColors.outlineVariant,
                            width: isHighlighted ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$qty stuks',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isHighlighted ? AppColors.primary : AppColors.onSurface,
                              ),
                            ),
                            Text(
                              optPrice != null ? '€ ${optPrice.toStringAsFixed(2)}' : '--',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: isHighlighted ? AppColors.tertiary : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ] else if (price != null) ...[
                    // Single numeric price
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (oldPrice != null)
                              Text(
                                '€ ${oldPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.outline,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              '€ ${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: AppColors.tertiary,
                                height: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        if (unitLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Text(
                              '/ $unitLabel',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ] else if (dealLabel != null) ...[
                    // Deal label only (BOGO, %, etc.)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary, width: 1.5),
                      ),
                      child: Text(
                        dealLabel,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // ── Details section ─────────────────────────────────────────
                  const Text(
                    'Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      description?.isNotEmpty == true
                          ? description!
                          : 'Deze aanbieding is beschikbaar in alle deelnemende winkels. De korting wordt automatisch verrekend bij de kassa. OP = OP!',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 80), // Space for bottom sheet
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: const Text(
                  'Toevoegen aan Lijst',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, color: AppColors.onSurface),
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
