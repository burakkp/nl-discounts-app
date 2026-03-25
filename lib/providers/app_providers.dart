// lib/providers/app_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/location_service.dart';

// 1. Service Providers (These act as global Singletons)
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

// 2. Location State
// A FutureProvider automatically handles Loading/Error/Data states for us!
final locationProvider = FutureProvider<Position>((ref) async {
  final locationService = ref.read(locationServiceProvider);
  return await locationService.getCurrentLocation();
});

// 3. Discounts State (The Magic)
// This provider automatically waits for the locationProvider to finish,
// then uses those coordinates to fetch the deals from your Render API.
final discountsProvider = FutureProvider<List<dynamic>>((ref) async {
  // By using .future, we wait for the GPS coordinates
  final position = await ref.watch(locationProvider.future);
  final apiService = ref.read(apiServiceProvider);

  return await apiService.getNearbyDiscounts(position.latitude, position.longitude);
});

// 4. Watchlist State
final watchlistProvider = FutureProvider<List<String>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  return await apiService.getWatchlist();
});

// 5. Navigation State (For our Bottom Menu)
class NavIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;
}

final navIndexProvider = NotifierProvider<NavIndexNotifier, int>(NavIndexNotifier.new);