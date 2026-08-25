# SPINEVISION MASTER SYSTEM ARCHITECTURE & TECHNICAL BLUEPRINT

## 1. SYSTEM ARCHITECTURE DIAGRAM (LOGICAL VIEW)

[CLIENT LAYER: Flutter/Dart]
   |
   |-- [Navigation Hub]
   |    |-- OmniVision (Acquisition)
   |    |-- NexusVision (Inventory/Management)
   |    |-- OperateVision (Business Ops)
   |    |-- AssistVision (Support/Membership)
   |    |-- DashVision (Intelligence/Analytics)
   |
[INTEGRATION LAYER: Orchestrator & API Gateway]
   |
   |-- [Orchestrator (Python/FastAPI)]: Modular microservice handling logic & AI orchestration.
   |-- [API Gateway (Google Cloud)]: Secures & routes requests to AI/External services.
   |
[INTELLIGENCE LAYER: Gemini AI]
   |
   |-- Vision: OCR/AR Scan Analysis (OmniVision)
   |-- Natural Language: Support/Tickets (AssistVision)
   |-- Predictive: Repricing & Forecasting (NexusVision/OperateVision)
   |
[DATA LAYER: Firebase Ecosystem]
   |
   |-- [Firestore]: Hierarchical /users/{uid}/[subcollections]
   |-- [Cloud Storage]: Media assets (/scans, /listings)
   |-- [Auth]: JWT-based identity & role gating

---

## 2. MODULE DEFINITIONS & DATA FLOW

### OMNIVISION (The Acquisition Engine)
- **Responsibility:** High-speed ingestion of physical assets via OCR, barcode, and AR scanning.
- **Inputs:** Real-time camera feed, image buffers, user scan thresholds.
- **Outputs:** Detected ISBNs, structured metadata (title, author), image refs, scan logs.
- **Integration:** Cloud Storage, Gemini Vision API, NexusVision.
- **Data Flow:** Asset -> Camera -> Gemini Analysis -> Firestore (users/uid/scans) -> NexusVision.

### NEXUSVISION (The Core Hub)
- **Responsibility:** Management of book lifecycle: inventory, warehouse location, listing prep.
- **Inputs:** Scan outputs, external price data, warehouse identifiers.
- **Outputs:** Master library records, marketplace listing drafts, set status, physical maps.
- **Integration:** Firestore (library, listings, sets, wishlists), OperateVision, DashVision.
- **Data Flow:** Scans -> Library Record -> Condition Grading -> Locate -> Listing Draft -> OperateVision.

### OPERATEVISION (The Business Execution Layer)
- **Responsibility:** Marketplace actions, buyer relationships, real-time financials.
- **Inputs:** Listing drafts, marketplace webhooks, buyer info, mileage logs.
- **Outputs:** Active listings, sales records, buyer history, P&L reports, tax logs.
- **Integration:** Amazon SP-API, eBay API, CRM/Sales collections.
- **Data Flow:** Listing Draft -> Marketplace API -> Sale Event -> CRM Update -> Sales Record -> ProfitVision.

### DASHVISION (The Intelligence Engine)
- **Responsibility:** Translating operational data into actionable BI through visualization.
- **Inputs:** Aggregated sales/inventory records, historical ROI trends.
- **Outputs:** Performance graphs, pivot tables, seasonal demand forecasts.
- **Integration:** Analytics collection, Firestore aggregation triggers, Gemini Predictive API.
- **Data Flow:** Sales/Inventory Data -> Cloud Function Aggregation -> Analytics Snapshot -> UI Charts.

### ASSISTVISION (The Support & Growth Layer)
- **Responsibility:** Tier-based access governance and automated support.
- **Inputs:** User queries, subscription signals (RevenueCat), system logs.
- **Outputs:** Resolved tickets, dynamic feature tokens (Hobbyist/Pro/Enterprise), FAQ responses.
- **Integration:** Firebase Auth (Custom Claims), Support collection, Gemini Natural Language.
- **Data Flow:** Subscription Event -> Auth Claim Update -> Feature Unlocking.

---

## 3. AI ORCHESTRATOR & GEMINI FUNCTIONS

### ORCHESTRATOR ARCHITECTURE
The Orchestrator is a central Node.js/Cloud Run service acting as Intelligent Middleware.
- **Routing:** Selects between Gemini Flash (speed) and Pro (complexity).
- **Enrichment:** Parallel-fetches data from Google Books/Amazon SP-API.
- **Fallback:** Handles AI low-confidence by re-routing to higher models or deterministic ML Kit lookups.

