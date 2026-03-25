# PROJECT_CONTEXT.md
**Project:** Nederland Discounts App
**Role:** Principal Software Architect
**Domain:** Hyper-local, AI-powered Dutch supermarket discount tracker & crowdsourcing platform.

## 1. Vision & Scope
A highly scalable mobile application for the Dutch market that tracks supermarket discounts (Albert Heijn, Jumbo, Lidl, Aldi, PLUS). It includes area-specific tracking (PostGIS/Geo-spatial), smart push notifications (Firebase), and an AI-powered crowdsourcing feature for unlisted "ghost" discounts.

## 2. System Architecture & Tech Stack (Aligned with EAAF)
[cite_start]We have successfully implemented a multi-layered reference architecture [cite: 378, 379] utilizing a Polyrepo (Separate Backend/Frontend repos) structure:
* **Frontend (Mobile/Interaction Layer):** Flutter (Dart). Configured for Linux Desktop testing and Mobile deployment. Handles native GPS and Camera interactions.
* **Backend (Integration & Orchestration Layer):** FastAPI (Python), Dockerized. [cite_start]Acts as the Enterprise Tool Bus and Orchestrator[cite: 539, 590].
* **Database (Infrastructure Layer):** PostgreSQL with PostGIS extension (Hosted on Supabase via IPv4 Pooler).
* **Hosting / DevOps:** Render (Free Tier, GitHub CD integration).
* [cite_start]**Security & Identity (Control Plane / Governance Layer):** Firebase Authentication (JWT) enforcing Zero-Trust APIs and Firebase Cloud Messaging (FCM) for temporal alerts[cite: 730, 778].

## 3. The "Brain" (Agentic Intelligence Layer)
* **Data Ingestion:** Playwright & API workers scraping 5 Dutch supermarkets.
* **Data Normalization:** Regex-based engine converting Dutch text into mathematical unit prices.
* **Entity Linking:** `RapidFuzz` (Levenshtein distance) mapping chaotic scraped names to a Canonical Master Catalog.
* **Vision Agent (Phase 6):** Google `gemini-2.5-flash` Multimodal LLM acting as a Data Entry Agent. [cite_start]Extracts `product_name`, `price`, and `deal_type` from user-uploaded photos with a strict JSON output and confidence scoring, guarded by our Safety/Governance pipeline[cite: 541, 630].

## 4. Core Database Schema (PostgreSQL)
* `stores`: Geographic locations of supermarkets (Lat/Lng mapped via PostGIS).
* `discounts`: Standardized deals linked to stores, including `start_date` and `end_date` for temporal logic.
* `users`: Firebase `uid` and `fcm_token` storage.
* `watchlist_items`: Products tracked by users for smart push notifications.

## 5. Current State & Progress
* **Backend (Phases 1-6): COMPLETED & LIVE.** * Dockerized and deployed to `https://nl-discounts-api.onrender.com`.
  * Supabase actively hosting the geospatial database.
  * Firebase security middleware ("The Bouncer") actively locking down private endpoints (like `POST /discounts/crowdsource`).
* **Frontend (Phase 7): End-to-End Vertical Slice COMPLETED.**
  * Successfully initialized Flutter app.
  * `geolocator`: App fetches real hardware GPS (with a built-in mock bypass for Linux desktop testing).
  * `image_picker`: App opens camera (or gallery on Linux) to select price tags.
  * `firebase_auth`: App securely requests an Anonymous JWT token and attaches it to multipart HTTP requests.
  * End-to-End Test Passed: The app can snap a photo, authenticate with Render, extract JSON via Gemini, save to Supabase, and refresh the Flutter UI.

## 6. Immediate Next Steps (The "Critical Path")
We are now focusing on Core Business Logic and UI/UX architecture.
1. **State Management:** Refactor the current `setState`/`FutureBuilder` spaghetti code by implementing **Riverpod** for robust, scalable state management and caching.
2. **Watchlist UI:** Build the screens allowing users to search the Master Catalog and add items to their personal "Shopping List" to close the Push Notification loop.
3. **UI/UX Polish:** Implement a modern theme, bottom navigation bar, and loading animations.