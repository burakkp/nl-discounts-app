// lib/screens/home_feed_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/catalog_item.dart';
import '../theme/app_theme.dart';
import '../widgets/shimmer_loaders.dart';
import 'catalog_search_sheet.dart';
import 'deal_detail_screen.dart';

// ─── STORE BRANDING ──────────────────────────────────────────────────────────

const Map<String, Color> _storeColors = {
  'albert heijn': Color(0xFF00A0E2),
  'ah':           Color(0xFF00A0E2),
  'jumbo':        Color(0xFFFFD800),
  'lidl':         Color(0xFF0050AA),
  'aldi':         Color(0xFF1A3A6B),
  'plus':         Color(0xFF00873D),
};

Color _storeColor(String? storeName) {
  if (storeName == null) return AppColors.outlineVariant;
  final key = storeName.toLowerCase();
  for (final entry in _storeColors.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return AppColors.primary;
}

// Deal-type badge derived from deal data
String _dealBadge(Map<String, dynamic> deal) {
  final type = deal['deal_type']?.toString().toUpperCase() ?? '';
  final raw = deal['original_deal_string']?.toString().toLowerCase() ?? '';

  if (type == 'BOGO' || raw.contains('1+1') || raw.contains('gratis')) {
    if (raw.contains('2+1')) return '2+1 GRATIS';
    if (raw.contains('2+2')) return '2+2 GRATIS';
    return '1+1 GRATIS';
  }
  if (type == 'HALF_PRICE_2ND' || raw.contains('halve prijs')) return '2e HALVE PRIJS';
  if (type == 'FIXED_BUNDLE') {
    final qty = deal['bundle_qty'] ?? 2;
    return '$qty VOOR';
  }

  final price = _parseDouble(deal['price']);
  final oldPrice = _parseDouble(deal['original_price'] ?? deal['old_price']);
  if (price != null && oldPrice != null && oldPrice > 0) {
    final pct = (((oldPrice - price) / oldPrice) * 100).round();
    if (pct > 5) return '-$pct%';
  }
  
  if (type == 'PERCENTAGE') return 'KORTING';
  
  return 'DEAL';
}

Color _badgeColor(String badge) {
  if (badge.startsWith('1+1') || badge.startsWith('2+1')) return AppColors.primary;
  if (badge.contains('HALVE')) return AppColors.tertiary;
  if (badge.startsWith('-')) return const Color(0xFF2E7D32); // deep green
  return AppColors.tertiary;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

// ─── SCREEN ──────────────────────────────────────────────────────────────────

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final ScrollController _scroll = ScrollController();
  bool _headerBlurred = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final blurred = _scroll.offset > 20;
      if (blurred != _headerBlurred) setState(() => _headerBlurred = blurred);

      // Trigger pagination when within 300 pixels of the bottom
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) {
        ref.read(thisWeekDiscountsProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(locationCityProvider);
    final activeStore = ref.watch(activeStoreProvider);
    final filteredAsync = ref.watch(filteredDiscountsProvider);
    final weeklyAsync = ref.watch(thisWeekDiscountsProvider);
    // Weekly deals are used directly in _HeroBento

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () async => ref.invalidate(thisWeekDiscountsProvider),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),

                // Top spacing under floating header
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Supermarket chips
                SliverToBoxAdapter(
                  child: _StoreBar(
                    activeStore: activeStore,
                    onSelect: (label) => ref
                        .read(activeStoreProvider.notifier)
                        .setStore(label),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),


                // Hero bento
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _HeroBento(
                      weeklyDeals: weeklyAsync.value,
                      onWatchlistTap: () =>
                          ref.read(navIndexProvider.notifier).setIndex(2),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),

                // Section header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          activeStore == 'Alle'
                              ? 'Populaire Aanbiedingen'
                              : '$activeStore Aanbiedingen',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        filteredAsync.maybeWhen(
                          data: (deals) => Text(
                            '${deals.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          orElse: () => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Deal grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: filteredAsync.when(
                    loading: () => SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.64, // Further increased vertical space
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => const DealCardShimmer(),
                        childCount: 6,
                      ),
                    ),
                    error: (e, _) => _ErrorBanner(
                      message: e.toString(),
                      onRetry: () =>
                          ref.refresh(thisWeekDiscountsProvider.future),
                    ),
                    data: (deals) {
                      if (deals.isEmpty) {
                        return _EmptyCategory(
                          category: activeStore,
                          onReset: () => ref
                              .read(activeStoreProvider.notifier)
                              .setStore('Alle'),
                        );
                      }
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final deal =
                                deals[index] as Map<String, dynamic>;
                            final name = deal['product']?.toString() ??
                                deal['product_name']?.toString() ??
                                'Onbekend';
                            // Use the slug for watchlist ID so backend can match it
                            final slug = deal['product_slug']?.toString() ?? name;
                            final store =
                                deal['supermarket']?.toString() ?? '';
                            final dist = deal['distance_km'] != null
                                ? '${deal['distance_km']}km'
                                : 'Dichtbij';
                            
                            final priceVal = _parseDouble(deal['price']);
                            final price = priceVal?.toStringAsFixed(2) ?? '--';
                            final hasOptions = (deal['deal_options'] as List?)?.isNotEmpty ?? false;
                            final displayPrice = hasOptions ? 'Vanaf €$price' : (priceVal != null ? '€$price' : (deal['deal_label']?.toString() ?? '--'));

                            final oldPrice = _parseDouble(deal['original_price'] ?? deal['old_price']);
                            final badge = _dealBadge(deal);
                            final unitLabel = deal['unit_label']?.toString();
                            final endDate = deal['end_date']?.toString();
                            
                            double? savings;
                            if (priceVal != null && oldPrice != null && oldPrice > priceVal) {
                              savings = oldPrice - priceVal;
                            }

                            var imageUrl = deal['image_url']?.toString();
                            if (imageUrl != null && imageUrl.startsWith('//')) {
                              imageUrl = 'https:$imageUrl';
                            }

                            return _DealGridCard(
                              title: name,
                              subtitle: '${store.toUpperCase()} • $dist',
                              price: displayPrice,
                              oldPrice: oldPrice != null
                                  ? '€${oldPrice.toStringAsFixed(2)}'
                                  : null,
                              unitLabel: unitLabel,
                              savings: savings != null ? 'Bespaar €${savings.toStringAsFixed(2)}' : null,
                              badgeText: badge,
                              badgeColor: _badgeColor(badge),
                              storeColor: _storeColor(store),
                              imageUrl: imageUrl,
                              endDate: endDate,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DealDetailScreen(deal: deal),
                                  ),
                                );
                              },
                              onAddToWatchlist: () {
                                ref.read(watchlistNotifierProvider.notifier).add(
                                  CatalogItem(
                                    id: slug, 
                                    name: name, 
                                    supermarket: store,
                                    originalPrice: oldPrice,
                                    unitLabel: unitLabel,
                                    endDate: endDate,
                                  )
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✅ "$name" aan lijst toegevoegd!'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: deals.length,
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.65,
                        ),
                      );
                    },
                  ),
                ),

                // Load-more spinner — visible when fetching the next page
                SliverToBoxAdapter(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final notifier = ref.read(thisWeekDiscountsProvider.notifier);
                      if (!notifier.isLoadingMore && !notifier.hasMore) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 32, top: 8),
                          child: Center(
                            child: Text('✅ Dat is alles!', style: TextStyle(color: AppColors.outline, fontSize: 13)),
                          ),
                        );
                      }
                      if (notifier.isLoadingMore) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                        );
                      }
                      return const SizedBox(height: 120);
                    },
                  ),
                ),
              ],
            ),
          ),

          // ── Floating header (blur on scroll) ───────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _headerBlurred
                    ? AppColors.background.withAlpha(220)
                    : AppColors.background.withAlpha(0),
              ),
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: _headerBlurred ? 12 : 0,
                    sigmaY: _headerBlurred ? 12 : 0,
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                      child: _SearchBar(
                        city: city,
                        onTap: () => showCatalogSearchSheet(context),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SEARCH BAR ──────────────────────────────────────────────────────────────

class _SearchBar extends ConsumerWidget {
  final String city;
  final VoidCallback onTap;
  const _SearchBar({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (val) => ref.read(homeFeedSearchQueryProvider.notifier).setQuery(val),
                    decoration: const InputDecoration(
                      hintText: 'Zoek naar producten...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    style: const TextStyle(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onTap, // Still opens catalog search if needed
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.onSecondaryContainer, size: 16),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'JE LOKALE ${city.toUpperCase()} STORE',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer, letterSpacing: 1.0),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}



// ─── STORE BAR ───────────────────────────────────────────────────────────────

class _StoreBar extends StatelessWidget {
  final String activeStore;
  final ValueChanged<String> onSelect;

  const _StoreBar({required this.activeStore, required this.onSelect});

  static const List<Map<String, dynamic>> _stores = [
    {'label': 'Alle', 'icon': Icons.all_inclusive_rounded},
    {'label': 'Albert Heijn', 'icon': Icons.shopping_basket_rounded},
    {'label': 'Jumbo', 'icon': Icons.store_rounded},
    {'label': 'Aldi', 'icon': Icons.discount_rounded},
    {'label': 'Lidl', 'icon': Icons.flash_on_rounded},
    {'label': 'Plus', 'icon': Icons.add_circle_rounded},
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _stores.map((store) {
          final isActive = store['label'] == activeStore;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelect(store['label'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      store['icon'] as IconData,
                      size: 18,
                      color: isActive
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      store['label'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppColors.onPrimaryContainer
                            : AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── HERO BENTO ──────────────────────────────────────────────────────────────

class _HeroBento extends StatelessWidget {
  final List<dynamic>? weeklyDeals;
  final VoidCallback onWatchlistTap;

  const _HeroBento({
    required this.weeklyDeals,
    required this.onWatchlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasDeals = weeklyDeals != null && weeklyDeals!.isNotEmpty;
    final primaryDeal = hasDeals ? weeklyDeals![0] as Map<String, dynamic> : null;
    final secondaryDeal = (hasDeals && weeklyDeals!.length > 1) ? weeklyDeals![1] as Map<String, dynamic> : null;

    final heroTitle = primaryDeal != null 
        ? (primaryDeal['product']?.toString() ?? primaryDeal['product_name']?.toString() ?? 'Mega Deal') 
        : 'Verse Hollandse Aardbeien';
    final heroSubtitle = primaryDeal != null ? '500 gram • Zoet en sappig van de lokale teler' : '500 gram • Zoet en sappig van de lokale teler';
    final heroPrice = primaryDeal != null ? _parseDouble(primaryDeal['price'])?.toStringAsFixed(2) ?? '2.49' : '2.49';
    final heroOldPrice = primaryDeal != null ? _parseDouble(primaryDeal['old_price'])?.toStringAsFixed(2) ?? '4.99' : '4.99';
    final heroImg = primaryDeal?['image_url']?.toString() ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuCmwV_NAj9y2JLv4AYdlAl_KoJetxnMLaOgiFLskwZ3NxwZim4COZzQwx8U1972tetSYUFJe6GaXjDXlw8aCHKK-N5d2-rE6IlXGKuh8v3VsQi-7MTdxXa38tDqvOy2-ogLUE-Jk9mbqLVVLGXCg0EWmwM_jO3bWBRoet3AtVkUiC9HwQfvBUWMQjCDh2ja637rGRWXV_llI7E2AQ7H1pwbzfKT1j0jDdulaMZG0_iV23lReySljtWIlQJ077PGVz-fuESD4MtztEWM';

    final secTitle = secondaryDeal != null 
        ? (secondaryDeal['product']?.toString() ?? secondaryDeal['product_name']?.toString() ?? 'Lidl Favoriet') 
        : 'Biologische Olijfolie';
    final secStore = secondaryDeal?['supermarket']?.toString() ?? 'Lidl Favoriet';
    final secImg = secondaryDeal?['image_url']?.toString() ?? 'https://lh3.googleusercontent.com/aida-public/AB6AXuCEflAnx9828lkcnI-5bAnLUHRpGfEgZitFxsXmpFf5i6RV6aJKire5jaY8KuSwOna9ND9A27pGQ9hQCh3UpXZnlB4dpTDvChcbIog3_JjkasrxFNySYIiZTFqxMTA2NXXPikGN4V7rWqw_17g3pCZ4dF8odnNT3yVplczsEsbn_4qT0wW8Hr9mMqa8tdr5KQuTL6bSzPvLCtbD1BxIoFBxoFGfZ7nskiYzo7YO1bsMdd4OmN_dEiksOh-YP8U17BoedH-31rBR-L1L';

    return LayoutBuilder(builder: (context, constraints) {
      final isDesktop = constraints.maxWidth > 600;
      final heroWidget = Container(
        height: 380,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(32),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(43, 47, 48, 0.06),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              bottom: -20,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.network(heroImg, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('MEGA DEAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onTertiaryContainer, letterSpacing: 1.5)),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 250,
                      child: Text(
                        heroTitle,
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.onSurface, height: 1.1),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(heroSubtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.onSurfaceVariant)),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('€ $heroOldPrice', style: const TextStyle(fontSize: 16, decoration: TextDecoration.lineThrough, color: AppColors.outline, fontWeight: FontWeight.w500)),
                        Text('€ $heroPrice', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.tertiary, height: 1.0)),
                      ],
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: primaryDeal == null ? null : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DealDetailScreen(deal: primaryDeal),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryContainer,
                        foregroundColor: AppColors.onPrimaryContainer,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Nu Bekijken', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    )
                  ],
                )
              ],
            ),
          ],
        ),
      );

      final secondaryWidget = Container(
        height: 380,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(secStore.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer.withAlpha(180), letterSpacing: 1.5)),
                const SizedBox(height: 4),
                Text(secTitle, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onSecondaryContainer, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: AppColors.tertiary, borderRadius: BorderRadius.circular(12)),
              child: const Text('2e HALVE PRIJS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
            ),
            Center(
              child: SizedBox(
                height: 140,
                child: Image.network(secImg, fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
            )
          ],
        ),
      );

      if (isDesktop) {
        return Row(
          children: [
            Expanded(flex: 7, child: heroWidget),
            const SizedBox(width: 24),
            Expanded(flex: 5, child: secondaryWidget),
          ],
        );
      } else {
        return Column(
          children: [
            heroWidget,
            const SizedBox(height: 24),
            secondaryWidget,
          ],
        );
      }
    });
  }
}

// ─── DEAL GRID CARD ──────────────────────────────────────────────────────────

class _DealGridCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String price;
  final String? oldPrice;
  final String? unitLabel;
  final String? savings;
  final String badgeText;
  final Color badgeColor;
  final Color storeColor;
  final String? imageUrl;
  final String? endDate;
  final VoidCallback onAddToWatchlist;
  final VoidCallback onTap;

  const _DealGridCard({
    required this.title,
    required this.subtitle,
    required this.price,
    this.oldPrice,
    this.unitLabel,
    this.savings,
    required this.badgeText,
    required this.badgeColor,
    required this.storeColor,
    this.imageUrl,
    this.endDate,
    required this.onAddToWatchlist,
    required this.onTap,
  });

  @override
  State<_DealGridCard> createState() => _DealGridCardState();
}

class _DealGridCardState extends State<_DealGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: widget.onAddToWatchlist,
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _isHovered ? widget.storeColor.withValues(alpha: 0.2) : Colors.transparent,
              width: 2,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image & Badge Section ---
              Expanded(
                flex: 10,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Colors.white),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Hero(
                          tag: 'deal_image_${widget.title}',
                          child: AnimatedScale(
                            scale: _isHovered ? 1.05 : 1.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                            child: widget.imageUrl != null 
                                ? Image.network(
                                    widget.imageUrl!.startsWith('//') ? 'https:${widget.imageUrl}' : widget.imageUrl!, 
                                    fit: BoxFit.contain,
                                    loadingBuilder: (ctx, child, progress) {
                                      if (progress == null) return child;
                                      return Container(
                                        color: AppColors.surfaceContainerHighest.withAlpha(80),
                                        child: const Center(
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (c,e,s) => _fallbackIcon(),
                                  )
                                : _fallbackIcon(),
                          ),
                        ),
                      ),
                    ),
                    // Deal Type Badge (Premium pill style)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.badgeColor.withAlpha(100),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.badgeText,
                          style: const TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.w900, 
                            color: Colors.white, 
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // Validity Indicator (Urgency)
                    if (widget.endDate != null)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(150),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'T/M ZONDAG', // Simplified for demo, logic can be added later
                            style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // --- Content Section ---
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.subtitle.split(' • ').first, 
                            style: TextStyle(
                              fontSize: 9, 
                              fontWeight: FontWeight.w900, 
                              color: widget.storeColor, 
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.title, 
                            style: const TextStyle(
                              fontSize: 13, 
                              fontWeight: FontWeight.bold, 
                              color: AppColors.onSurface, 
                              height: 1.2,
                            ), 
                            maxLines: 2, 
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.unitLabel != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.unitLabel!,
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                      
                      const Spacer(),
                      
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.savings != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Text(
                                widget.savings!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                // Detect if this is a numeric price or a deal label
                                Builder(builder: (context) {
                                  final isNumeric = widget.price.contains('€');
                                  final isMissing = widget.price == '--';
                                return Text(
                                  widget.price,
                                  style: TextStyle(
                                    fontSize: isNumeric ? 20 : (isMissing ? 16 : 13),
                                    fontWeight: FontWeight.w900,
                                    color: isNumeric
                                        ? AppColors.tertiary
                                        : isMissing
                                            ? AppColors.onSurfaceVariant
                                            : AppColors.primary,
                                    letterSpacing: isNumeric ? -0.5 : 0.2,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                );
                              }),
                              if (widget.oldPrice != null) ...[
                                const SizedBox(width: 6),
                                Text(
                                  widget.oldPrice!, 
                                  style: const TextStyle(
                                    fontSize: 12, 
                                    decoration: TextDecoration.lineThrough, 
                                    color: AppColors.outline,
                                  ),
                                ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackIcon() {
    return Center(
      child: Icon(
        Icons.shopping_basket_rounded, 
        color: widget.storeColor.withAlpha(40), 
        size: 40,
      ),
    );
  }
}



// ─── EMPTY & ERROR STATES ────────────────────────────────────────────────────

class _EmptyCategory extends StatelessWidget {
  final String category;
  final VoidCallback onReset;

  const _EmptyCategory({required this.category, required this.onReset});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 40, color: AppColors.outline),
            const SizedBox(height: 12),
            Text(
              'Geen "$category" deals gevonden',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onReset,
              child: const Text('Toon alle deals'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withAlpha(30),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Kon deals niet laden',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Opnieuw'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
