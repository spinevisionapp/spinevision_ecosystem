# SpineVision Theme Pipeline

This document details the SpineVision Design Language and the process for maintaining theme consistency across the Flutter application and the FlutterFlow UI builder.

## Design Philosophy
SpineVision utilizes a high-contrast, professional palette designed for readability and focus. The core branding uses deep purple and vibrant teal to distinguish between primary actions and secondary information.

## Core Branding
*   **Primary Purple:** `#6F167A` - Used for primary buttons, headers, and the overall "brand" feel.
*   **Secondary Teal:** `#14B8A6` - Used for "Buy" indicators, success states, and key navigational accents.
*   **Accent Coral/Rose:** `#FB7185` / `#F472B6` - Used for highlighting ROI opportunities and error states.

## Theme Token Architecture
The design system is managed via a JSON-based token structure located in `/theme/`. This allows for a single source of truth that can be synced across different tools.

### Directory Structure
*   `theme/tokens/`: Core design constants (colors, spacing, radii).
*   `theme/typography/`: Font families, sizes, and weights.
*   `theme/variants/`: Light and Dark mode overrides.
*   `theme/components/`: Specific styles for inputs, app bars, and other widgets.

## Flutter Integration
In the Flutter codebase, the theme is implemented in `lib/shared/theme/`.
*   `colors.dart`: Maps the hex codes to `Color` constants.
*   `app_theme.dart`: Defines the global `ThemeData` for the application.

## FlutterFlow Integration
To sync changes to FlutterFlow:
1.  Update the relevant JSON file in `theme/`.
2.  If adding a new token, ensure it is added to `theme/spinevision_theme_combined.ff.json`.
3.  Export the `spinevision_theme_combined.ff.json` and import it into the FlutterFlow Theme Settings.

## Usage in Code
Always use the `AppColors` and `AppTextStyles` classes to ensure consistency.

```dart
// Example: Using the primary color
Container(
  color: AppColors.primary,
  child: Text(
    'Buy Now',
    style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
  ),
)
```

---
**Maintained by the SpineVision Design Team.**
