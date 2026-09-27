import 'package:daftary/core/design_system/glass/app_glass_tokens.dart';
import 'package:daftary/features/settings/domain/entities/glass_appearance.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:daftary/features/settings/presentation/glass/glass_style_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const lightAlpha = {
    GlassLevel.low: AppGlassTokens.tintAlphaLightLow,
    GlassLevel.medium: AppGlassTokens.tintAlphaLightMedium,
    GlassLevel.high: AppGlassTokens.tintAlphaLightHigh,
  };
  const darkAlpha = {
    GlassLevel.low: AppGlassTokens.tintAlphaDarkLow,
    GlassLevel.medium: AppGlassTokens.tintAlphaDarkMedium,
    GlassLevel.high: AppGlassTokens.tintAlphaDarkHigh,
  };
  const blur = {
    GlassLevel.low: AppGlassTokens.blurLow,
    GlassLevel.medium: AppGlassTokens.blurMedium,
    GlassLevel.high: AppGlassTokens.blurHigh,
  };

  for (final enabled in [true, false]) {
    for (final transparency in GlassLevel.values) {
      for (final intensity in GlassLevel.values) {
        test('maps enabled=$enabled, transparency=${transparency.value}, '
            'intensity=${intensity.value}', () {
          final style = toAppGlassStyle(
            GlassAppearance(
              enabled: enabled,
              transparency: transparency,
              intensity: intensity,
            ),
          );

          expect(style.enabled, enabled);
          expect(style.tintAlphaLight, lightAlpha[transparency]);
          expect(style.tintAlphaDark, darkAlpha[transparency]);
          expect(style.blur, blur[intensity]);
        });
      }
    }
  }

  test('defaults map to the Medium tokens with glass on', () {
    final style = toAppGlassStyle(GlassAppearance.defaults);

    expect(style.enabled, isTrue);
    expect(style.tintAlphaLight, AppGlassTokens.tintAlphaLightMedium);
    expect(style.blur, AppGlassTokens.blurMedium);
  });
}
