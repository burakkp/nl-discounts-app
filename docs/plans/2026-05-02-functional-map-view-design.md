# Design Doc: Functional Map View with Watchlist Integration

## Overview
Transform the current "mock" map view into a functional Google Maps interface that shows supermarkets around the user and highlights branches with active deals matching the user's watchlist.

## Architecture

### 1. Backend (Python/FastAPI)
- **New Endpoint**: `GET /stores/nearby`
  - **Query Params**: `lat` (float), `lng` (float), `radius_km` (float, default 5.0)
  - **Security**: Requires Firebase JWT in `Authorization` header for watchlist matching.
  - **Implementation**:
    - Use PostGIS `ST_DWithin` to find stores.
    - JOIN with `discounts` (active this week).
    - LEFT JOIN with `watchlist_items` for the authenticated user.
    - Return `watchlist_hits` count per store.
    - Return coordinates (Lat/Lng) as separate floats in the JSON response.

### 2. Frontend (Flutter)
- **Dependencies**: `google_maps_flutter`
- **Services**: 
  - `ApiService`: Add `getNearbyStores(lat, lng)` method.
  - `LocationService`: Ensure robust GPS fetching (already exists).
- **Providers**:
  - `nearbyStoresProvider`: AsyncNotifier to fetch and store the list of stores.
- **UI (MapViewScreen)**:
  - Replace `_MapCanvas` with `GoogleMap` widget.
  - **Custom Markers**: 
    - Standard supermarket logo for base stores.
    - Highlighted markers (badge or glow) for stores where `watchlist_hits > 0`.
  - **Interactions**:
    - Tap marker -> Open existing `_StoreDealsSheet`.
    - FAB Search -> Switch to "Location Search" mode.
    - FAB Location -> Animate camera to user GPS.

## Data Flow
1. `MapViewScreen` gets current user location via `locationProvider`.
2. `nearbyStoresProvider` calls `ApiService.getNearbyStores(lat, lng)`.
3. Backend fetches stores from DB, matches with user watchlist, and returns JSON.
4. `GoogleMap` renders markers based on the results.

## Success Criteria
- [ ] Google Maps loads correctly in the app.
- [ ] Real supermarket locations from the database appear as markers.
- [ ] Stores with watchlist matches are visually distinct.
- [ ] Search FAB allows searching for supermarket locations.
