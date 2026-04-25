// lib/screens/home_feed_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/catalog_item.dart';
import '../theme/app_theme.dart';
import 'catalog_search_sheet.dart';

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
  final type = deal['deal_type']?.toString().toLowerCase() ?? '';
  if (type.contains('1+1') || type.contains('een plus een')) return '1+1';
  if (type.contains('2+1')) return '2+1';
  if (type.contains('2de') || type.contains('tweede')) return '2e HALVE PRIJS';
  final price = _parseDouble(deal['price']);
  final oldPrice = _parseDouble(deal['old_price']);
  if (price != null && oldPrice != null && oldPrice > 0) {
    final pct = (((oldPrice - price) / oldPrice) * 100).round();
    if (pct > 0) return '-$pct%';
  }
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

// ─── CATEGORIES ──────────────────────────────────────────────────────────────

const List<_CategoryDef> _categories = [
  _CategoryDef('Alle',    Icons.whatshot_rounded),
  _CategoryDef('Vers',    Icons.eco_rounded),
  _CategoryDef('Pantry',  Icons.kitchen_rounded),
  _CategoryDef('Drinken', Icons.local_drink_rounded),
  _CategoryDef('Huis',    Icons.home_rounded),
];

class _CategoryDef {
  final String label;
  final IconData icon;
  const _CategoryDef(this.label, this.icon);
}

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
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final city            = ref.watch(locationCityProvider);
    final activeCategory  = ref.watch(activeCategoryProvider);
    final filteredAsync   = ref.watch(filteredDiscountsProvider);
    final weeklyAsync     = ref.watch(thisWeekDiscountsProvider);
    // Weekly deals are used directly in _HeroBento

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () => ref.refresh(thisWeekDiscountsProvider.future),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),

                // Top spacing under floating header
                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Category chips
                SliverToBoxAdapter(
                  child: _CategoryBar(
                    activeCategory: activeCategory,
                    onSelect: (label) => ref
                        .read(activeCategoryProvider.notifier)
                        .setCategory(label),
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
                          activeCategory == 'Alle'
                              ? 'Populaire Aanbiedingen'
                              : '$activeCategory Aanbiedingen',
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
                    loading: () => const _SkeletonGrid(),
                    error: (e, _) => _ErrorBanner(
                      message: e.toString(),
                      onRetry: () =>
                          ref.refresh(thisWeekDiscountsProvider.future),
                    ),
                    data: (deals) {
                      if (deals.isEmpty) {
                        return _EmptyCategory(
                          category: activeCategory,
                          onReset: () => ref
                              .read(activeCategoryProvider.notifier)
                              .setCategory('Alle'),
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
                            final price = _parseDouble(deal['price']);
                            final oldPrice = _parseDouble(deal['old_price']);
                            final badge = _dealBadge(deal);

                            return _DealGridCard(
                              title: name,
                              subtitle: '${store.toUpperCase()} • $dist',
                              price: price != null
                                  ? '€${price.toStringAsFixed(2)}'
                                  : '--',
                              oldPrice: oldPrice != null
                                  ? '€${oldPrice.toStringAsFixed(2)}'
                                  : '',
                              badgeText: badge,
                              badgeColor: _badgeColor(badge),
                              storeColor: _storeColor(store),
                              imageUrl: deal['image_url']?.toString(),
                              onAddToWatchlist: () {
                                ref
                                    .read(watchlistNotifierProvider.notifier)
                                    .add(CatalogItem(id: slug, name: name, supermarket: store));
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

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
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

class _SearchBar extends StatelessWidget {
  final String city;
  final VoidCallback onTap;
  const _SearchBar({required this.city, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.outline),
                  SizedBox(width: 12),
                  Text('Zoek naar producten...', style: TextStyle(color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
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
              Text('JE LOKALE ${city.toUpperCase()} STORE', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.onSecondaryContainer, letterSpacing: 1.0)),
            ],
          ),
        ),
      ],
    );
  }
}



// ─── CATEGORY BAR ────────────────────────────────────────────────────────────

class _CategoryBar extends StatelessWidget {
  final String activeCategory;
  final ValueChanged<String> onSelect;

  const _CategoryBar({required this.activeCategory, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: _categories.map((cat) {
          final isActive = cat.label == activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelect(cat.label),
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
                      cat.icon,
                      size: 18,
                      color: isActive
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.label,
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
                      onPressed: () {},
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
            Positioned(
              right: -40,
              bottom: -20,
              child: SizedBox(
                width: 200,
                height: 200,
                child: Image.network(heroImg, fit: BoxFit.cover, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
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
  final String oldPrice;
  final String badgeText;
  final Color badgeColor;
  final Color storeColor;
  final String? imageUrl;
  final VoidCallback onAddToWatchlist;

  const _DealGridCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.badgeText,
    required this.badgeColor,
    required this.storeColor,
    this.imageUrl,
    required this.onAddToWatchlist,
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
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surfaceContainerHigh : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and badge container
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedScale(
                          scale: _isHovered ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          child: widget.imageUrl != null 
                              ? Image.network(widget.imageUrl!, fit: BoxFit.contain, errorBuilder: (c,e,s) => Center(child: Icon(Icons.shopping_basket_rounded, color: widget.storeColor.withAlpha(50), size: 40)))
                              : Center(child: Icon(Icons.shopping_basket_rounded, color: widget.storeColor.withAlpha(50), size: 40)),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -4,
                      left: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.badgeText,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Text Content
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.subtitle.split(' • ').first, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.storeColor, letterSpacing: 1.5, height: 1.0)),
                        const SizedBox(height: 4),
                        Text(widget.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.onSurface, height: 1.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(widget.subtitle.split(' • ').last, style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant)),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(widget.price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: widget.price == '--' ? AppColors.onSurfaceVariant : AppColors.tertiary)),
                        if (widget.oldPrice.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(widget.oldPrice, style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: AppColors.outline)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SKELETON GRID ───────────────────────────────────────────────────────────

class _SkeletonGrid extends StatefulWidget {
  const _SkeletonGrid();

  @override
  State<_SkeletonGrid> createState() => _SkeletonGridState();
}

class _SkeletonGridState extends State<_SkeletonGrid>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverGrid(
      delegate: SliverChildBuilderDelegate(
        (context, index) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value > 0.5
                ? 1 - _controller.value
                : _controller.value;
            final color = Color.lerp(
              AppColors.surfaceContainerLow,
              AppColors.surfaceContainerHigh,
              t * 2,
            )!;
            return Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(28),
              ),
            );
          },
        ),
        childCount: 6,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.65,
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
