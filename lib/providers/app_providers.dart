// lib/providers/app_providers.dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../models/catalog_item.dart';
import '../models/notification_history_item.dart';
import '../models/watchlist_item.dart';

// ─── SERVICE PROVIDERS ───────────────────────────────────────────────────────

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// ─── CURRENT USER ────────────────────────────────────────────────────────────

/// Streams the Firebase [User] object. Null when signed out or on Linux desktop.
/// UI can watch this to reactively update identity-related widgets.
final currentUserProvider = StreamProvider<User?>((ref) {
  // Firebase Auth native plugin is not supported on Linux Desktop.
  if (!kIsWeb && Platform.isLinux) return const Stream.empty();
  return FirebaseAuth.instance.authStateChanges();
});


// ─── LOCATION ────────────────────────────────────────────────────────────────

final locationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

/// Derives a Dutch city display name from GPS coordinates using bounding boxes.
/// Falls back to "Jouw Buurt" when coordinates don't match any known city,
/// or when GPS is unavailable (e.g. Linux desktop).
final locationCityProvider = Provider<String>((ref) {
  final locationAsync = ref.watch(locationProvider);
  return locationAsync.when(
    data: (pos) => _cityFromCoords(pos.latitude, pos.longitude),
    loading: () => '...',
    error: (_, _) => 'Jouw Buurt',
  );
});

String _cityFromCoords(double lat, double lng) {
  // Bounding boxes for major Dutch cities [minLat, maxLat, minLng, maxLng]
  const cities = {
    'Amsterdam':  [52.28, 52.43, 4.73, 5.08],
    'Rotterdam':  [51.86, 51.98, 4.39, 4.58],
    'Utrecht':    [52.04, 52.13, 5.04, 5.18],
    'Den Haag':   [52.02, 52.14, 4.20, 4.43],
    'Eindhoven':  [51.39, 51.49, 5.42, 5.55],
    'Groningen':  [53.18, 53.24, 6.52, 6.62],
    'Tilburg':    [51.54, 51.58, 5.04, 5.15],
    'Breda':      [51.56, 51.62, 4.73, 4.83],
    'Arnhem':     [51.96, 52.00, 5.88, 5.94],
    'Nijmegen':   [51.81, 51.86, 5.83, 5.90],
  };

  for (final entry in cities.entries) {
    final b = entry.value;
    if (lat >= b[0] && lat <= b[1] && lng >= b[2] && lng <= b[3]) {
      return entry.key;
    }
  }
  return 'Jouw Buurt';
}

// ─── NEARBY DISCOUNTS ────────────────────────────────────────────────────────

final discountsProvider = FutureProvider<List<dynamic>>((ref) async {
  final position = await ref.watch(locationProvider.future);
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getNearbyDiscounts(
    position.latitude,
    position.longitude,
  );
});

final thisWeekDiscountsProvider = FutureProvider<List<dynamic>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getThisWeekDiscounts();
});

// ─── HOME FEED CATEGORY FILTER ───────────────────────────────────────────────

/// Simple Notifier wrapping the active category string.
class _ActiveCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Alle';
  void setCategory(String category) => state = category;
}

/// The currently selected category label. 'Alle' means no filter.
final activeCategoryProvider =
    NotifierProvider<_ActiveCategoryNotifier, String>(_ActiveCategoryNotifier.new);

/// Simple Notifier wrapping the search query.
class _SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';
  void setQuery(String query) => state = query;
}

/// Holds the current search query string (updated by the search sheet).
final catalogSearchQueryProvider =
    NotifierProvider<_SearchQueryNotifier, String>(_SearchQueryNotifier.new);

/// Category → keyword lists for local substring filtering on product names.
const Map<String, List<String>> _categoryKeywords = {
  'Vers': [
    'vers', 'vlees', 'gehakt', 'kipfilet', 'kip', 'vis', 'zalm', 'groente',
    'fruit', 'appel', 'banaan', 'kaas', 'melk', 'yoghurt', 'kwark', 'boter',
    'eieren', 'ei', 'zuivel', 'sla', 'tomaat', 'komkommer', 'paprika',
  ],
  'Pantry': [
    'pasta', 'spaghetti', 'saus', 'pesto', 'soep', 'rijst', 'olie', 'azijn',
    'conserve', 'blik', 'chips', 'biscuit', 'koek', 'crackers', 'noten',
    'jam', 'pindakaas', 'hagelslag', 'muesli', 'ontbijtgranen', 'brood',
  ],
  'Drinken': [
    'sap', 'cola', 'fanta', 'sprite', 'bier', 'wijn', 'water', 'thee',
    'koffie', 'drank', 'limonade', 'melk', 'frisdrank', 'smoothie', 'energy',
  ],
  'Huis': [
    'wasmiddel', 'schoonmaak', 'toiletpapier', 'zeep', 'shampoo', 'douchegel',
    'tandpasta', 'deodorant', 'scheermesje', 'afwasmiddel', 'vuilniszak',
    'allesreiniger', 'vloeistof',
  ],
};

