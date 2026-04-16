# 📋 Development Log — 16 April 2026

**Project:** Nederland Discounts App (`nl_discounts_app`)
**Session Focus:** Notification History — Priority 5 (Final Feature)
**Status:** ✅ Completed & Verified (`flutter analyze` → 0 new errors)

---

## 🎯 Session Goals

Close the push-notification loop by persisting FCM payloads locally and surfacing them in the **"RECENTE MELDINGEN"** section of the Watchlist screen:

1. Add `shared_preferences` dependency for cross-restart persistence.
2. Extend `NotificationService` with a full CRUD persistence layer.
3. Introduce `NotificationHistoryNotifier` (Riverpod `AsyncNotifier`) that loads history on boot and reactively subscribes to foreground FCM messages.
4. Replace the hard-coded `_NotificationItem` system card with a live, dismissible list that tracks read/unread state.

---

## 🏗️ Architecture

```
FCM Cloud (Android / iOS / Web)
   │
   ▼
NotificationHistoryNotifier._setupFcmListeners()
   │   (guarded — skipped on Linux via Platform.isLinux check)
   ▼
NotificationService.saveNotification(item)  ←─ SharedPreferences
   │   (capped at 20 entries, newest-first)
   ▼
state = AsyncData([newItem, ...current])    ←─ immediate in-memory update
   │
   ▼
WatchlistScreen watches notificationHistoryProvider
   └─ rebuilds RECENTE MELDINGEN section reactively
```

> **Key Decision: SharedPreferences vs SQLite**
> History is capped at 20 items, entirely read-only (no relational queries),
> and each payload is a compact JSON object (~200 bytes). `SharedPreferences`
> (`getStringList` / `setStringList`) is dramatically simpler than SQLite —
> zero schema, zero migration risk, and adequate performance for this volume.

---

## 📁 Files Changed

### MODIFIED — `pubspec.yaml`

```yaml
dependencies:
  ...
  shared_preferences: ^2.5.2   # ← added
```

`flutter pub get` resolved `shared_preferences 2.5.5` plus 6 platform-specific sub-packages (Android, iOS, Linux, Web, Windows, Foundation).

---

### NEW — `lib/models/notification_history_item.dart`

A lightweight, fully-serialisable data class:

```dart
class NotificationHistoryItem {
  final String id;           // FCM messageId, or microsecondsSinceEpoch fallback
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;         // drives blue highlight + unread border in UI
  final String? supermarket; // from FCM data payload — drives icon selection
  final Map<String, dynamic>? data; // full FCM data map for future extensibility

  NotificationHistoryItem copyWith({bool? isRead}) { ... }
  Map<String, dynamic> toJson() { ... }
  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) { ... }

  /// Safe deserialiser — silently drops corrupted entries instead of crashing.
  static NotificationHistoryItem? tryFromRaw(String raw) { ... }
}
```

**Design notes:**
- `tryFromRaw` prevents a single corrupted SharedPreferences entry from crashing the entire provider on startup.
- `copyWith` enables immutable read-state toggling without reconstructing every field.

---

### MODIFIED — `lib/services/notification_service.dart`

The existing `initializeAndSaveToken()` instance method was preserved unchanged. The following **static** persistence methods were added:

| Method | Behaviour |
|--------|-----------|
| `getNotificationHistory()` | Reads `notification_history` key, deserialises via `tryFromRaw`, drops nulls |
| `saveNotification(item)` | Inserts at index 0; trims list to `_maxHistory = 20` after insert |
| `markRead(id)` | Rewrites full list with `isRead: true` for the matched item |
| `deleteNotification(id)` | Rewrites full list excluding the matched item |
| `clearHistory()` | Removes the `notification_history` key entirely |
| `fromRemoteMessage(msg)` | Converts `RemoteMessage` → `NotificationHistoryItem`; prefers notification block, falls back to `data['title']` / `data['body']` for data-only messages |

**Why static?**
The `NotificationHistoryNotifier` calls these methods without needing a service instance injected via Riverpod. Keeping them static avoids creating a circular provider dependency and keeps the service stateless.

---

### MODIFIED — `lib/providers/app_providers.dart`

New imports added:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/notification_service.dart';
import '../models/notification_history_item.dart';
```

New class + provider appended:

```dart
class NotificationHistoryNotifier
    extends AsyncNotifier<List<NotificationHistoryItem>> {

  @override
  Future<List<NotificationHistoryItem>> build() async {
    _setupFcmListeners(); // no-op on Linux
    return NotificationService.getNotificationHistory(); // load persisted data
  }

  void _setupFcmListeners() {
    if (!kIsWeb && Platform.isLinux) return; // FCM not supported on Linux

    final sub = FirebaseMessaging.onMessage.listen((message) async {
      final item = NotificationService.fromRemoteMessage(message);
      await NotificationService.saveNotification(item);  // persist first
      state = AsyncData([item, ...state.value ?? []]);   // then update UI
    });

    ref.onDispose(sub.cancel); // ✅ no stream leak on provider dispose
  }

  Future<void> markRead(String id) async { ... }   // updates SP + state
  Future<void> delete(String id) async { ... }     // updates SP + state
  Future<void> clearAll() async { ... }            // clears SP + state
}

