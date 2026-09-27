import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_glass_surface.dart';
import 'package:daftary/core/design_system/glass/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

void main() {
  const title = Text('Title');
  const leadingKey = Key('leading');
  const actionKey = Key('action');

  AppTopBar buildBar({
    VoidCallback? onAction,
    VoidCallback? onLeading,
    List<Widget>? actions,
  }) {
    return AppTopBar(
      title: title,
      leading: IconButton(
        key: leadingKey,
        tooltip: 'Menu',
        icon: const Icon(Icons.menu),
        onPressed: onLeading ?? () {},
      ),
      actions:
          actions ??
          [
            IconButton(
              key: actionKey,
              tooltip: 'Add',
              icon: const Icon(Icons.add),
              onPressed: onAction ?? () {},
            ),
          ],
    );
  }

  group('OFF', () {
    for (final (name, style) in [
      ('no scope', null),
      ('scope off', AppGlassStyle.off),
    ]) {
      testWidgets('builds the plain AppBar with the same args ($name)', (
        tester,
      ) async {
        final actions = <Widget>[
          IconButton(
            key: actionKey,
            tooltip: 'Add',
            icon: const Icon(Icons.add),
            onPressed: () {},
          ),
        ];
        final bar = buildBar(actions: actions);
        await tester.pumpWidget(
          glassApp(
            style: style,
            home: Scaffold(appBar: bar),
          ),
        );

        expect(find.byType(GlassContainer), findsNothing);
        expect(find.byType(AppGlassSurface), findsNothing);

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        final expected = AppBar(
          title: title,
          leading: bar.leading,
          actions: actions,
        );
        expect(appBar.title, same(expected.title));
        expect(appBar.leading, same(expected.leading));
        expect(appBar.actions, same(expected.actions));
        expect(
          appBar.automaticallyImplyLeading,
          expected.automaticallyImplyLeading,
        );
        expect(appBar.centerTitle, expected.centerTitle);
        expect(appBar.bottom, expected.bottom);
        expect(appBar.backgroundColor, expected.backgroundColor);
        expect(appBar.surfaceTintColor, expected.surfaceTintColor);
        expect(appBar.elevation, expected.elevation);
        expect(appBar.scrolledUnderElevation, expected.scrolledUnderElevation);
        expect(appBar.flexibleSpace, expected.flexibleSpace);
      });
    }
  });

  group('ON', () {
    testWidgets('one glass surface behind a transparent AppBar', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          home: Scaffold(appBar: buildBar()),
        ),
      );

      expect(find.byType(GlassContainer), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.backgroundColor, Colors.transparent);
      expect(appBar.surfaceTintColor, Colors.transparent);
      expect(appBar.elevation, 0);
      expect(appBar.scrolledUnderElevation, 0);
      expect(appBar.flexibleSpace, isA<AppGlassSurface>());
      expect(appBar.title, same(title));
    });
  });

  for (final (mode, style) in [('OFF', null), ('ON', onStyle)]) {
    group('both modes ($mode)', () {
      testWidgets('preferredSize equals the AppBar equivalent', (tester) async {
        const bottom = PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: SizedBox(),
        );
        expect(
          const AppTopBar(title: title).preferredSize,
          AppBar(title: title).preferredSize,
        );
        expect(
          const AppTopBar(title: title, bottom: bottom).preferredSize,
          AppBar(title: title, bottom: bottom).preferredSize,
        );
      });

      testWidgets('callbacks fire and tooltips are present', (tester) async {
        var actionTaps = 0;
        var leadingTaps = 0;
        await tester.pumpWidget(
          glassApp(
            style: style,
            home: Scaffold(
              appBar: buildBar(
                onAction: () => actionTaps++,
                onLeading: () => leadingTaps++,
              ),
            ),
          ),
        );

        expect(find.byTooltip('Add'), findsOneWidget);
        expect(find.byTooltip('Menu'), findsOneWidget);
        await tester.tap(find.byKey(actionKey));
        await tester.tap(find.byKey(leadingKey));
        expect(actionTaps, 1);
        expect(leadingTaps, 1);
      });

      testWidgets('the implied back button still pops', (tester) async {
        await tester.pumpWidget(
          glassApp(
            style: style,
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(
                        appBar: AppTopBar(title: Text('Second')),
                      ),
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
        expect(find.text('Second'), findsOneWidget);
        expect(find.byType(BackButton), findsOneWidget);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();
        expect(find.text('Second'), findsNothing);
      });

      testWidgets('no overflow at text scale 2.0', (tester) async {
        await tester.pumpWidget(
          glassApp(
            style: style,
            textScale: 2,
            home: Scaffold(appBar: buildBar()),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('leading and actions mirror under RTL', (tester) async {
        await tester.pumpWidget(
          glassApp(
            style: style,
            home: Scaffold(appBar: buildBar()),
          ),
        );
        final ltrLeading = tester.getCenter(find.byKey(leadingKey)).dx;
        final ltrAction = tester.getCenter(find.byKey(actionKey)).dx;
        expect(ltrLeading, lessThan(ltrAction));

        await tester.pumpWidget(
          glassApp(
            style: style,
            textDirection: TextDirection.rtl,
            home: Scaffold(appBar: buildBar()),
          ),
        );
        final rtlLeading = tester.getCenter(find.byKey(leadingKey)).dx;
        final rtlAction = tester.getCenter(find.byKey(actionKey)).dx;
        expect(rtlLeading, greaterThan(rtlAction));
      });
    });
  }
}
