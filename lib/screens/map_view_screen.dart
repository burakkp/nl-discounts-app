// lib/screens/map_view_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../models/catalog_item.dart';
import '../theme/app_theme.dart';
import 'catalog_search_sheet.dart';

// ─── STORE DATA HELPERS ──────────────────────────────────────────────────────

const Map<String, Color> _storeColors = {
  'albert heijn': Color(0xFF00A0E2),
  'ah':           Color(0xFF00A0E2),
  'jumbo':        Color(0xFFFFD800),
  'lidl':         Color(0xFF0050AA),
  'aldi':         Color(0xFF1A3A6B),
  'plus':         Color(0xFF00873D),
};

Color _colorForStore(String name) {
  final key = name.toLowerCase();
  for (final e in _storeColors.entries) {
    if (key.contains(e.key)) return e.value;
  }
  return AppColors.primary;
}

String _initials(String name) {
  final words = name.trim().split(' ');
  if (words.length >= 2) return '${words[0][0]}${words[1][0]}'.toUpperCase();
  if (name.length >= 2) return name.substring(0, 2).toUpperCase();
  return name.toUpperCase();
}

// Groups deals by supermarket name
Map<String, List<Map<String, dynamic>>> _groupByStore(
    List<dynamic> deals) {
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (final deal in deals) {
    final d = deal as Map<String, dynamic>;
    final store =
        d['supermarket']?.toString() ?? d['store']?.toString() ?? 'Onbekend';
    grouped.putIfAbsent(store, () => []).add(d);
  }
  return grouped;
}

double? _parseDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  return double.tryParse(v.toString());
}

String _dealBadge(Map<String, dynamic> deal) {
  final type = deal['deal_type']?.toString().toLowerCase() ?? '';
  if (type.contains('1+1')) return '1+1';
  if (type.contains('2+1')) return '2+1';
  final price = _parseDouble(deal['price']);
  final oldPrice = _parseDouble(deal['old_price']);
  if (price != null && oldPrice != null && oldPrice > 0) {
    final pct = (((oldPrice - price) / oldPrice) * 100).round();
    if (pct > 0) return '-$pct%';
  }
  return 'DEAL';
}

// ─── STORE FILTER PILLS ──────────────────────────────────────────────────────

const _storeFilters = [
  'Alle',
  'Albert Heijn',
  'Jumbo',
  'Lidl',
  'Aldi',
  'PLUS',
];

// ─── SCREEN ──────────────────────────────────────────────────────────────────

class MapViewScreen extends ConsumerStatefulWidget {
  const MapViewScreen({super.key});

  @override
  ConsumerState<MapViewScreen> createState() => _MapViewScreenState();
}

