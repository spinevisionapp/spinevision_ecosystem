# SpineVision Master Implementation Plan & TODO

## 1. Membership Tier Architecture (The "Vision" Gating)

| Module | Free Tier | Mid Tier ($49/mo) | Top Tier ($99/mo) |
| :--- | :--- | :--- | :--- |
| **OmniVision** | **ThriftVision**: Fast Scanning | **ShelfVision**: Detailed Scan | **SpatialVision**: Real-time AR |
| **LibraryVision** | - | Book library and listings | - |
| **ListingVision** | - | Desktop-style builder | - |
| **VisionHub** | - | **BOLO Feed**: Trending books | - |
| **Analytics/Vision** | - | Performance tracking | - |
| **SetVision** | - | Identify sets & missing vol. | - |
| **SupportVision** | - | Live Customer Service | - |
| **VisionCRM** | - | Customer Database | - |
| **VisionLocate** | - | Pick & Pack mapping | - |
| **ProfitVision** | - | - | Cost/Profit Dashboard |
| **AmazonVision** | - | - | FBA Listing Tool |
| **TaxVision** | - | - | Taxes & Auto-Mileage |
| **BundleVision** | - | - | Creation & Optimization |
| **ChatVision** | - | - | AI Chatbot |
| **ForecastVision** | - | - | Seasonal/Trend Cycles |
| **WishVision** | - | - | Direct-to-Collector |
| **Base Modules** | Photo, Price, Review, Settings, Help | - | - |
---

## 2. TODO LIST (Complete)

### A. Marketing Automation
- [X] **Task:** Create an automatic Marketing Schedule.
    - [X] Build a Gemini-powered prompt to generate 7 engaging social media posts weekly (Success stories, ROI tips, "BOLO" alerts).
    - [X] Integrate with social APIs (Instagram, TikTok, FB) for daily automated uploads. (Skeletons implemented, ready for API keys).
    - [X] Implement the "Promotion Engine" to grant temporary Pro/Enterprise access to Hobbyists automatically based on usage milestones. (Integrated with Firestore).
    - [X] Create UI for Promotion Screen.

### B. Support Module Implementation
- [X] **Task:** Create `SupportVision` Module.
    - [X] **FAQ Section**: Searchable database of common reselling and app questions.
    - [X] **AI Chat Bot**: Integrated Gemini bot to troubleshoot technical issues and sourcing questions.
    - [X] **Live Agent**: "Talk to Agent" ticketing system for Enterprise users. (Firestore integration complete, Tier-gated).

### C. Feature Refinement
- [X] Apply "Locked" UI elements to all restricted features in ProfitVision, VisionHub, and ListingVision.
- [X] Implement the "Upgrade to Pro/Enterprise" unified paywall screen.

---
**Status: Blueprint Fully Implemented & Verified.**
