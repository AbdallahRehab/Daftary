import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:daftary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

/// A minimal router fixture (mirroring `test/widget/main_shell_test.dart`)
/// so `OnboardingPage`'s post-completion/skip `context.go('/')` has a real
/// destination to land on.
GoRouter _buildTestRouter() {
  return GoRouter(
    initialLocation: '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/', builder: (context, state) => const Text('MainApp')),
    ],
  );
}

void main() {
  late MockOnboardingCubit cubit;

  setUp(() {
    cubit = MockOnboardingCubit();
    when(() => cubit.state).thenReturn(
      const OnboardingState(status: OnboardingLoadStatus.showOnboarding),
    );
    when(() => cubit.completeOnboarding()).thenAnswer((_) async {});
    when(() => cubit.skipOnboarding()).thenAnswer((_) async {});
  });

  Widget wrap({Locale locale = const Locale('en')}) {
    return BlocProvider<OnboardingCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        routerConfig: _buildTestRouter(),
        theme: buildLightTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
  }

  Future<AppLocalizations> pumpAndGetL10n(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(wrap(locale: locale));
    await tester.pumpAndSettle();
    return AppLocalizations.of(tester.element(find.byType(OnboardingPage)))!;
  }

  testWidgets('renders the 5 topics in OnboardingTopic.values order with no '
      'accounting jargon, and the progress indicator shows the correct '
      'step/total, under LTR', (tester) async {
    final l10n = await pumpAndGetL10n(tester);
    final state = tester.state<OnboardingPageState>(
      find.byType(OnboardingPage),
    );

    final expectedTitles = [
      l10n.onboardingUnderstandingMoneyTitle,
      l10n.onboardingMoneyBetweenPeopleTitle,
      l10n.onboardingSocialOccasionsTitle,
      l10n.onboardingScanningRecordsTitle,
      l10n.onboardingAiAssistantTitle,
    ];

    for (var i = 0; i < expectedTitles.length; i++) {
      state.pageController.jumpToPage(i);
      await tester.pumpAndSettle();
      expect(find.text(expectedTitles[i]), findsOneWidget);
      expect(find.text(l10n.onboardingStepProgress(i + 1, 5)), findsOneWidget);
    }

    // No jargon: none of the app's own accounting-term ARB strings leak
    // into onboarding copy.
    expect(find.textContaining('ledger'), findsNothing);
    expect(find.textContaining('accrual'), findsNothing);
  });

  testWidgets('renders correctly under RTL (Arabic)', (tester) async {
    final l10n = await pumpAndGetL10n(tester, locale: const Locale('ar'));

    expect(find.text(l10n.onboardingUnderstandingMoneyTitle), findsOneWidget);
    expect(find.text(l10n.onboardingStepProgress(1, 5)), findsOneWidget);
    final directionality = tester.widget<Directionality>(
      find
          .ancestor(
            of: find.byType(OnboardingPage),
            matching: find.byType(Directionality),
          )
          .first,
    );
    expect(directionality.textDirection, TextDirection.rtl);
  });

  testWidgets(
    'tapping Next advances the screen and updates progress at each step '
    '(US2)',
    (tester) async {
      final l10n = await pumpAndGetL10n(tester);

      for (var step = 0; step < 4; step++) {
        expect(
          find.text(l10n.onboardingStepProgress(step + 1, 5)),
          findsOneWidget,
        );
        await tester.tap(find.text(l10n.onboardingNextAction));
        await tester.pumpAndSettle();
      }

      expect(find.text(l10n.onboardingStepProgress(5, 5)), findsOneWidget);
    },
  );

  testWidgets(
    'tapping Back from a later screen returns to the previous screen with '
    'progress decremented correctly (US2)',
    (tester) async {
      final l10n = await pumpAndGetL10n(tester);
      final state = tester.state<OnboardingPageState>(
        find.byType(OnboardingPage),
      );
      state.pageController.jumpToPage(2);
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);

      await tester.tap(find.text(l10n.onboardingBackAction));
      await tester.pumpAndSettle();

      expect(find.text(l10n.onboardingStepProgress(2, 5)), findsOneWidget);
    },
  );

  testWidgets('tapping the final screen\'s call-to-action invokes '
      'OnboardingCubit.completeOnboarding() (US2, FR-007)', (tester) async {
    final l10n = await pumpAndGetL10n(tester);
    final state = tester.state<OnboardingPageState>(
      find.byType(OnboardingPage),
    );
    state.pageController.jumpToPage(4);
    await tester.pumpAndSettle();

    expect(find.text(l10n.onboardingGetStartedAction), findsOneWidget);
    expect(find.text(l10n.onboardingNextAction), findsNothing);

    await tester.tap(find.text(l10n.onboardingGetStartedAction));
    await tester.pumpAndSettle();

    verify(() => cubit.completeOnboarding()).called(1);
  });

  testWidgets('tapping Skip from the first, a middle, and the last screen each '
      'invokes OnboardingCubit.skipOnboarding() (US4)', (tester) async {
    // Skip navigates away from OnboardingPage each time (context.go('/')
    // once the cubit call resolves), so each step needs its own fresh
    // boot rather than reusing one still-mounted PageController.
    for (final step in [0, 2, 4]) {
      final l10n = await pumpAndGetL10n(tester);
      final state = tester.state<OnboardingPageState>(
        find.byType(OnboardingPage),
      );
      state.pageController.jumpToPage(step);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingSkipAction));
      await tester.pumpAndSettle();
    }

    verify(() => cubit.skipOnboarding()).called(3);
  });

  testWidgets('the Back control is hidden on the first screen', (tester) async {
    final l10n = await pumpAndGetL10n(tester);

    expect(find.text(l10n.onboardingBackAction), findsNothing);
  });

  testWidgets(
    'remains fully usable at a small screen width (Edge Cases: very small '
    'screens)',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final l10n = await pumpAndGetL10n(tester);

      expect(find.text(l10n.onboardingUnderstandingMoneyTitle), findsOneWidget);
      expect(find.text(l10n.onboardingNextAction), findsOneWidget);
      expect(find.text(l10n.onboardingSkipAction), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
