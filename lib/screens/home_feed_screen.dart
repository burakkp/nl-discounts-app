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
    final discountsAsync  = ref.watch(discountsProvider);      // raw, for hero
    final watchlistAsync  = ref.watch(watchlistNotifierProvider);

    // Count watchlist items that currently have an active deal
    final dropCount = watchlistAsync.value
            ?.where((i) => i.hasActiveDeal)
            .length ??
        0;

    // Best live deal for hero (first item from full unfiltered list)
    final heroDeal = discountsAsync.value?.isNotEmpty == true
        ? discountsAsync.value!.first as Map<String, dynamic>
        : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          RefreshIndicator(
            onRefresh: () => ref.refresh(discountsProvider.future),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scroll,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 100)),

                // City badge + categories
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _LocationBadge(city: city),
                  ),
                ),
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
                      heroDeal: heroDeal,
                      dropCount: dropCount,
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
                    error: (e, _) => SliverToBoxAdapter(
                      child: _ErrorBanner(
                        message: e.toString(),
                        onRetry: () =>
                            ref.refresh(discountsProvider.future),
                      ),
                    ),
                    data: (deals) {
                      if (deals.isEmpty) {
                        return SliverToBoxAdapter(
                          child: _EmptyCategory(
                            category: activeCategory,
                            onReset: () => ref
                                .read(activeCategoryProvider.notifier)
                                .setCategory('Alle'),
                          ),
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
                              onAddToWatchlist: () {
                                ref
                                    .read(watchlistNotifierProvider.notifier)
                                    .add(CatalogItem(id: name, name: name, supermarket: store));
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
  final VoidCallback onTap;
  const _SearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.outlineVariant.withAlpha(120),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.outline),
                  SizedBox(width: 12),
                  Text(
                    'Zoek naar producten...',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.onSecondaryContainer,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── LOCATION BADGE ──────────────────────────────────────────────────────────

class _LocationBadge extends StatelessWidget {
  final String city;
  const _LocationBadge({required this.city});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'JE LOKALE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              city.toUpperCase(),
              key: ValueKey(city),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppColors.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 6),
          const Text(
            'DEALS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
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
                  horizontal: 20, vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.onSurface
                      : AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? Colors.transparent
                        : AppColors.outlineVariant.withAlpha(80),
                  ),
                  boxShadow: isActive
                      ? const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat.icon,
                      size: 16,
                      color: isActive
                          ? AppColors.surface
                          : AppColors.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat.label,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? AppColors.surface
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
  final Map<String, dynamic>? heroDeal;
  final int dropCount;
  final VoidCallback onWatchlistTap;

  const _HeroBento({
    required this.heroDeal,
    required this.dropCount,
    required this.onWatchlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final productName = heroDeal != null
        ? (heroDeal!['product']?.toString() ??
            heroDeal!['product_name']?.toString() ??
            'Top Deal')
        : 'Top Deal';

    final badge = heroDeal != null ? _dealBadge(heroDeal!) : 'DEAL';
    final price = heroDeal != null ? _parseDouble(heroDeal!['price']) : null;
    final store = heroDeal?['supermarket']?.toString() ?? '';

    // Truncate long product names to 2 words for the hero card
    final heroTitle = productName.split(' ').take(2).join('\n');

    return Row(
      children: [
        // Mega deal card
        Expanded(
          flex: 6,
          child: Container(
            height: 210,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.orange600],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(220),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (store.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(60),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          store.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Spacer(),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Text(
                    heroTitle,
                    key: ValueKey(heroTitle),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                if (price != null)
                  Text(
                    '€${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -2,
                    ),
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      const Text(
                        '1+1',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GRATIS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withAlpha(200),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Watchlist shortcut card
        Expanded(
          flex: 4,
          child: GestureDetector(
            onTap: onWatchlistTap,
            child: Container(
              height: 210,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.tertiary,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Jouw\nLijst',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.onSecondaryContainer,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      dropCount > 0
                          ? '$dropCount PRIJSDROPS'
                          : 'GEEN DROPS',
                      key: ValueKey(dropCount),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
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
  final VoidCallback onAddToWatchlist;

  const _DealGridCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.oldPrice,
    required this.badgeText,
    required this.badgeColor,
    required this.storeColor,
    required this.onAddToWatchlist,
  });

  @override
  State<_DealGridCard> createState() => _DealGridCardState();
}

class _DealGridCardState extends State<_DealGridCard> {
  bool _showAdd = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => setState(() => _showAdd = !_showAdd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(28),
          border: _showAdd
              ? Border.all(color: AppColors.primary.withAlpha(120), width: 2)
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image area — store color accent background
                Expanded(
                  flex: 5,
                  child: Container(
                    width: double.infinity,
                    color: widget.storeColor.withAlpha(18),
                    child: Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.shopping_basket_rounded,
                            size: 52,
                            color: widget.storeColor.withAlpha(90),
                          ),
                        ),
                        // Store color bar at bottom of image area
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            height: 3,
                            color: widget.storeColor.withAlpha(180),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Info area
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                height: 1.2,
                                color: AppColors.onSurface,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              widget.price,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                color: widget.price == '--'
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.primary,
                              ),
                            ),
                            if (widget.oldPrice.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                widget.oldPrice,
                                style: const TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Deal badge
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  widget.badgeText,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),

            // Long-press add-to-watchlist overlay
            AnimatedOpacity(
              opacity: _showAdd ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    widget.onAddToWatchlist();
                    setState(() => _showAdd = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
          border: Border.all(color: AppColors.error.withAlpha(80)),
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
