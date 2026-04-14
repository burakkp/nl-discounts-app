# 📋 Development Log — 14 April 2026

**Project:** Nederland Discounts App (`nl_discounts_app`)
**Session Focus:** Watchlist Feature — Priority 1 (Core Business Logic)
**Status:** ✅ Completed & Verified (`flutter analyze` → 0 new errors)

---

## 🎯 Session Goals

Close the push-notification loop by building a production-ready Watchlist feature:

1. Replace the bare `AlertDialog` text input with a real **Master Catalog search** flow.
2. Upgrade all watchlist data from raw `List<String>` to **strongly-typed, deal-enriched models**.
3. Implement **optimistic state updates** via Riverpod `AsyncNotifier` (eliminate `ref.invalidate` round-trips).
4. Deliver premium UI: swipe-to-delete, animated skeletons, live price badges, store chips.

---

## 🏗️ Architecture Context

```
Backend (LIVE on Render)          Flutter App (this session)
────────────────────────          ─────────────────────────────────────
FastAPI + Supabase (PostGIS)  ──► ApiService.searchCatalog()  (fuzzy local)
GET /discounts/nearby             ApiService.getWatchlist()   (enriched)
POST /watchlist                   WatchlistNotifier           (optimistic)
DELETE /watchlist/{id}            CatalogSearchSheet          (new UI)
```

> **Key Decision:** No new backend endpoint was needed for catalog search.
> `searchCatalog()` reuses the existing `GET /discounts/nearby` endpoint with a
> wide radius (50 km), deduplicates by product name, and sorts by relevance
> (prefix-match first). This avoids Render free-tier cold-start latency on a
> dedicated search route.

---

## 📁 Files Changed

### NEW — `lib/models/catalog_item.dart`

A strongly-typed model for a product from the Master Catalog.

```dart
class CatalogItem {
  final String id;          // Canonical product name (used as backend key)
  final String name;
  final String? category;
  final String? supermarket;

  factory CatalogItem.fromDiscountMap(Map<String, dynamic> map) { ... }
}
```

- Implements `==` / `hashCode` on `id` for deduplication in `Set<CatalogItem>`.
- `fromDiscountMap` handles both `product` and `product_name` API key variants (defensive parsing).

---

### NEW — `lib/models/watchlist_item.dart`

Enriched watchlist entry that replaces the bare `String` representation.

```dart
class WatchlistItem {
  final String productId;
  final String productName;
  final double? currentPrice;
  final double? originalPrice;
  final String? storeName;
  final bool hasActiveDeal;

  factory WatchlistItem.fromProductName(String name) { ... }   // Legacy compat
  factory WatchlistItem.fromEnrichedMap(Map map) { ... }       // Full API map
  WatchlistItem enrichWith(Map<String, dynamic>? deal) { ... } // Merge with live deal
  int get discountPercent { ... }                              // Computed %
}
```

**Backward compatibility:** `fromProductName()` wraps a plain string (for the
current `List<String>` API response shape) so nothing breaks if the backend
hasn't been updated.

---

### MODIFIED — `lib/services/api_service.dart`

Three key additions:

#### 1. `searchCatalog(String query, {lat, lng})`
```dart
Future<List<CatalogItem>> searchCatalog(String query, ...) async {
  // Fetch all deals in 50km radius
  final allDeals = await getNearbyDiscounts(lat, lng, radius: 50.0);

  final seen = <String>{};
  final results = allDeals
    .where((d) => productName.contains(query))       // substring match
    .map(CatalogItem.fromDiscountMap)
    .where((item) => seen.add(item.id))              // deduplicate
    .toList();

  // Sort: prefix-match first, then alphabetical
  results.sort((a, b) { ... });
  return results;
}
```

#### 2. Updated `getWatchlist()` → `Future<List<WatchlistItem>>`
- Fetches the user's raw watchlist from `GET /watchlist`.
- Parses entries as `WatchlistItem` (handles both `String` and `Map` shapes).
- **Enriches** each entry by matching against `GET /discounts/nearby` — fills
  `currentPrice`, `originalPrice`, `storeName`, `hasActiveDeal`.
- Graceful degradation: if enrichment fails (e.g. no GPS on Linux desktop),
  returns bare items with `null` prices rather than throwing.

#### 3. Logging — replaced `print()` with `dart:developer log()` in new methods.

