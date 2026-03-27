# 🛒 NL Discounts (Nederland Discounts)
**Enterprise Agentic Architecture & MVP Documentation**

## 📖 Project Overview
NL Discounts is a hyper-local, crowdsourced mobile application designed to help users in the Netherlands track and share supermarket deals (e.g., Albert Heijn, Jumbo, Lidl). The system leverages AI-driven optical character recognition (OCR) to process crowdsourced photos, geolocates deals, and autonomously notifies users when items on their personal watchlist go on sale.

---

## 🏗️ The Technology Stack
The application is built using a modern, decoupled "Full-Stack Slice" architecture:
* **Frontend Mobile:** Flutter (Dart)
* **State Management:** Riverpod (Predictable, decoupled UI state)
* **Backend API:** FastAPI (Python) hosted on Render
* **Database:** Supabase (PostgreSQL with geospatial querying)
* **AI Engine:** Google Gemini Vision (Automated receipt/price tag extraction)
* **Identity & Access:** Firebase Authentication (Zero-trust JWT verification)
* **Push Notifications:** Firebase Cloud Messaging (FCM) + cron-job.org automation

---

## 🚀 Core MVP Features

### 1. Geospatial Deal Tracking
* **Description:** The app uses the device's native GPS hardware to fetch the user's exact coordinates.
* **Backend Logic:** The FastAPI server calculates the distance between the user and nearby supermarkets, returning only active deals within a specific radius (e.g., 15km).

### 2. The Vision Agent (Crowdsourcing)
* **Description:** Users can snap a picture of a price tag or receipt in the supermarket to share a deal with the community.
* **Execution:** * The app uploads the image to the FastAPI server.
    * The backend hands the image to the **Gemini Vision AI Agent**.
    * The AI autonomously extracts the `product_name`, `price`, and `supermarket` from the image pixels.
    * The deal is instantly saved to the Supabase database and broadcast to the community.

### 3. Personal Watchlists
* **Description:** Users can build a digital shopping list of items they want to track (e.g., "Koffie", "Verse Stroopwafels").
* **Execution:** The app communicates with a dedicated set of CRUD endpoints (`GET`, `POST`, `DELETE`) on the backend, ensuring the user's list is permanently synced to the cloud.

### 4. Autonomous Notification Engine
* **Description:** A self-sustaining engagement loop that alerts users to deals without requiring them to open the app.
* **Execution:** * A scheduled Cloud Worker pings a secure, password-protected webhook on the FastAPI server every morning at 08:00 AM.
    * The server scans the Supabase database, cross-referencing active deals with individual user watchlists.
    * If a match is found (e.g., a "Fresh Week" deal or a "Last Chance" expiring deal), the server securely beams a push notification directly to the user's physical phone via Firebase Cloud Messaging (FCM).

---

## 🛡️ Security & Architecture Principles
* **Zero-Trust Bouncer:** Every API request made by the mobile app must include a valid, cryptographic JWT from Google Firebase. The backend verifies this token before allowing database access.
* **Separation of Concerns:** The Flutter UI contains zero business logic. All data fetching, caching, and state updates are handled invisibly by Riverpod providers.
* **Silent Latency Mitigation:** The UI employs explicit loading barriers (spinners) during asynchronous cloud writes to ensure the frontend perfectly mirrors the backend state before the user can interact again.