import 'package:daftary/core/design_system/glass/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

/// FR-019: the app keeps the package's automatic accessibility bridging on,
/// so iOS "Increase Contrast" and reduce-motion reach every glass surface.
void main() {
  testWidgets(
    'system high contrast and reduced motion reach glass surfaces with glass ON',
    (tester) async {
      late GlassAccessibilityData data;

      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(highContrast: true, disableAnimations: true),
              child: Scaffold(
                appBar: const AppTopBar(title: Text('Title')),
                body: Builder(
                  builder: (context) {
                    data = GlassAccessibilityData.of(context);
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(GlassContainer), findsOneWidget);
      expect(data.reduceTransparency, isTrue);
      expect(data.reduceMotion, isTrue);
    },
  );

  testWidgets('without the system flags glass renders unrestricted', (
    tester,
  ) async {
    late GlassAccessibilityData data;

    await tester.pumpWidget(
      glassApp(
        style: onStyle,
        home: Builder(
          builder: (context) {
            data = GlassAccessibilityData.of(context);
            return const Scaffold(appBar: AppTopBar(title: Text('Title')));
          },
        ),
      ),
    );

    expect(data.reduceTransparency, isFalse);
    expect(data.reduceMotion, isFalse);
  });
}
