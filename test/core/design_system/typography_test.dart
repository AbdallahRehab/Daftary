import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Custom rows (AppTypography) and Material components (textTheme) must
/// share one scale, in both themes.
void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    test('$name textTheme carries the AppTypography roles', () {
      final t = theme.textTheme;
      void same(TextStyle? slot, TextStyle role) {
        expect(slot!.fontSize, role.fontSize);
        expect(slot.height, role.height);
        if (role.fontWeight != null) {
          expect(slot.fontWeight, role.fontWeight);
        }
      }

      same(t.headlineSmall, AppTypography.headline);
      same(t.titleMedium, AppTypography.title);
      same(t.bodyLarge, AppTypography.body);
      same(t.bodyMedium, AppTypography.bodyMuted);
      same(t.labelMedium, AppTypography.label);
      // Tracking would pull Arabic's joined letters apart.
      expect(t.labelMedium!.letterSpacing, 0);
    });
  }

  test('money styles use tabular, lining figures', () {
    for (final style in [AppTypography.amount, AppTypography.figure]) {
      expect(
        style.fontFeatures,
        containsAll(const [
          FontFeature.tabularFigures(),
          FontFeature.liningFigures(),
        ]),
      );
    }
  });

  test('no body-level role is below 14sp', () {
    expect(AppTypography.body.fontSize, greaterThanOrEqualTo(16));
    expect(AppTypography.bodyMuted.fontSize, greaterThanOrEqualTo(14));
  });
}