class _MapViewScreenState extends ConsumerState<MapViewScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _markerController;
  String _selectedStore = 'Alle';
  String? _focusedStore; // Which store bottom sheet is open for

  // Deterministic "positions" for markers on the canvas (seeded by store name)
  final Map<String, Offset> _markerPositions = {};

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _markerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
      value: 0,
    )..forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _markerController.dispose();
    super.dispose();
  }

  // Assigns stable random-ish positions to store markers within the canvas
  Offset _positionForStore(String storeName, Size canvasSize) {
    if (!_markerPositions.containsKey(storeName)) {
      final seed = storeName.codeUnits.fold(0, (a, b) => a + b);
      final rng = math.Random(seed);
      _markerPositions[storeName] = Offset(
        canvasSize.width * (0.12 + rng.nextDouble() * 0.72),
        canvasSize.height * (0.12 + rng.nextDouble() * 0.64),
      );
    }
    return _markerPositions[storeName]!;
  }

  List<Map<String, dynamic>> _filteredDeals(List<dynamic> deals) {
    if (_selectedStore == 'Alle') return deals.cast();
    return deals
        .cast<Map<String, dynamic>>()
        .where((d) =>
            (d['supermarket']?.toString() ?? '')
                .toLowerCase()
                .contains(_selectedStore.toLowerCase()))
        .toList();
  }

  void _onStoreTap(String storeName, List<Map<String, dynamic>> deals) {
    setState(() => _focusedStore = storeName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StoreDealsSheet(
        storeName: storeName,
        deals: deals,
        ref: ref,
      ),
    ).then((_) => setState(() => _focusedStore = null));
  }

  @override
  Widget build(BuildContext context) {
    final discountsAsync = ref.watch(discountsProvider);
    final city = ref.watch(locationCityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map Canvas ────────────────────────────────────────────────────
          Positioned.fill(
            child: _MapCanvas(
              discountsAsync: discountsAsync,
              selectedStore: _selectedStore,
              focusedStore: _focusedStore,
              pulseController: _pulseController,
              markerController: _markerController,
              positionForStore: _positionForStore,
              filteredDeals: _filteredDeals,
              onStoreTap: _onStoreTap,
            ),
          ),

          // ── Top filter bar (safe-area aware) ─────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // City badge + search
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // City badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest
                                  .withAlpha(230),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withAlpha(180),
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4CAF50),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.location_on_rounded,
                                  size: 14,
                                  color: AppColors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  city.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.onSurface,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Refresh button
                          GestureDetector(
                            onTap: () => ref.refresh(discountsProvider.future),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLowest
                                    .withAlpha(230),
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                size: 20,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Store filter pills
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: _storeFilters.map((label) {
                          final isActive = _selectedStore == label;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                () => _selectedStore = label,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.primary
                                      : AppColors.surfaceContainerLowest
                                          .withAlpha(220),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? AppColors.primary
                                        : Colors.white.withAlpha(180),
                                    width: 1.5,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? Colors.white
                                        : AppColors.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── FABs ─────────────────────────────────────────────────────────
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.38,
            child: Column(
              children: [
                _MapFab(
                  heroTag: 'search_map_fab',
                  icon: Icons.search_rounded,
                  onTap: () => showCatalogSearchSheet(context),
                  color: AppColors.surfaceContainerLowest,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _MapFab(
                  heroTag: 'location_map_fab',
                  icon: Icons.my_location_rounded,
                  onTap: () => ref.refresh(locationProvider.future),
                  color: AppColors.primaryContainer,
                  iconColor: AppColors.onPrimaryContainer,
                ),
              ],
            ),
          ),

          // ── Bottom sheet: store list ──────────────────────────────────────
          _StoreListSheet(
            discountsAsync: discountsAsync,
            selectedStore: _selectedStore,
            filteredDeals: _filteredDeals,
            onStoreTap: _onStoreTap,
          ),
        ],
      ),
    );
  }
}

// ─── MAP CANVAS ──────────────────────────────────────────────────────────────

class _MapCanvas extends StatelessWidget {
  final AsyncValue<List<dynamic>> discountsAsync;
  final String selectedStore;
  final String? focusedStore;
  final AnimationController pulseController;
  final AnimationController markerController;
  final Offset Function(String, Size) positionForStore;
  final List<Map<String, dynamic>> Function(List<dynamic>) filteredDeals;
  final void Function(String, List<Map<String, dynamic>>) onStoreTap;

  const _MapCanvas({
    required this.discountsAsync,
    required this.selectedStore,
    required this.focusedStore,
    required this.pulseController,
    required this.markerController,
    required this.positionForStore,
    required this.filteredDeals,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            // Map background (styled grid)
            Positioned.fill(child: _MapBackground()),

            // Gradient overlay (bottom fade for sheet)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      AppColors.background.withAlpha(180),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
            ),

            // User location dot
            Positioned(
              left: size.width * 0.48,
              top: size.height * 0.44,
              child: _AnimatedLocationDot(controller: pulseController),
            ),

            // Store markers
            ...discountsAsync.when(
              data: (deals) {
                final grouped = _groupByStore(deals);
                final filtered =
                    selectedStore == 'Alle'
                        ? grouped
                        : {
                            for (final e in grouped.entries)
                              if (e.key
                                  .toLowerCase()
                                  .contains(selectedStore.toLowerCase()))
                                e.key: e.value,
                          };

                return filtered.entries.map((entry) {
                  final pos = positionForStore(entry.key, size);
                  final isFocused = focusedStore == entry.key;
                  return Positioned(
                    left: pos.dx - 24,
                    top: pos.dy - 24,
                    child: ScaleTransition(
                      scale: CurvedAnimation(
                        parent: markerController,
                        curve: Curves.elasticOut,
                      ),
                      child: _StoreMarker(
                        storeName: entry.key,
                        dealCount: entry.value.length,
                        isFocused: isFocused,
                        onTap: () => onStoreTap(entry.key, entry.value),
                      ),
                    ),
                  );
                }).toList();
              },
              loading: () => [],
              error: (_, _) => [],
            ),
          ],
        );
      },
    );
  }
}

