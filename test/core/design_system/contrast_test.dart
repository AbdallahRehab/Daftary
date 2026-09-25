import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Status colors carry the app's core meaning (who owes whom), so every
/// text pairing they appear in must clear WCAG AA (4.5:1) in both themes.
void main() {
  for (final (name, theme) in [
    ('light', buildLightTheme()),
    ('dark', buildDarkTheme()),
  ]) {
    group('$name theme', () {
      final scheme = theme.colorScheme;
      final f = theme.extension<AppFinanceColors>()!;
      final pairs = <String, (Color, Color)>{
        'positive on surface': (f.positive, scheme.surface),
        'positive on positiveSurface': (f.positive, f.positiveSurface),
        'negative on surface': (f.negative, scheme.surface),
        'negative on negativeSurface': (f.negative, f.negativeSurface),
        'neutral on surface': (f.neutral, scheme.surface),
        'neutral on neutralSurface': (f.neutral, f.neutralSurface),
        'warning on surface': (f.warning, scheme.surface),
        'warning on warningSurface': (f.warning, f.warningSurface),
        'error on surface': (scheme.error, scheme.surface),
      };
      pairs.forEach((label, pair) {
        test('$label meets 4.5:1', () {
          expect(_contrast(pair.$1, pair.$2), greaterThanOrEqualTo(4.5));
        });
      });
    });
  }
}
