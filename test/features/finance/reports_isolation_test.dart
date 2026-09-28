import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:daftary/features/finance/domain/usecases/watch_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/watch_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/stream_recorder.dart';
import '../../helpers/test_daos.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/core/money/money.dart';

/// 013 T047 / FR-003 — Reports is a read-only composition over 007.
///
/// Every figure `GetSpendingTrend` and `ReportsCubit` surface must be
/// exactly what `GetFinanceSummary`/`GetCategoryBreakdown` return when
/// called directly for the same period against the same database — no
/// second calculation path, no rounding, no filtering. Real repositories
/// over one in-memory SQLite file, so the guarantee covers the whole read
/// path rather than a stub's echo — including the live read path the
/// Reports screen subscribes to (021 FR-031).
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl repository;
  late CurrencyRepositoryImpl currency;
  late GetFinanceSummary getSummary;
  late GetCategoryBreakdown getBreakdown;
  late GetSpendingTrend getTrend;
  late WatchSpendingTrend watchTrend;
  late WatchCategoryBreakdown watchBreakdown;

  final now = DateTime.now();

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FinanceRepositoryImpl(testFinanceDao(db));
    currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    getSummary = GetFinanceSummary(
      repository,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );
    getBreakdown = GetCategoryBreakdown(
      repository,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );
    getTrend = GetSpendingTrend(getSummary);
    watchTrend = WatchSpendingTrend(
      repository,
      WatchConversionContext(currency),
      getSummary,
    );
    watchBreakdown = WatchCategoryBreakdown(
      repository,
      WatchConversionContext(currency),
      getBreakdown,
    );

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
        amount: Money.egp(amount),
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
      expect(point.totalIncomeMinorUnits, direct.totalIncome!.minorUnits);
      expect(point.totalExpenseMinorUnits, direct.totalExpense!.minorUnits);
      expect(point.netMinorUnits, direct.net!.minorUnits);
    }

    // The current month is literally "this month" as Home and the history
    // screen compute it.
    final thisMonth = (await getSummary(
      DateRange.thisMonth(),
    )).getOrElse((f) => throw StateError(f.message));
    expect(trend.last.period, DateRange.thisMonth());
    expect(trend.last.netMinorUnits, thisMonth.net!.minorUnits);
  });

  test('the cubit surfaces the same trend and, for every period preset, the '
      'same breakdown as GetCategoryBreakdown', () async {
    final cubit = ReportsCubit(watchTrend, watchBreakdown, repository);
    addTearDown(cubit.close);

    await cubit.subscribe();
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
      expect(cubit.state.breakdown.items, isNotEmpty, reason: period.name);
    }
  });

  test('loading Reports changes nothing underneath', () async {
    Future<int> rowCount() async =>
        (await db.select(db.financeEntries).get()).length;
    final before = await rowCount();
    final summaryBefore = await getSummary(DateRange.thisMonth());

    final cubit = ReportsCubit(watchTrend, watchBreakdown, repository);
    addTearDown(cubit.close);
    await cubit.subscribe();
    for (final period in ReportsPeriod.values) {
      await cubit.changeBreakdownPeriod(period);
    }

    expect(await rowCount(), before);
    expect(await getSummary(DateRange.thisMonth()), summaryBefore);
  });
  test('the live reads equal the one-shot reads for the same window and '
      'every period preset (021)', () async {
    final trend = StreamRecorder(
      watchTrend(monthsBack: ReportsCubit.trendMonths),
    );
    addTearDown(trend.cancel);
    final direct = await getTrend(monthsBack: ReportsCubit.trendMonths);
    expect(
      (await trend.waitFor((_) => true)).toNullable(),
      direct.toNullable(),
    );

    for (final period in ReportsPeriod.values) {
      final range = period.range();
      final breakdown = StreamRecorder(
        watchBreakdown(range, type: FinanceEntryType.expense),
      );
      addTearDown(breakdown.cancel);
      expect(
        (await breakdown.waitFor((_) => true)).toNullable(),
        (await getBreakdown(
          range,
          type: FinanceEntryType.expense,
        )).toNullable(),
        reason: period.name,
      );
    }
  });

  group('a change elsewhere updates the open Reports screen (021 FR-031)', () {
    late ReportsCubit cubit;

    /// The cubit's first state, current or future, satisfying [test] — the
    /// database streams debounce writes, so this waits in real time.
    Future<ReportsState> stateWhere(bool Function(ReportsState s) test) {
      if (test(cubit.state)) return Future.value(cubit.state);
      return cubit.stream.firstWhere(test).timeout(const Duration(seconds: 2));
    }

    setUp(() async {
      cubit = ReportsCubit(watchTrend, watchBreakdown, repository);
      await cubit.subscribe();
      expect(cubit.state.status, ReportsStatus.success);
    });

    tearDown(() => cubit.close());

    test('an entry recorded on another screen reaches the trend and the '
        'breakdown, with no reload', () async {
      final before = cubit.state.trend.last.totalExpenseMinorUnits;
      final states = <ReportsState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await repository.addEntry(
        idempotencyKey: 'elsewhere-1',
        categoryId: 'seed_water',
        type: FinanceEntryType.expense,
        amount: Money.egp(98765),
        date: DateTime(now.year, now.month, 1),
      );

      await stateWhere(
        (s) =>
            s.trend.last.totalExpenseMinorUnits == before + 98765 &&
            s.breakdown.items.any((i) => i.categoryId == 'seed_water'),
      );
      expect(
        cubit.state.breakdown,
        (await getBreakdown(
          ReportsPeriod.thisMonth.range(),
          type: FinanceEntryType.expense,
        )).getOrElse((f) => throw StateError(f.message)),
      );
      expect(states.map((s) => s.status), everyElement(ReportsStatus.success));
    });

    test('a foreign-currency entry blocks the screen until its rate is set, '
        'then shows the converted figures', () async {
      final before = cubit.state.trend.last.totalExpenseMinorUnits;
      await repository.addEntry(
        idempotencyKey: 'elsewhere-usd',
        categoryId: 'seed_fuel',
        type: FinanceEntryType.expense,
        amount: Money.fromMinorUnits(1000, Currency.usd),
        date: DateTime(now.year, now.month, 1),
      );
      await stateWhere((s) => s.isFailure && s.failure is RatesMissingFailure);

      await currency.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 50,
      );

      // 10.00 USD × 50 = 500.00 EGP. The trend and the breakdown each
      // re-read, so wait for both.
      final state = await stateWhere(
        (s) => s.isSuccess && !s.breakdown.isBlocked,
      );
      expect(state.trend.last.totalExpenseMinorUnits, before + 50000);
    });

    test('a category renamed elsewhere relabels its breakdown row', () async {
      final categories = CategoryRepositoryImpl(testFinanceDao(db));
      await categories.editCategory(
        categoryId: 'seed_groceries',
        name: 'Supermarket',
        icon: 'groceries',
      );

      await stateWhere(
        (s) => s.breakdown.items.any(
          (i) =>
              i.categoryId == 'seed_groceries' &&
              i.categoryName == 'Supermarket',
        ),
      );
    });
  });
}
