# SpineVision Ecosystem - App Blueprint

This repository contains the complete Flutter-based mobile app blueprint for the **SpineVision** ecosystem, by Lisa Jones. The project is structured as a modular mobile application suite, including the main app, a fast-scanning mini-app, and placeholders for future extensions.

## Core Technologies & Architecture

- **Framework**: [Flutter](https://flutter.dev/)
- **Language**: [Dart](https://dart.dev/)
- **Architecture**: Modular Monorepo
  - The project is organized into a main application (`main_spinevision`), several mini-apps (`mini_thriftvision`, `mini_placeholders`), and a `shared` library. This approach promotes code reuse and independent development of features.
- **State Management**: [flutter_bloc](https://bloclibrary.dev/)
  - BLoC (Business Logic Component) is used to separate presentation from business logic, making the app more scalable and testable.
- **Navigation**: [go_router](https://pub.dev/packages/go_router)
  - A declarative routing package for Flutter that simplifies navigation, deeplinking, and passing arguments between screens.
- **Styling**: A custom theme is defined in `lib/shared/theme`, using the specified **Purple (#4c3a87)** and **Teal (#2bb3a3)** color scheme. Typography is managed with [Google Fonts](https://pub.dev/packages/google_fonts).

## Project Structure

```
.
├── lib
│   ├── main.dart                   # Main app entry point
│   ├── main_spinevision            # Code for the main SpineVision app
│   │   ├── bloc
│   │   ├── screens
│   │   └── widgets
│   ├── mini_placeholders           # Placeholder modules for future mini-apps
│   │   ├── bundle_vision
│   │   ├── listing_vision
│   │   ├── price_vision
│   │   ├── set_vision
│   │   └── shelf_vision_pro
│   ├── mini_thriftvision           # Code for the ThriftVision mini-app
│   │   └── screens
│   └── shared                      # Shared code used across the ecosystem
│       ├── data
│       │   ├── models              # Shared data models (e.g., book_model.dart)
│       │   └── repositories        # Data repositories (e.g., book_repository.dart)
│       ├── navigation              # Routing and navigation logic (routes.dart)
│       ├── services                # Backend services, camera integration, etc.
│       ├── theme                   # App-wide theme, colors, and styles
│       └── widgets                 # Common reusable widgets
└── pubspec.yaml                    # Project dependencies
```

## Running the Application

1.  **Install Flutter**: Ensure you have Flutter installed on your system. Follow the [official installation guide](https://docs.flutter.dev/get-started/install).
2.  **Install Dependencies**: From the root of the project, run:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```

## Backend Services & API Contracts

This blueprint focuses on the frontend application. A complete implementation requires a backend server to handle complex logic like AI analysis and web scraping.

### Suggested Backend Tech Stack

-   **Language**: Python (with FastAPI or Flask) or Node.js (with Express)
-   **Database**: Firebase Firestore or a PostgreSQL database.
-   **AI/ML**: Python libraries like TensorFlow, PyTorch, or services like Google Cloud Vision AI.
-   **Web Scraping**: Python libraries like `BeautifulSoup` and `Requests`, or a service like Scrapy Cloud.

### API Endpoints (Example)

#### `POST /api/v1/scan/image`

-   **Description**: Analyzes an image of a book (or a shelf of books) to extract information.
-   **Request Body**: `multipart/form-data` with an image file.
-   **Response Body**:
    ```json
    {
      "books": [
        {
          "isbn": "978-0547928227",
          "title": "The Hobbit",
          "author": "J.R.R. Tolkien",
          // ... other extracted fields
          "scraped_data": {
            "cover_image_url": "...",
            "description": "...",
            "original_retail_price": 24.99,
            "comparable_prices": [
              { "marketplace": "Amazon", "price": 19.99, "url": "..." },
              { "marketplace": "eBay", "price": 18.50, "url": "..." }
            ],
            "sales_rank": 1500,
            "is_part_of_set": true
          }
        }
      ]
    }
    ```

#### `POST /api/v1/scan/thrift_vision`

-   **Description**: A lightweight endpoint for the ThriftVision mini-app to get a quick "buy/skip" recommendation.
-   **Request Body**: `multipart/form-data` with an image file.
-   **Response Body**:
    ```json
    {
      "decision": "buy", // "buy", "skip", "unknown"
      "profit_estimate": 12.50,
      "demand_score": 85, // 0-100
      "best_platform": "eBay"
    }
    ```
This concludes the blueprint for the SpineVision ecosystem. The project is now structured and ready for detailed implementation of each feature.
