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
                builder: (context, state) => const Text('People'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/overview',
                builder: (context, state) => const Text('Overview'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const Text('Settings'),
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

void main() {
  testWidgets('renders the 3 destinations in People/Overview/Settings order '
      'under LTR', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('en')));
    await tester.pumpAndSettle();

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();

    expect(destinations, hasLength(3));
    expect(destinations[0].label, 'People');
    expect(destinations[1].label, 'Overview');
    expect(destinations[2].label, 'Settings');

    // LTR: destinations lay out left-to-right, so x offsets increase.
    final offsets = destinations
        .map((d) => tester.getTopLeft(find.byWidget(d)).dx)
        .toList();
    expect(offsets[0], lessThan(offsets[1]));
    expect(offsets[1], lessThan(offsets[2]));
  });

  testWidgets('mirrors destination layout order under RTL', (tester) async {
    await tester.pumpWidget(_wrap(const Locale('ar')));
    await tester.pumpAndSettle();

    final destinations = tester
        .widgetList<NavigationDestination>(find.byType(NavigationDestination))
        .toList();

    expect(destinations, hasLength(3));
    // Underlying destination order/icons are unchanged (Arabic labels)...
    expect(destinations[0].label, 'الأشخاص');
    expect(destinations[1].label, 'نظرة عامة');
    expect(destinations[2].label, 'الإعدادات');

    // ...but under RTL, NavigationBar mirrors layout automatically: the
    // first-declared destination renders on the right, not the left.
    final offsets = destinations
        .map((d) => tester.getTopLeft(find.byWidget(d)).dx)
        .toList();
    expect(offsets[0], greaterThan(offsets[1]));
    expect(offsets[1], greaterThan(offsets[2]));
  });
}
