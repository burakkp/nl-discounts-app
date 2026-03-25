import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_service.dart';

class NotificationService {
  final ApiService _apiService = ApiService();

  Future<void> initializeAndSaveToken() async {
    // 🛡️ THE ARCHITECT'S LINUX BYPASS
    // FCM does not support native Linux desktop apps. We skip it here so your app doesn't crash while coding.
    if (!kIsWeb && Platform.isLinux) {
      print('💻 Linux detected. Skipping Push Notification initialization.');
      return;
    }

    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Request Permission from the user (Required for iOS & Android 13+)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('🔔 User granted permission for notifications.');

      // 2. Fetch the unique FCM Token from Google's hardware bridge
      String? token = await messaging.getToken();

      if (token != null) {
        print('🔑 FCM Token grabbed: ${token.substring(0, 15)}...');
        // 3. Send it to our Python Backend!
        await _apiService.saveDeviceToken(token);
      }

      // 4. Listen for token refreshes (Google occasionally rotates these for security)
      messaging.onTokenRefresh.listen((newToken) {
        _apiService.saveDeviceToken(newToken);
      });
    } else {
      print('🔕 User declined notification permissions.');
    }
  }
}