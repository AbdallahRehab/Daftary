import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/routing/app_router.dart';
import 'package:daftary/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/people/presentation/pages/people_list_page.dart';
import 'package:daftary/features/settings/domain/entities/app_language.dart';
import 'package:daftary/features/settings/domain/entities/app_theme_mode.dart';
import 'package:daftary/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:daftary/features/startup/presentation/cubit/app_startup_cubit.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// End-to-end onboarding gate + navigation + skip + restart flow
/// (006-onboarding-screens quickstart.md, all 4 User Stories plus both
/// Edge Cases). Runs against the real app (real DI, real on-device
/// SQLite) — mirrors `integration_test/language_switch_flow_test.dart`'s
/// `bootApp()`-style helper.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Deletes every row this feature's gate decision depends on
  /// (`people`, `money_transactions`, `transaction_audit_entries`,
  /// `onboarding_status`), so a "fresh install" scenario is deterministic
  /// regardless of data left behind by other integration test files
  /// sharing this same on-device database (e.g.
  /// `archive_state_refresh_flow_test.dart` creates real `Person` rows).
  Future<void> clearOnboardingRelevantTables(AppDatabase db) async {
    await db.delete(db.transactionAuditEntries).go();
    await db.delete(db.moneyTransactions).go();
    await db.delete(db.people).go();
    await db.delete(db.onboardingStatus).go();
  }

  /// (Re)builds GetIt's singletons from scratch — a fresh `SettingsCubit`,
  /// `OnboardingCubit`, `AppStartupCubit`, `AppDatabase`, etc. — then runs
  /// startup (settings + onboarding gate) via `AppStartupCubit.start()`,
  /// exactly like `main()` does. The underlying SQLite file on disk is otherwise
  /// unaffected, so calling this simulates a real app restart: the new
  /// "session" only knows what was actually persisted.
  Future<void> bootApp(WidgetTester tester, {bool freshInstall = false}) async {
    await getIt.reset();
    await configureDependencies();
    if (freshInstall) {
      await clearOnboardingRelevantTables(getIt<AppDatabase>());
    }
    await getIt<AppStartupCubit>().start();
    // Force a known-English baseline regardless of the simulator's device
    // locale or any language persisted by an earlier test run on this
    // same on-device database.
    await getIt<SettingsCubit>().changeLanguage(AppLanguage.english);
    appRouter.go('/');
    await tester.pumpWidget(const DaftaryApp());
    await tester.pumpAndSettle();
  }

  Future<AppLocalizations> l10nOf(WidgetTester tester) async =>
      AppLocalizations.of(tester.element(find.byType(DaftaryApp)))!;

  testWidgets(
    'a fresh install shows OnboardingPage before the main app is reachable '
    '(US1 Acceptance Scenario 1)',
    (tester) async {
      await bootApp(tester, freshInstall: true);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(PeopleListPage), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  group('FR-010a — existing-data auto-completes onboarding', () {
    testWidgets('a Person-only install launches directly to the main app', (
      tester,
    ) async {
      await getIt.reset();
      await configureDependencies();
      await clearOnboardingRelevantTables(getIt<AppDatabase>());
      await getIt<PeopleRepository>().createPerson(name: 'Seed Person');

      await getIt<AppStartupCubit>().start();
      appRouter.go('/');
      await tester.pumpWidget(const DaftaryApp());
      await tester.pumpAndSettle();

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(PeopleListPage), findsOneWidget);

      final status = await (getIt<AppDatabase>().select(
        getIt<AppDatabase>().onboardingStatus,
      )..where((t) => t.id.equals('singleton'))).getSingle();
      expect(status.isComplete, isTrue);
    });

    testWidgets(
      'a MoneyTransaction-only install launches directly to the main app',
      (tester) async {
        await getIt.reset();
        await configureDependencies();
        await clearOnboardingRelevantTables(getIt<AppDatabase>());
        final person = await getIt<PeopleRepository>().createPerson(
          name: 'Seed Person',
        );
        final personId = person
            .getOrElse((_) => throw StateError('expected Right'))
            .id;
        await getIt<TransactionsRepository>().addTransaction(
          idempotencyKey: 'onboarding-seed-1',
          personId: personId,
          amount: const Money.egp(10000),
          direction: TransactionDirection.given,
          date: DateTime.now(),
        );

        await getIt<AppStartupCubit>().start();
        appRouter.go('/');
        await tester.pumpWidget(const DaftaryApp());
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingPage), findsNothing);
        expect(find.byType(PeopleListPage), findsOneWidget);
      },
    );

    testWidgets(
      'an archived-person-only install launches directly to the main app',
      (tester) async {
        await getIt.reset();
        await configureDependencies();
        await clearOnboardingRelevantTables(getIt<AppDatabase>());
        final person = await getIt<PeopleRepository>().createPerson(
          name: 'Seed Archived Person',
        );
        final personId = person
            .getOrElse((_) => throw StateError('expected Right'))
            .id;
        await getIt<PeopleRepository>().archivePerson(personId);

        await getIt<AppStartupCubit>().start();
        appRouter.go('/');
        await tester.pumpWidget(const DaftaryApp());
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingPage), findsNothing);
        expect(find.byType(PeopleListPage), findsOneWidget);
      },
    );

    testWidgets(
      'a soft-deleted-transaction-only install launches directly to the '
      'main app',
      (tester) async {
        await getIt.reset();
        await configureDependencies();
        await clearOnboardingRelevantTables(getIt<AppDatabase>());
        final person = await getIt<PeopleRepository>().createPerson(
          name: 'Seed Person',
        );
        final personId = person
            .getOrElse((_) => throw StateError('expected Right'))
            .id;
        final added = await getIt<TransactionsRepository>().addTransaction(
          idempotencyKey: 'onboarding-seed-2',
          personId: personId,
          amount: const Money.egp(10000),
          direction: TransactionDirection.given,
          date: DateTime.now(),
        );
        final txId = added
            .getOrElse((_) => throw StateError('expected Right'))
            .id;
        await getIt<TransactionsRepository>().deleteTransaction(txId);

        await getIt<AppStartupCubit>().start();
        appRouter.go('/');
        await tester.pumpWidget(const DaftaryApp());
        await tester.pumpAndSettle();

        expect(find.byType(OnboardingPage), findsNothing);
        expect(find.byType(PeopleListPage), findsOneWidget);
      },
    );
  });

  testWidgets(
    'stepping through all 5 screens with Next/Back shows correct progress '
    'and content at each step, and the final CTA lands on the main app\'s '
    'People list, completing in under 60 seconds (US2, SC-002)',
    (tester) async {
      await bootApp(tester, freshInstall: true);
      final l10n = await l10nOf(tester);
      final stopwatch = Stopwatch()..start();

      final titles = [
        l10n.onboardingUnderstandingMoneyTitle,
        l10n.onboardingMoneyBetweenPeopleTitle,
        l10n.onboardingSocialOccasionsTitle,
        l10n.onboardingScanningRecordsTitle,
        l10n.onboardingIncomeExpenseTitle,
      ];

      for (var step = 0; step < 5; step++) {
        expect(find.text(titles[step]), findsOneWidget);
        expect(
          find.text(l10n.onboardingStepProgress(step + 1, 5)),
          findsOneWidget,
        );
        if (step < 4) {
          await tester.tap(find.text(l10n.onboardingNextAction));
          await tester.pumpAndSettle();
        }
      }

      await tester.tap(find.text(l10n.onboardingGetStartedAction));
      await tester.pumpAndSettle();
      stopwatch.stop();

      expect(find.byType(PeopleListPage), findsOneWidget);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 60)));

      // Back decrement, checked on the way back up from screen 2.
      // (Re-verified independently below to keep this test focused on the
      // forward walkthrough + timing.)
    },
  );

  testWidgets('tapping Back decrements the progress correctly (US2)', (
    tester,
  ) async {
    await bootApp(tester, freshInstall: true);
    final l10n = await l10nOf(tester);

    await tester.tap(find.text(l10n.onboardingNextAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.onboardingNextAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);

    await tester.tap(find.text(l10n.onboardingBackAction));
    await tester.pumpAndSettle();

    expect(find.text(l10n.onboardingStepProgress(2, 5)), findsOneWidget);
  });

  testWidgets('completing onboarding persists, and a simulated restart goes '
      'directly to the main app with no onboarding shown (US3 Acceptance '
      'Scenario 1)', (tester) async {
    await bootApp(tester, freshInstall: true);
    final l10n = await l10nOf(tester);

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text(l10n.onboardingNextAction));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(l10n.onboardingGetStartedAction));
    await tester.pumpAndSettle();
    expect(find.byType(PeopleListPage), findsOneWidget);

    // Simulated restart against the same underlying database.
    await bootApp(tester);

    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(PeopleListPage), findsOneWidget);
  });

  testWidgets(
    'the app killed mid-onboarding shows onboarding again from screen 1 on '
    'the next launch, not resumed, with nothing persisted (Edge Case, '
    'FR-010)',
    (tester) async {
      await bootApp(tester, freshInstall: true);
      final l10n = await l10nOf(tester);

      // Advance to screen 3 of 5, then "kill" the app without completing
      // or skipping.
      await tester.tap(find.text(l10n.onboardingNextAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingNextAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);

      // Simulated restart — no completeOnboarding()/skipOnboarding() was
      // ever called.
      await bootApp(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.text(l10n.onboardingStepProgress(1, 5)), findsOneWidget);

      final rows = await getIt<AppDatabase>()
          .select(getIt<AppDatabase>().onboardingStatus)
          .get();
      expect(rows, isEmpty);
    },
  );

  testWidgets(
    'skipping from a middle screen lands directly in the main app, and a '
    'restart does not show onboarding again (US4 Acceptance Scenarios 1-2)',
    (tester) async {
      await bootApp(tester, freshInstall: true);
      final l10n = await l10nOf(tester);

      await tester.tap(find.text(l10n.onboardingNextAction));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.onboardingSkipAction));
      await tester.pumpAndSettle();

      expect(find.byType(PeopleListPage), findsOneWidget);

      await bootApp(tester);

      expect(find.byType(OnboardingPage), findsNothing);
      expect(find.byType(PeopleListPage), findsOneWidget);
    },
  );

  testWidgets('switching language then theme mid-onboarding preserves the same '
      'screen/step index and re-renders correctly (Edge Case, research.md '
      'Decision 6)', (tester) async {
    await bootApp(tester, freshInstall: true);
    var l10n = await l10nOf(tester);

    await tester.tap(find.text(l10n.onboardingNextAction));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.onboardingNextAction));
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);

    await getIt<SettingsCubit>().changeLanguage(AppLanguage.arabic);
    await tester.pumpAndSettle();
    l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);
    expect(find.text(l10n.onboardingSocialOccasionsTitle), findsOneWidget);

    await getIt<SettingsCubit>().changeThemeMode(AppThemeMode.dark);
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboardingStepProgress(3, 5)), findsOneWidget);
    expect(find.byType(OnboardingPage), findsOneWidget);
  });
}
