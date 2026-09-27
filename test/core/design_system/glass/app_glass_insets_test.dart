import 'package:daftary/core/design_system/glass/app_glass_insets.dart';
import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'glass_test_harness.dart';

void main() {
  const padding = EdgeInsets.fromLTRB(0, 47, 0, 34);

  Future<EdgeInsets> insetsUnder(
    WidgetTester tester, {
    AppGlassStyle? style,
  }) async {
    late EdgeInsets insets;
    Widget probe = Builder(
      builder: (context) {
        insets = AppGlassInsets.of(context);
        return const SizedBox();
      },
    );
    if (style != null) {
      probe = AppGlassScope(style: style, child: probe);
    }
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: padding),
        child: probe,
      ),
    );
    return insets;
  }

  testWidgets('no scope: zero even with a non-zero MediaQuery padding', (
    tester,
  ) async {
    expect(await insetsUnder(tester), EdgeInsets.zero);
  });

  testWidgets('scope OFF: zero', (tester) async {
    expect(
      await insetsUnder(tester, style: AppGlassStyle.off),
      EdgeInsets.zero,
    );
  });

  testWidgets('scope ON: the MediaQuery padding', (tester) async {
    expect(await insetsUnder(tester, style: onStyle), padding);
  });
}
