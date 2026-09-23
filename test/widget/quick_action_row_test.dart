import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/dashboard/presentation/widgets/quick_action_button.dart';
import 'package:daftary/features/dashboard/presentation/widgets/quick_action_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _PushCounter extends NavigatorObserver {
  int pushes = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // The initial Home route has no predecessor — only count real pushes.
    if (previousRoute != null) pushes++;
  }
}

void main() {
  late GoRouter router;
  late _PushCounter counter;
  late int returns;
  String? lastStubLocation;

  Widget stub(GoRouterState state) {
    lastStubLocation = state.uri.toString();
    return Scaffold(body: Text('stub:${state.uri}'));
  }

  Future<void> pumpRow(
    WidgetTester tester, {
    bool showOccasion = false,
    bool showScan = false,
    Locale locale = const Locale('en'),
  }) async {
    returns = 0;
    lastStubLocation = null;
    counter = _PushCounter();
    router = GoRouter(
      observers: [counter],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: QuickActionRow(
                showOccasion: showOccasion,
                showScan: showScan,
                onReturn: () => returns++,
              ),
            ),
          ),
        ),
        for (final path in [
          '/finance/entries/new',
          '/people/new',
          '/transactions/new',
          '/occasions/new',
          '/ocr/scan',
        ])
          GoRoute(path: path, builder: (context, state) => stub(state)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      MaterialApp.router(
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The full location (path + query) of the stub page on top, or `null`
  /// when Home itself is showing.
  String? currentLocation() =>
      find.textContaining('stub:').evaluate().isEmpty ? null : lastStubLocation;

  void usePhoneSize(WidgetTester tester, {double width = 320}) {
    tester.view.physicalSize = Size(width, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  const activeActions = {
    'Add expense': '/finance/entries/new?type=expense',
    'Add income': '/finance/entries/new?type=income',
    'Add person': '/people/new',
    'Money received': '/transactions/new?direction=received',
    'Money given': '/transactions/new?direction=given',
  };

  group('with both feature flags off', () {
    testWidgets('renders exactly the five active quick actions', (
      tester,
    ) async {
      await pumpRow(tester);

      expect(find.byType(QuickActionButton), findsNWidgets(5));
      for (final label in activeActions.keys) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('Add occasion'), findsNothing);
      expect(find.text('Scan paper'), findsNothing);
    });

    for (final entry in activeActions.entries) {
      testWidgets(
        '"${entry.key}" pushes ${entry.value} and reports the return',
        (tester) async {
          await pumpRow(tester);

          await tester.tap(find.text(entry.key));
          await tester.pumpAndSettle();

          expect(currentLocation(), entry.value);
          expect(find.text('stub:${entry.value}'), findsOneWidget);
          expect(returns, 0);

          router.pop();
          await tester.pumpAndSettle();

          expect(currentLocation(), isNull);
          expect(returns, 1);
        },
      );
    }
  });

  group('with both feature flags on', () {
    testWidgets('also renders the occasion and scan slots', (tester) async {
      await pumpRow(tester, showOccasion: true, showScan: true);

      expect(find.byType(QuickActionButton), findsNWidgets(7));
      expect(find.text('Add occasion'), findsOneWidget);
      expect(find.text('Scan paper'), findsOneWidget);
    });

    testWidgets('"Add occasion" pushes /occasions/new', (tester) async {
      await pumpRow(tester, showOccasion: true, showScan: true);

      await tester.tap(find.text('Add occasion'));
      await tester.pumpAndSettle();

      expect(currentLocation(), '/occasions/new');
    });

    testWidgets('"Scan paper" pushes /ocr/scan', (tester) async {
      await pumpRow(tester, showOccasion: true, showScan: true);

      await tester.tap(find.text('Scan paper'));
      await tester.pumpAndSettle();

      expect(currentLocation(), '/ocr/scan');
    });

    testWidgets('only one flag on renders only that slot', (tester) async {
      await pumpRow(tester, showOccasion: true);

      expect(find.byType(QuickActionButton), findsNWidgets(6));
      expect(find.text('Add occasion'), findsOneWidget);
      expect(find.text('Scan paper'), findsNothing);
    });
  });

  group('FR-013 duplicate-navigation protection', () {
    testWidgets('a rapid double-tap triggers only one navigation', (
      tester,
    ) async {
      await pumpRow(tester);

      // Two taps with no frame in between — the second lands on the same,
      // not-yet-rebuilt button.
      await tester.tap(find.text('Add expense'));
      await tester.tap(find.text('Add expense'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(counter.pushes, 1);
    });

    testWidgets('the button is re-enabled once the pushed route pops', (
      tester,
    ) async {
      await pumpRow(tester);

      await tester.tap(find.text('Add person'));
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add person'));
      await tester.pumpAndSettle();

      expect(counter.pushes, 2);
      expect(currentLocation(), '/people/new');
    });
  });

  group('layout', () {
    testWidgets('all seven actions fit a narrow phone without overflow', (
      tester,
    ) async {
      usePhoneSize(tester);
      await pumpRow(tester, showOccasion: true, showScan: true);

      expect(tester.takeException(), isNull);
      expect(find.byType(QuickActionButton), findsNWidgets(7));
      for (final finder in find.byType(QuickActionButton).evaluate()) {
        final rect = tester.getRect(find.byWidget(finder.widget));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(320));
      }
    });

    testWidgets('renders localized labels under Arabic (RTL) without '
        'overflow', (tester) async {
      usePhoneSize(tester);
      await pumpRow(
        tester,
        showOccasion: true,
        showScan: true,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('إضافة مصروف'), findsOneWidget);
      expect(find.text('مسح ورقة'), findsOneWidget);
      // RTL: the first action sits at the trailing (right) edge.
      final first = tester.getRect(find.text('إضافة مصروف'));
      final second = tester.getRect(find.text('إضافة دخل'));
      expect(first.left, greaterThan(second.left));
    });
  });
}
