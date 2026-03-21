# PROJECT_CONTEXT.md
**Project:** Nederland Discounts App
**Role:** Principal Software Architect
**Domain:** Hyper-local, AI-powered Dutch supermarket discount tracker & crowdsourcing platform.

## 1. Vision & Scope
A highly scalable mobile application for the Dutch market that tracks supermarket discounts (Albert Heijn, Jumbo, Lidl, Aldi, PLUS). It includes area-specific tracking (PostGIS/Geo-spatial), smart push notifications (Firebase), and an AI-powered crowdsourcing feature for unlisted "ghost" discounts.

## 2. System Architecture & Tech Stack
**Architecture Pattern:** Clean Architecture, Modular Worker Pattern, Polyrepo (Separate Backend/Frontend repos).
* **Frontend (Mobile):** Flutter (Dart) - *Currently initializing*.
* **Backend (API & Orchestrator):** FastAPI (Python), Dockerized.
* **Database:** PostgreSQL with PostGIS extension (Hosted on Supabase via IPv4 Pooler).
* **Hosting / DevOps:** Render (Free Tier, GitHub CD integration).
* **Security & Identity:** Firebase Authentication (JWT) & Firebase Cloud Messaging (FCM).

## 3. The "Brain" (Agentic & Intelligence Layer)
* **Data Ingestion:** Playwright & API workers scraping 5 Dutch supermarkets.
* **Data Normalization:** Regex-based engine converting Dutch text ("1+1 gratis", "2e halve prijs") into mathematical unit prices.
* **Entity Linking:** `RapidFuzz` (Levenshtein distance) mapping chaotic scraped names to a Canonical Master Catalog.
* **Vision Agent (Phase 6):** Google `gemini-2.5-flash` Multimodal LLM acting as a Data Entry Agent. It extracts `product_name`, `price`, and `deal_type` from user-uploaded photos with a strict JSON output and confidence scoring.

## 4. Core Database Schema (PostgreSQL)
* `stores`: Geographic locations of supermarkets (Lat/Lng mapped via PostGIS).
* `discounts`: Standardized deals linked to stores, including `start_date` and `end_date` for temporal logic.
* `users`: Firebase `uid` and `fcm_token` storage.
* `watchlist_items`: Products tracked by users for smart push notifications.

## 5. Current State & Progress
* **Phase 1-6 (Backend): COMPLETED.** * The backend is fully containerized (Docker) and deployed live on Render. 
* Supabase is actively hosting the database. 
* Firebase security middleware is actively locking down private endpoints (like `POST /discounts/crowdsource`).
* **Phase 7 (Frontend): IN PROGRESS.** * We have chosen **Option A (Flutter)** and adopted a **Polyrepo** approach.
* The Flutter project (`nederland_discounts_app`) has been initialized locally.

## 6. Immediate Next Steps (The "Critical Path")
1. Confirm successful launch of the default Flutter "Counter App" via `flutter run` on an emulator or physical device.
2. Clean up the default `main.dart` boilerplate.
3. Establish the Flutter folder structure (e.g., Models, Views, Controllers/Providers).
4. Integrate the `http` or `dio` package to connect the Flutter app to the live Render API.