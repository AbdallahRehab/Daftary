import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_failures.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/ports/budget_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/notification_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import 'notification_engine_harness.dart';

BudgetCategorySnapshot category(
  String id,
  BudgetCategoryStatus status, {
  String month = '2026-09',
  double? percent = 50,
}) => BudgetCategorySnapshot(
  categoryId: id,
  categoryName: 'Cat $id',
  month: month,
  plannedMinorUnits: 100000,
  actualMinorUnits: 50000,
  percentageUsed: percent,
  status: status,
);

/// T021/T022 — `NotificationEngine.run()`'s budget-category path.
void main() {
  setUpAll(EngineHarness.registerFallbacks);

  late EngineHarness h;
  setUp(() => h = EngineHarness());

  group('FR-018 disabled / category toggles', () {
    test(
      'feature disabled: empty summary and no source is ever read',
      () async {
        h.givenPreference(enabledPreference.copyWith(isEnabled: false));

        final result = await h.engine.run();

        expect(
          result,
          const Right<Failure, NotificationRunSummary>(
            NotificationRunSummary.empty,
          ),
        );
        verifyZeroInteractions(h.budgetSource);
        verifyZeroInteractions(h.savingsSource);
        verifyZeroInteractions(h.historyMock);
        verifyZeroInteractions(h.scheduler);
      },
    );

    test('budget warnings off: the budget source is never read', () async {
      h.givenPreference(
        enabledPreference.copyWith(budgetWarningsEnabled: false),
      );

      await h.engine.run();

      verifyNever(() => h.budgetSource.currentMonthCategories());
      verify(() => h.savingsSource.activeGoals()).called(1);
    });

    test('a preference read failure fails the run', () async {
      when(
        () => h.preferences.getPreference(),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));

      expect(
        await h.engine.run(),
        const Left<Failure, NotificationRunSummary>(CacheFailure('db')),
      );
      verifyZeroInteractions(h.budgetSource);
    });
  });

  group('band change', () {
    test('belowWarning → nearLimit notifies once, read-only on 010', () async {
      h.givenBudgets([
        category('food', BudgetCategoryStatus.nearFull, percent: 92.4),
      ]);
      h.givenHistory(
        historyEntry(
          type: NotificationSourceType.budgetCategory,
          sourceId: 'food',
          period: '2026-09',
          band: ThresholdBand.belowWarning,
        ),
      );

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      verify(
        () => h.historyMock.find(
          NotificationSourceType.budgetCategory,
          'food',
          '2026-09',
        ),
      ).called(1);
      final sent = h.scheduled();
      expect(sent, hasLength(1));
      expect(sent.single.title, 'Cat food is close to its limit');
      expect(sent.single.body, contains('92%'));
      expect(
        sent.single.deepLinkTarget,
        const NotificationDeepLinkTarget(
          type: NotificationSourceType.budgetCategory,
          id: 'food',
          applicablePeriod: '2026-09',
        ),
      );
      verify(() => h.phrasing.compose(any())).called(1);
      final row = h.upserted().single;
      expect(row.lastNotifiedBand, ThresholdBand.nearLimit);
      expect(row.applicablePeriod, '2026-09');
      expect(summary.notifiedCount, 1);
      expect(summary.evaluatedCount, 1);
      expect(summary.failures, isEmpty);
      verifyNever(() => h.budgetSource.categoryBudgetExists(any(), any()));
    });

    test('the phrased notification is the one delivered', () async {
      h.givenBudgets([
        category('food', BudgetCategoryStatus.overBudget, percent: 120),
      ]);
      const phrased = ComposedNotification(
        title: 'phrased',
        body: 'phrased body',
        deepLinkTarget: NotificationDeepLinkTarget(
          type: NotificationSourceType.budgetCategory,
          id: 'food',
          applicablePeriod: '2026-09',
        ),
      );
      when(() => h.phrasing.compose(any())).thenAnswer((_) async => phrased);

      await h.engine.run();

      expect(h.scheduled(), [phrased]);
    });

    test(
      'FR-016: first observation in a new month at nearLimit notifies',
      () async {
        h.givenBudgets([
          category('food', BudgetCategoryStatus.nearFull, month: '2026-10'),
        ]);
        // Last month's row is not this month's.
        h.givenHistory(
          historyEntry(
            type: NotificationSourceType.budgetCategory,
            sourceId: 'food',
            period: '2026-09',
            band: ThresholdBand.nearLimit,
          ),
        );

        await h.engine.run();

        expect(h.scheduled(), hasLength(1));
        expect(h.upserted().single.applicablePeriod, '2026-10');
      },
    );

    test('first observation below warning records the band silently', () async {
      h.givenBudgets([category('food', BudgetCategoryStatus.onTrack)]);

      await h.engine.run();

      h.verifyNothingScheduled();
      expect(h.upserted().single.lastNotifiedBand, ThresholdBand.belowWarning);
    });

    test(
      'nearLimit → belowWarning records the band without notifying',
      () async {
        h.givenBudgets([category('food', BudgetCategoryStatus.onTrack)]);
        h.givenHistory(
          historyEntry(
            type: NotificationSourceType.budgetCategory,
            sourceId: 'food',
            period: '2026-09',
            band: ThresholdBand.nearLimit,
          ),
        );

        await h.engine.run();

        h.verifyNothingScheduled();
        expect(
          h.upserted().single.lastNotifiedBand,
          ThresholdBand.belowWarning,
        );
      },
    );

    test('nearLimit → exceeded notifies again', () async {
      h.givenBudgets([
        category('food', BudgetCategoryStatus.overBudget, percent: 105),
      ]);
      h.givenHistory(
        historyEntry(
          type: NotificationSourceType.budgetCategory,
          sourceId: 'food',
          period: '2026-09',
          band: ThresholdBand.nearLimit,
        ),
      );

      await h.engine.run();

      expect(h.scheduled().single.title, 'Cat food is over budget');
    });

    test('composes in the current app language', () async {
      h.language.code = 'ar';
      h.givenBudgets([category('food', BudgetCategoryStatus.nearFull)]);

      await h.engine.run();

      expect(h.scheduled().single.title, isNot(contains('close to its limit')));
    });
  });

  group('T022 cooldown (FR-015)', () {
    test('an unchanged band schedules nothing and writes no history', () async {
      h.givenBudgets([category('food', BudgetCategoryStatus.nearFull)]);
      h.givenHistory(
        historyEntry(
          type: NotificationSourceType.budgetCategory,
          sourceId: 'food',
          period: '2026-09',
          band: ThresholdBand.nearLimit,
        ),
      );

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      h.verifyNothingScheduled();
      verifyNever(() => h.historyMock.upsert(any()));
      expect(summary.notifiedCount, 0);
    });

    test(
      'repeated runs on an unchanged band notify exactly once in total',
      () async {
        final stateful = EngineHarness(history: InMemoryHistoryRepository());
        stateful.givenBudgets([
          category('food', BudgetCategoryStatus.nearFull),
        ]);

        for (var i = 0; i < 4; i++) {
          await stateful.engine.run();
        }

        verify(
          () => stateful.scheduler.scheduleOrDeliver(
            any(),
            deliverAt: any(named: 'deliverAt'),
          ),
        ).called(1);
      },
    );
  });

  group('resilience', () {
    test('a scheduling failure does not abort the rest of the pass', () async {
      h.givenBudgets([
        category('a', BudgetCategoryStatus.nearFull),
        category('b', BudgetCategoryStatus.overBudget),
      ]);
      const failure = NotificationSchedulingFailure('boom');
      when(
        () => h.scheduler.scheduleOrDeliver(
          any(
            that: isA<ComposedNotification>().having(
              (n) => n.deepLinkTarget.id,
              'id',
              'a',
            ),
          ),
          deliverAt: any(named: 'deliverAt'),
        ),
      ).thenAnswer((_) async => const Left(failure));

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      expect(h.scheduled().map((n) => n.deepLinkTarget.id), ['a', 'b']);
      expect(summary.notifiedCount, 1);
      expect(summary.failures, [failure]);
      // Bands are still recorded, so a failed delivery never re-fires on
      // every later pass.
      expect(h.upserted().map((e) => e.sourceId), ['a', 'b']);
    });

    test('a history read failure skips only that candidate', () async {
      h.givenBudgets([
        category('a', BudgetCategoryStatus.nearFull),
        category('b', BudgetCategoryStatus.nearFull),
      ]);
      when(
        () => h.historyMock.find(any(), 'a', any()),
      ).thenAnswer((_) async => const Left(CacheFailure('read')));

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      expect(h.scheduled().single.deepLinkTarget.id, 'b');
      expect(summary.failures, [const CacheFailure('read')]);
    });

    test('a budget source failure is recorded and savings still run', () async {
      when(
        () => h.budgetSource.currentMonthCategories(),
      ).thenAnswer((_) async => const Left(CacheFailure('010')));

      final summary = (await h.engine.run()).getOrElse((f) => throw f);

      expect(summary.failures, [const CacheFailure('010')]);
      verify(() => h.savingsSource.activeGoals()).called(1);
    });

    test('records the completed run for the foreground catch-up', () async {
      await h.engine.run();
      expect(h.lastRun.value, h.clock.current);
    });
  });

  group('FR-013 quiet hours', () {
    test(
      'inside a midnight-crossing window defers to the next window end',
      () async {
        final quiet = EngineHarness(now: DateTime(2026, 9, 24, 23, 15));
        quiet.givenPreference(
          enabledPreference.copyWith(
            quietHoursStart: 22 * 60,
            quietHoursEnd: 8 * 60,
          ),
        );
        quiet.givenBudgets([category('food', BudgetCategoryStatus.nearFull)]);

        final summary = (await quiet.engine.run()).getOrElse((f) => throw f);

        verify(
          () => quiet.scheduler.scheduleOrDeliver(
            any(),
            deliverAt: DateTime(2026, 9, 25, 8),
          ),
        ).called(1);
        expect(summary.deferredCount, 1);
      },
    );

    test('outside the window delivers immediately', () async {
      final awake = EngineHarness(now: DateTime(2026, 9, 24, 12));
      awake.givenPreference(
        enabledPreference.copyWith(
          quietHoursStart: 22 * 60,
          quietHoursEnd: 8 * 60,
        ),
      );
      awake.givenBudgets([category('food', BudgetCategoryStatus.nearFull)]);

      await awake.engine.run();

      verify(
        () => awake.scheduler.scheduleOrDeliver(any(), deliverAt: null),
      ).called(1);
    });
  });
}
