import 'package:flutter/material.dart';

/// Centralized color palette (constitution Principle XV — no hardcoded
/// colors scattered across feature widgets). Status colors never stand
/// alone as the only signal (accessibility: never convey meaning by color
/// alone) — every status is always paired with text/an icon.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F6F5C);
  static const Color primaryVariant = Color(0xFF15493D);
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceMuted = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE3E3E0);

  /// "They owe you" — money coming to the user.
  static const Color positive = Color(0xFF1F8A56);
  static const Color positiveSurface = Color(0xFFE4F5EC);

  /// "You owe them" — money the user owes.
  static const Color negative = Color(0xFFC24B3F);
  static const Color negativeSurface = Color(0xFFFBEAE7);

  /// Settled.
  static const Color neutral = Color(0xFF6B6B6B);
  static const Color neutralSurface = Color(0xFFEDEDEA);

  static const Color error = Color(0xFFB3261E);
}

class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

class AppTypography {
  const AppTypography._();

  static const TextStyle headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle title = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );
  static const TextStyle body = TextStyle(fontSize: 15, height: 1.4);

  /// No hardcoded color — a `static const TextStyle` can't vary by theme
  /// (research.md Decision 8). Call sites append
  /// `.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)`.
  static const TextStyle bodyMuted = TextStyle(fontSize: 13, height: 1.4);
  static const TextStyle amount = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}

/// The app's Material theme, built entirely from the tokens above.
ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    surface: AppColors.surface,
    error: AppColors.error,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.divider,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
    ),
  );
}
