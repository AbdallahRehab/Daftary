import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/conversion_fakes.dart';
import '../../helpers/test_daos.dart';

/// T079 — the Scale/Scope ceiling from plan.md: ~5,000 finance entries, with
/// summary, breakdown, and history each expected inside 1s.
///
/// This asserts the query shape, not the device. The budgets below are
/// deliberately loose (10x the stated target) because CI machines are
/// noisy: what this test actually catches is a regression from a SQL
/// aggregate to client-side summing, which turns these milliseconds into
/// seconds and fails by an order of magnitude rather than by a hair.
///
/// Frame-rate behavior of the history list is not measurable here — it is
/// covered by quickstart.md's manual scroll check, and by `getHistory`
/// paginating rather than returning all 5,000 rows.
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;

  const entryCount = 5000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(testFinanceDao(db));

    final categories = await db.select(db.financeCategories).get();
    final now = DateTime.now().millisecondsSinceEpoch;

    // One batch insert rather than 5,000 repository calls: the subject here
    // is read performance, and seeding through the write path would dominate
    // the test's own runtime without measuring anything.
    await db.batch((batch) {
      for (var i = 0; i < entryCount; i++) {
        final category = categories[i % categories.length];
        final date = DateTime(
          2026,
          1 + (i % 12),
          1 + (i % 28),
        ).millisecondsSinceEpoch;
        batch.insert(
          db.financeEntries,
          FinanceEntriesCompanion.insert(
            id: 'entry_$i',
            idempotencyKey: 'key_$i',
            categoryId: category.id,
            type: category.type,
            amountMinorUnits: 1000 + i,
            date: date,
            createdAt: now,
          ),
        );
      }
    });
  });

  tearDown(() => db.close());

  final wholeYear = DateRange(
    start: DateTime(2026, 1, 1),
    end: DateTime(2026, 12, 31),
  );

  test(
    'getSummary over $entryCount entries stays well inside budget',
    () async {
      final stopwatch = Stopwatch()..start();
      final result = await summaryUseCase(repository)(wholeYear);
      stopwatch.stop();

      final summary = result.getOrElse((f) => throw StateError(f.message));
      expect(
        summary.totalIncome!.minorUnits + summary.totalExpense!.minorUnits,
        greaterThan(0),
      );
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    },
  );

  test(
    'getCategoryBreakdown over $entryCount entries stays well inside budget',
    () async {
      final stopwatch = Stopwatch()..start();
      final result = await breakdownUseCase(repository)(wholeYear);
      stopwatch.stop();

      final breakdown = result
          .getOrElse((f) => throw StateError(f.message))
          .items;
      expect(breakdown, isNotEmpty);
      // Descending by amount, as FR-015 requires.
      for (var i = 1; i < breakdown.length; i++) {
        expect(
          breakdown[i - 1].total!.minorUnits,
          greaterThanOrEqualTo(breakdown[i].total!.minorUnits),
        );
      }
      expect(stopwatch.elapsedMilliseconds, lessThan(10000));
    },
  );

  test('getHistory paginates rather than loading every row', () async {
    final stopwatch = Stopwatch()..start();
    final result = await repository.getHistory(limit: 50);
    stopwatch.stop();

    final page = result.getOrElse((f) => throw StateError(f.message));
    expect(
      page,
      hasLength(50),
      reason:
          'a page, not all $entryCount rows — this is what keeps the '
          'list scrolling smoothly',
    );
    expect(stopwatch.elapsedMilliseconds, lessThan(10000));
  });

  test(
    'totals are exact integer minor units — no rounding drift (SC-003)',
    () async {
      final result = await summaryUseCase(repository)(wholeYear);
      final summary = result.getOrElse((f) => throw StateError(f.message));

      // The expected total is computed independently, in pure integer
      // arithmetic, from the same formula the seeding used.
      var expectedTotal = 0;
      for (var i = 0; i < entryCount; i++) {
        expectedTotal += 1000 + i;
      }

      expect(
        summary.totalIncome!.minorUnits + summary.totalExpense!.minorUnits,
        expectedTotal,
      );
    },
  );
}
