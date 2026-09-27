import 'package:daftary/core/design_system/glass/app_fab.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

typedef _FabPair = ({
  AppFab Function(VoidCallback onPressed) app,
  FloatingActionButton Function(VoidCallback onPressed) material,
  double radius,
});

void main() {
  const icon = Icon(Icons.add, key: Key('icon'));
  const label = Text('Add person');
  final defaultHeroTag = const FloatingActionButton(onPressed: null).heroTag;

  final variants = <String, _FabPair>{
    'AppFab': (
      app: (onPressed) =>
          AppFab(onPressed: onPressed, tooltip: 'Add', child: icon),
      material: (onPressed) => FloatingActionButton(
        onPressed: onPressed,
        tooltip: 'Add',
        child: icon,
      ),
      radius: AppRadius.lg,
    ),
    'AppFab.small': (
      app: (onPressed) =>
          AppFab.small(onPressed: onPressed, tooltip: 'Add', child: icon),
      material: (onPressed) => FloatingActionButton.small(
        onPressed: onPressed,
        tooltip: 'Add',
        child: icon,
      ),
      radius: AppRadius.md,
    ),
    'AppFab.extended': (
      app: (onPressed) => AppFab.extended(
        onPressed: onPressed,
        tooltip: 'Add',
        icon: icon,
        label: label,
      ),
      material: (onPressed) => FloatingActionButton.extended(
        onPressed: onPressed,
        tooltip: 'Add',
        icon: icon,
        label: label,
      ),
      radius: AppRadius.lg,
    ),
  };

  Widget host(
    Widget fab, {
    AppGlassStyle? style,
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
  }) {
    return glassApp(
      style: style,
      textDirection: textDirection,
      textScale: textScale,
      home: Scaffold(floatingActionButton: fab),
    );
  }

  FloatingActionButton fabOf(WidgetTester tester) =>
      tester.widget<FloatingActionButton>(find.byType(FloatingActionButton));

  for (final MapEntry(key: name, value: variant) in variants.entries) {
    group(name, () {
      for (final (mode, style) in [
        ('no scope', null),
        ('scope off', AppGlassStyle.off),
      ]) {
        testWidgets('OFF ($mode): identical to the FloatingActionButton', (
          tester,
        ) async {
          void onPressed() {}
          final expected = variant.material(onPressed);
          await tester.pumpWidget(host(expected));
          final expectedSize = tester.getSize(
            find.byType(FloatingActionButton),
          );

          await tester.pumpWidget(host(variant.app(onPressed), style: style));

          expect(find.byType(GlassContainer), findsNothing);
          final fab = fabOf(tester);
          expect(fab.onPressed, same(onPressed));
          expect(fab.tooltip, expected.tooltip);
          expect(fab.child, same(expected.child));
          expect(fab.heroTag, same(defaultHeroTag));
          expect(fab.mini, expected.mini);
          expect(fab.isExtended, expected.isExtended);
          expect(fab.backgroundColor, isNull);
          expect(fab.foregroundColor, isNull);
          expect(fab.elevation, isNull);
          expect(
            tester.getSize(find.byType(FloatingActionButton)),
            expectedSize,
          );
        });
      }

      testWidgets('an explicit heroTag is forwarded', (tester) async {
        final withTag = switch (name) {
          'AppFab' => AppFab(onPressed: () {}, heroTag: 'tag', child: icon),
          'AppFab.small' => AppFab.small(
            onPressed: () {},
            heroTag: 'tag',
            child: icon,
          ),
          _ => AppFab.extended(onPressed: () {}, heroTag: 'tag', label: label),
        };
        await tester.pumpWidget(host(withTag));
        expect(fabOf(tester).heroTag, 'tag');

        await tester.pumpWidget(host(withTag, style: onStyle));
        expect(fabOf(tester).heroTag, 'tag');
      });

      testWidgets('ON: one glass surface behind a transparent FAB', (
        tester,
      ) async {
        await tester.pumpWidget(host(variant.material(() {})));
        final expectedSize = tester.getSize(find.byType(FloatingActionButton));

        await tester.pumpWidget(host(variant.app(() {}), style: onStyle));

        expect(find.byType(GlassContainer), findsOneWidget);
        final fab = fabOf(tester);
        final theme = Theme.of(tester.element(find.byType(Scaffold)));
        expect(fab.backgroundColor, Colors.transparent);
        expect(fab.foregroundColor, theme.colorScheme.primary);
        expect(fab.elevation, 0);
        expect(fab.focusElevation, 0);
        expect(fab.hoverElevation, 0);
        expect(fab.highlightElevation, 0);
        expect(fab.disabledElevation, 0);
        expect(fab.heroTag, same(defaultHeroTag));
        expect(tester.getSize(find.byType(FloatingActionButton)), expectedSize);

        final glass = tester.widget<GlassContainer>(
          find.byType(GlassContainer),
        );
        expect(
          (glass.shape as LiquidRoundedSuperellipse).borderRadius,
          variant.radius,
        );
      });

      for (final (mode, style) in [('OFF', null), ('ON', onStyle)]) {
        testWidgets('$mode: onPressed fires and the tooltip is present', (
          tester,
        ) async {
          var taps = 0;
          await tester.pumpWidget(
            host(variant.app(() => taps++), style: style),
          );

          expect(find.byTooltip('Add'), findsOneWidget);
          await tester.tap(find.byType(FloatingActionButton));
          expect(taps, 1);
        });

        testWidgets('$mode: no overflow at text scale 2.0', (tester) async {
          await tester.pumpWidget(
            host(variant.app(() {}), style: style, textScale: 2),
          );

          expect(tester.takeException(), isNull);
        });
      }
    });
  }

  group('AppFab.extended RTL', () {
    for (final (mode, style) in [('OFF', null), ('ON', onStyle)]) {
      testWidgets('$mode: icon and label order mirror', (tester) async {
        final fab = variants['AppFab.extended']!.app(() {});

        await tester.pumpWidget(host(fab, style: style));
        expect(
          tester.getCenter(find.byKey(const Key('icon'))).dx,
          lessThan(tester.getCenter(find.text('Add person')).dx),
        );

        await tester.pumpWidget(
          host(fab, style: style, textDirection: TextDirection.rtl),
        );
        expect(
          tester.getCenter(find.byKey(const Key('icon'))).dx,
          greaterThan(tester.getCenter(find.text('Add person')).dx),
        );
      });
    }
  });
}
