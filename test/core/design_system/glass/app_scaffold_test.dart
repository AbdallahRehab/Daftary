import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

void main() {
  Scaffold scaffoldOf(WidgetTester tester) =>
      tester.widget<Scaffold>(find.byType(Scaffold));

  group('OFF', () {
    for (final (name, style) in [
      ('no scope', null),
      ('scope off', AppGlassStyle.off),
    ]) {
      testWidgets('forwards every param unchanged ($name)', (tester) async {
        final appBar = AppBar(title: const Text('Title'));
        const body = Text('Body');
        final fab = FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add),
        );
        const bottom = SizedBox(height: 56);

        await tester.pumpWidget(
          glassApp(
            style: style,
            home: AppScaffold(
              appBar: appBar,
              body: body,
              floatingActionButton: fab,
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.startFloat,
              bottomNavigationBar: bottom,
              backgroundColor: Colors.transparent,
              resizeToAvoidBottomInset: false,
            ),
          ),
        );

        expect(find.byType(GlassContainer), findsNothing);
        final scaffold = scaffoldOf(tester);
        expect(scaffold.appBar, same(appBar));
        expect(scaffold.body, same(body));
        expect(scaffold.floatingActionButton, same(fab));
        expect(
          scaffold.floatingActionButtonLocation,
          FloatingActionButtonLocation.startFloat,
        );
        expect(scaffold.bottomNavigationBar, same(bottom));
        expect(scaffold.backgroundColor, Colors.transparent);
        expect(scaffold.resizeToAvoidBottomInset, isFalse);
        expect(scaffold.extendBodyBehindAppBar, isFalse);
        expect(scaffold.extendBody, isFalse);
      });
    }

    testWidgets('passes the caller\'s extend flags through', (tester) async {
      await tester.pumpWidget(
        glassApp(
          home: const AppScaffold(
            body: SizedBox(),
            extendBody: true,
            extendBodyBehindAppBar: true,
          ),
        ),
      );

      expect(scaffoldOf(tester).extendBody, isTrue);
      expect(scaffoldOf(tester).extendBodyBehindAppBar, isTrue);
    });

    testWidgets('defaults match Scaffold\'s', (tester) async {
      await tester.pumpWidget(glassApp(home: const AppScaffold()));

      const expected = Scaffold();
      final scaffold = scaffoldOf(tester);
      expect(scaffold.backgroundColor, expected.backgroundColor);
      expect(
        scaffold.resizeToAvoidBottomInset,
        expected.resizeToAvoidBottomInset,
      );
      expect(
        scaffold.floatingActionButtonLocation,
        expected.floatingActionButtonLocation,
      );
    });
  });

  group('ON', () {
    testWidgets('extends the body behind an app bar and a bottom bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          home: AppScaffold(
            appBar: AppBar(title: const Text('Title')),
            body: const SizedBox(),
            bottomNavigationBar: const SizedBox(height: 56),
          ),
        ),
      );

      expect(scaffoldOf(tester).extendBodyBehindAppBar, isTrue);
      expect(scaffoldOf(tester).extendBody, isTrue);
    });

    testWidgets('without bars, keeps the caller\'s values', (tester) async {
      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          home: const AppScaffold(body: SizedBox()),
        ),
      );

      expect(scaffoldOf(tester).extendBodyBehindAppBar, isFalse);
      expect(scaffoldOf(tester).extendBody, isFalse);
    });

    testWidgets('only an app bar extends only behind the app bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        glassApp(
          style: onStyle,
          home: AppScaffold(
            appBar: AppBar(title: const Text('Title')),
            body: const SizedBox(),
          ),
        ),
      );

      expect(scaffoldOf(tester).extendBodyBehindAppBar, isTrue);
      expect(scaffoldOf(tester).extendBody, isFalse);
    });
  });
}
