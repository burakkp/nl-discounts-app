// lib/screens/map_view_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  final type = deal['deal_type']?.toString().toUpperCase() ?? '';
  final raw = deal['original_deal_string']?.toString().toLowerCase() ?? '';

  if (type == 'BOGO' || raw.contains('1+1') || raw.contains('gratis')) {
    if (raw.contains('2+1')) return '2+1 GRATIS';
    return '1+1 GRATIS';
  }
  if (type == 'HALF_PRICE_2ND' || raw.contains('halve prijs')) return '2e HALVE PRIJS';
  
  final price = _parseDouble(deal['price']);
  final oldPrice = _parseDouble(deal['original_price'] ?? deal['old_price']);
  if (price != null && oldPrice != null && oldPrice > 0) {
    final pct = (((oldPrice - price) / oldPrice) * 100).round();
    if (pct > 5) return '-$pct%';
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
  GoogleMapController? _mapController;
  String _selectedStore = 'Alle';
  String? _focusedStore;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _mapController = controller;
    
    // Smoothly animate to user location on start
    final pos = await ref.read(locationProvider.future);
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(pos.latitude, pos.longitude),
        14.0,
      ),
    );
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
    final rawStoresAsync = ref.watch(nearbyStoresProvider);
    final storesAsync = rawStoresAsync.whenData((stores) {
      if (_selectedStore == 'Alle') return stores;
      return stores.where((s) {
        final chain = (s['chain_name']?.toString() ?? '').toLowerCase();
        final selected = _selectedStore.toLowerCase();
        return chain.contains(selected);
      }).toList();
    });
    final locationAsync = ref.watch(locationProvider);
    final city = ref.watch(locationCityProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Real Google Map ──────────────────────────────────────────────
          Positioned.fill(
            child: locationAsync.when(
              data: (pos) => GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(pos.latitude, pos.longitude),
                  zoom: 14,
                ),
                onMapCreated: _onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                markers: storesAsync.when(
                  data: (stores) {
                    return stores.map((s) {
                      final lat = s['latitude'] as double;
                      final lng = s['longitude'] as double;
                      final name = s['chain_name'] as String;
                      final hits = s['watchlist_hits'] as int;

                      return Marker(
                        markerId: MarkerId(s['id'].toString()),
                        position: LatLng(lat, lng),
                        infoWindow: InfoWindow(
                          title: name,
                          snippet: hits > 0 ? '$hits watchlist deals!' : 'Tap to view deals',
                        ),
                        icon: hits > 0 
                          ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
                          : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
                        onTap: () {
                          // We still need the deals for this store. 
                          // For now, we'll fetch them from the overall deals provider 
                          // or just show the sheet with what we have.
                          final allDeals = ref.read(discountsProvider).value ?? [];
                          final storeDeals = allDeals.where((d) => 
                            (d['supermarket']?.toString() ?? '').toLowerCase() == name.toLowerCase()
                          ).toList().cast<Map<String, dynamic>>();
                          
                          _onStoreTap(name, storeDeals);
                        },
                      );
                    }).toSet();
                  },
                  loading: () => {},
                  error: (_, __) => {},
                ),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Map Error: $err')),
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
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(43, 47, 48, 0.06),
                                  blurRadius: 32,
                                  offset: Offset(0, 12),
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
                                    color: Color.fromRGBO(43, 47, 48, 0.06),
                                    blurRadius: 32,
                                    offset: Offset(0, 12),
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
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(43, 47, 48, 0.06),
                                      blurRadius: 32,
                                      offset: Offset(0, 12),
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
            bottom: MediaQuery.of(context).size.height * 0.42,
            child: Column(
              children: [
                _MapFab(
                  heroTag: 'search_map_fab',
                  icon: Icons.storefront_rounded,
                  onTap: () {
                    // Quick store chain filter sheet
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: AppColors.background,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Filter op supermarkt',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 12,
                              children: _storeFilters.map((label) {
                                final isActive = _selectedStore == label;
                                return ChoiceChip(
                                  label: Text(label),
                                  selected: isActive,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedStore = label);
                                      Navigator.pop(context);
                                    }
                                  },
                                  selectedColor: AppColors.primary,
                                  labelStyle: TextStyle(
                                    color: isActive ? Colors.white : AppColors.onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    );
                  },
                  color: AppColors.surfaceContainerLowest,
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 12),
                _MapFab(
                  heroTag: 'location_map_fab',
                  icon: Icons.my_location_rounded,
                  onTap: () async {
                    if (_mapController == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Wachten op kaart...')),
                      );
                      return;
                    }
                    try {
                      final pos = await ref.read(locationProvider.future);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(pos.latitude, pos.longitude),
                          14.0,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Locatie niet gevonden: $e')),
                      );
                    }
                  },
                  color: AppColors.primaryContainer,
                  iconColor: AppColors.onPrimaryContainer,
                ),
              ],
            ),
          ),

          // ── Bottom sheet: store list ──────────────────────────────────────
          _StoreListSheet(
            storesAsync: storesAsync,
            onStoreTap: _onStoreTap,
            ref: ref,
          ),
        ],
      ),
    );
  }
}