---

### MODIFIED — `lib/providers/app_providers.dart`

Full provider layer upgrade:

| Provider | Before | After |
|----------|--------|-------|
| `watchlistProvider` | `FutureProvider<List<String>>` | Legacy alias (deprecated) |
| `watchlistNotifierProvider` | ❌ did not exist | `AsyncNotifierProvider<WatchlistNotifier, List<WatchlistItem>>` |
| `catalogSearchQueryProvider` | ❌ | `StateProvider<String>` (holds debounced query) |
| `catalogSearchProvider` | ❌ | `FutureProvider.autoDispose<List<CatalogItem>>` (watches query) |

#### `WatchlistNotifier` — Optimistic Update Pattern

```dart
class WatchlistNotifier extends AsyncNotifier<List<WatchlistItem>> {
  Future<void> add(CatalogItem item) async {
    final previous = state;                      // Snapshot for rollback
    state = AsyncData([newItem, ...currentList]); // UI updates instantly
    try {
      await api.addToWatchlist(item.id);         // Persist to backend
      await _refresh();                           // Enrich with deal data
    } catch (e) {
      state = previous;                           // Rollback on failure
      rethrow;
    }
  }

  Future<void> remove(String productId) async { ... } // Same pattern
  Future<void> refresh() async { ... }                // Pull-to-refresh
}
```

**Why `AsyncNotifier` over `FutureProvider` + `ref.invalidate`?**
- `ref.invalidate` causes a full reload (loading spinner) on every add/remove.
- `AsyncNotifier` with optimistic state shows the result immediately and only
  degrades to a spinner if enrichment takes time after the local update.

---

### NEW — `lib/screens/catalog_search_sheet.dart`

A `showModalBottomSheet` occupying 85% of screen height.

**Components:**

| Widget | Purpose |
|--------|---------|
| `_CatalogSearchSheet` | Root `ConsumerStatefulWidget` — manages debounce timer, added-IDs set |
| `_SearchResultTile` | Single result row: icon + name + category chip + add button |
| `_Chip` | Reusable label chip (category / supermarket) |

**Key UX details:**
- **400ms debounce** on `TextField.onChanged` → prevents hammering the API on every keystroke.
- **`_addedIds: Set<String>`** tracks added items locally, giving instant `✓ check` feedback before the async call resolves.
- **`AnimatedContainer`** on the add button transitions smoothly from `+ (orange)` → `✓ (filled primary)`.
- **Hand-rolled shimmer** using `AnimationController` with `Color.lerp` — no extra package required.
- **Three empty states:** "Start typing", "No results", "Search failed" — each with an icon + subtitle.
- **Keyboard-aware layout:** `MediaQuery.viewInsets.bottom` prevents the sheet from being covered by the software keyboard.

---

### MODIFIED — `lib/screens/watchlist_screen.dart`

Complete rewrite of the screen. Key upgrades:

#### Pull-to-Refresh
```dart
RefreshIndicator(
  onRefresh: () => ref.read(watchlistNotifierProvider.notifier).refresh(),
  child: SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), ...),
)
```

#### Dynamic Hero Badge
Shows a live count of products currently on-deal (e.g. `3 DEALS`) in the header.

#### Swipe-to-Delete (Dismissible)
```dart
Dismissible(
  key: ValueKey(item.productId),
  direction: DismissDirection.endToStart,
  onDismissed: (_) => onDelete(),         // Calls WatchlistNotifier.remove()
  background: RedContainer(Icons.delete_outline),
  child: _WatchlistItemCard(...),
)
```
With a `SnackBar` **undo** action that re-calls `WatchlistNotifier.add()`.

#### Live Price Cards
- Shows `€2.49` (primary color) when `hasActiveDeal == true`.
- Shows strikethrough `€3.99` when `originalPrice` is available.
- Shows `▼30%` badge on the product thumbnail.
- Shows store name chip (e.g. `JUMBO`) in the bottom-right of the card.
- Falls back gracefully to `--` and no badge when no deal data is available.

#### Skeleton Loader
Animated placeholder cards during initial load — same `Color.lerp` shimmer technique, no package dependency.

#### Error State
Full error card with retry button connected to `WatchlistNotifier.refresh()`.

#### Empty State
Tappable illustration card that opens `showCatalogSearchSheet()` — encourages first-time product add.

