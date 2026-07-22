# PromoVision: Promotion Engine & Tier System

PromoVision is the growth-focused module that manages the SpineVision membership tiers, user entitlements, and automated promotion campaigns.

## Membership Tiers
SpineVision is structured into three distinct tiers to cater to different stages of a reseller's journey.

| Tier | Name | Target User | Focus |
| :--- | :--- | :--- | :--- |
| **Free** | Hobbyist | New resellers / Casual sellers | Sourcing basics and quick scans. |
| **Mid** | Pro | Growing businesses | Batch efficiency and inventory management. |
| **Top** | Enterprise | High-volume professionals | Automation, logistics, and deep analytics. |

## The Promotion Engine
The Promotion Engine is designed to encourage user growth by rewarding high-usage milestones with temporary tier upgrades.

### Key Mechanics
*   **Usage Milestones:** Tracks metrics like total scans, successful listings, and ROI.
*   **Automated Rewards:** Automatically grants "Pro" or "Enterprise" access for 24-72 hours when a milestone is hit.
*   **Conversion Optimization:** Integrated with the unified paywall to show users the value of higher tiers during their promotion period.

## Tier Gating
Features are gated using a robust entitlement system.
*   **UI Gating:** "Locked" icons and upgrade prompts in the FlutterFlow app.
*   **API Gating:** Server-side checks in Cloud Run to prevent unauthorized module access.
*   **Database Gating:** Firestore security rules based on the `membershipTier` field.

## Unified Paywall
A central screen where users can compare tiers, view their progress toward the next promotion, and manage their RevenueCat subscriptions.

---
**Maintained by the SpineVision Growth Team.**
