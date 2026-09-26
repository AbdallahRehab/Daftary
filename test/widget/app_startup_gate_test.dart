import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_state.dart';
import 'package:daftary/features/startup/presentation/widgets/app_startup_gate.dart';
import 'package:daftary/features/startup/presentation/widgets/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAppStartupCubit extends MockCubit<AppStartupState>
    implements AppStartupCubit {}

/// Stands in for the app's Router: counts how often it is mounted, which is
/// how often navigation would start.
class _Probe extends StatefulWidget {
  const _Probe();

  static int inits = 0;

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.inits++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

const _preparing = AppStartupState(status: AppStartupStatus.preparing);
const _ready = AppStartupState(
  status: AppStartupStatus.ready,
  appearanceResolved: true,
);
const _failed = AppStartupState(
  status: AppStartupStatus.failed,
  appearanceResolved: true,
  failure: StartupFailure.error,
);
const _retrying = AppStartupState(
  status: AppStartupStatus.preparing,
  appearanceResolved: true,
  isRetry: true,
);

/// 019 US2–US4: hand-off timing, reduced motion, failure/retry, and no
/// replay — against a mocked `AppStartupCubit`.
void main() {
  late MockAppStartupCubit cubit;
  late StreamController<AppStartupState> states;

  setUp(() {
    _Probe.inits = 0;
    cubit = MockAppStartupCubit();
    states = StreamController<AppStartupState>.broadcast();
    when(() => cubit.retry()).thenAnswer((_) async {});
  });

  tearDown(() => states.close());

  void startIn(AppStartupState initial) {
    whenListen(cubit, states.stream, initialState: initial);
  }

  Future<void> emit(WidgetTester tester, AppStartupState state) async {
    states.add(state);
    await tester.pump();
  }

  Widget app({
    bool disableAnimations = false,
    Locale locale = const Locale('en'),
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? buildLightTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disableAnimations),
        child: child!,
      ),
      home: BlocProvider<AppStartupCubit>.value(
        value: cubit,
        child: const AppStartupGate(child: _Probe()),
      ),
    );
  }

  final probe = find.byType(_Probe);
  final splash = find.byType(SplashView);

  /// Advances [ms] of wall time in ~60 fps frames, as a device would —
  /// a ticker started mid-frame only begins counting on the next frame.
  Future<void> pumpFor(WidgetTester tester, int ms) async {
    for (var elapsed = 0; elapsed < ms; elapsed += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  /// Plays the intro (900 ms) and the exit fade (280 ms), with frame slack.
  Future<void> playThrough(WidgetTester tester) => pumpFor(tester, 1250);

  group('US2 — intro and hand-off', () {
    testWidgets('1. ready early: waits for the intro, then fades to the app', (
      tester,
    ) async {
      startIn(_ready);
      await tester.pumpWidget(app());
      await pumpFor(tester, 450);
      expect(probe, findsNothing);
      await playThrough(tester);
      expect(probe, findsOneWidget);
      expect(splash, findsNothing);
      expect(_Probe.inits, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('2. reduced motion: hands off on the first frame', (
      tester,
    ) async {
      startIn(_ready);
      await tester.pumpWidget(app(disableAnimations: true));
      await tester.pump();
      expect(probe, findsOneWidget);
      expect(splash, findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets(
      '14. a janky first frame cannot skip the story; a cap ends it',
      (tester) async {
        startIn(_ready);
        await tester.pumpWidget(app());
        double introValue() => tester.widget<SplashView>(splash).intro.value;

        await tester.pump(); // ticker's first tick (t = 0)
        await tester.pump(const Duration(milliseconds: 600)); // one long frame
        expect(introValue(), closeTo(50 / 900, 0.001));
        expect(probe, findsNothing);

        // Long frames keep coming: the 1.6 s wall-clock cap still finishes it.
        for (var i = 0; i < 3; i++) {
          await tester.pump(const Duration(milliseconds: 400));
        }
        expect(introValue(), 1.0);
        await pumpFor(tester, 320);
        expect(probe, findsOneWidget);
        expect(_Probe.inits, 1);
      },
    );

    testWidgets('3. right-to-left intro plays without errors', (tester) async {
      startIn(_ready);
      await tester.pumpWidget(app(locale: const Locale('ar')));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await playThrough(tester);
      expect(probe, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('US3 — right place, never stuck', () {
    testWidgets('4. intro ends first: rests, then hands off once on ready', (
      tester,
    ) async {
      startIn(_preparing);
      await tester.pumpWidget(app());
      await pumpFor(tester, 1500);
      expect(probe, findsNothing);
      expect(splash, findsOneWidget);
      expect(tester.hasRunningAnimations, isFalse);
      await emit(tester, _ready);
      await pumpFor(tester, 320);
      expect(probe, findsOneWidget);
      expect(_Probe.inits, 1);
    });

    testWidgets('5. ready at the exact intro end: still mounts once', (
      tester,
    ) async {
      startIn(_preparing);
      await tester.pumpWidget(app());
      // The intro starts two frames after the first (warm-up), so ~930 ms of
      // 16 ms frames lands its last frame and `ready` in the same frame.
      await pumpFor(tester, 920);
      states.add(_ready);
      await tester.pump(const Duration(milliseconds: 16));
      await pumpFor(tester, 320);
      expect(probe, findsOneWidget);
      expect(_Probe.inits, 1);
    });

    testWidgets('6. failure shows the message and a guarded Try again', (
      tester,
    ) async {
      startIn(_failed);
      await tester.pumpWidget(app());
      await tester.pump();
      final l10n = AppLocalizations.of(tester.element(splash))!;
      expect(probe, findsNothing);
      expect(find.text(l10n.splashErrorMessage), findsOneWidget);
      expect(find.widgetWithText(FilledButton, l10n.commonRetry), findsOne);

      await tester.tap(find.byType(FilledButton));
      verify(() => cubit.retry()).called(1);

      await emit(tester, _retrying);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      verifyNever(() => cubit.retry());
    });

    testWidgets('7. failed → retry → ready mounts the app once', (
      tester,
    ) async {
      startIn(_failed);
      await tester.pumpWidget(app());
      await tester.pump();
      await emit(tester, _retrying);
      await emit(tester, _ready);
      await pumpFor(tester, 320);
      expect(probe, findsOneWidget);
      expect(_Probe.inits, 1);
    });

    testWidgets('8. error message is a live region; action is ≥ 48×48', (
      tester,
    ) async {
      startIn(_failed);
      await tester.pumpWidget(app());
      await tester.pump();
      final l10n = AppLocalizations.of(tester.element(splash))!;
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.text(l10n.splashErrorMessage),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.liveRegion, isTrue);
      final size = tester.getSize(find.byType(FilledButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('9. Arabic error reads right-to-left', (tester) async {
      startIn(_failed);
      await tester.pumpWidget(app(locale: const Locale('ar')));
      await tester.pump();
      expect(
        find.text('تعذّر إكمال فتح دفتري. حاول مرة أخرى.'),
        findsOneWidget,
      );
      expect(find.text('حاول مرة أخرى'), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(FilledButton))),
        TextDirection.rtl,
      );
    });

    testWidgets('13. Back and taps during the splash change nothing', (
      tester,
    ) async {
      startIn(_preparing);
      await tester.pumpWidget(app());
      await pumpFor(tester, 300);
      await tester.binding.handlePopRoute();
      await tester.tapAt(tester.getCenter(splash));
      await tester.pump();
      expect(probe, findsNothing);
      expect(tester.takeException(), isNull);
      await pumpFor(tester, 700);
      await emit(tester, _ready);
      await pumpFor(tester, 320);
      expect(_Probe.inits, 1);
    });
  });

  group('US4 — only on a real launch', () {
    Future<void> handedOff(WidgetTester tester) async {
      startIn(_ready);
      await tester.pumpWidget(app());
      await playThrough(tester);
      expect(probe, findsOneWidget);
    }

    testWidgets('10. 20 background/foreground cycles never replay it', (
      tester,
    ) async {
      await handedOff(tester);
      for (var i = 0; i < 20; i++) {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await tester.pump();
        expect(splash, findsNothing);
      }
      expect(_Probe.inits, 1);
    });

    testWidgets('11. theme and language changes keep the app mounted', (
      tester,
    ) async {
      await handedOff(tester);
      await tester.pumpWidget(
        app(theme: buildDarkTheme(), locale: const Locale('ar')),
      );
      await tester.pumpAndSettle();
      expect(splash, findsNothing);
      expect(_Probe.inits, 1);
    });

    testWidgets('12. rotation keeps the app mounted', (tester) async {
      await handedOff(tester);
      tester.view.physicalSize = const Size(2400, 1080);
      addTearDown(tester.view.reset);
      await tester.pumpAndSettle();
      expect(splash, findsNothing);
      expect(_Probe.inits, 1);
    });
  });
}