---

## 🔬 Verification

```bash
flutter analyze
# Result: 66 issues found, exit code 0
# - 0 new errors from today's code
# - All issues are pre-existing info-level warnings (withOpacity deprecation,
#   avoid_print in legacy service files) + 1 pre-existing error in test/widget_test.dart
```

---

## 🔜 Next Steps (Remaining Critical Path)

| Priority | Feature | Status |
|----------|---------|--------|
| ~~🟡 2~~ | ~~**Home Feed polish**~~ | ✅ Done |
| 🟢 3 | **Profile Screen** | Sign-out flow, FCM token display, account stats |
| 🔵 4 | **Map Screen** | Cluster markers, tap-to-view deal detail sheet |
| ⚪ 5 | **Notification History** | Cache FCM payloads in `shared_preferences`, display in Watchlist "RECENTE MELDINGEN" section |

---

---

# 🏠 Home Feed Polish — Priority 2

**Session Focus:** Home Feed UI/UX Polish
**Time:** 22:27 CEST
**Status:** ✅ Completed & Verified (`flutter analyze` → exit 0, 0 new errors)

---

## 🎯 Session Goals

Close 8 hardcoded/broken gaps in `HomeFeedScreen`:

| # | Gap | Fix Applied |
|---|-----|-------------|
| 1 | Category chips did nothing | `activeCategoryProvider` + `filteredDiscountsProvider` |
| 2 | City badge showed "AMSTERDAM" | `locationCityProvider` via GPS bounding boxes |
| 3 | Spinner instead of skeleton | `_SkeletonGrid` (SliverGrid shimmer, no extra package) |
| 4 | Static hero copy ("Koffie Bonen") | Live first deal from `discountsProvider` |
| 5 | "3 PRIJSDROPS" hardcoded | Real count from `watchlistNotifierProvider` |
| 6 | Search bar not tappable | `onTap` → `showCatalogSearchSheet()` |
| 7 | All deal badges identical | Derived from data: `1+1`, `-30%`, `2e HALVE PRIJS`, etc. |
| 8 | No watchlist shortcut from feed | Long-press card → `+` overlay button |

---

## 📁 Files Changed

### MODIFIED — `lib/providers/app_providers.dart`

Three new providers added:

#### `activeCategoryProvider` — `StateProvider<String>`
Holds selected category (`'Alle'` by default). Updated by chip tap via
`ref.read(activeCategoryProvider.notifier).state = label`.

#### `filteredDiscountsProvider` — `Provider<AsyncValue<List<dynamic>>>`
Pure derived provider — watches `discountsProvider` + `activeCategoryProvider`
and returns a filtered subset using local keyword matching. Zero extra API calls.

```dart
const Map<String, List<String>> _categoryKeywords = {
  'Vers':    ['vers', 'vlees', 'vis', 'groente', 'melk', 'kaas', ...],
  'Pantry':  ['pasta', 'saus', 'soep', 'chips', 'biscuit', ...],
  'Drinken': ['sap', 'cola', 'bier', 'koffie', 'thee', ...],
  'Huis':    ['wasmiddel', 'toiletpapier', 'shampoo', ...],
};
```

#### `locationCityProvider` — `Provider<String>`
Derives a display city name from `locationProvider` GPS coordinates by testing
against hardcoded bounding boxes for 10 major Dutch cities. Falls back to
`'Jouw Buurt'` on no match or GPS unavailability.

```dart
const cities = {
  'Amsterdam': [52.28, 52.43, 4.73, 5.08],
  'Rotterdam': [51.86, 51.98, 4.39, 4.58],
  // ... 8 more
};
```

> **Why bounding boxes instead of reverse geocoding?**
> Reverse geocoding requires a network call + an extra package (`geocoding`).
> A pure in-memory lookup is instantaneous and has zero additional dependencies.

---

### MODIFIED — `lib/screens/home_feed_screen.dart`

Full architecture change: `SingleChildScrollView + GridView` replaced with
`CustomScrollView + SliverGrid` for proper scroll physics and performance.

#### Key structural changes:

**`ConsumerStatefulWidget` + `ScrollController`**
Needed to animate the floating header blur on scroll — `_headerBlurred` flips
at `_scroll.offset > 20px`, triggering `BackdropFilter` with sigmaX/Y = 12.

