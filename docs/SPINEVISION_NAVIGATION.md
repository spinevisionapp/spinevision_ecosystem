# SpineVision Navigation & User Flow Mapping

This document maps the navigational structure and primary user flows within the SpineVision application.

## 1. App Map (Sitemap)

### Dashboard (Main Hub)
*   **OmniVision Quick-Scan** (Primary Action)
*   **VisionHub (BOLO Feed)**
*   **Performance Snapshots** (ProfitVision preview)
*   **Recent Scans**

### OmniVision (Sourcing)
*   **ThriftVision:** Single-shot scanner.
*   **ShelfVision:** Batch-scan mode.
*   **SpatialVision:** AR Live mode (Top Tier).
*   **History:** List of all previous scans.

### Inventory (LibraryVision)
*   **Library:** All scanned/owned items.
*   **Sets:** Grouped items and missing volumes.
*   **Listings:** Drafts, Active, and Sold items.
*   **Search/Filter:** Detailed inventory queries.

### Operations (The "Vision" Suite)
*   **AmazonVision:** FBA shipping and logistics.
*   **ProfitVision:** Detailed financial reports.
*   **TaxVision:** Receipts and mileage.
*   **SocialVision:** Marketing content manager.

### Profile & Settings
*   **Membership Management:** Subscription status and Paywall.
*   **Integrations:** API keys (Amazon, Keepa, eBay).
*   **App Settings:** Theme, notifications, and language.
*   **SupportVision:** FAQ and Live Chat.

## 2. Primary User Flows

### The "Source to List" Flow
1.  **Sourcing:** User scans a book via ThriftVision or ShelfVision.
2.  **Review:** User reviews the AI-extracted metadata and ROI estimate.
3.  **Add to Library:** Item is saved to LibraryVision.
4.  **Draft Listing:** User selects "Create Listing" in ListingVision.
5.  **AI Copywriting:** Gemini generates the SEO description.
6.  **Publish:** User pushes the listing to eBay, Amazon, or a personal storefront.

### The "Batch Sourcing" Flow
1.  **Capture:** User takes a photo of an entire bookshelf in ShelfVision.
2.  **Processing:** Gemini identifies all spines and flags high-value "BOLO" items.
3.  **Triage:** User taps "BOLO" items to view details and adds them to their physical cart.
4.  **Bulk Add:** User adds all selected items to their digital inventory in one tap.

### The "Logistics" Flow (Top Tier)
1.  **Select for FBA:** User selects 20 books from LibraryVision.
2.  **Smart Boxing:** AmazonVision calculates weight and suggests box sizes.
3.  **Labeling:** User generates and prints FBA shipping labels via the app.
4.  **Tracking:** System monitors the shipment and updates inventory status automatically.

---
**Maintained by the SpineVision Product Team.**