// ─── MAP BACKGROUND ──────────────────────────────────────────────────────────

class _MapBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MapGridPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F4F8),
              Color(0xFFDDEEF5),
              Color(0xFFD0E8F2),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(200)
      ..strokeWidth = 1;

    // Horizontal streets
    for (double y = 0; y < size.height; y += 48) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    // Vertical streets
    for (double x = 0; x < size.width; x += 64) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Some "block" fills
    final blockPaint = Paint()..color = Colors.white.withAlpha(120);
    final rng = math.Random(42);
    for (int i = 0; i < 12; i++) {
      final x = (rng.nextDouble() * (size.width - 80)).clamp(8.0, size.width - 80);
      final y = (rng.nextDouble() * (size.height - 60)).clamp(8.0, size.height - 60);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 56 + rng.nextDouble() * 40, 36 + rng.nextDouble() * 24),
          const Radius.circular(6),
        ),
        blockPaint,
      );
    }

    // A "park" blob
    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.35),
      60,
      Paint()..color = const Color(0xFF9DC8A8).withAlpha(100),
    );
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.6),
      40,
      Paint()..color = const Color(0xFF9DC8A8).withAlpha(80),
    );
  }

  @override
  bool shouldRepaint(_MapGridPainter old) => false;
}

// ─── ANIMATED LOCATION DOT ───────────────────────────────────────────────────

class _AnimatedLocationDot extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedLocationDot({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final pulse = controller.value;
        return SizedBox(
          width: 48,
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: 48 * (0.5 + pulse * 0.5),
                height: 48 * (0.5 + pulse * 0.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha((80 * (1 - pulse)).toInt()),
                  shape: BoxShape.circle,
                ),
              ),
              // White ring
              Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 8),
                  ],
                ),
              ),
              // Inner dot
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── STORE MARKER ────────────────────────────────────────────────────────────

class _StoreMarker extends StatelessWidget {
  final String storeName;
  final int dealCount;
  final bool isFocused;
  final VoidCallback onTap;