**Floating Header with Blur**
```dart
BackdropFilter(
  filter: ImageFilter.blur(
    sigmaX: _headerBlurred ? 12 : 0,
    sigmaY: _headerBlurred ? 12 : 0,
  ),
  child: _SearchBar(onTap: () => showCatalogSearchSheet(context)),
)
```

**`_CategoryBar`** — each chip is a `GestureDetector` wrapping an `AnimatedContainer`
that smoothly transitions color/shadow on selection.

**`_HeroBento`** — reads:
- `heroDeal = discountsAsync.valueOrNull?.first` → live product name, badge, price, store
- `dropCount` from `watchlistNotifierProvider` → live "X PRIJSDROPS" count
- Tapping "Jouw Lijst" card navigates to watchlist via `navIndexProvider`

**`_DealGridCard`** upgraded to `StatefulWidget`:
- Store brand color background tint (AH=blue, Jumbo=yellow, Lidl=dark blue, etc.)
- Store color accent bar at bottom edge of image area
- Deal badge: computed from `deal_type` field, then from price delta %
- Long-press toggles `_showAdd` → animated `+` button overlay appears
- `onAddToWatchlist` → `WatchlistNotifier.add()` with SnackBar confirmation

**`_SkeletonGrid`** — `SliverGrid` of 6 shimmer cards using `Color.lerp` on a
looping `AnimationController`. Identical technique to Watchlist skeleton.

**`_EmptyCategory`** — shown when filter yields 0 results, with "Toon alle deals"
reset button that sets `activeCategoryProvider` to `'Alle'`.

**`_ErrorBanner`** — shown on fetch failure with retry that calls
`ref.refresh(discountsProvider.future)`.

---

## 🔬 Verification

```bash
flutter analyze
# Result: 68 issues found, exit code 0
# - 0 new errors from Priority 2 code
# - All issues are pre-existing info-level warnings from legacy service files
```

---

---

# 👤 Profile Screen — Priority 3

**Session Focus:** Profile Screen + Cross-cutting Riverpod 3 API Fixes
**Time:** 22:40 CEST
**Status:** ✅ Completed & Verified (`flutter analyze` → exit 0, 51 issues — all pre-existing)

---

## 🎯 Session Goals

1. Replace the fully-static `StatelessWidget` profile screen with a reactive `ConsumerStatefulWidget`.
2. Wire live Firebase identity (name, email, photo, UID, anonymous/Google status) via `currentUserProvider`.
3. Show real watchlist & deal counts from `watchlistNotifierProvider`.
4. Implement working sign-out with a confirmation dialog.
5. Add a collapsible FCM token tile with tap-to-copy.
6. Fix all Riverpod 3.x API incompatibilities discovered during `flutter analyze`.

---

## 🔧 Cross-Cutting Fix — Riverpod 3 API Incompatibilities

Discovered during `flutter analyze` after integrating the new providers. These changes affected **4 files**.

### Problem 1: `StateProvider` removed from main barrel

`StateProvider` is in `package:riverpod/src/providers/legacy/` but is not exported from the main `riverpod.dart` or `flutter_riverpod.dart` barrel in v3.2+.

**Fix:** Replaced both `StateProvider` usages with explicit `Notifier` + `NotifierProvider` subclasses:

```dart
// BEFORE (Riverpod 2 style — breaks in v3)
final activeCategoryProvider = StateProvider<String>((ref) => 'Alle');

// AFTER (Riverpod 3 — NotifierProvider with typed mutation method)
class _ActiveCategoryNotifier extends Notifier<String> {
  @override
  String build() => 'Alle';
  void setCategory(String category) => state = category;
}
final activeCategoryProvider =
    NotifierProvider<_ActiveCategoryNotifier, String>(_ActiveCategoryNotifier.new);
```

Same pattern applied to `catalogSearchQueryProvider` → `_SearchQueryNotifier.setQuery()`.

### Problem 2: `valueOrNull` not defined on `AsyncValue<T>` in Riverpod 3

Riverpod 3 `AsyncValue<T>` exposes `.value` (returns `T?`, null when loading/error) instead of `.valueOrNull`.

```dart
// BEFORE
final count = watchlistAsync.valueOrNull?.length ?? 0;

// AFTER
final count = watchlistAsync.value?.length ?? 0;
```

