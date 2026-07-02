# SpineVision Launch & Verification Master Guide

This document contains the consolidated "Click-by-Click" instructions for finalizing the SpineVision ecosystem.

## 1. Technical Cleanup (Immediate)
Before running the app, you must generate the boilerplate code for the expanded Freezed models:
```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## 2. Verification Walkthrough (Click-by-Click)

### Phase A: Navigation & Hub
1. **Launch App**: `flutter run`
2. **VisionHub**: Confirm the 16-tile grid is visible and the background gradient (Purple/Rose) renders correctly.
3. **Gating Check**: Tap on **VisionCRM** or **ForecastVision**. If your mocked tier is 'Hobbyist', ensure the 'Upgrade' screen appears.

### Phase B: Core Logic Test
1. **OmniVision (Scan)**: Open the scanner, simulate a scan, and verify the metadata appears.
2. **LibraryVision**: Confirm the scanned book is listed in your inventory.
3. **ListingVision**: Tap a book in the library and select 'Generate Listing' for eBay.
4. **TaxVision (Mileage)**: Open TaxVision, tap 'Log Trip', enter 10 miles, and verify the ~$6.70 deduction.

### Phase C: Logistics & Support
1. **AmazonVision**: Open the **Box Builder** and verify the AI-suggested packing layout.
2. **SupportVision**: Ask a question in the **AI Chatbot** and verify the Gemini-powered response.

## 3. Production Hardening (Security & DevOps)

### Secrets Management
- **DO NOT** commit `serviceAccount.json` or `.env` to public repositories.
- Use **Google Cloud Secret Manager** for production keys.

### App Store Readiness
- **Android**: Update `android/app/build.gradle.kts` with your unique `applicationId`.
- **iOS**: Ensure `Runner.xcodeproj` has the correct Bundle Identifier and Team ID.

## 4. AI Performance Tuning (Advanced)
To maximize the accuracy of your 'Vision' modules, use the **Vertex AI Prompt Optimizer**:
- **Goal**: Improve the ROI accuracy of `buy_decision` logic.
- **Action**: Run a `VAPO` optimization job using a dataset of successful vs. unsuccessful book flips.