  const _StoreMarker({
    required this.storeName,
    required this.dealCount,
    required this.isFocused,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForStore(storeName);
    final label = _initials(storeName);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isFocused ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Deal count bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.tertiary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4),
                ],
              ),
              child: Text(
                '$dealCount deals',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 3),
            // Pin
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isFocused ? Colors.white : Colors.white.withAlpha(180),
                  width: isFocused ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(140),
                    blurRadius: isFocused ? 14 : 8,
                    spreadRadius: isFocused ? 2 : 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                  ),
                ),
              ),
            ),
            // Tail
            Container(
              width: 4,
              height: 6,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STORE LIST BOTTOM SHEET ─────────────────────────────────────────────────

class _StoreListSheet extends StatelessWidget {
  final AsyncValue<List<dynamic>> discountsAsync;
  final String selectedStore;
  final List<Map<String, dynamic>> Function(List<dynamic>) filteredDeals;
  final void Function(String, List<Map<String, dynamic>>) onStoreTap;

  const _StoreListSheet({
    required this.discountsAsync,
    required this.selectedStore,
    required this.filteredDeals,
    required this.onStoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.16,
      maxChildSize: 0.72,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: discountsAsync.when(
                  loading: () => _SheetSkeleton(),
                  error: (e, _) => Center(
                    child: Text(
                      'Kon winkels niet laden',
                      style: const TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  data: (deals) {
                    final grouped = _groupByStore(filteredDeals(deals));
                    if (grouped.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.store_mall_directory_outlined,
                              size: 40,
                              color: AppColors.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Geen "$selectedStore" winkels gevonden',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                      itemCount: grouped.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = grouped.entries.elementAt(index);
                        return _StoreListTile(
                          storeName: entry.key,
                          deals: entry.value,
                          onTap: () => onStoreTap(entry.key, entry.value),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── STORE LIST TILE ─────────────────────────────────────────────────────────

class _StoreListTile extends StatelessWidget {
  final String storeName;
  final List<Map<String, dynamic>> deals;
  final VoidCallback onTap;

  const _StoreListTile({
    required this.storeName,
    required this.deals,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForStore(storeName);
    final label = _initials(storeName);
    final closestDist = deals
        .map((d) => _parseDouble(d['distance_km']))
        .whereType<double>()
        .fold<double?>(null, (a, b) => a == null ? b : (b < a ? b : a));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Store icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${deals.length} aanbiedingen',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (closestDist != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '${closestDist.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── STORE DEALS BOTTOM SHEET ────────────────────────────────────────────────

class _StoreDealsSheet extends StatelessWidget {
  final String storeName;
  final List<Map<String, dynamic>> deals;
  final WidgetRef ref;

  const _StoreDealsSheet({
    required this.storeName,
    required this.deals,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForStore(storeName);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(storeName),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: color.computeLuminance() > 0.5
                          ? Colors.black87
                          : Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        storeName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${deals.length} actieve aanbiedingen',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceContainerLow,
                  ),
                  icon: const Icon(
                    Icons.directions_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.surfaceContainerLow),
          const SizedBox(height: 8),

          // Deals horizontal scroll
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              scrollDirection: Axis.vertical,
              itemCount: deals.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final deal = deals[index];
                final name = deal['product']?.toString() ??
                    deal['product_name']?.toString() ??
                    'Onbekend product';
                final price = _parseDouble(deal['price']);
                final oldPrice = _parseDouble(deal['old_price']);
                final badge = _dealBadge(deal);
                final dist = _parseDouble(deal['distance_km']);

                return _DealListTile(
                  name: name,
                  price: price,
                  oldPrice: oldPrice,
                  badge: badge,
                  distance: dist,
                  storeName: storeName,
                  onAddToWatchlist: () {
                    ref.read(watchlistNotifierProvider.notifier).add(
                          CatalogItem(id: name, name: name, supermarket: storeName),
                        );
                    Navigator.pop(context);
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
            ),
          ),
        ],
      ),
    );
  }
}

// ─── DEAL LIST TILE ──────────────────────────────────────────────────────────

class _DealListTile extends StatelessWidget {
  final String name;
  final double? price;
  final double? oldPrice;
  final String badge;
  final double? distance;
  final String storeName;
  final VoidCallback onAddToWatchlist;

  const _DealListTile({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.badge,
    required this.distance,
    required this.storeName,
    required this.onAddToWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: AppColors.outlineVariant,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (distance != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${distance!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.onSurface,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      price != null ? '€${price!.toStringAsFixed(2)}' : '--',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (oldPrice != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '€${oldPrice!.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
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

          // Add to watchlist
          GestureDetector(
            onTap: onAddToWatchlist,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: AppColors.onPrimaryContainer,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MAP FAB ─────────────────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final Color iconColor;

  const _MapFab({
    required this.heroTag,
    required this.icon,
    required this.onTap,
    required this.color,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 4,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Icon(icon, color: iconColor, size: 22),
        ),
      ),
    );
  }
}

// ─── SKELETON ────────────────────────────────────────────────────────────────

class _SheetSkeleton extends StatefulWidget {
  @override
  State<_SheetSkeleton> createState() => _SheetSkeletonState();
}

class _SheetSkeletonState extends State<_SheetSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        final t = _ctrl.value > 0.5 ? 1 - _ctrl.value : _ctrl.value;
        final color = Color.lerp(
          AppColors.surfaceContainerLow,
          AppColors.surfaceContainerHigh,
          t * 2,
        )!;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (_, _) => Container(
            height: 80,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
