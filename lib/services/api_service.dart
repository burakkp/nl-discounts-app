import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/catalog_item.dart';
import '../models/watchlist_item.dart';

class ApiService {
  static String get baseUrl {
    // 💡 THE ARCHITECT'S CHOICE:
    // We use a compile-time constant to toggle between Local and Prod.
    // Run with: flutter run --dart-define=IS_LOCAL=true to use localhost.
    const bool isLocal = bool.fromEnvironment('IS_LOCAL', defaultValue: true);

    if (!isLocal) {
      return 'https://nl-discounts-api.onrender.com';
    }

    // --- DEVELOPMENT FALLBACKS ---
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  final AuthService _authService = AuthService();

  // ─── AI SCAN ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> uploadCrowdsourceDeal(
    int storeId,
    double lat,
    double lng,
    File imageFile,
  ) async {
    final uri = Uri.parse('$baseUrl/discounts/crowdsource');
    var request = http.MultipartRequest('POST', uri);

    // 🛡️ DYNAMIC SECURITY: Fetch a fresh token right before uploading
    String freshToken = await _authService.getValidToken();
    request.headers['Authorization'] = 'Bearer $freshToken';

    request.fields['store_id'] = storeId.toString();
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    log('📸 Uploading image with fresh security token...');

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        log('✅ AI Successfully extracted the deal!');
        return json.decode(response.body);
      } else {
        throw Exception(
          'Server rejected upload: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      log('❌ Upload Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  // ─── NEARBY DISCOUNTS ────────────────────────────────────────────────────────

  Future<List<dynamic>> getNearbyDiscounts(
    double lat,
    double lng, {
    double radius = 15.0,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/discounts/nearby?lat=$lat&lng=$lng&radius_km=$radius',
    );

    try {
      log('📡 Fetching from: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = json.decode(response.body);
        if (decoded['status'] == 'success') {
          return decoded['data'] as List<dynamic>;
        } else {
          throw Exception('API returned failure status');
        }
      } else {
        throw Exception('Failed to load discounts: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ API Service Error: $e');
      throw Exception('Network error: $e');
    }
  }
  
  // ─── NEARBY STORES ─────────────────────────────────────────────────────────

  Future<List<dynamic>> getNearbyStores(double lat, double lng) async {
    final token = await _authService.getValidToken();
    final uri = Uri.parse('$baseUrl/stores/nearby?lat=$lat&lng=$lng');
    
    try {
      log('🏪 Fetching nearby stores: $uri');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      log('❌ Nearby Stores Fetch Error: $e');
      return [];
    }
  }

  // ─── WEEKLY DISCOUNTS ────────────────────────────────────────────────────────

  Future<List<dynamic>> getThisWeekDiscounts({
    String? store,
    String? dealType,
    String? query,
    int page = 1,
    int pageSize = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };
    if (store != null) queryParams['store'] = store;
    if (dealType != null) queryParams['deal_type'] = dealType;
    if (query != null) queryParams['query'] = query;

    final uri = Uri.parse('$baseUrl/discounts/this-week')
        .replace(queryParameters: queryParams);

    try {
      log('📅 Fetching weekly deals: $uri');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['data'] as List<dynamic>;
      } else {
        throw Exception('Failed to load weekly deals: ${response.statusCode}');
      }
    } catch (e) {
      log('❌ Weekly Fetch Error: $e');
      return []; // Return empty list on error to keep UI stable
    }
  }

  // ─── CATALOG SEARCH (local fuzzy via discounts endpoint) ─────────────────────

  /// Searches the Master Catalog for products matching [query].
  ///
  /// Strategy: calls the nearby-discounts endpoint with a wide radius and
  /// filters results locally using a case-insensitive substring match. This
  /// avoids needing a dedicated `/catalog/search` backend route while still
  /// surfacing real, in-season products from the database.
  ///
  /// Deduplication is applied so each canonical product name appears once.
  Future<List<CatalogItem>> searchCatalog(
    String query, {
    double lat = 52.3676, // Amsterdam fallback
    double lng = 4.9041,
    double radius = 50.0, // Wide radius for catalog coverage
  }) async {
    if (query.trim().length < 2) return [];

    try {
      final allDeals = await getNearbyDiscounts(lat, lng, radius: radius);
      final q = query.toLowerCase().trim();

      final seen = <String>{};
      final results = <CatalogItem>[];

      for (final deal in allDeals) {
        final item = CatalogItem.fromDiscountMap(deal as Map<String, dynamic>);
        if (item.name.toLowerCase().contains(q) && seen.add(item.id)) {
          results.add(item);
        }
      }

      // Sort: exact-start matches first, then contains
      results.sort((a, b) {
        final aStarts = a.name.toLowerCase().startsWith(q) ? 0 : 1;
        final bStarts = b.name.toLowerCase().startsWith(q) ? 0 : 1;
        if (aStarts != bStarts) return aStarts - bStarts;
        return a.name.compareTo(b.name);
      });

      return results;
    } catch (e) {
      log('🔍 Catalog search error: $e');
      return [];
    }
  }

  // ─── WATCHLIST ───────────────────────────────────────────────────────────────

  /// Fetches the user's watchlist and enriches each entry with current deal
  /// data from the nearby-discounts endpoint.
  ///
  /// Returns [WatchlistItem] objects. Backward-compatible: if the backend
  /// returns plain strings, wraps them. If it returns maps, parses them fully.
  Future<List<WatchlistItem>> getWatchlist({
    double lat = 52.3676,
    double lng = 4.9041,
  }) async {
    final uri = Uri.parse('$baseUrl/watchlist');
    final token = await _authService.getValidToken();

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    log('📥 GET Watchlist Response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to load watchlist (${response.statusCode})');
    }

    final decoded = json.decode(response.body);
    final rawData = decoded['data'] as List<dynamic>;

    if (rawData.isEmpty) return [];

    // Parse raw watchlist entries into WatchlistItem (bare strings or maps)
    final List<WatchlistItem> items = rawData.map((e) {
      if (e is String) return WatchlistItem.fromProductName(e);
      if (e is Map<String, dynamic>) return WatchlistItem.fromEnrichedMap(e);
      return WatchlistItem.fromProductName(e.toString());
    }).toList();

    // Enrich with live deal data
    try {
      final deals = await getNearbyDiscounts(lat, lng, radius: 15.0);
      return items.map((item) {
        final match = deals.cast<Map<String, dynamic>>().firstWhere(
          (d) =>
              (d['product']?.toString() ?? d['product_name']?.toString() ?? '')
                  .toLowerCase()
                  .contains(item.productId.toLowerCase()),
          orElse: () => {},
        );
        final enriched = item.enrichWith(match.isEmpty ? null : match);
        // Mock: if it has a deal, simulate that we were notified recently
        if (enriched.hasActiveDeal && enriched.lastNotifiedAt == null) {
          return enriched.copyWith(
            lastNotifiedAt:
                DateTime.now().subtract(const Duration(minutes: 42)),
          );
        }
        return enriched;
      }).toList();
    } catch (_) {
      // If enrichment fails (e.g. geolocator not available on Linux),
      // return the bare items without deal data.
      return items;
    }
  }

  Future<void> addToWatchlist(String productId) async {
    final uri = Uri.parse('$baseUrl/watchlist');
    final token = await _authService.getValidToken();

    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'product_id': productId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add to watchlist (${response.statusCode})');
    }
  }

  Future<void> removeFromWatchlist(String productId) async {
    final uri = Uri.parse('$baseUrl/watchlist/$productId');
    final token = await _authService.getValidToken();

    final response = await http.delete(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to remove from watchlist (${response.statusCode})',
      );
    }
  }

  // ─── NOTIFICATIONS ───────────────────────────────────────────────────────────

  Future<void> saveDeviceToken(String fcmToken) async {
    final uri = Uri.parse('$baseUrl/users/fcm-token');
    final token = await _authService.getValidToken();

    final response = await http.put(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({'fcm_token': fcmToken}),
    );

    if (response.statusCode != 200) {
      log('⚠️ Failed to save FCM token: ${response.body}');
    } else {
      log('✅ Device token securely saved to Supabase!');
    }
  }
}