final notificationHistoryProvider = AsyncNotifierProvider<
    NotificationHistoryNotifier, List<NotificationHistoryItem>>(
  NotificationHistoryNotifier.new,
);
```

**Why `AsyncNotifier` vs `StreamNotifier`?**
The initial data load is async (SharedPreferences I/O). `AsyncNotifier.build()` returns a `Future` which maps directly to this pattern — the provider shows `loading` during the SP read, then `data` once loaded. `StreamNotifier` would require an artificial stream wrapper for the initial load.

---

### MODIFIED — `lib/screens/watchlist_screen.dart`

**Imports added:**
```dart
import '../models/notification_history_item.dart';
```

**In `build()`:**
```dart
final notifAsync = ref.watch(notificationHistoryProvider);
```

**RECENTE MELDINGEN section — before:**
```dart
// Static, hard-coded system card
_NotificationItem(
  icon: Icons.notifications_active,
  title: 'Smart Meldingen Actief',
  time: 'SYSTEEM INFO',
  isNew: true,
)
```

**RECENTE MELDINGEN section — after:**

1. **Section header** — now a `Row` with the label on the left and a `TextButton('Wis alles')` on the right (only rendered when `items.isNotEmpty`).

2. **Live list** via `notifAsync.when()`:
   - `loading:` → small `CircularProgressIndicator` (24px, 2px stroke)
   - `error:` → falls back to the original static system card
   - `data:` → renders `_DismissibleNotificationCard` per item + a **pinned** system card at the bottom

3. **NEW widget: `_DismissibleNotificationCard`**

```dart
class _DismissibleNotificationCard extends StatelessWidget {
  // Swipe left → delete (calls notifier.delete(id))
  // Tap       → mark read (calls notifier.markRead(id))

  IconData _iconForSupermarket(String? name) {
    // AH → Icons.store | Jumbo → Icons.storefront
    // Lidl/Aldi → Icons.shopping_bag_outlined | fallback → Icons.local_offer_outlined
  }

  String _relativeTime(DateTime dt) {
    // < 60s  → 'ZOJUIST'
    // < 60m  → '${diff.inMinutes}M GELEDEN'
    // < 24h  → '${diff.inHours}U GELEDEN'
    // else   → '${diff.inDays}D GELEDEN'
  }
}
```

**Read/Unread visual system:**

| State | Icon colour | Background | Left border |
|-------|------------|------------|-------------|
| Unread | `AppColors.primary` (orange) | `primary.withOpacity(0.05)` | `primary.withOpacity(0.2)` |
| Read | `AppColors.onSurfaceVariant` (muted) | `surfaceContainerLow` | none |

---

## 🔬 Verification

```bash
flutter pub get
# Resolving dependencies...
# + shared_preferences 2.5.5
# + shared_preferences_android 2.4.23
# + shared_preferences_foundation 2.5.6
# + shared_preferences_linux 2.4.1
# + shared_preferences_platform_interface 2.4.2
# + shared_preferences_web 2.4.3
# + shared_preferences_windows 2.4.1
# Changed 7 dependencies!

flutter analyze --no-pub
# 54 issues found (exit code 1)
# ── Breakdown ───────────────────────────────────────────
#  0  new errors from today's code                        ✅
#  4  pre-existing warnings in main.dart                  (Riverpod .state access from outside Notifier)
#  1  pre-existing error in test/widget_test.dart         (MyApp not a class — not our code)
# 49  info-level items                                    (withOpacity deprecation, avoid_print in legacy services)
```

---

## 🎉 Full Critical Path — All Features Complete

| Priority | Feature | Sessions | Status |
|----------|---------|----------|--------|
| 1 | Watchlist — Catalog Search, Optimistic Updates, Live Price Cards | 14 Apr | ✅ Done |
| 2 | Home Feed — Category Filter, City Badge, Hero Bento, Skeleton Loader | 14 Apr | ✅ Done |
| 3 | Profile Screen — Live Identity, Stats, FCM Token Tile, Sign-Out Flow | 14 Apr | ✅ Done |
| 4 | Map Screen — Procedural Canvas, Clustered Markers, Store Deal Sheet | 14 Apr | ✅ Done |
| 5 | Notification History — SharedPreferences Persistence, Live FCM List | **16 Apr** | ✅ Done |