### GEMINI FUNCTION DEFINITIONS
1. **ANALYZE_SCAN:** OCR & Metadata extraction from image buffers.
2. **EVALUATE_BUY_DECISION:** Real-time Buy/Pass logic based on marketplace floor prices and user thresholds.
3. **GENERATE_LISTING_SEO:** Platform-specific, search-optimized marketplace descriptions.
4. **ANALYZE_SET_COMPLETION:** Identification of series volumes and estimated "set bonus" value.
5. **COMPOSE_MARKETING_POSTS:** Generation of social content based on recent "Wins".
6. **TRIAGE_SUPPORT_TICKET:** Automated ticket resolution or sentiment-based categorization.
7. **GENERATE_BUSINESS_INSIGHTS:** Narrative summary of financial snapshots.

---

## 4. DATA LAYER: SCHEMAS & MODELS

### HIERARCHICAL FIRESTORE SCHEMA
- **/users/{uid}**: Core profile and membership status.
- **/users/{uid}/library**: Master book inventory.
- **/users/{uid}/listings**: Active/Historical marketplace entries.
- **/users/{uid}/scans**: History of all physical scan interactions.
- **/users/{uid}/crm**: Database of buyers and lifetime value.
- **/users/{uid}/sales**: Granular financial transaction records.
- **/users/{uid}/analytics**: Pre-aggregated performance snapshots.
- **/users/{uid}/settings**: Configuration, thresholds, and UI preferences.
- **/support**: (Global) Master help desk ticket system.
- **/metadata**: (Global) Shared ground-truth data (FAQ, Series definitions).

### CORE MODELS
- **BookModel:** isbn, title, author, condition_rating, acquired_price, workflow_status, location_id.
- **ScanModel:** scan_mode, isbn_detected, confidence_score, buy_decision, image_ref.
- **ListingModel:** book_id, platform, list_price, status, external_id.
- **BuyerModel:** name, email, purchase_history, lifetime_value, tags.
- **SaleModel:** gross_amount, net_amount, cogs, platform_fees, shipping_cost, date_sold.
- **AnalyticsSnapshotModel:** total_revenue, total_profit, sell_through_rate, inventory_valuation.

### COMPOSITE INDEXING STRATEGY
- **library:** `status` (ASC) + `date_sourced` (DESC)
- **listings:** `platform` (ASC) + `status` (ASC) + `date_listed` (DESC)
- **scans:** `scan_mode` (ASC) + `timestamp` (DESC)
- **sales:** `payment_status` (ASC) + `date_sold` (DESC)
- **crm:** `total_spent` (DESC) + `purchase_count` (DESC)

---

## 5. INFRASTRUCTURE & GLOBAL SYSTEMS

### CLOUD STORAGE STRUCTURE
- `/users/{uid}/scans/`: Raw scan frames.
- `/users/{uid}/listings/`: Product photos for marketplace entries.
- `/users/{uid}/exports/`: CSV/PDF reports.
- `/system/assets/`: UI elements and overlays.

### API GATEWAY CONFIGURATION
- **Security:** Firebase Auth JWT validation at the edge.
- **Rate Limiting:** Tier-gated quotas (100 RPM Hobbyist / 1000 RPM Enterprise).
- **Timeouts:** 300s deadline for complex visual analysis tasks.

### OFFLINE-FIRST STRATEGY
- **Persistence:** Firestore local cache enabled for `/library`, `/scans`, and `/settings`.
- **Queuing:** Background WorkManager handles media uploads and deferred AI analysis.
- **Conflict Policy:** Last Write Wins (LWW) with version tracking in `/history` 
...

### GLOBAL ERROR HANDLING
- **VisionError:** Standardized JSON structure with code, severity, and retryable flag.
- **Fallback:** Automatic degradation from Gemini Pro -> Flash -> Deterministic (ML Kit).
- **UI Behavior:** Ghost states for data loading and AR "Caution" (Yellow) overlays for low confidence.

---
gemini
## 6. INTEGRATION MAP (THE GLUE)
- **Omni -> Nexus:** Automated promotion of high-confidence scans.
- **Nexus -> Operate:** Library data serves as the source of truth for marketplace listings.
- **Operate -> Dash:** Sale events trigger Cloud Function aggregations for analytics snapshots.
- **Assist -> All:** Subscription tier from settings acts as a global feature gate.
