import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'glass_test_harness.dart';

void main() {
  testWidgets('no scope: maybeOf is null, of is off, enabledOf is false', (
    tester,
  ) async {
    late AppGlassStyle? maybe;
    late AppGlassStyle style;
    late bool enabled;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          maybe = AppGlassScope.maybeOf(context);
          style = AppGlassScope.of(context);
          enabled = AppGlassScope.enabledOf(context);
          return const SizedBox();
        },
      ),
    );

    expect(maybe, isNull);
    expect(style, AppGlassStyle.off);
    expect(enabled, isFalse);
  });

  testWidgets('a scope exposes its style', (tester) async {
    late AppGlassStyle style;
    late bool enabled;
    await tester.pumpWidget(
      AppGlassScope(
        style: onStyle,
        child: Builder(
          builder: (context) {
            style = AppGlassScope.of(context);
            enabled = AppGlassScope.enabledOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(style, onStyle);
    expect(enabled, isTrue);
  });

  test('updateShouldNotify only when the style changes', () {
    const child = SizedBox();
    const scope = AppGlassScope(style: onStyle, child: child);

    expect(
      scope.updateShouldNotify(
        const AppGlassScope(style: onStyle, child: child),
      ),
      isFalse,
    );
    expect(
      scope.updateShouldNotify(
        const AppGlassScope(style: AppGlassStyle.off, child: child),
      ),
      isTrue,
    );
  });

  testWidgets('dependents rebuild when the style changes', (tester) async {
    var builds = 0;
    final probe = Builder(
      builder: (context) {
        AppGlassScope.of(context);
        builds++;
        return const SizedBox();
      },
    );

    await tester.pumpWidget(AppGlassScope(style: onStyle, child: probe));
    await tester.pumpWidget(AppGlassScope(style: onStyle, child: probe));
    expect(builds, 1);

    await tester.pumpWidget(
      AppGlassScope(style: AppGlassStyle.off, child: probe),
    );
    expect(builds, 2);
  });
}
