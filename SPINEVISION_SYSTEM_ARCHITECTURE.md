# SpineVision Ecosystem: Complete System Architecture Blueprint

## Table of Contents
1. [High-Level Architecture](#1-high-level-architecture)
2. [Vision Module Definitions](#2-vision-module-definitions)
3. [The Orchestrator](#3-the-orchestrator)
4. [Gemini Function Definitions & Schemas](#4-gemini-function-definitions--schemas)
5. [Workflows](#5-workflows)
6. [Database Schema (Firestore)](#6-database-schema-firestore)
7. [Infrastructure](#7-infrastructure)
8. [Global Frameworks](#8-global-frameworks)
9. [VisionHub & Notifications](#9-visionhub--notifications)
10. [AmazonVision & Advanced Logistics](#10-amazonvision--advanced-logistics)
11. [Advanced AI & Automation Modules](#11-advanced-ai--automation-modules)
12. [Omni-Modal Input & Search Strategy](#12-omni-modal-input--search-strategy)
13. [Spatial Intelligence & Future Scaling](#13-spatial-intelligence--future-scaling)
14. [Monetization & Billing](#14-monetization--billing)

---

## 1. High-Level Architecture
The SpineVision ecosystem is a **Decoupled Multi-Module Cloud-Native Architecture**. It consists of a unified FlutterFlow frontend communicating via a secure API Gateway to a suite of specialized Microservices on Google Cloud Run. An **AI Orchestrator** coordinates tasks between modules and leverages Gemini 2.0 for vision and data tasks.

---

## 2. Vision Module Definitions
*   **OmniVision:** 
    *   *ThriftVision:* Fast in-store scanning (Free). 
    *   *ShelfVision:* Detailed batch scanning (Mid).
    *   *SpatialVision:* Real-time AR walk-by scanning (Top).
*   **AmazonVision:** Comprehensive Amazon FBA listing and logistics tool (Top).
*   **ProfitVision:** Dashboard for tracking costs, profits, and sales history (Top).
*   **TaxVision:** Automatic mileage logs and tax filing data (Top).
*   **ForecastVision:** Predictive seasonal and market trend cycle analytics (Top).
*   **ChatVision:** Advanced AI support chatbot (Top).
*   **BundleVision:** Resale bundle creation and ROI optimization (Top).
*   **WishVision:** Direct-to-collector sales matching (Top).
*   **VisionHub:** BOLO Feed for currently trending high-value books (Mid).
*   **LibraryVision:** Centralized book library and listing management (Mid).
*   **ListingVision:** Multi-platform desktop-style listing builder (Mid).
*   **SetVision:** Identifying book sets and missing volumes (Mid).
*   **SupportVision:** Contact live customer service agents (Mid).
*   **VisionCRM:** Integrated customer database management (Mid).
*   **VisionLocate:** Pick & Pack inventory location system (Mid).
*   **Analytics/Vision:** Strategic performance intelligence (Mid).

---

## 3. The Orchestrator
The Orchestrator (Cloud Run) is the central "brain" of the system.
*   **Routing:** Maps tasks (e.g., `analyze_spine`) to specific Gemini models.
*   **Enrichment:** Adds user strategy context to prompts.
*   **Fallback:** Automatically redirects to local OCR (ML Kit) if AI confidence is < 0.70.

---

## 4. Gemini Function Definitions & Schemas
Gemini interacts with the system via these tools:
*   `extract_metadata`: ISBN, Title, Author extraction from images.
*   `price_vision_lookup`: Real-time market value lookups.
*   `analyze_condition`: Visual quality assessment and grading.
*   `batch_process_shelf`: Multi-object detection for shelf scanning.
*   `generate_listing`: SEO-optimized copywriting for sales.
*   `library_catalog`: CRUD operations on the Firestore database.
*   `buy_decision`: ROI-based Buy/Pass algorithmic logic.

---

## 5. Workflows (ThriftVision, ShelfVision, ListingVision)
Standardized workflows for sourcing, reviewing, and listing books using AI-driven automation.

---

## 6. Database Schema (Firestore)
*   **Partitioning:** Root collections with `user_id` indexing.
*   **Collections:** `users`, `books`, `scans`, `batches`, `listings`, `buyers`, `sales`, `tags`, `analytics_snapshots`, `user_settings`.

---

## 7. Infrastructure
*   **Cloud Storage:** `raw-uploads`, `processed-assets`, `listing-photos`.
*   **Compute:** Cloud Run (Python/FastAPI) with IAM roles for Vertex AI and Firestore.
*   **API Gateway:** Firebase Auth JWT validation, rate limiting, and CORS.

---

## 8. Global Frameworks
*   **Security:** Firestore rules enforcing `request.auth.uid == userId`.
*   **Offline-First:** Firestore Local Persistence + Local SQLite Queue.
*   **Error Handling:** Standardized JSON error codes with suggested UI actions.

---

## 9. VisionHub & Notifications
*   **Analytics Pipeline:** Firestore -> Cloud Function -> BigQuery -> Daily Snapshots -> UI Charts.
*   **Notification System:** FCM triggers for "Sale Completed" and "Low Inventory".

---

## 10. AmazonVision & Advanced Logistics
Advanced module for high-volume FBA sellers, introducing complex decision matrices and supply chain automation.
*   **Keepa Integration:** Evaluating 6-month history and sales velocity.
*   **Smart Boxing:** Tracking weight for 40-45lb FBA boxes.
*   **Ungating Engine:** Intelligent flagging of restricted but high-margin opportunities.

---

## 11. Advanced AI & Automation Modules
*   **SetVision:** ROI multiplier alerts when completing book series.
*   **RefurbishVision:** AI-driven repair guides to upgrade condition grades.
*   **VisionLocate:** AR-driven inventory mapping for bins and shelves.
*   **TaxVision:** Automated COGS extraction and mileage tracking.

---

## 12. Omni-Modal Input & Search Strategy
*   **Speech-to-Text:** Native voice listeners for all text input fields.
*   **Omni-Search:** Fallback chain (Spine OCR -> Barcode -> Cover Match -> Internal Text).

---

## 13. Spatial Intelligence & Future Scaling
*   **SpatialVision:** Real-time AR "walk-by" scanning using Gemini 2.0 Live.
*   **DemandVision:** Direct-to-collector sales matching.
*   **ForecastVision:** Predictive seasonal market cycles.

---

## 14. Monetization & Billing (Subscription Architecture)

SpineVision utilizes a **Tiered SaaS Model** managed via RevenueCat for cross-platform entitlement synchronization.

### A. Subscription Tiers & Entitlements
*   **Entitlement: `free_tier` ($0/mo)**
    *   ThriftVision, PhotoVision, PriceVision, Help (FAQ).
*   **Entitlement: `mid_tier` ($49/mo)**
    *   VisionHub (BOLO Feed), LibraryVision, ListingVision, ShelfVision, SupportVision (Live).
    *   SetVision, VisionCRM, VisionLocate, Analytics/Vision.
*   **Entitlement: `top_tier` ($99/mo)**
    *   AmazonVision, ProfitVision, TaxVision, BundleVision, ChatVision.
    *   ForecastVision, WishVision, SpatialVision (AR).

---

**Generated by Gemini CLI.**
