import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

void main() {
  const destinations = <Widget>[
    NavigationDestination(icon: Icon(Icons.people), label: 'One'),
    NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Two'),
    NavigationDestination(icon: Icon(Icons.settings), label: 'Three'),
  ];

  Widget host({
    required ValueChanged<int> onSelected,
    AppGlassStyle? style,
    TextDirection textDirection = TextDirection.ltr,
    double textScale = 1,
  }) {
    return glassApp(
      style: style,
      textDirection: textDirection,
      textScale: textScale,
      home: Scaffold(
        bottomNavigationBar: AppNavigationBar(
          selectedIndex: 0,
          onDestinationSelected: onSelected,
          destinations: destinations,
        ),
      ),
    );
  }

  group('OFF', () {
    for (final (name, style) in [
      ('no scope', null),
      ('scope off', AppGlassStyle.off),
    ]) {
      testWidgets('builds the plain NavigationBar ($name)', (tester) async {
        void onSelected(int _) {}
        await tester.pumpWidget(host(style: style, onSelected: onSelected));

        expect(find.byType(GlassContainer), findsNothing);
        expect(
          find.ancestor(
            of: find.byType(NavigationBar),
            matching: find.byType(Stack),
          ),
          findsNothing,
        );
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.selectedIndex, 0);
        expect(bar.destinations, same(destinations));
        expect(bar.onDestinationSelected, same(onSelected));
        expect(bar.backgroundColor, isNull);
        expect(bar.surfaceTintColor, isNull);
        expect(bar.elevation, isNull);
      });
    }
  });

  group('ON', () {
    testWidgets('one glass surface behind a transparent NavigationBar', (
      tester,
    ) async {
      await tester.pumpWidget(host(style: onStyle, onSelected: (_) {}));

      expect(find.byType(GlassContainer), findsOneWidget);
      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.surfaceTintColor, Colors.transparent);
      expect(bar.elevation, 0);
      expect(bar.selectedIndex, 0);
      expect(bar.destinations, same(destinations));

      // The glass fills the whole bar, including its bottom safe area.
      expect(
        tester.getRect(find.byType(GlassContainer)),
        tester.getRect(find.byType(NavigationBar)),
      );
    });
  });

  for (final (mode, style) in [('OFF', null), ('ON', onStyle)]) {
    group('both modes ($mode)', () {
      testWidgets('tapping a destination reports its index', (tester) async {
        final selected = <int>[];
        await tester.pumpWidget(host(style: style, onSelected: selected.add));

        await tester.tap(find.text('Two'));
        await tester.tap(find.text('Three'));
        expect(selected, [1, 2]);
      });

      testWidgets('labels are present at text scale 2.0 without overflow', (
        tester,
      ) async {
        await tester.pumpWidget(
          host(style: style, textScale: 2, onSelected: (_) {}),
        );

        expect(tester.takeException(), isNull);
        for (final label in ['One', 'Two', 'Three']) {
          expect(find.text(label), findsOneWidget);
        }
      });

      testWidgets('destinations mirror under RTL', (tester) async {
        await tester.pumpWidget(host(style: style, onSelected: (_) {}));
        expect(
          tester.getCenter(find.text('One')).dx,
          lessThan(tester.getCenter(find.text('Three')).dx),
        );

        await tester.pumpWidget(
          host(
            style: style,
            textDirection: TextDirection.rtl,
            onSelected: (_) {},
          ),
        );
        expect(
          tester.getCenter(find.text('One')).dx,
          greaterThan(tester.getCenter(find.text('Three')).dx),
        );
      });
    });
  }
}
