import 'package:flutter/foundation.dart';

import 'app_glass_tokens.dart';

/// The resolved glass appearance that the adaptive components render with.
///
/// Carried by `AppGlassScope`. It holds concrete numbers, never the user's
/// levels, so `core/` stays independent of the settings feature (which maps
/// its preference onto this).
@immutable
class AppGlassStyle {
  const AppGlassStyle({
    required this.enabled,
    required this.tintAlphaLight,
    required this.tintAlphaDark,
    required this.blur,
  });

  /// Glass OFF. The numbers are the Medium levels so a surface built directly
  /// (e.g. the Settings preview) still has sensible values.
  static const AppGlassStyle off = AppGlassStyle(
    enabled: false,
    tintAlphaLight: AppGlassTokens.tintAlphaLightMedium,
    tintAlphaDark: AppGlassTokens.tintAlphaDarkMedium,
    blur: AppGlassTokens.blurMedium,
  );

  /// Whether the adaptive components render glass at all.
  final bool enabled;

  /// Alpha of `ColorScheme.surface` over the glass in the Light theme.
  final double tintAlphaLight;

  /// Alpha of `ColorScheme.surface` over the glass in the Dark theme.
  final double tintAlphaDark;

  /// Backdrop blur, in logical pixels.
  final double blur;

  @override
  bool operator ==(Object other) =>
      other is AppGlassStyle &&
      other.enabled == enabled &&
      other.tintAlphaLight == tintAlphaLight &&
      other.tintAlphaDark == tintAlphaDark &&
      other.blur == blur;

  @override
  int get hashCode => Object.hash(enabled, tintAlphaLight, tintAlphaDark, blur);

  @override
  String toString() =>
      'AppGlassStyle(enabled: $enabled, tintAlphaLight: $tintAlphaLight, '
      'tintAlphaDark: $tintAlphaDark, blur: $blur)';
}
