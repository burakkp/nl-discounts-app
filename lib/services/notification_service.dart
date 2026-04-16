// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_history_item.dart';
import 'api_service.dart';

class NotificationService {
  static const String _historyKey = 'notification_history';
  static const int _maxHistory = 20;

  final ApiService _apiService = ApiService();

  // ─── TOKEN REGISTRATION ──────────────────────────────────────────────────────

  Future<void> initializeAndSaveToken() async {
    // 🛡️ THE ARCHITECT'S LINUX BYPASS
    // FCM does not support native Linux desktop apps. We skip it here so your app doesn't crash while coding.
    if (!kIsWeb && Platform.isLinux) {
      debugPrint('💻 Linux detected. Skipping Push Notification initialization.');
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
      debugPrint('🔔 User granted permission for notifications.');

      // 2. Fetch the unique FCM Token from Google's hardware bridge
      String? token = await messaging.getToken();

      if (token != null) {
        debugPrint('🔑 FCM Token grabbed: ${token.substring(0, 15)}...');
        // 3. Send it to our Python Backend!
        await _apiService.saveDeviceToken(token);
      }

      // 4. Listen for token refreshes (Google occasionally rotates these for security)
      messaging.onTokenRefresh.listen((newToken) {
        _apiService.saveDeviceToken(newToken);
      });
    } else {
      debugPrint('🔕 User declined notification permissions.');
    }
  }

  // ─── STATIC PERSISTENCE (SharedPreferences) ────────────────────────────────

  /// Retrieves the persisted notification history, newest-first.
  static Future<List<NotificationHistoryItem>> getNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    return raw
        .map(NotificationHistoryItem.tryFromRaw)
        .whereType<NotificationHistoryItem>()
        .toList();
  }

  /// Saves a new notification to the front of the list, capped at [_maxHistory].
  static Future<void> saveNotification(NotificationHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_historyKey) ?? [];
    raw.insert(0, jsonEncode(item.toJson()));
    if (raw.length > _maxHistory) raw.removeRange(_maxHistory, raw.length);
    await prefs.setStringList(_historyKey, raw);
  }

  /// Marks a single notification as read in persistent storage.
  static Future<void> markRead(String id) async {
    final items = await getNotificationHistory();
    final updated =
        items.map((i) => i.id == id ? i.copyWith(isRead: true) : i).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      updated.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  /// Removes a single notification from persistent storage.
  static Future<void> deleteNotification(String id) async {
    final items = await getNotificationHistory();
    final updated = items.where((i) => i.id != id).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _historyKey,
      updated.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  /// Clears the entire notification history.
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  // ─── FCM MESSAGE ADAPTER ─────────────────────────────────────────────────────

  /// Converts a [RemoteMessage] into a storable [NotificationHistoryItem].
  static NotificationHistoryItem fromRemoteMessage(RemoteMessage message) {
    final notification = message.notification;

    // Prefer notification block → fall back to data payload keys
    final title = notification?.title ??
        message.data['title'] as String? ??
        'Nieuwe aanbieding';
    final body = notification?.body ??
        message.data['body'] as String? ??
        '';

    return NotificationHistoryItem(
      id: message.messageId ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      body: body,
      timestamp: message.sentTime ?? DateTime.now(),
      supermarket: message.data['supermarket'] as String?,
      data: message.data.cast<String, dynamic>(),
    );
  }
}