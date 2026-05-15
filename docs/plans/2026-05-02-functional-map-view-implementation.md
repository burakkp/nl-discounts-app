# Functional Map View Implementation Plan

> **For Antigravity:** REQUIRED WORKFLOW: Use `.agent/workflows/execute-plan.md` to execute this plan in single-flow mode.

**Goal:** Transform the mock map into a functional Google Maps interface that highlights supermarkets with watchlist deals.

**Architecture:** A server-side enrichment approach where the backend filters nearby stores and calculates "watchlist hits" for the authenticated user, returning coordinates and hit counts to the Flutter app.

**Tech Stack:** Python (FastAPI, SQLAlchemy, PostGIS), Flutter (Riverpod, Google Maps Flutter).

---

### Task 1: Backend - Add Nearby Stores Endpoint

**Files:**
- Modify: `/home/burakkp/Documents/Projects/nederland-discounts/apps/api/main.py`
- Test: Create a temporary test script `test_stores_api.py` in backend root.

**Step 1: Implement the `/stores/nearby` endpoint**
Add the following endpoint to `main.py`:
```python
@app.get("/stores/nearby")
def get_nearby_stores(
    lat: float = Query(..., description="User's latitude"),
    lng: float = Query(..., description="User's longitude"),
    radius_km: float = Query(5.0, description="Search radius in kilometers"),
    db: Session = Depends(get_db),
    user_uid: Optional[str] = Depends(verify_firebase_token)
):
    """
    Returns supermarkets within radius, enriched with watchlist hit counts if authenticated.
    """
    radius_meters = radius_km * 1000
    user_location = f"SRID=4326;POINT({lng} {lat})"
    today = date.today()

    # Find the user's DB ID if authenticated
    user_id = None
    if user_uid:
        user = db.query(User).filter(User.device_id == user_uid).first()
        if user:
            user_id = user.id

    # Core Query: Stores in radius
    # If user_id is present, we also count matches in their watchlist
    query = db.query(
        Store.id,
        Store.chain_name,
        Store.address,
        func.ST_Y(func.ST_AsText(Store.location)).label("lat"),
        func.ST_X(func.ST_AsText(Store.location)).label("lng"),
        func.ST_Distance(Store.location, func.ST_GeographyFromText(user_location)).label("distance_meters")
    ).filter(
        func.ST_DWithin(Store.location, func.ST_GeographyFromText(user_location), radius_meters)
    )

    stores = query.all()
    results = []

    for s in stores:
        # Calculate watchlist hits for this store
        hits = 0
        if user_id:
            hits = db.query(func.count(Discount.id)).join(
                WatchlistItem, WatchlistItem.master_product_id == Discount.master_product_id
            ).filter(
                Discount.store_id == s.id,
                WatchlistItem.user_id == user_id,
                Discount.start_date <= today,
                Discount.end_date >= today
            ).scalar()

        results.append({
            "id": s.id,
            "chain_name": s.chain_name,
            "address": s.address,
            "latitude": s.lat,
            "longitude": s.lng,
            "distance_km": round(s.distance_meters / 1000, 2),
            "watchlist_hits": hits
        })

    return {"status": "success", "data": results}
```

**Step 2: Verify backend manually**
Run a `curl` or create a small python script to verify the endpoint returns JSON data.

**Step 3: Commit backend changes**
```bash
git add apps/api/main.py
git commit -m "backend: add nearby stores endpoint with watchlist hits"
```

### Task 2: Flutter - Add Google Maps Dependency

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**
```yaml
dependencies:
  google_maps_flutter: ^2.12.1
```

**Step 2: Run pub get**
```bash
flutter pub get
```

**Step 3: Commit**
```bash
git add pubspec.yaml
git commit -m "deps: add google_maps_flutter"
```

### Task 3: Flutter - Update ApiService and Providers

**Files:**
- Modify: `lib/services/api_service.dart`
- Modify: `lib/providers/app_providers.dart`

**Step 1: Add `getNearbyStores` to `ApiService`**
```dart
Future<List<dynamic>> getNearbyStores(double lat, double lng) async {
  final token = await _authService.getValidToken();
  final uri = Uri.parse('$baseUrl/stores/nearby?lat=$lat&lng=$lng');
  
  final response = await http.get(
    uri,
    headers: {'Authorization': 'Bearer $token'},
  );
  
  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);
    return decoded['data'] as List<dynamic>;
  }
  return [];
}
```

**Step 2: Add `nearbyStoresProvider` to `app_providers.dart`**
```dart
final nearbyStoresProvider = FutureProvider<List<dynamic>>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  return ref.read(apiServiceProvider).getNearbyStores(pos.latitude, pos.longitude);
});
```

**Step 3: Commit**
```bash
git add lib/services/api_service.dart lib/providers/app_providers.dart
git commit -m "feat: add api and provider support for nearby stores"
```

### Task 4: Flutter - Implement Google Maps UI

**Files:**
- Modify: `lib/screens/map_view_screen.dart`

**Step 1: Replace `_MapCanvas` with `GoogleMap`**
Refactor the `MapViewScreen` to use the `GoogleMap` widget. Use the `nearbyStoresProvider` to generate markers.

**Step 2: Implement Marker logic**
Create `Marker` objects for each store. If `watchlist_hits > 0`, use a custom colored marker or a custom icon.

**Step 3: Update Search FAB**
Change the search FAB to perform a location-based search or filter stores by name.

**Step 4: Verify on Emulator**
Run the app and check the Map tab.

**Step 5: Commit**
```bash
git add lib/screens/map_view_screen.dart
git commit -m "ui: implement functional google maps with store markers"
```
