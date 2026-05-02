import 'package:flutter/material.dart';

class AppColors {
  // Core Branding
  static const Color primary = Color(0xFF6F167A);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color tertiary = Color(0xFFFB7185);
  static const Color alternate = Color(0xFFFCA5A5);

  // Backgrounds
  static const Color primaryBackground = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF8F8F8);

  // Text
  static const Color primaryText = Color(0xFF1A1A1A);
  static const Color secondaryText = Color(0xFF4A4A4A);

  // Accents
  static const Color accent1 = Color(0xFFF472B6);
  static const Color accent2 = Color(0xFF14B8A6);
  static const Color accent3 = Color(0xFFFB7185);
  static const Color accent4 = Color(0xFFFCA5A5);

  // Status
  static const Color success = Color(0xFF14B8A6);
  static const Color warning = Color(0xFFFCA5A5);
  static const Color error = Color(0xFFFB7185);
  static const Color info = Color(0xFF6F167A);

  // UI Components
  static const Color appBarBackground = Color(0xFF6F167A);
  static const Color appBarForeground = Color(0xFFFFFFFF);
  static const Color dividerColor = Color(0xFFE0E0E0);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleCoral = LinearGradient(
    colors: [primary, Color(0xFFFB7185)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleSalmon = LinearGradient(
    colors: [primary, Color(0xFFFCA5A5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient purpleRose = LinearGradient(
    colors: [primary, Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy Mapping (keeping code compatible while updating values)
  static const Color primaryPurple = primary;
  static const Color primaryTeal = secondary;
  static const Color darkGrey = secondaryText;
}

class AppTextStyles {
  static const TextStyle displayLarge = TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.primaryText);
  static const TextStyle displayMedium = TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.primaryText);
  static const TextStyle headlineLarge = TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: AppColors.primaryText);
  static const TextStyle headlineMedium = TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.primaryText);
  static const TextStyle titleLarge = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.primaryText);
  static const TextStyle titleMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.primaryText);
  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.primaryText);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.secondaryText);
  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary);
}
