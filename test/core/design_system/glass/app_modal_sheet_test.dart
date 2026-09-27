import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_glass_surface.dart';
import 'package:daftary/core/design_system/glass/app_modal_sheet.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

void main() {
  const sheetBody = 'Sheet body';

  /// Pumps a page whose button opens a sheet with a [bodyHeight]-tall body,
  /// and returns once it is open. The 800x600 test surface makes a 500-tall
  /// body taller than a non-scroll-controlled sheet's 9/16 cap (337.5).
  Future<void> openSheet(
    WidgetTester tester, {
    AppGlassStyle? style,
    bool isScrollControlled = false,
    double bodyHeight = 200,
  }) async {
    await tester.pumpWidget(
      glassApp(
        style: style,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppModalSheet<void>(
                context: context,
                isScrollControlled: isScrollControlled,
                builder: (_) => SizedBox(
                  height: bodyHeight,
                  child: const Center(child: Text(sheetBody)),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text(sheetBody), findsOneWidget);
  }

  BottomSheet sheetOf(WidgetTester tester) =>
      tester.widget<BottomSheet>(find.byType(BottomSheet));

  ModalBottomSheetRoute<void> routeOf(WidgetTester tester) =>
      ModalRoute.of(tester.element(find.text(sheetBody)))!
          as ModalBottomSheetRoute<void>;

  group('OFF', () {
    for (final (name, style) in [
      ('no scope', null),
      ('scope off', AppGlassStyle.off),
    ]) {
      testWidgets('the plain sheet with the theme background ($name)', (
        tester,
      ) async {
        await openSheet(tester, style: style);

        expect(find.byType(GlassContainer), findsNothing);
        expect(find.byType(AppGlassSurface), findsNothing);
        // No colour or elevation is passed, so the theme's apply.
        final route = routeOf(tester);
        expect(route.backgroundColor, isNull);
        expect(route.elevation, isNull);
        expect(route.isScrollControlled, isFalse);

        final theme = Theme.of(tester.element(find.text(sheetBody)));
        expect(
          sheetOf(tester).backgroundColor,
          theme.bottomSheetTheme.backgroundColor,
        );
      });
    }
  });

  group('ON', () {
    testWidgets('a transparent sheet with the body in one glass surface', (
      tester,
    ) async {
      await openSheet(tester, style: onStyle);

      final route = routeOf(tester);
      expect(route.backgroundColor, Colors.transparent);
      expect(route.elevation, 0);
      expect(sheetOf(tester).backgroundColor, Colors.transparent);
      expect(sheetOf(tester).elevation, 0);

      expect(find.byType(GlassContainer), findsOneWidget);
      final surface = find.ancestor(
        of: find.text(sheetBody),
        matching: find.byType(AppGlassSurface),
      );
      expect(surface, findsOneWidget);
      expect(
        tester.widget<AppGlassSurface>(surface).borderRadius,
        AppRadius.lg,
      );
    });
  });

  for (final (mode, style) in [('OFF', null), ('ON', onStyle)]) {
    group('both modes ($mode)', () {
      testWidgets('isScrollControlled is honoured', (tester) async {
        await openSheet(tester, style: style, bodyHeight: 500);
        expect(tester.getSize(find.byType(BottomSheet)).height, lessThan(500));
        Navigator.of(tester.element(find.text(sheetBody))).pop();
        await tester.pumpAndSettle();

        await openSheet(
          tester,
          style: style,
          isScrollControlled: true,
          bodyHeight: 500,
        );
        expect(routeOf(tester).isScrollControlled, isTrue);
        expect(tester.getSize(find.byType(BottomSheet)).height, 500);
      });

      testWidgets('dismisses on a barrier tap', (tester) async {
        await openSheet(tester, style: style);

        await tester.tapAt(const Offset(20, 20));
        await tester.pumpAndSettle();
        expect(find.text(sheetBody), findsNothing);
      });

      testWidgets('dismisses on a downward drag', (tester) async {
        await openSheet(tester, style: style);

        await tester.drag(find.text(sheetBody), const Offset(0, 400));
        await tester.pumpAndSettle();
        expect(find.text(sheetBody), findsNothing);
      });
    });
  }
}
