/// The Liquid Glass level values (research Decision 7).
///
/// **Transparency** maps to the tint alpha of `ColorScheme.surface` laid over
/// the glass: a *higher* Transparency is *more* see-through, so a lower alpha.
/// **Intensity** maps to the backdrop blur, in logical pixels.
///
/// The High Transparency alphas ([tintAlphaLightHigh], [tintAlphaDarkHigh])
/// are the **readability floor** (FR-008, FR-019): no level may tint bars
/// more thinly than this, because Android reports no high-contrast flag and so
/// the package's automatic plain-frost fallback never fires there. Blur never
/// drops below [blurLow], so even the most transparent level frosts busy
/// content.
///
/// These are the research starting values, **pending on-device contrast
/// validation** (tasks T008, SC-005: 4.5:1 text, 3:1 icons). Tune only the
/// numbers here.
abstract final class AppGlassTokens {
  /// Transparency Low, Light theme.
  static const double tintAlphaLightLow = 0.86;

  /// Transparency Medium (default), Light theme.
  static const double tintAlphaLightMedium = 0.74;

  /// Transparency High, Light theme — the readability floor.
  static const double tintAlphaLightHigh = 0.62;

  /// Transparency Low, Dark theme.
  static const double tintAlphaDarkLow = 0.84;

  /// Transparency Medium (default), Dark theme.
  static const double tintAlphaDarkMedium = 0.70;

  /// Transparency High, Dark theme — the readability floor.
  static const double tintAlphaDarkHigh = 0.58;

  /// Intensity Low: the minimum blur.
  static const double blurLow = 4;

  /// Intensity Medium (default).
  static const double blurMedium = 8;

  /// Intensity High.
  static const double blurHigh = 14;

  /// Refraction depth, fixed and subtle so text on bars doesn't warp. It is
  /// not a user level (Transparency is the tint alpha, not the thickness).
  static const double thickness = 10;
}