// ─── STORE LIST BOTTOM SHEET ─────────────────────────────────────────────────

class _StoreListSheet extends StatelessWidget {
  final AsyncValue<List<dynamic>> storesAsync;
  final void Function(String, List<Map<String, dynamic>>) onStoreTap;
  final WidgetRef ref;

  const _StoreListSheet({
    required this.storesAsync,
    required this.onStoreTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.22, // Increased to clear the floating nav bar
      minChildSize: 0.18,     // Increased to clear the floating nav bar
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background.withAlpha(245),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outlineVariant.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Winkels in de buurt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    storesAsync.maybeWhen(
                      data: (stores) => Text(
                        '${stores.length} gevonden',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      orElse: () => const SizedBox(),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: storesAsync.when(
                  data: (stores) {
                    if (stores.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.storefront_outlined, size: 48, color: AppColors.outline),
                            const SizedBox(height: 16),
                            const Text('Geen winkels gevonden in dit gebied'),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: stores.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final s = stores[index];
                        final name = s['chain_name'] as String;
                        final address = s['address'] as String;
                        final dist = s['distance_km'] as double;
                        final hits = s['watchlist_hits'] as int;

                        return _StoreListTile(
                          storeName: name,
                          address: address,
                          distance: dist,
                          watchlistHits: hits,
                          onTap: () {
                            // Fetch deals for this store from the main discounts provider
                            final allDeals = ref.read(discountsProvider).value ?? [];
                            final storeDeals = allDeals.where((d) => 
                              (d['supermarket']?.toString() ?? '').toLowerCase() == name.toLowerCase()
                            ).toList().cast<Map<String, dynamic>>();
                            
                            onStoreTap(name, storeDeals);
                          },
                        );
                      },
                    );
                  },
                  loading: () => _SheetSkeleton(),
                  error: (err, _) => Center(child: Text('Fout bij laden winkels: $err')),
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
  final String address;
  final double distance;
  final int watchlistHits;
  final VoidCallback onTap;

  const _StoreListTile({
    required this.storeName,
    required this.address,
    required this.distance,
    required this.watchlistHits,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForStore(storeName);
    final label = _initials(storeName);

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
            // Store icon with optional badge
            Stack(
              clipBehavior: Clip.none,
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
                if (watchlistHits > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: const Text(
                        '🔥',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
              ],
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
                  const SizedBox(height: 2),
                  Text(
                    address,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (watchlistHits > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$watchlistHits watchlist items!',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
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
                final unitLabel = deal['unit_label']?.toString();

                return _DealListTile(
                  name: name,
                  price: price,
                  oldPrice: oldPrice,
                  badge: badge,
                  unitLabel: unitLabel,
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
  final String? unitLabel;
  final double? distance;
  final String storeName;
  final VoidCallback onAddToWatchlist;

  const _DealListTile({
    required this.name,
    required this.price,
    required this.oldPrice,
    required this.badge,
    this.unitLabel,
    required this.distance,
    required this.storeName,
    required this.onAddToWatchlist,
  });

  @override
  Widget build(BuildContext context) {
    double? savings;
    if (price != null && oldPrice != null && oldPrice! > price!) {
      savings = oldPrice! - price!;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.04),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Placeholder (could be store logo)
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
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
                if (unitLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      unitLabel!,
                      style: const TextStyle(fontSize: 10, color: AppColors.onSurfaceVariant),
                    ),
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
                    if (savings != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Bespaar €${savings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
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

