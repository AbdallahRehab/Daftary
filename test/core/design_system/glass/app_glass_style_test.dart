import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_glass_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppGlassStyle', () {
    test('off is disabled at the Medium token values', () {
      expect(AppGlassStyle.off.enabled, isFalse);
      expect(
        AppGlassStyle.off.tintAlphaLight,
        AppGlassTokens.tintAlphaLightMedium,
      );
      expect(
        AppGlassStyle.off.tintAlphaDark,
        AppGlassTokens.tintAlphaDarkMedium,
      );
      expect(AppGlassStyle.off.blur, AppGlassTokens.blurMedium);
    });

    test('value equality covers every field', () {
      const a = AppGlassStyle(
        enabled: true,
        tintAlphaLight: 0.7,
        tintAlphaDark: 0.6,
        blur: 8,
      );
      const b = AppGlassStyle(
        enabled: true,
        tintAlphaLight: 0.7,
        tintAlphaDark: 0.6,
        blur: 8,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      expect(
        a,
        isNot(
          const AppGlassStyle(
            enabled: false,
            tintAlphaLight: 0.7,
            tintAlphaDark: 0.6,
            blur: 8,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const AppGlassStyle(
            enabled: true,
            tintAlphaLight: 0.8,
            tintAlphaDark: 0.6,
            blur: 8,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const AppGlassStyle(
            enabled: true,
            tintAlphaLight: 0.7,
            tintAlphaDark: 0.5,
            blur: 8,
          ),
        ),
      );
      expect(
        a,
        isNot(
          const AppGlassStyle(
            enabled: true,
            tintAlphaLight: 0.7,
            tintAlphaDark: 0.6,
            blur: 14,
          ),
        ),
      );
    });
  });

  group('AppGlassTokens', () {
    test('match the research Decision 7 starting values', () {
      expect(AppGlassTokens.tintAlphaLightLow, 0.86);
      expect(AppGlassTokens.tintAlphaLightMedium, 0.74);
      expect(AppGlassTokens.tintAlphaLightHigh, 0.62);
      expect(AppGlassTokens.tintAlphaDarkLow, 0.84);
      expect(AppGlassTokens.tintAlphaDarkMedium, 0.70);
      expect(AppGlassTokens.tintAlphaDarkHigh, 0.58);
      expect(AppGlassTokens.blurLow, 4);
      expect(AppGlassTokens.blurMedium, 8);
      expect(AppGlassTokens.blurHigh, 14);
      expect(AppGlassTokens.thickness, 10);
    });

    test('higher Transparency is more see-through; higher Intensity blurs '
        'more', () {
      expect(
        AppGlassTokens.tintAlphaLightLow,
        greaterThan(AppGlassTokens.tintAlphaLightMedium),
      );
      expect(
        AppGlassTokens.tintAlphaLightMedium,
        greaterThan(AppGlassTokens.tintAlphaLightHigh),
      );
      expect(
        AppGlassTokens.tintAlphaDarkLow,
        greaterThan(AppGlassTokens.tintAlphaDarkMedium),
      );
      expect(
        AppGlassTokens.tintAlphaDarkMedium,
        greaterThan(AppGlassTokens.tintAlphaDarkHigh),
      );
      expect(AppGlassTokens.blurLow, lessThan(AppGlassTokens.blurMedium));
      expect(AppGlassTokens.blurMedium, lessThan(AppGlassTokens.blurHigh));
    });
  });
}
