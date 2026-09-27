import 'package:daftary/core/design_system/glass/app_fab.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/glass/app_navigation_bar.dart';
import 'package:daftary/core/design_system/glass/app_scaffold.dart';
import 'package:daftary/core/design_system/glass/app_top_bar.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import 'glass_test_harness.dart';

/// Cross-cutting matrix (020 US5; FR-012, FR-017, FR-018, FR-020): a
/// representative page frame under every theme × direction × glass × text
/// scale combination.
void main() {
  Widget page() => AppScaffold(
    appBar: AppTopBar(
      title: const Text('Title'),
      actions: [
        IconButton(
          tooltip: 'Search',
          icon: const Icon(Icons.search),
          onPressed: () {},
        ),
      ],
    ),
    body: ListView.builder(
      itemCount: 50,
      itemBuilder: (context, i) => ListTile(title: Text('Row $i')),
    ),
    floatingActionButton: AppFab.extended(
      tooltip: 'Add',
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Add'),
    ),
    bottomNavigationBar: AppNavigationBar(
      selectedIndex: 0,
      onDestinationSelected: (_) {},
      destinations: const [
        NavigationDestination(icon: Icon(Icons.people), label: 'People'),
        NavigationDestination(icon: Icon(Icons.pie_chart), label: 'Overview'),
      ],
    ),
  );

  for (final dark in [false, true]) {
    for (final direction in TextDirection.values) {
      for (final glassOn in [false, true]) {
        for (final scale in [1.0, 2.0]) {
          final label =
              '${dark ? 'dark' : 'light'} · ${direction.name} · '
              'glass ${glassOn ? 'ON' : 'OFF'} · text ×$scale';

          testWidgets(label, (tester) async {
            tester.view.physicalSize = const Size(1080, 2340);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              glassApp(
                home: page(),
                style: glassOn ? onStyle : AppGlassStyle.off,
                theme: dark ? buildDarkTheme() : buildLightTheme(),
                textDirection: direction,
                textScale: scale,
              ),
            );
            await tester.pump();

            expect(tester.takeException(), isNull);
            expect(find.byTooltip('Search'), findsOneWidget);
            expect(find.byTooltip('Add'), findsOneWidget);
            expect(find.text('People'), findsOneWidget);
            expect(find.text('Overview'), findsOneWidget);

            // Bar, FAB and navigation bar — and nothing inside the list.
            expect(find.byType(GlassContainer), findsNWidgets(glassOn ? 3 : 0));
            expect(
              find.descendant(
                of: find.byType(ListTile),
                matching: find.byType(GlassContainer),
              ),
              findsNothing,
            );

            // The action sits on the trailing edge in both directions.
            final screenWidth =
                tester.view.physicalSize.width / tester.view.devicePixelRatio;
            final actionX = tester.getCenter(find.byTooltip('Search')).dx;
            expect(
              direction == TextDirection.ltr
                  ? actionX > screenWidth / 2
                  : actionX < screenWidth / 2,
              isTrue,
            );
          });
        }
      }
    }
  }
}
