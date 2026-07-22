# SpineVision Firebase Pipeline

This document outlines the Firebase backend architecture, data schema, and security protocols for the SpineVision ecosystem.

## Backend Architecture
SpineVision utilizes a serverless architecture powered by Firebase and Google Cloud.
*   **Firestore:** Real-time NoSQL database for structured data.
*   **Firebase Auth:** Secure user authentication (Email, Google, etc.).
*   **Firebase Storage:** Hosting for scan images and listing photos.
*   **Cloud Functions:** Automated backend triggers (e.g., generating BOLO alerts).
*   **API Gateway:** Secure endpoint management for external integrations (Amazon, eBay).

## Data Schema (18 Core Collections)
The SpineVision database is partitioned into 18 primary collections to ensure modularity and scalability.

1.  **`users`**: User profiles, preferences, and subscription status.
2.  **`books`**: Master catalog of book metadata and condition assessments.
3.  **`scans`**: History of individual scans (ThriftVision, ShelfVision).
4.  **`batches`**: Grouped scans for ShelfVision processing.
5.  **`listings`**: Multi-platform drafts and active listings.
6.  **`buyers`**: CRM data for frequent buyers and collectors.
7.  **`sales`**: Transaction history and revenue data.
8.  **`tags`**: Custom user-defined tags for inventory organization.
9.  **`analytics_snapshots`**: Aggregated performance metrics for DashVision.
10. **`user_settings`**: Global app settings and integration keys (Keepa, Amazon).
11. **`social`**: Generated marketing content and posting schedules.
12. **`promotions`**: Promotion engine rules and active milestone rewards.
13. **`membership`**: Detailed tier entitlements and billing history.
14. **`prices`**: Real-time market value snapshots.
15. **`sets`**: Series tracking and missing volume alerts.
16. **`support`**: Ticketing data and AI chatbot logs.
17. **`amazon`**: FBA-specific logistics, weight tracking, and smart boxing data.
18. **`profit`**: Itemized COGS, expenses, and profit margin analysis.

## Security Rules
Data security is enforced at the Firestore level using granular security rules.
*   **Owner-Only Access:** All user-specific data is protected by `request.auth.uid == userId`.
*   **Tier-Gating:** Access to specific collections (e.g., `amazon`, `profit`) is validated against the user's `membershipTier` in their profile.
*   **Validation:** Strict schema validation on `write` operations to prevent data corruption.

## Data Flow
1.  **Scan:** User uploads image to `scans`.
2.  **Process:** Cloud Function triggers Gemini to extract metadata -> Update `books`.
3.  **Analyze:** Orchestrator checks for BOLO status -> Update `VisionHub` (Global).
4.  **List:** User promotes `book` to `listing`.

---
**Maintained by the SpineVision DevOps Team.**
