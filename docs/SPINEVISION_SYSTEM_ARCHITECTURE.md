# SpineVision System Architecture

SpineVision is built on a modern, decoupled architecture designed for high scalability, real-time AI processing, and a seamless cross-platform user experience.

## 1. High-Level Overview
The system is divided into three primary layers:
1.  **Frontend (FlutterFlow/Flutter):** A high-performance mobile and web application providing the user interface and local device capabilities (Camera, OCR, AR).
2.  **Orchestration Layer (Google Cloud Run):** A central Python-based API that coordinates logic between the frontend, AI models, and backend services.
3.  **Data & AI Layer (Firebase/Vertex AI):** Serverless data storage, authentication, and state-of-the-art generative AI via Gemini 2.0.

## 2. Component Breakdown

### Frontend: FlutterFlow + Custom Flutter
*   **FlutterFlow:** Used for rapid UI prototyping and core navigation.
*   **Custom Code:** Integrated BLoC for state management, custom camera controllers for ShelfVision, and ARCore/SceneKit for SpatialVision.
*   **Local Persistence:** Firestore local cache and SQLite for offline scan queuing.

### Orchestrator: Python (FastAPI) on Cloud Run
The Orchestrator is the system's "Brain." It handles:
*   **Task Routing:** Directing scan data to the appropriate Gemini model.
*   **Logic Gates:** Validating membership tiers before executing expensive AI tasks.
*   **Third-Party Integration:** Managing sessions with Keepa, Amazon SP-API, and eBay API.
*   **Confidence Fallbacks:** Automatically switching to traditional OCR if AI confidence scores are below threshold.

### AI Engine: Gemini 2.0 (Vertex AI)
We leverage Gemini 2.0 for its multi-modal capabilities:
*   **Visual Extraction:** Extracting ISBNs, titles, and authors from messy shelf photos.
*   **Condition Grading:** Analyzing photos of book corners, spines, and pages to suggest a condition grade.
*   **Copywriting:** Generating SEO-optimized product descriptions for listings.
*   **BOLO Identification:** Identifying high-value outliers in batch scans.

## 3. Data Flow: The Scanning Pipeline
1.  **Capture:** User takes a photo in `OmniVision`.
2.  **Upload:** Image is stored in Cloud Storage; metadata is written to `scans` collection.
3.  **Trigger:** Cloud Function detects new scan and calls the Orchestrator.
4.  **Analyze:** Orchestrator calls Gemini with the image and a specific instruction set.
5.  **Enrich:** Gemini returns JSON metadata; Orchestrator fetches real-time pricing.
6.  **Notify:** Results are pushed to the user's mobile app via FCM/Firestore.

## 4. Scalability & Security
*   **Concurrency:** Cloud Run scales horizontally based on request volume.
*   **Isolation:** All data access is controlled by Firestore Security Rules and IAM roles.
*   **Encryption:** All data in transit (TLS 1.3) and at rest (AES-256) is encrypted.

---
**Maintained by the SpineVision Engineering Team.**