Applied across: `app_providers.dart`, `home_feed_screen.dart`, `profile_screen.dart`.

### Problem 3: `.state =` from outside `Notifier` subclass

Setting `.state` directly on a `NotifierProvider.notifier` from `WidgetRef` is protected in Riverpod 3. **Fix:** Added typed public mutation methods to all notifiers.

```dart
// NavIndexNotifier
void setIndex(int index) => state = index;

// Usage in UI
ref.read(navIndexProvider.notifier).setIndex(2);  // not .state = 2
```

### Problem 4: `Colors.black08` — invalid constant

`Colors.black08` does not exist in the Flutter `Colors` class. Was used in a `const BoxShadow`.

```dart
// BEFORE (compile error)
BoxShadow(color: Colors.black08, ...)

// AFTER
BoxShadow(color: Color(0x14000000), ...)  // 8% opacity black
```

---

## 📁 Files Changed

### MODIFIED — `lib/providers/app_providers.dart`

Three new providers added:

#### `authServiceProvider` — `Provider<AuthService>`
Simple singleton provider so `AuthService` is injectable and testable.

#### `currentUserProvider` — `StreamProvider<User?>`
```dart
final currentUserProvider = StreamProvider<User?>((ref) {
  // Firebase Auth native is not supported on Linux Desktop
  if (!kIsWeb && Platform.isLinux) return const Stream.empty();
  return FirebaseAuth.instance.authStateChanges();
});
```
- Linux guard: returns `Stream.empty()` so the app never crashes on desktop dev.
- On mobile: streams `User?` — null after sign-out, non-null after sign-in.
- Any widget watching this provider automatically rebuilds on auth state change.

#### `NavIndexNotifier.setIndex()`
Added public `setIndex(int)` mutation method. Required because Riverpod 3 marks
`.state` as `@protected` — accessible only from within `Notifier` subclasses,
not from external `WidgetRef` calls.

---

### MODIFIED — `lib/screens/profile_screen.dart`

Full rewrite. Key decisions:

**Identity Card — Gradient Header**
```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [AppColors.primary, AppColors.orange600], ...
    ),
    ...
  ),
  child: Column(
    avatar,
    displayName,
    email,
    [LINUX DESKTOP | ANONIEM | GOOGLE] badge,
    UID chip (first 8 chars + "…"),
  ),
)
```

- `photoUrl != null` → `Image.network()` in a `ClipOval`; otherwise shows `Icons.person_rounded`.
- Badge icon: `Icons.person_outline_rounded` (anonymous) vs `Icons.gpp_good_rounded` (Google blue — verified).

**Live Stats Row**
```dart
final watchlistCount = watchlistAsync.value?.length ?? 0;
final dealCount = watchlistAsync.value?.where((i) => i.hasActiveDeal).length ?? 0;
```
Both values are wrapped in `AnimatedSwitcher` so they animate when the count changes (e.g. after adding to watchlist).

**Sign-Out Flow**
```dart
Future<void> _confirmSignOut() async {
  final confirmed = await showDialog<bool>(context, ...AlertDialog...);
  if (confirmed == true && mounted) {
    await ref.read(authServiceProvider).signOut();  // Clears Google + Firebase
    ref.read(navIndexProvider.notifier).setIndex(0); // Reset to Feed tab
    // On mobile only — navigate to login route
    if (!kIsWeb && !Platform.isLinux && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
    }
  }
}
```

On Linux desktop: sign-out button is **disabled** (`onPressed: null`) with a contextual label to avoid crashing the Firebase Auth plugin.

**FCM Token Tile — Collapsible**
```dart
_FcmTokenTile(
  token: _fcmToken,        // loaded in initState via NotificationService
  expanded: _fcmExpanded,  // local state
  onToggle: () => setState(() => _fcmExpanded = !_fcmExpanded),
)
```
- Expanded state: shows `SelectableText` (user can highlight token) + "Kopieer" `TextButton`.
- Copy action: `Clipboard.setData(ClipboardData(text: token))` + SnackBar confirmation.
- `AnimatedRotation` on chevron icon: rotates 180° when expanded.

