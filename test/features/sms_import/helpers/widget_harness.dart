import 'package:daftary/core/design_system/glass/app_glass_scope.dart';
import 'package:daftary/core/design_system/glass/app_glass_style.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// The RTL x LTR x light x dark matrix of ui-contract §8.7.
final smsLocales = [
  (name: 'ar RTL', locale: const Locale('ar')),
  (name: 'en LTR', locale: const Locale('en')),
];
final smsThemes = [
  (name: 'light', theme: buildLightTheme()),
  (name: 'dark', theme: buildDarkTheme()),
];

/// Pumps [page] at `/` inside a router that also knows the bank-message
/// paths, so navigation from the page can be observed.
///
/// [glass] (when non-null) inserts an [AppGlassScope] above the navigator,
/// as `MaterialApp.builder` does in production; [frame] wraps the page at
/// `/` (e.g. in the shell's scaffold and bottom bar).
Future<GoRouter> pumpSmsPage(
  WidgetTester tester,
  Widget page, {
  Locale locale = const Locale('en'),
  ThemeData? theme,
  double textScale = 1,
  bool settle = true,
  AppGlassStyle? glass,
  Widget Function(Widget page)? frame,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => frame?.call(page) ?? page),
      GoRoute(
        path: '/bank-messages',
        builder: (_, _) => const Scaffold(body: Text('hub-route')),
      ),
      GoRoute(
        path: '/bank-messages/enable',
        builder: (_, _) => const Scaffold(body: Text('enable-route')),
      ),
      GoRoute(
        path: '/settings/bank-messages',
        builder: (_, _) => const Scaffold(body: Text('sms-settings-route')),
      ),
      GoRoute(
        path: '/bank-messages/paste',
        builder: (_, _) => const Scaffold(body: Text('paste-route')),
      ),
      GoRoute(
        path: '/bank-messages/ignored',
        builder: (_, _) => const Scaffold(body: Text('ignored-route')),
      ),
      GoRoute(
        path: '/bank-messages/senders',
        builder: (_, _) => const Scaffold(body: Text('senders-route')),
      ),
      GoRoute(
        path: '/bank-messages/learned',
        builder: (_, _) => const Scaffold(body: Text('learned-route')),
      ),
      GoRoute(
        path: '/bank-messages/review/:importId',
        builder: (_, state) =>
            Scaffold(body: Text('review-${state.pathParameters['importId']}')),
      ),
      GoRoute(
        path: '/finance/categories',
        builder: (_, _) => const Scaffold(body: Text('categories-route')),
      ),
      GoRoute(
        path: '/finance/entries/:id/edit',
        builder: (_, state) =>
            Scaffold(body: Text('entry-${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        builder: (_, state) =>
            Scaffold(body: Text('tx-${state.pathParameters['id']}')),
      ),
    ],
  );
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
      locale: locale,
      theme: theme ?? buildLightTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        final scaled = MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        );
        return glass == null
            ? scaled
            : AppGlassScope(style: glass, child: scaled);
      },
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

/// Every tappable control under [root] meets 48 x 48 dp.
void expectTapTargets(WidgetTester tester, Finder root) {
  for (final finder in [
    find.descendant(of: root, matching: find.byType(ChoiceChip)),
    find.descendant(of: root, matching: find.byType(ActionChip)),
    find.descendant(of: root, matching: find.byType(IconButton)),
    find.descendant(of: root, matching: find.byType(TextButton)),
    find.descendant(of: root, matching: find.byType(FilledButton)),
  ]) {
    for (final element in finder.evaluate()) {
      final size = tester.getSize(find.byWidget(element.widget).first);
      expect(size.height, greaterThanOrEqualTo(48), reason: '$element');
      expect(size.width, greaterThanOrEqualTo(48), reason: '$element');
    }
  }
}
