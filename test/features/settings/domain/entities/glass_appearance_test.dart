import 'package:daftary/features/settings/domain/entities/glass_appearance.dart';
import 'package:daftary/features/settings/domain/entities/glass_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults are enabled with medium transparency and intensity', () {
    expect(
      GlassAppearance.defaults,
      const GlassAppearance(
        enabled: true,
        transparency: GlassLevel.medium,
        intensity: GlassLevel.medium,
      ),
    );
  });

  test('equality and hashCode cover all three fields', () {
    const a = GlassAppearance(
      enabled: false,
      transparency: GlassLevel.high,
      intensity: GlassLevel.low,
    );
    const b = GlassAppearance(
      enabled: false,
      transparency: GlassLevel.high,
      intensity: GlassLevel.low,
    );

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(b.copyWith(enabled: true)));
    expect(a, isNot(b.copyWith(transparency: GlassLevel.medium)));
    expect(a, isNot(b.copyWith(intensity: GlassLevel.medium)));
  });

  test('copyWith changes only the named field', () {
    const base = GlassAppearance.defaults;

    expect(
      base.copyWith(transparency: GlassLevel.high),
      const GlassAppearance(transparency: GlassLevel.high),
    );
    expect(
      base.copyWith(intensity: GlassLevel.low),
      const GlassAppearance(intensity: GlassLevel.low),
    );
    expect(base.copyWith(), base);
  });

  test('disabling keeps transparency and intensity unchanged '
      '(data-model.md State transitions)', () {
    const base = GlassAppearance(
      transparency: GlassLevel.high,
      intensity: GlassLevel.low,
    );

    final disabled = base.copyWith(enabled: false);

    expect(disabled.enabled, isFalse);
    expect(disabled.transparency, GlassLevel.high);
    expect(disabled.intensity, GlassLevel.low);
    expect(disabled.copyWith(enabled: true), base);
  });

  test('GlassLevel wire values are low, medium, high', () {
    expect(GlassLevel.values.map((l) => l.value).toList(), [
      'low',
      'medium',
      'high',
    ]);
  });
}
