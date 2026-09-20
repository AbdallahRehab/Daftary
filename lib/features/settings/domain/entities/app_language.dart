/// The app's display language (Domain, Flutter-free per constitution
/// Principle I). Also drives the active `TextDirection` at the
/// Presentation boundary — Arabic is RTL, English is LTR.
enum AppLanguage {
  english('en'),
  arabic('ar');

  const AppLanguage(this.code);

  /// The wire value persisted in `AppSettings.languageCode` and used to
  /// build a `Locale`.
  final String code;
}
