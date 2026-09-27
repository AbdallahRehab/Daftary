import '../../../../core/design_system/glass/app_glass_style.dart';
import '../../../../core/design_system/glass/app_glass_tokens.dart';
import '../../domain/entities/glass_appearance.dart';
import '../../domain/entities/glass_level.dart';

/// Maps the user's [GlassAppearance] onto the concrete [AppGlassStyle] the
/// design system renders with (research.md Decision 11). Lives in this
/// feature rather than `core/` so `core/` never imports a feature's domain —
/// the same boundary `AppThemeMode` → `ThemeMode` crosses in `main.dart`.
AppGlassStyle toAppGlassStyle(GlassAppearance appearance) {
  return AppGlassStyle(
    enabled: appearance.enabled,
    tintAlphaLight: switch (appearance.transparency) {
      GlassLevel.low => AppGlassTokens.tintAlphaLightLow,
      GlassLevel.medium => AppGlassTokens.tintAlphaLightMedium,
      GlassLevel.high => AppGlassTokens.tintAlphaLightHigh,
    },
    tintAlphaDark: switch (appearance.transparency) {
      GlassLevel.low => AppGlassTokens.tintAlphaDarkLow,
      GlassLevel.medium => AppGlassTokens.tintAlphaDarkMedium,
      GlassLevel.high => AppGlassTokens.tintAlphaDarkHigh,
    },
    blur: switch (appearance.intensity) {
      GlassLevel.low => AppGlassTokens.blurLow,
      GlassLevel.medium => AppGlassTokens.blurMedium,
      GlassLevel.high => AppGlassTokens.blurHigh,
    },
  );
}