/// Returns a filtered (and sorted) subset of [discountsProvider] based on
/// [activeCategoryProvider]. Filtering is entirely local — no extra API call.
final filteredDiscountsProvider =
    Provider<AsyncValue<List<dynamic>>>((ref) {
  // Use the general weekly deals for the main feed
  final discountsAsync = ref.watch(thisWeekDiscountsProvider);
  final category = ref.watch(activeCategoryProvider);

  if (category == 'Alle') return discountsAsync;

  return discountsAsync.whenData((deals) {
    final keywords = _categoryKeywords[category] ?? [];
    if (keywords.isEmpty) return deals;

    return deals.where((deal) {
      final name = (deal['product']?.toString() ??
              deal['product_name']?.toString() ??
              '')
          .toLowerCase();
      return keywords.any((kw) => name.contains(kw));
    }).toList();
  });
});

// ─── CATALOG SEARCH ──────────────────────────────────────────────────────────

/// Executes a fuzzy catalog search whenever the query changes.
final catalogSearchProvider =
    FutureProvider.autoDispose<List<CatalogItem>>((ref) async {
  final query = ref.watch(catalogSearchQueryProvider);
  if (query.trim().length < 2) return [];

  final apiService = ref.read(apiServiceProvider);
  double lat = 52.3676;
  double lng = 4.9041;
  try {
    final position = await ref.read(locationProvider.future);
    lat = position.latitude;
    lng = position.longitude;
  } catch (_) {}

  return await apiService.searchCatalog(query, lat: lat, lng: lng);
});

// ─── WATCHLIST (AsyncNotifier — optimistic updates) ──────────────────────────

class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  @override
  Future<List<WatchlistItem>> build() async {
    final apiService = ref.read(apiServiceProvider);
    double lat = 52.3676;
    double lng = 4.9041;
    try {
      final position = await ref.read(locationProvider.future);
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}
    return await apiService.getWatchlist(lat: lat, lng: lng);
  }

  Future<void> add(CatalogItem item) async {
    final previous = state;
    state = AsyncData([
      WatchlistItem(productId: item.id, productName: item.name),
      ...state.value ?? [],
    ]);
    try {
      await ref.read(apiServiceProvider).addToWatchlist(item.id);
      await _refresh();
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> remove(String productId) async {
    final previous = state;
    state = AsyncData(
      (state.value ?? [])
          .where((i) => i.productId != productId)
          .toList(),
    );
    try {
      await ref.read(apiServiceProvider).removeFromWatchlist(productId);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<void> _refresh() async {
    final apiService = ref.read(apiServiceProvider);
    double lat = 52.3676;
    double lng = 4.9041;
    try {
      final position = await ref.read(locationProvider.future);
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {}
    state = AsyncData(await apiService.getWatchlist(lat: lat, lng: lng));
  }

  Future<void> refresh() => _refresh();
}

final watchlistNotifierProvider =
    AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>(
  WatchlistNotifier.new,
);

/// Deprecated alias — prefer [watchlistNotifierProvider].
final watchlistProvider = FutureProvider<List<WatchlistItem>>((ref) async {
  return await ref.watch(watchlistNotifierProvider.future);
});

// ─── NAVIGATION ──────────────────────────────────────────────────────────────

class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setIndex(int index) => state = index;
}

final navIndexProvider =
    NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);

// ─── NOTIFICATION HISTORY ────────────────────────────────────────────────────

/// Manages a capped, persisted list of FCM notification payloads.
/// Loads from SharedPreferences on init and refreshes in-memory state
/// whenever a foreground FCM message arrives.
class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationHistoryItem>> {
  @override
  Future<List<NotificationHistoryItem>> build() async {
    _setupFcmListeners();
    return NotificationService.getNotificationHistory();
  }

  // Subscribe to foreground FCM messages; cancel subscription on dispose.
  void _setupFcmListeners() {
    // FCM not supported on native Linux.
    if (!kIsWeb && Platform.isLinux) return;

    final sub = FirebaseMessaging.onMessage.listen((message) async {
      final item = NotificationService.fromRemoteMessage(message);
      await NotificationService.saveNotification(item);
      final current = state.value ?? [];
      state = AsyncData([item, ...current]);
    });

    ref.onDispose(sub.cancel);
  }

  /// Marks a notification as read (persisted + in-memory).
  Future<void> markRead(String id) async {
    await NotificationService.markRead(id);
    state = AsyncData(
      (state.value ?? [])
          .map((i) => i.id == id ? i.copyWith(isRead: true) : i)
          .toList(),
    );
  }

  /// Removes a single notification (persisted + in-memory).
  Future<void> delete(String id) async {
    await NotificationService.deleteNotification(id);
    state = AsyncData(
      (state.value ?? []).where((i) => i.id != id).toList(),
    );
  }

  /// Clears the entire history (persisted + in-memory).
  Future<void> clearAll() async {
    await NotificationService.clearHistory();
    state = const AsyncData([]);
  }
}

final notificationHistoryProvider = AsyncNotifierProvider<
    NotificationHistoryNotifier, List<NotificationHistoryItem>>(
  NotificationHistoryNotifier.new,
);