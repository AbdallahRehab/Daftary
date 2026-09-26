import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:daftary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/startup/presentation/widgets/splash_view.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end branded splash flow (019-splash-screen US3 T054, US4 T060).
/// Runs against the real app (real DI, real on-device SQLite) and mirrors
/// `integration_test/onboarding_flow_test.dart`'s `bootApp()`-style helper,
/// except that the app is pumped *before* startup runs, so the splash is
/// observable while `AppStartupCubit.start()` is still pending.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Same fresh-install reset as `onboarding_flow_test.dart`'s
  /// `clearOnboardingRelevantTables`: deletes every row the onboarding gate
  /// depends on, so a "fresh install" is deterministic regardless of data
  /// left behind by other integration test files sharing this database.
  Future<void> clearOnboardingRelevantTables(AppDatabase db) async {
    await db.delete(db.transactionAuditEntries).go();
    await db.delete(db.moneyTransactions).go();
    await db.delete(db.people).go();
    await db.delete(db.onboardingStatus).go();
  }

  /// Simulates a real cold launch: rebuilds GetIt's singletons from scratch,
  /// mounts `DaftaryApp` (which shows `SplashView` until startup is ready
  /// and the intro has played), asserts the splash is on screen, then runs
  /// startup exactly like `main()` does and lets the hand-off settle.
  Future<void> bootApp(WidgetTester tester, {bool freshInstall = false}) async {
    await getIt.reset();
    await configureDependencies();
    if (freshInstall) {
      await clearOnboardingRelevantTables(getIt<AppDatabase>());
    }
    appRouter.go('/');
    // A real relaunch is a new process with a new widget tree. Unmount any
    // app from an earlier boot in this test first, or its AppStartupGate
    // (already handed off) would be reused and correctly never replay.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(const DaftaryApp());

    expect(find.byType(SplashView), findsOneWidget);

    await getIt<AppStartupCubit>().start();
    // Force a known-English baseline regardless of the simulator's device
    // locale or any language persisted by an earlier test run on this
    // same on-device database.
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh install shows the splash first, then hands off to '
      'OnboardingPage and the splash is gone (T054 cases 1 and 3)', (
    tester,
  ) async {
    await bootApp(tester, freshInstall: true);

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(PeopleListPage), findsNothing);
    expect(find.byType(SplashView), findsNothing);

    // The splash never re-appears once handed off.
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });

  testWidgets('a returning user (onboarding completed) goes from the splash to '
      'PeopleListPage (T054 cases 2 and 3)', (tester) async {
    // First launch: complete onboarding, which is persisted.
    await bootApp(tester, freshInstall: true);
    expect(find.byType(OnboardingPage), findsOneWidget);
    await getIt<OnboardingCubit>().completeOnboarding();
    await tester.pumpAndSettle();

    // Relaunch: only what was persisted carries over.
    await bootApp(tester);

    expect(find.byType(PeopleListPage), findsOneWidget);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(SplashView), findsNothing);

    // The splash never re-appears once handed off.
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);
  });

  testWidgets('theme change, language change and pause/resume never replay the '
      'splash (T060, FR-017)', (tester) async {
    await bootApp(tester, freshInstall: true);
    await getIt<OnboardingCubit>().completeOnboarding();
    await tester.pumpAndSettle();
    await bootApp(tester);
    expect(find.byType(PeopleListPage), findsOneWidget);
    expect(find.byType(SplashView), findsNothing);

    await getIt<SettingsCubit>().changeThemeMode(AppThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);

    await getIt<SettingsCubit>().changeLanguage(AppLanguage.arabic);
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);

    // Background and return through the same state sequence the OS reports
    // (the app's AppLifecycleListener asserts on skipped states). No pump
    // while paused: a live binding stops producing frames then, so
    // pumpAndSettle would wait forever; the tree is still inspectable.
    void lifecycle(List<AppLifecycleState> states) {
      for (final state in states) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
    }

    lifecycle(const [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]);
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);

    lifecycle(const [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]);
    await tester.pumpAndSettle();
    expect(find.byType(SplashView), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);

    // Restore the persisted appearance so later test files sharing this
    // on-device database start from the usual light/English baseline.
    await getIt<SettingsCubit>().changeThemeMode(AppThemeMode.light);
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    await tester.pumpAndSettle();
  });
}
