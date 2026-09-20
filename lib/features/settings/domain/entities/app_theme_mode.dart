/// The user's chosen theme mode (Domain, Flutter-free per constitution
/// Principle I). Mapped to Flutter's own `ThemeMode` only at the
/// Presentation boundary (main.dart) — mirrors how `AppLanguage` maps to
/// `Locale` only at that same boundary.
enum AppThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  const AppThemeMode(this.value);

  /// The wire value persisted in `AppSettings.themeMode`.
  final String value;
}
