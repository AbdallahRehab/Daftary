/// One step of the user's Liquid Glass transparency or intensity choice
/// (Domain, Flutter-free per constitution Principle I). Mapped to concrete
/// renderer values (`AppGlassTokens`) only at the Presentation boundary —
/// mirrors how `AppThemeMode` maps to `ThemeMode` only at that boundary.
enum GlassLevel {
  low('low'),
  medium('medium'),
  high('high');

  const GlassLevel(this.value);

  /// The wire value persisted in `AppSettings.glassTransparency` /
  /// `glassIntensity`.
  final String value;
}
