import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/routing/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A minimal 3-branch shell router mirroring `appRouter`'s People/Overview/
/// Settings branch structure, using placeholder pages so this test doesn't
/// depend on the real pages' DI-registered Cubits.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(
                  key: Key('page_People'),
                  body: Text('People'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/overview',
                builder: (context, state) => const Scaffold(
                  key: Key('page_Overview'),
                  body: Text('Overview'),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const Scaffold(
                  key: Key('page_Settings'),
                  body: Text('Settings'),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// `MaterialApp` derives its own `Directionality` from the resolved
// `locale` (Arabic -> RTL, English -> LTR) via `Localizations` — it does
// not inherit an ambient `Directionality`, so the locale itself is what
// drives mirroring here, exactly as it does in the real app.
Widget _wrap(Locale locale) {
  return MaterialApp.router(
    routerConfig: _buildTestRouter(),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

/// Sizes the test surface in logical pixels.
Future<void> _setSize(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

const _phone = Size(390, 844);
const _tablet = Size(1280, 800);

void main() {
  testWidgets('renders the 3 destinations in People/Home/Settings order '
      'under LTR', (tester) async {
    await _setSize(tester, _phone);
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();

    expect(destinations, hasLength(3));
    expect(destinations[0].label, 'People');
    expect(destinations[1].label, 'Home');
    expect(destinations[2].label, 'Settings');

    // LTR: destinations lay out left-to-right, so x offsets increase.
    final offsets = destinations
        .map((d) => tester.getTopLeft(find.byWidget(d)).dx)
        .toList();
    expect(offsets[0], lessThan(offsets[1]));
    expect(offsets[1], lessThan(offsets[2]));
  });

  testWidgets('mirrors destination layout order under RTL', (tester) async {
    await _setSize(tester, _phone);
    await tester.pumpWidget(_wrap(const Locale('ar')));
    await tester.pumpAndSettle();

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();

    expect(destinations, hasLength(3));
    // Underlying destination order/icons are unchanged (Arabic labels)...
    expect(destinations[0].label, 'الأشخاص');
    expect(destinations[1].label, 'الرئيسية');
    expect(destinations[2].label, 'الإعدادات');

    // ...but under RTL, NavigationBar mirrors layout automatically: the
    // first-declared destination renders on the right, not the left.
    final offsets = destinations
        .map((d) => tester.getTopLeft(find.byWidget(d)).dx)
        .toList();
    expect(offsets[0], greaterThan(offsets[1]));
    expect(offsets[1], greaterThan(offsets[2]));
  });

  group('medium and wider windows', () {
    testWidgets('a tablet gets a navigation rail and a capped, centered '
        'content column instead of a stretched phone layout', (tester) async {
      await _setSize(tester, _tablet);
      await tester.pumpWidget(_wrap(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsOneWidget);

      final page = tester.getRect(find.byKey(const Key('page_People')));
      final rail = tester.getRect(find.byType(NavigationRail));
      expect(page.width, 720);
      // Centered in the space to the right of the rail.
      final free = _tablet.width - rail.right;
      expect(page.left - rail.right, closeTo((free - 720) / 2, 0.5));
    });

    testWidgets('a landscape phone switches to the rail too', (tester) async {
      await _setSize(tester, const Size(844, 390));
      await tester.pumpWidget(_wrap(const Locale('en')));
      await tester.pumpAndSettle();

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the rail sits on the leading edge under RTL', (tester) async {
      await _setSize(tester, _tablet);
      await tester.pumpWidget(_wrap(const Locale('ar')));
      await tester.pumpAndSettle();

      final rail = tester.getRect(find.byType(NavigationRail));
      expect(rail.right, _tablet.width);
    });

    testWidgets('selecting a rail destination switches branch', (tester) async {
      await _setSize(tester, _tablet);
      await tester.pumpWidget(_wrap(const Locale('en')));
      await tester.pumpAndSettle();

      // The second destination is labelled Home since 012.
      await tester.tap(find.text('Home').last);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('page_Overview')), findsOneWidget);
    });
  });
}
