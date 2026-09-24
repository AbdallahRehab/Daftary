import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/ports/savings_insights_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'notification_engine_harness.dart';

final _created = DateTime(2026, 1, 1);

/// A monthly-contribution-only goal; the evaluator compares
/// [currentMinor] with 1000 × whole months since Jan 1 (8 at the harness's
/// Sep 24 "now"), so 8000 is on pace, 6000 is 2 months behind, 10000 is
/// 2 months ahead.
SavingsGoalSnapshot goal(
  String id, {
  int currentMinor = 8000,
  bool achieved = false,
  bool noPlan = false,
}) => SavingsGoalSnapshot(
  goalId: id,
  name: 'Goal $id',
  targetAmountMinorUnits: 100000,
  currentAmountMinorUnits: currentMinor,
  isAchieved: achieved,
  createdAt: _created,
  monthlyContributionMinorUnits: noPlan ? null : 1000,
);

NotificationHistoryEntry goalHistory(String id, ThresholdBand band) =>
    historyEntry(
      type: NotificationSourceType.savingsGoal,
      sourceId: id,
      band: band,
    );

/// T029/T030 — `NotificationEngine.run()`'s savings-goal path.
void main() {
  setUpAll(EngineHarness.registerFallbacks);

  late EngineHarness h;
  setUp(() => h = EngineHarness());

  test('check-ins off: the savings source is never read', () async {
    h.givenPreference(
      enabledPreference.copyWith(savingsCheckInsEnabled: false),
    );

    await h.engine.run();

    verifyNever(() => h.savingsSource.activeGoals());
    verify(() => h.budgetSource.currentMonthCategories()).called(1);
  });

  test(
    'onPace → behindPace notifies, keyed by goal id with no period',
    () async {
      h.givenGoals([goal('car', currentMinor: 6000)]);
      h.givenHistory(goalHistory('car', ThresholdBand.onPace));

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      verify(
        () =>
            h.historyMock.find(NotificationSourceType.savingsGoal, 'car', null),
      ).called(1);
      final sent = h.scheduled().single;
      expect(sent.title, contains('Goal car'));
      expect(
        sent.deepLinkTarget,
        const NotificationDeepLinkTarget(
          type: NotificationSourceType.savingsGoal,
          id: 'car',
        ),
      );
      verify(() => h.phrasing.compose(any())).called(1);
      final row = h.upserted().single;
      expect(row.lastNotifiedBand, ThresholdBand.behindPace);
      expect(row.applicablePeriod, isNull);
      expect(summary.notifiedCount, 1);
      verifyNever(() => h.savingsSource.goalExists(any()));
    },
  );

  test('onPace → aheadOfPace notifies', () async {
    h.givenGoals([goal('car', currentMinor: 10000)]);
    h.givenHistory(goalHistory('car', ThresholdBand.onPace));

    await h.engine.run();

    expect(h.scheduled(), hasLength(1));
  });

  test('behindPace → onPace records the band without notifying', () async {
    h.givenGoals([goal('car')]);
    h.givenHistory(goalHistory('car', ThresholdBand.behindPace));

    await h.engine.run();

    h.verifyNothingScheduled();
    expect(h.upserted().single.lastNotifiedBand, ThresholdBand.onPace);
  });

  test('FR-005: a goal with no plan is skipped entirely', () async {
    h.givenGoals([goal('free', noPlan: true)]);

    final summary = (await h.engine.run()).getOrElse((f) => throw f);

    verifyNever(() => h.historyMock.find(any(), any(), any()));
    verifyNever(() => h.historyMock.upsert(any()));
    h.verifyNothingScheduled();
    expect(summary.evaluatedCount, 0);
  });

  test('an unchanged band is a no-op (cooldown)', () async {
    h.givenGoals([goal('car', currentMinor: 6000)]);
    h.givenHistory(goalHistory('car', ThresholdBand.behindPace));

    await h.engine.run();

    h.verifyNothingScheduled();
    verifyNever(() => h.historyMock.upsert(any()));
  });

  group('FR-006 achievement', () {
    test('a known goal newly reaching achieved notifies once', () async {
      h.givenGoals([goal('car', achieved: true)]);
      h.givenHistory(goalHistory('car', ThresholdBand.onPace));

      await h.engine.run();

      expect(h.scheduled().single.deepLinkTarget.id, 'car');
      expect(h.upserted().single.lastNotifiedBand, ThresholdBand.achieved);
    });

    test('exactly once across repeated runs', () async {
      final history = InMemoryHistoryRepository();
      final stateful = EngineHarness(history: history);
      await history.upsert(goalHistory('car', ThresholdBand.onPace));
      stateful.givenGoals([goal('car', achieved: true)]);

      for (var i = 0; i < 3; i++) {
        await stateful.engine.run();
      }

      verify(
        () => stateful.scheduler.scheduleOrDeliver(
          any(),
          deliverAt: any(named: 'deliverAt'),
        ),
      ).called(1);
    });
  });

  group('T030 no transition from unknown', () {
    test(
      'an already-achieved goal on first evaluation does not notify',
      () async {
        h.givenGoals([goal('done', achieved: true)]);

        final summary = (await h.engine.run()).getOrElse((f) => throw f);

        h.verifyNothingScheduled();
        expect(h.upserted().single.lastNotifiedBand, ThresholdBand.achieved);
        expect(summary.notifiedCount, 0);
      },
    );

    test('a behind-pace goal on first evaluation records silently', () async {
      h.givenGoals([goal('car', currentMinor: 6000)]);

      await h.engine.run();

      h.verifyNothingScheduled();
      expect(h.upserted().single.lastNotifiedBand, ThresholdBand.behindPace);
    });

    test('never fires on later runs either, while the band holds', () async {
      final stateful = EngineHarness(history: InMemoryHistoryRepository());
      stateful.givenGoals([goal('done', achieved: true)]);

      await stateful.engine.run();
      await stateful.engine.run();

      stateful.verifyNothingScheduled();
    });
  });

  test('a savings source failure is recorded, not fatal', () async {
    when(
      () => h.savingsSource.activeGoals(),
    ).thenAnswer((_) async => const Left(CacheFailure('011')));

    final summary = (await h.engine.run()).getOrElse((f) => throw f);

    expect(summary.failures, [const CacheFailure('011')]);
  });
}
