import 'dart:io';

import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/ports/budget_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/services/evaluate_budget_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

/// T010 — exhaustive band coverage for [EvaluateBudgetNotifications].
///
/// Each fixture carries the status 010 itself assigns at that point
/// (`overBudget` when actual > planned, else `nearFull` at >= 90%, else
/// `onTrack` — specs/010-household-budgets/data-model.md), so the boundaries
/// below are 010's, not a threshold of this feature's own (FR-003).
void main() {
  const evaluator = EvaluateBudgetNotificationsImpl();

  BudgetCategorySnapshot line({
    required int planned,
    required int actual,
    required BudgetCategoryStatus status,
    String categoryId = 'cat-food',
  }) {
    return BudgetCategorySnapshot(
      categoryId: categoryId,
      categoryName: 'Food',
      month: '2026-09',
      plannedMinorUnits: planned,
      actualMinorUnits: actual,
      percentageUsed: planned == 0 ? null : actual / planned * 100,
      status: status,
    );
  }

  ThresholdBand bandOf(BudgetCategorySnapshot snapshot) =>
      evaluator.evaluate([snapshot]).single.band;

  group('band boundaries', () {
    test('just below the warning threshold (89.99%) is belowWarning', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 89990,
            status: BudgetCategoryStatus.onTrack,
          ),
        ),
        ThresholdBand.belowWarning,
      );
    });

    test('exactly at the threshold (90%) is nearLimit', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 90000,
            status: BudgetCategoryStatus.nearFull,
          ),
        ),
        ThresholdBand.nearLimit,
      );
    });

    test('between the threshold and 100% (95%) is nearLimit', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 95000,
            status: BudgetCategoryStatus.nearFull,
          ),
        ),
        ThresholdBand.nearLimit,
      );
    });

    test('exactly 100% is nearLimit — 010 marks over-budget only when actual '
        'exceeds planned', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 100000,
            status: BudgetCategoryStatus.nearFull,
          ),
        ),
        ThresholdBand.nearLimit,
      );
    });

    test('above 100% (100.01%) is exceeded', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 100010,
            status: BudgetCategoryStatus.overBudget,
          ),
        ),
        ThresholdBand.exceeded,
      );
    });

    test('zero spend is belowWarning', () {
      expect(
        bandOf(
          line(
            planned: 100000,
            actual: 0,
            status: BudgetCategoryStatus.onTrack,
          ),
        ),
        ThresholdBand.belowWarning,
      );
    });

    test('any spend against a zero-planned allocation is exceeded, with no '
        'percentage', () {
      final candidate = evaluator.evaluate([
        line(planned: 0, actual: 500, status: BudgetCategoryStatus.overBudget),
      ]).single;
      expect(candidate.band, ThresholdBand.exceeded);
      expect(candidate.percentageUsed, isNull);
    });
  });

  group('non-duplication (FR-003)', () {
    test("the band follows 010's status, never a recomputed percentage", () {
      // Deliberately inconsistent fixtures: if the evaluator derived the band
      // from the numbers itself, these would come out differently.
      final snapshots = [
        BudgetCategorySnapshot(
          categoryId: 'a',
          categoryName: 'A',
          month: '2026-09',
          plannedMinorUnits: 100,
          actualMinorUnits: 150,
          percentageUsed: 150,
          status: BudgetCategoryStatus.onTrack,
        ),
        BudgetCategorySnapshot(
          categoryId: 'b',
          categoryName: 'B',
          month: '2026-09',
          plannedMinorUnits: 100,
          actualMinorUnits: 10,
          percentageUsed: 10,
          status: BudgetCategoryStatus.overBudget,
        ),
      ];

      expect(evaluator.evaluate(snapshots).map((c) => c.band), [
        ThresholdBand.belowWarning,
        ThresholdBand.exceeded,
      ]);
    });

    test('carries 010 values through unchanged', () {
      final snapshot = line(
        planned: 120000,
        actual: 111000,
        status: BudgetCategoryStatus.nearFull,
      );
      final candidate = evaluator.evaluate([snapshot]).single;

      expect(candidate.categoryId, snapshot.categoryId);
      expect(candidate.categoryName, snapshot.categoryName);
      expect(candidate.applicablePeriod, '2026-09');
      expect(candidate.percentageUsed, snapshot.percentageUsed);
      expect(candidate.actualMinorUnits, 111000);
      expect(candidate.plannedMinorUnits, 120000);
    });

    test('one candidate per category, in input order; none for none', () {
      expect(evaluator.evaluate(const []), isEmpty);
      final candidates = evaluator.evaluate([
        line(
          categoryId: 'x',
          planned: 1,
          actual: 0,
          status: BudgetCategoryStatus.onTrack,
        ),
        line(
          categoryId: 'y',
          planned: 1,
          actual: 2,
          status: BudgetCategoryStatus.overBudget,
        ),
      ]);
      expect(candidates.map((c) => c.categoryId), ['x', 'y']);
    });

    test('the evaluation services never import a repository, the database, '
        'or another feature', () {
      final dir = Directory(
        'lib/features/insights_notifications/domain/services',
      );
      final directive = RegExp(
        r'''^\s*(?:import|export|part)\s+['"]([^'"]+)['"]''',
        multiLine: true,
      );
      final forbidden = RegExp(
        'repositor|database|drift|dao|features/(?!insights_notifications)',
        caseSensitive: false,
      );
      final evaluators = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.contains('evaluate_'))
          .toList();
      expect(evaluators, hasLength(2));

      final violations = [
        for (final file in evaluators)
          for (final m in directive.allMatches(file.readAsStringSync()))
            if (forbidden.hasMatch(m.group(1)!)) '${file.path}: ${m.group(1)}',
      ];
      expect(violations, isEmpty);
    });
  });
}
