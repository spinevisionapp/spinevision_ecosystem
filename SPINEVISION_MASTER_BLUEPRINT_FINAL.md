# SPINEVISION MASTER STRATEGIC BLUEPRINT & ARCHITECTURE (FINAL)

## 1. EXECUTIVE SUMMARY
SpineVision is the definitive "OS for Resellers"—a high-performance ecosystem where multi-modal AI (Gemini 2.0) and predictive analytics automate the entire physical-to-digital inventory lifecycle. This document serves as the unified source of truth for all modules, data schemas, and strategic roadmaps.

---

## 2. SYSTEM ARCHITECTURE (MODERNIZED)

### A. Frontend Layer (Flutter/Dart)
- **Framework:** Flutter with BLoC for reactive state and GoRouter for declarative, modular navigation.
- **Navigation Hub:** A central routing engine (VisionHub) directing users to specialized 'Vision' modules.
- **Intelligence Integration:** Direct camera-to-cloud pipelines for OCR, AR, and visual extraction.

### B. Orchestration Layer (Python/FastAPI)
- **Architecture:** Modular microservice hosted on Google Cloud Run.
- **Core Services:**
    - `VisionService`: Multimodal reasoning for OCR, condition analysis, and shelf-batching.
    - `BusinessService`: Buy/Pass logic, profit modeling, and series identification.
    - `MarketingService`: Weekly social content generation and automated uploads.
    - `MembershipService`: Real-time tier validation and usage milestone tracking.
    - `SupportService`: Gemini-powered help desk with tool-calling for user stats.

### C. Data & AI Layer (Firebase/Vertex AI)
- **Database:** Hierarchical Firestore schema (`/users/{uid}/[subcollections]`).
- **Storage:** Cloud Storage for high-resolution scans and marketplace media.
- **AI Engine:** Gemini 2.0 Flash/Pro providing multimodal reasoning and NLP.

---

## 3. THE "VISION" MODULE SUITE

| Module | Responsibility | Core Functionality | Tier Access |
| :--- | :--- | :--- | :--- |
| **OmniVision** | Acquisition | High-speed single & batch scanning (Thrift/Shelf). | Hobbyist / Pro |
| **NexusVision** | Management | Inventory lifecycle, condition grading, series tracking. | Pro |
| **OperateVision** | Execution | Multi-channel listing (AMZ, eBay) and financials. | Enterprise |
| **DashVision** | Intelligence | BI visualization, ROI trends, and sourcing tips. | Pro |
| **AssistVision** | Support | AI Support bot, ticketing, and tier governance. | All |
| **PromoVision** | Growth | Automated usage milestones and temporary trials. | All |

---

## 4. HIERARCHICAL DATA SCHEMA (FIRESTORE)
- **/users/{uid}**: Core profile and membership status.
- **/users/{uid}/library**: Master book inventory.
- **/users/{uid}/listings**: Active/Historical marketplace entries.
- **/users/{uid}/scans**: History of all physical scan interactions.
- **/users/{uid}/crm**: Database of buyers and lifetime value.
- **/users/{uid}/sales**: Granular financial transaction records.
- **/users/{uid}/analytics**: Pre-aggregated performance snapshots.
- **/support**: (Global) Master help desk ticket system.

---

## 5. STRATEGIC ROADMAP

### PHASE 1: CORE STABILIZATION (COMPLETED)
- [X] Migrate backend to **Modular FastAPI**.
- [X] Implement **GoRouter** declarative navigation.
- [X] Integrate **Promotion Engine** for growth.
- [X] Standardize **Hierarchical Data Schema**.

### PHASE 2: INTELLIGENCE & SCALE (ACTIVE)
- [ ] **SpatialVision Alpha:** Real-time AR overlays for "Buy/Pass" indicators.
- [ ] **Amazon SP-API Integration:** Direct-to-FBA listing and shipping.
- [ ] **ProfitVision Pro:** Granular P&L reports and tax-prep exports.
- [ ] **SocialVision Beta:** Multi-platform automated posting (TikTok/Instagram).

### PHASE 3: PREDICTIVE DOMINANCE (FUTURE)
- [ ] **ForecastVision:** Predictive seasonal demand modeling.
- [ ] **VisionLocate:** AR-guided warehouse picking.
- [ ] **Direct-to-Collector:** P2P marketplace for verified rare finds.

---
**Maintained by the SpineVision Product & Engineering Teams.**