**Loyalty Cards — Pure Flutter Barcode**
Replaced `Image.network()` broken URLs with a hand-crafted barcode widget:
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: List.generate(30, (i) => Container(
    width: i.isEven ? 2 : 1,
    color: i.isEven ? Colors.black87 : Colors.black38,
  )),
)
```
Alternating wide/narrow bars give a realistic EAN-13 visual. No network dependency.

---

## 🔬 Verification

```bash
flutter analyze
# Result: 51 issues found, exit code 0
# - 0 new errors from Priority 3 code
# - Down from 68 issues (Priority 2 baseline) — cleaned up some pre-existing warnings
# - Remaining items: avoid_print in legacy services, desiredAccuracy deprecation,
#   1 pre-existing error in test/widget_test.dart (MyApp not a class)
```

---

## 🔜 Remaining Critical Path

| Priority | Feature | Status |
|----------|---------|--------|
| ~~🟡 1~~ | ~~Watchlist Feature~~ | ✅ Done |
| ~~🟡 2~~ | ~~Home Feed Polish~~ | ✅ Done |
| ~~🟢 3~~ | ~~Profile Screen~~ | ✅ Done |
| ~~🔵 4~~ | ~~**Map Screen**~~ | ✅ Done |
| ⚪ 5 | **Notification History** | Cache FCM payloads in `shared_preferences`, display in Watchlist "RECENTE MELDINGEN" section |

---

---

# 🗺️ Map Screen — Priority 4

**Session Focus:** Interactive Map & Store Deals
**Time:** 23:25 CEST
**Status:** ✅ Completed & Verified (`flutter analyze` → exit 0)

---

## 🎯 Session Goals

Replace the broken static map image with a fully interactive, data-driven mapping experience:

1. Create a procedural, lightweight map background using `CustomPaint`.
2. Implement animated, real-time store markers clustered by supermarket.
3. Add a Draggable Store List for quick browsing of nearby supermarket locations.
4. Implement a "Store Detail" flow: tapping a store opens a dedicated deals sheet.
5. Wire all map elements to live data via `discountsProvider` and `locationCityProvider`.
6. Add "Watchlist Shortcut" directly from the map deal cards.

---

## 🏗️ Technical Implementation

### procedural Map Canvas (`_MapCanvas` & `_MapBackground`)

Instead of a heavy external map dependency or a broken 16MB network image, I implemented a procedural `CustomPaint` background:
- **Grid Painter:** Renders a subtle street-grid with block fills and green "park" blobs.
- **Performance:** Instant loading, 0KB asset size, and perfectly consistent with the app's clean aesthetic.
- **Coordinate Mapping:** Uses a deterministic seeded random placement for store markers based on the store name. This ensuring markers stay in the same place across rebuilds while naturally scattering them across the "neighborhood."

### Clustered Store Markers (`_StoreMarker`)

- **Dynamic Grouping:** Deals are grouped by `supermarket` name locally.
- **Branding:** Markers automatically use brand colors (AH = Blue, Jumbo = Yellow, etc.) and store initials.
- **Interactivity:** Markers scale up with a bounce animation (`ScaleTransition` + `Curves.elasticOut`) when the screen loads or filters change.
- **Badges:** Each marker displays a "X deals" count badge.

### Draggable Store Sheet (`_StoreListSheet`)

A `DraggableScrollableSheet` at the bottom of the screen allows users to:
- Pull up to see a full list of nearby supermarkets.
- View deal counts and distances (formatted as `X.X km`).
- Quick-tap any store to focus the map and open details.

### Store Deals Detail Sheet (`_StoreDealsSheet`)

Tapping any marker or list tile opens a modal sheet containing:
- Store branding and summary.
- A vertical list of all active deals at that location.
- **Watchlist Shortcut:** Every deal card in the map view has an `(+)` button for instant adding with SnackBar confirmation.
- **Navigation:** Deep-link button to directions (mocked).

---

## 📁 Files Changed

### MODIFIED — `lib/screens/map_view_screen.dart`

Complete rewrite from static mockup to reactive `ConsumerStatefulWidget`.

- **Key Logic:** Used `AnimationController` for the pulsing location dot and marker entrance.
- **State Management:** Watched `discountsProvider` for data, `locationCityProvider` for the neighborhood badge, and `watchlistNotifierProvider` for adding items.

---

## 🔬 Verification

```bash
flutter analyze
# Result: 0 new errors
# Checked for syntax issues and Riverpod 3.0 API consistency.
```

