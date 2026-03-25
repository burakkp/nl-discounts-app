// lib/services/api_service.dart
import 'dart:io';
import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://nl-discount.onrender.com';
  final AuthService _authService = AuthService();

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

    // Attach the text form fields
    request.fields['store_id'] = storeId.toString();
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

    print('📸 Uploading image with fresh security token...');

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        print('✅ AI Successfully extracted the deal!');
        return json.decode(response.body);
      } else {
        throw Exception(
          'Server rejected upload: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('❌ Upload Error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

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

  // --- WATCHLIST ENDPOINTS ---

  Future<List<String>> getWatchlist() async {
    final uri = Uri.parse('$baseUrl/watchlist');
    String token = await _authService.getValidToken();

    final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});

    // 🔍 ADD THIS X-RAY LOG:
    print('📥 GET Watchlist Response: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      return List<String>.from(decoded['data']);
    } else {
      throw Exception('Failed to load watchlist');
    }
  }

  Future<void> addToWatchlist(String productId) async {
    final uri = Uri.parse('$baseUrl/watchlist');
    String token = await _authService.getValidToken();

    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'product_id': productId}),
    );

    if (response.statusCode != 200) throw Exception('Failed to add to watchlist');
  }

  Future<void> removeFromWatchlist(String productId) async {
    final uri = Uri.parse('$baseUrl/watchlist/$productId');
    String token = await _authService.getValidToken();

    final response = await http.delete(uri, headers: {'Authorization': 'Bearer $token'});

    if (response.statusCode != 200) throw Exception('Failed to remove from watchlist');
  }

  // --- NOTIFICATION ENDPOINTS ---

  Future<void> saveDeviceToken(String fcmToken) async {
    final uri = Uri.parse('$baseUrl/users/fcm-token');
    String token = await _authService.getValidToken();

    final response = await http.put(
      uri,
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: json.encode({'fcm_token': fcmToken}),
    );

    if (response.statusCode != 200) {
      print('⚠️ Failed to save FCM token: ${response.body}');
    } else {
      print('✅ Device token securely saved to Supabase!');
    }
  }
}
