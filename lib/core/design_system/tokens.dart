import 'package:flutter/material.dart';

/// Seed values only (constitution Principle XV): the two themes' seed
/// colors and `AppFinanceColors.light`'s concrete values are defined here,
/// but this class is no longer imported or referenced directly by any file
/// outside this one — every other call site reads
/// `Theme.of(context).colorScheme.*` or `context.financeColors.*` instead
/// (contracts/theme_tokens.md), since a `static const Color` cannot vary by
/// theme.
class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF1F6F5C);
  static const Color primaryVariant = Color(0xFF15493D);
  static const Color background = Color(0xFFF7F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color onSurfaceMuted = Color(0xFF6B6B6B);
  static const Color divider = Color(0xFFE3E3E0);

  // Light-mode status foregrounds are tuned to clear WCAG AA (≥4.8:1) as
  // text on the scheme's `surface`, on their own `*Surface` tint, and as an
  // icon on a 12% tint of themselves (the transaction-row avatar).

  /// "They owe you" — money coming to the user.
  static const Color positive = Color(0xFF1A7347);
  static const Color positiveSurface = Color(0xFFE4F5EC);

  /// "You owe them" — money the user owes.
  static const Color negative = Color(0xFFAB4136);
  static const Color negativeSurface = Color(0xFFFBEAE7);

  /// Settled.
  static const Color neutral = Color(0xFF646464);
  static const Color neutralSurface = Color(0xFFEDEDEA);

  static const Color warning = Color(0xFF8D5A09);
  static const Color warningSurface = Color(0xFFFCEFDB);

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

/// Material 3 window size classes (by available width, never by device
/// model) plus the content width cap used once a screen stops being
/// phone-shaped. Compact < [medium] ≤ medium < [expanded] ≤ expanded.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 840;

  /// Widest a page's content column grows on tablets, foldables, and
  /// landscape phones, so rows, forms, and text stay scannable.
  static const double maxContentWidth = 720;

  /// Onboarding's narrower reading column.
  static const double maxReadingWidth = 560;
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

/// Finance-domain color roles Material's `ColorScheme` has no equivalent
/// for (data-model.md Entity 2 Part B, contracts/theme_tokens.md). Never
/// read directly via `Theme.of(context).extension<...>()` — use the
/// `context.financeColors` extension below.
class AppFinanceColors extends ThemeExtension<AppFinanceColors> {
  const AppFinanceColors({
    required this.positive,
    required this.positiveSurface,
    required this.negative,
    required this.negativeSurface,
    required this.neutral,
    required this.neutralSurface,
    required this.success,
    required this.successSurface,
    required this.warning,
    required this.warningSurface,
    required this.chartPositive,
    required this.chartNegative,
    required this.chartNeutral,
  });

  final Color positive;
  final Color positiveSurface;
  final Color negative;
  final Color negativeSurface;
  final Color neutral;
  final Color neutralSurface;
  final Color success;
  final Color successSurface;
  final Color warning;
  final Color warningSurface;
  final Color chartPositive;
  final Color chartNegative;
  final Color chartNeutral;

  static const light = AppFinanceColors(
    positive: AppColors.positive,
    positiveSurface: AppColors.positiveSurface,
    negative: AppColors.negative,
    negativeSurface: AppColors.negativeSurface,
    neutral: AppColors.neutral,
    neutralSurface: AppColors.neutralSurface,
    success: AppColors.positive,
    successSurface: AppColors.positiveSurface,
    warning: AppColors.warning,
    warningSurface: AppColors.warningSurface,
    chartPositive: AppColors.positive,
    chartNegative: AppColors.negative,
    chartNeutral: AppColors.neutral,
  );

  static const dark = AppFinanceColors(
    positive: Color(0xFF4ADE93),
    positiveSurface: Color(0xFF1C3B2C),
    negative: Color(0xFFFF6B57),
    negativeSurface: Color(0xFF40201C),
    neutral: Color(0xFFB0B0AE),
    neutralSurface: Color(0xFF2A2A28),
    success: Color(0xFF4ADE93),
    successSurface: Color(0xFF1C3B2C),
    warning: Color(0xFFF2B84B),
    warningSurface: Color(0xFF3B2E13),
    chartPositive: Color(0xFF4ADE93),
    chartNegative: Color(0xFFFF6B57),
    chartNeutral: Color(0xFFB0B0AE),
  );

  @override
  AppFinanceColors copyWith({
    Color? positive,
    Color? positiveSurface,
    Color? negative,
    Color? negativeSurface,
    Color? neutral,
    Color? neutralSurface,
    Color? success,
    Color? successSurface,
    Color? warning,
    Color? warningSurface,
    Color? chartPositive,
    Color? chartNegative,
    Color? chartNeutral,
  }) {
    return AppFinanceColors(
      positive: positive ?? this.positive,
      positiveSurface: positiveSurface ?? this.positiveSurface,
      negative: negative ?? this.negative,
      negativeSurface: negativeSurface ?? this.negativeSurface,
      neutral: neutral ?? this.neutral,
      neutralSurface: neutralSurface ?? this.neutralSurface,
      success: success ?? this.success,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      warningSurface: warningSurface ?? this.warningSurface,
      chartPositive: chartPositive ?? this.chartPositive,
      chartNegative: chartNegative ?? this.chartNegative,
      chartNeutral: chartNeutral ?? this.chartNeutral,
    );
  }

  @override
  AppFinanceColors lerp(ThemeExtension<AppFinanceColors>? other, double t) {
    if (other is! AppFinanceColors) return this;
    return AppFinanceColors(
      positive: Color.lerp(positive, other.positive, t)!,
      positiveSurface: Color.lerp(positiveSurface, other.positiveSurface, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      negativeSurface: Color.lerp(negativeSurface, other.negativeSurface, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
      neutralSurface: Color.lerp(neutralSurface, other.neutralSurface, t)!,
      success: Color.lerp(success, other.success, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      chartPositive: Color.lerp(chartPositive, other.chartPositive, t)!,
      chartNegative: Color.lerp(chartNegative, other.chartNegative, t)!,
      chartNeutral: Color.lerp(chartNeutral, other.chartNeutral, t)!,
    );
  }
}

/// Ergonomic accessor so call sites never write
/// `Theme.of(context).extension<AppFinanceColors>()!` directly.
extension AppThemeContext on BuildContext {
  AppFinanceColors get financeColors =>
      Theme.of(this).extension<AppFinanceColors>()!;
}

ThemeData _buildTheme({
  required Brightness brightness,
  required AppFinanceColors financeColors,
}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
    // Light only: this dark red on a dark surface is ~2.8:1, so the dark
    // scheme keeps Material's own tonal error (a light red that reads).
    error: brightness == Brightness.light ? AppColors.error : null,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    dividerColor: colorScheme.outlineVariant,
    appBarTheme: AppBarTheme(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    cardTheme: CardThemeData(
      color: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
    ),
    dialogTheme: DialogThemeData(backgroundColor: colorScheme.surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.surface,
      indicatorColor: colorScheme.secondaryContainer,
    ),
    extensions: [financeColors],
  );
}

/// The app's Light Material theme, built from `AppColors` + `AppFinanceColors.light`.
ThemeData buildLightTheme() {
  return _buildTheme(
    brightness: Brightness.light,
    financeColors: AppFinanceColors.light,
  );
}

/// The app's Dark Material theme, built from `AppColors` + `AppFinanceColors.dark`.
ThemeData buildDarkTheme() {
  return _buildTheme(
    brightness: Brightness.dark,
    financeColors: AppFinanceColors.dark,
  );
}
