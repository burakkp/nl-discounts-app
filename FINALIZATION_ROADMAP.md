# 🏁 Finalization Roadmap — Nederland Discounts

This document track the final transition from a development prototype to a production-grade hyper-local application.

## 🧠 AI Context & Governance (Catch-up Info)
- **App Name**: Nederland Discounts (nl_discounts_app)
- **Stack**: Flutter (Frontend) | FastAPI/PostGIS (Backend/Render) | Supabase (DB) | Firebase (Auth/FCM).
- **Architecture**: Polyrepo with Service-Oriented Backend and Provider-based (Riverpod) Frontend.
- **Key Logic**: Every discount is geofenced (PostGIS) and unit-normalized (Agentic Scraping).

---

## 🛠️ Phase 1: Infrastructure & Core Connectivity
### 1. Production Connectivity & Env Config
- **Goal**: Implement dynamic switching between `localhost` and `production` URLs.
- **Status**: ✅ **DONE**
- **Implementation**: Used `bool.fromEnvironment('IS_LOCAL')` in `ApiService.baseUrl`. Default is now the Render production URL. Developers can switch to local for debugging using `--dart-define=IS_LOCAL=true`.

### 2. Autonomous Scraper Orchestration
- **Goal**: Set up CRON jobs (Render or GitHub Actions) to run daily ingestion scripts.
- **Status**: ✅ **DONE**
- **Implementation**: Created a master `sync_all.py` script and a GitHub Action workflow (`daily_sync.yml`) that runs at 04:30 UTC daily. It scrapes, harmonizes, ingests, and triggers smart notifications based on user watchlists.

### 3. Production Security Hardening
- **Goal**: Verify Firebase Security Rules for Supabase/DB access and protect admin cron endpoints.
- **Status**: ✅ **DONE**
- **Implementation**: Implemented `CORSMiddleware`, SSL-enforced DB connections, strict Pydantic Field validation, and mandatory environment-secret checks in `main.py`.

---

## 🎨 Phase 2: UI/UX Aesthetic Excellence
### 4. Brand & Launch Identity
- **Goal**: Implement high-resolution App Icons, Splash Screens, and Dutch-market branding.
- **Status**: ⏳ Pending

### 5. Interaction Polish & Shimmers
- **Goal**: Replace simple "Loading" texts with Shimmer/Skeleton loaders and Bento-style transitions.
- **Status**: ⏳ Pending

### 6. Global Resilience (Error UX)
- **Goal**: Implement a "Maintenance Mode" and user-friendly SnackBar system for network failures.
- **Status**: ⏳ Pending

---

## 📦 Phase 3: Deployment & Operations
### 7. Performance & Offline Caching
- **Goal**: Persist the "This Week" feed locally (SharedPrefs/Hive) for instant-on behavior.
- **Status**: ⏳ Pending

### 8. Release Asset Pipeline
- **Goal**: Configure Android Signing (Keystore), Fastlane (optional), and App Store metadata.
- **Status**: ⏳ Pending

### 9. Observability & Crash Reporting
- **Goal**: Integrate Sentry/Crashlytics for proactive production monitoring.
- **Status**: ⏳ Pending

---
*Last Updated: 18 April 2026*
