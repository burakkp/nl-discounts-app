// lib/models/notification_history_item.dart
import 'dart:convert';

/// A single persisted notification payload received via FCM.
class NotificationHistoryItem {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? supermarket; // optional tag from FCM data payload
  final Map<String, dynamic>? data; // full FCM data map for future use

  const NotificationHistoryItem({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.supermarket,
    this.data,
  });

  NotificationHistoryItem copyWith({bool? isRead}) {
    return NotificationHistoryItem(
      id: id,
      title: title,
      body: body,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      supermarket: supermarket,
      data: data,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
        'isRead': isRead,
        'supermarket': supermarket,
        'data': data,
      };

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) {
    return NotificationHistoryItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Melding',
      body: json['body'] as String? ?? '',
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      supermarket: json['supermarket'] as String?,
      data: (json['data'] as Map?)?.cast<String, dynamic>(),
    );
  }

  /// Deserialize from a raw JSON string stored in SharedPreferences.
  static NotificationHistoryItem? tryFromRaw(String raw) {
    try {
      return NotificationHistoryItem.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
