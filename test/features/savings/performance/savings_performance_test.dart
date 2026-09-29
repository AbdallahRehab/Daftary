import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_goal_detail.dart';
import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_cubit.dart';
import 'package:daftary/features/savings/presentation/pages/goal_detail_page.dart';
import 'package:daftary/features/savings/presentation/widgets/contribution_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/watch_stubs.dart';
import '../helpers/savings_harness.dart';
import '../helpers/savings_test_data.dart';

/// T072 — plan.md Performance Goals: a goal with 200 contributions opens
/// its detail in well under a second, 50 goals load the overview promptly,
/// and the goal page's history is lazy (only on-screen rows are built).
///
/// Timings are measured against the real repository on an in-memory
/// database, so they cover the queries, the conversion and the calculator —
/// everything behind `GetGoalDetail` / `GetSavingsOverview`. The budgets are
/// generous on purpose (a CI machine is slower than a phone is fast); they
/// catch an accidental N+1 or quadratic pass, not micro-regressions.
void main() {
  group('repository reads at scale', () {
    late SavingsHarness h;

    setUp(() async => h = await SavingsHarness.open());
    tearDown(() => h.close());

    test(
      'GetGoalDetail on a goal with 200 entries completes in < 1s',
      () async {
        final goal = await h.createGoal(
          target: 100000000,
          monthly: 500000,
          targetDate: DateTime(2028, 9, 15),
        );
        await h.setRate(Currency.usd, 48.35);
        for (var i = 0; i < 200; i++) {
          // A realistic mix: mostly deposits, some foreign-currency, a few
          // withdrawals, spread over past dates.
          final date = h.today.subtract(Duration(days: 200 - i));
          if (i % 10 == 9) {
            await h.withdraw(goal.id, 10000, date: date);
          } else if (i % 7 == 0) {
            await h.contribute(
              goal.id,
              2000,
              currency: Currency.usd,
              date: date,
            );
          } else {
            await h.contribute(goal.id, 50000, date: date);
          }
        }

        final getDetail = GetGoalDetail(h.repository);
        // Warm-up (first query compiles statements), then the measured read.
        await getDetail(goal.id);
        final watch = Stopwatch()..start();
        final result = await getDetail(goal.id);
        watch.stop();

        final detail = result.getOrElse((f) => throw StateError(f.message));
        expect(detail.history, hasLength(200));
        expect(detail.progress.currentAmountMinorUnits, greaterThan(0));
        expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
      },
    );

    test('GetSavingsOverview over 50 goals completes promptly', () async {
      await h.setRate(Currency.usd, 48.35);
      for (var i = 0; i < 50; i++) {
        final goal = await h.createGoal(
          name: 'Goal $i',
          currency: i % 5 == 0 ? Currency.usd : Currency.egp,
          target: 1000000 + i * 1000,
          starting: 10000 * (i + 1),
          monthly: 50000,
        );
        await h.contribute(
          goal.id,
          5000,
          currency: goal.currency,
          date: h.today,
        );
      }

      final getOverview = GetSavingsOverview(h.repository);
      await getOverview();
      final watch = Stopwatch()..start();
      final result = await getOverview();
      watch.stop();

      final overview = result.getOrElse((f) => throw StateError(f.message));
      expect(overview.goals, hasLength(50));
      expect(overview.isIncomplete, isFalse);
      expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    });
  });

  testWidgets('the goal page builds only the history rows on screen', (
    tester,
  ) async {
    final repository = MockSavingsRepository();
    final changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
    final goal = testGoal(target: 100000000, monthly: 500000);
    final history = [
      for (var i = 0; i < 200; i++)
        testEntry(
          id: 'c$i',
          amount: 50000,
          type: ContributionType.contribution,
          date: DateTime(2026, 1, 1).add(Duration(days: i)),
        ),
    ];
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(testDetail(goal, history: history)));
    final cubit = GoalDetailCubit(
      WatchGoalDetail(repository),
      DeleteContribution(repository),
    );
    addTearDown(cubit.close);
    addTearDown(changes.close);
    tester.view
      ..physicalSize = const Size(360, 780)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider.value(
          value: cubit..subscribe('g1'),
          child: const GoalDetailView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final built = find.byType(ContributionListTile).evaluate().length;
    expect(built, greaterThan(0));
    expect(built, lessThan(40), reason: 'history must be lazily built');

    // Scrolling far down builds later rows on demand, still without error.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -6000));
    await tester.pumpAndSettle();
    expect(find.byType(ContributionListTile).evaluate().length, lessThan(40));
    expect(tester.takeException(), isNull);
  });
}
