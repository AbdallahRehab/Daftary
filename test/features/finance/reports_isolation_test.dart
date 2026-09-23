import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// 013 T047 / FR-003 — Reports is a read-only composition over 007.
///
/// Every figure `GetSpendingTrend` and `ReportsCubit` surface must be
/// exactly what `GetFinanceSummary`/`GetCategoryBreakdown` return when
/// called directly for the same period against the same database — no
/// second calculation path, no rounding, no filtering. Real repositories
/// over one in-memory SQLite file, so the guarantee covers the whole read
/// path rather than a stub's echo.
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;
  late GetFinanceSummary getSummary;
  late GetCategoryBreakdown getBreakdown;
  late GetSpendingTrend getTrend;

  final now = DateTime.now();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(FinanceDao(db));
    getSummary = GetFinanceSummary(repository);
    getBreakdown = GetCategoryBreakdown(repository);
    getTrend = GetSpendingTrend(repository);

    // Entries spread across the current month and several past ones, with
    // odd piastre amounts so any rounding would show.
    final entries = [
      (0, 'seed_groceries', FinanceEntryType.expense, 75033),
      (0, 'seed_fuel', FinanceEntryType.expense, 12345),
      (0, 'seed_salary', FinanceEntryType.income, 900001),
      (1, 'seed_rent', FinanceEntryType.expense, 400000),
      (1, 'seed_groceries', FinanceEntryType.expense, 33301),
      (1, 'seed_salary', FinanceEntryType.income, 900001),
      (3, 'seed_medical', FinanceEntryType.expense, 22222),
      (5, 'seed_freelance', FinanceEntryType.income, 150099),
      // Outside the six-month window: must not reach the trend at all.
      (7, 'seed_rent', FinanceEntryType.expense, 999999),
    ];
    var i = 0;
    for (final (monthsAgo, categoryId, type, amount) in entries) {
      final result = await repository.addEntry(
        idempotencyKey: 'fin-${i++}',
        categoryId: categoryId,
        type: type,
        amountMinorUnits: amount,
        date: DateTime(now.year, now.month - monthsAgo, 1),
      );
      expect(result.isRight(), isTrue, reason: 'seeding $categoryId');
    }
  });

  tearDown(() => db.close());

  test('every trend point equals GetFinanceSummary for that month', () async {
    final trend = (await getTrend(
      monthsBack: ReportsCubit.trendMonths,
    )).getOrElse((f) => throw StateError(f.message));

    expect(trend, hasLength(ReportsCubit.trendMonths));
    for (final point in trend) {
      final direct = (await getSummary(
        point.period,
      )).getOrElse((f) => throw StateError(f.message));
      expect(point.totalIncomeMinorUnits, direct.totalIncome.minorUnits);
      expect(point.totalExpenseMinorUnits, direct.totalExpense.minorUnits);
      expect(point.netMinorUnits, direct.net.minorUnits);
    }

    // The current month is literally "this month" as Home and the history
    // screen compute it.
    final thisMonth = (await getSummary(
      DateRange.thisMonth(),
    )).getOrElse((f) => throw StateError(f.message));
    expect(trend.last.period, DateRange.thisMonth());
    expect(trend.last.netMinorUnits, thisMonth.net.minorUnits);
  });

  test('the cubit surfaces the same trend and, for every period preset, the '
      'same breakdown as GetCategoryBreakdown', () async {
    final cubit = ReportsCubit(getTrend, getBreakdown, repository);
    addTearDown(cubit.close);

    await cubit.load();
    expect(cubit.state.status, ReportsStatus.success);
    expect(
      cubit.state.trend,
      (await getTrend(
        monthsBack: ReportsCubit.trendMonths,
      )).getOrElse((f) => throw StateError(f.message)),
    );

    for (final period in ReportsPeriod.values) {
      await cubit.changeBreakdownPeriod(period);
      final direct = (await getBreakdown(
        period.range(),
        type: FinanceEntryType.expense,
      )).getOrElse((f) => throw StateError(f.message));

      expect(cubit.state.breakdownPeriod, period);
      expect(cubit.state.breakdown, direct, reason: period.name);
      expect(cubit.state.breakdown, isNotEmpty, reason: period.name);
    }
  });

  test('loading Reports changes nothing underneath', () async {
    Future<int> rowCount() async =>
        (await db.select(db.financeEntries).get()).length;
    final before = await rowCount();
    final summaryBefore = await getSummary(DateRange.thisMonth());

    final cubit = ReportsCubit(getTrend, getBreakdown, repository);
    addTearDown(cubit.close);
    await cubit.load();
    for (final period in ReportsPeriod.values) {
      await cubit.changeBreakdownPeriod(period);
    }

    expect(await rowCount(), before);
    expect(await getSummary(DateRange.thisMonth()), summaryBefore);
  });
}
