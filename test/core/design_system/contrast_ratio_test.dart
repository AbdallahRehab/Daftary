import 'dart:math' as math;

import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standard WCAG 2.1 relative-luminance formula (data-model.md "WCAG 2.1 AA
/// contrast verification"), computed directly from token values — no
/// widget pump required. Guards the values recorded by hand in
/// data-model.md against silent drift.
double _relativeLuminance(Color color) {
  double linearize(double c) {
    if (c <= 0.03928) return c / 12.92;
    return math.pow((c + 0.055) / 1.055, 2.4) as double;
  }

  final r = linearize(color.r);
  final g = linearize(color.g);
  final b = linearize(color.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  group('Dark theme WCAG 2.1 AA contrast (data-model.md table)', () {
    final darkScheme = buildDarkTheme().colorScheme;
    final darkFinance = AppFinanceColors.dark;

    test('onSurface text on background >= 4.5:1', () {
      final ratio = contrastRatio(darkScheme.onSurface, darkScheme.surface);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('onSurfaceVariant text on background >= 4.5:1', () {
      final ratio = contrastRatio(
        darkScheme.onSurfaceVariant,
        darkScheme.surface,
      );
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('positive financial text on background >= 4.5:1', () {
      final ratio = contrastRatio(darkFinance.positive, darkScheme.surface);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('positive icon/text on positiveSurface >= 3:1', () {
      final ratio = contrastRatio(
        darkFinance.positive,
        darkFinance.positiveSurface,
      );
      expect(ratio, greaterThanOrEqualTo(3));
    });

    test('negative financial text on background >= 4.5:1', () {
      final ratio = contrastRatio(darkFinance.negative, darkScheme.surface);
      expect(ratio, greaterThanOrEqualTo(4.5));
    });

    test('negative icon/text on negativeSurface >= 3:1', () {
      final ratio = contrastRatio(
        darkFinance.negative,
        darkFinance.negativeSurface,
      );
      expect(ratio, greaterThanOrEqualTo(3));
    });
  });

  // Light theme pairs are unchanged from the app's current (already-
  // shipping) values and are intentionally not re-verified here — only the
  // newly-introduced dark values needed checking (data-model.md WCAG 2.1 AA
  // contrast verification section).
}
