# SpineVision: The Professional Reseller Ecosystem
**Version 1.0 | Final Documentation Packet**

## 1. Executive Summary
SpineVision is a multi-module, professional-grade book reselling platform. It leverages **Gemini 2.0 Flash** for real-time metadata extraction, pricing strategy, inventory management, and FBA logistics optimization. The ecosystem provides an end-to-end workflow from thrift store sourcing to automated multi-channel publishing and financial tracking.

---

## 2. Technical Architecture
*   **Frontend**: Flutter (Mobile) with Bloc for state management and GoRouter for navigation.
*   **Backend**: Python Flask Orchestrator integrated with Google Generative AI (Gemini).
*   **Database**: Google Cloud Firestore (NoSQL) with real-time streaming.
*   **Storage**: Google Cloud Storage (GCS) for high-fidelity book spine and receipt imagery.
*   **Authentication**: Firebase Auth with JWT-based API Gateway security.
*   **Tier System**: Three-tier membership logic (Hobbyist, Pro, Enterprise) enforced via RevenueCat and backend middleware.

---

## 3. Core Module Breakdown

### **Sourcing & Discovery**
*   **OmniVision (AR Engine)**: A real-time camera HUD with three modes:
    *   *Thrift Mode*: Precision single-item appraisal with haptic and voice feedback.
    *   *Shelf Mode (Pro)*: Batch-scan entire bookshelves using AI object detection.
    *   *Spatial Mode (Enterprise)*: Live AR overlays highlighting high-ROI items in real-time.
*   **WishVision (Golden Snitch)**: A "Grail Target" system that alerts users with a pulsing gold AR glow when rare, high-value ISBNs or keywords are detected.

### **Management & Analytics**
*   **VisionHub (The Command Dashboard)**: High-level business intelligence showing Projected Profit, Efficiency Scores, and total Inventory Value.
*   **LibraryVision (Deep Catalog)**: A searchable, filterable database of every book in the user's collection, featuring market-delta tracking and multi-channel status indicators.

### **Profit Optimization**
*   **ListingVision**: AI-driven marketplace drafting (eBay, Amazon, FB Marketplace). Generates SEO-optimized titles and engaging descriptions via Gemini.
*   **BundleVision (Set Maximizer)**: Uses the backend `bundle_optimizer` to suggest high-value book sets, premium pricing, and themed marketing strategies to increase Average Order Value (AOV).
*   **RepriceVision (Market Watch)**: Automated market analysis that flags items for price increases based on real-time spikes in demand or scarcity.

### **Enterprise Operations**
*   **LogisticsVision (Box Builder)**: An AI-optimized FBA shipment tool. Gemini selects items from inventory to hit the **40-45 lbs UPS "Sweet Spot"** exactly, maximizing shipping efficiency.
*   **TaxVision (Financial Ledger)**: AI receipt scanning and auto-categorization of COGS (Cost of Goods Sold) and business expenses.

### **Intelligence & Growth**
*   **SupportVision (AI Strategist)**: A direct chat line to the Gemini AI Orchestrator for high-level reselling strategy, market trend analysis, and technical help.
*   **MarketingVision (Social Hub)**: A weekly content planner that approves and schedules AI-generated success stories and BOLO alerts for Instagram, Facebook, and TikTok.

---

## 4. Database Schema (Firestore)

### **Collections & Subcollections**
*   `/users/{uid}`: Primary profile, membership tier, and usage metrics.
    *   `/inventory/{isbn}`: Sourced book data, listing statuses, and market check timestamps.
    *   `/ledger/{expenseId}`: TaxVision financial entries.
    *   `/sets/{setId}`: Series progress and "Set Bonus" multipliers.
    *   `/wishlist/{isbn}`: Grail targets and specific profit goals.
    *   `/bundles/{bundleId}`: AI-optimized collection strategies.
*   `/Tickets/{ticketId}`: SupportVision live agent and AI tickets.
*   `/MetadataCache/{hash}`: Shared global metadata to reduce Gemini API costs.

### **Rules & Security**
*   **Owner-Only Access**: Strict `isOwner(userId)` checks for all personal reselling data.
*   **Tier Gating**: Specific rules prevent Hobbyist/Pro users from modifying Enterprise-only fields (e.g., `status` on tickets).
*   **Shared AI Cache**: Read-only global access for all authenticated users.

---

## 5. API Integrations
| Endpoint | Function | Module |
| :--- | :--- | :--- |
| `/buy_decision` | Real-time ROI & Risk Analysis | OmniVision |
| `/box_optimizer` | FBA Box Weight Optimization | LogisticsVision |
| `/bundle_optimizer` | Collection Strategy Generation | BundleVision |
| `/reprice_vision` | Market Watch & Price Delta Scan | RepriceVision |
| `/extract_receipt` | OCR financial extraction | TaxVision |
| `/chatbot` | Reseller Strategy Assistant | SupportVision |
| `/marketing_automation` | Social Media Content Engine | MarketingVision |

---

## 6. Project Vision & Roadmap
SpineVision 1.0 is a complete professional workstation. Future versions (2.0+) will focus on:
1.  **Optical Character Recognition (OCR) for Signatures**: Identifying signed first editions during the AR scan.
2.  **Community Sourcing Maps**: Visual heatmaps showing "High Density" thrift areas based on anonymized user data.
3.  **Direct Printing Integration**: One-click thermal printing for eBay and FBA labels directly from the mobile app.

---
**Documentation Complete.**
*SpineVision: See the Value in Every Spine.*
