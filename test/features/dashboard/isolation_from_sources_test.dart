import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_summary.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_overview.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_daos.dart';

/// T043 / FR-016 — Home is a read-only composition layer.
///
/// Whatever `DashboardCubit` surfaces must be exactly what `GetOverview`
/// and `GetFinanceSummary` return when called directly against the same
/// database — no re-derived totals, no rounding,
/// no filtering. Real repositories over one in-memory SQLite file, so the
/// guarantee covers the whole read path rather than a stub's echo.
void main() {
  late AppDatabase db;
  late GetOverview getOverview;
  late GetFinanceSummary getFinanceSummary;

  /// Home's cubit over real repositories on [db], wired as DI wires it.
  DashboardCubit homeCubit() {
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final finance = FinanceRepositoryImpl(testFinanceDao(db));
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: GetConversionContext(currency),
    );
    final summary = GetFinanceSummary(
      finance,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );
    return DashboardCubit(
      WatchOverview(transactions),
      WatchFinanceSummary(finance, WatchConversionContext(currency), summary),
      WatchFinanceHistory(finance),
    );
  }

  /// Waits until neither aggregate is loading any more.
  Future<void> settled(DashboardCubit cubit) => cubit.stream.firstWhere(
    (s) =>
        s.overviewStatus != LoadStatus.loading &&
        s.financeStatus != LoadStatus.loading,
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final finance = FinanceRepositoryImpl(testFinanceDao(db));
    final transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: GetConversionContext(currency),
    );
    getOverview = GetOverview(transactions);
    getFinanceSummary = GetFinanceSummary(
      finance,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );

    for (final (id, name) in [
      ('p1', 'Ahmed'),
      ('p2', 'Mona'),
      ('p3', 'Sara'),
    ]) {
      await db
          .into(db.people)
          .insert(
            PeopleCompanion.insert(
              id: id,
              name: name,
              normalizedName: name.toLowerCase(),
              createdAt: 1,
              updatedAt: 1,
            ),
          );
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastMonth = DateTime(now.year, now.month - 1, 10);

    await transactions.addTransaction(
      idempotencyKey: 'tx-1',
      personId: 'p1',
      amount: const Money.egp(50025),
      direction: TransactionDirection.given,
      date: today,
    );
    await transactions.addTransaction(
      idempotencyKey: 'tx-2',
      personId: 'p2',
      amount: const Money.egp(20010),
      direction: TransactionDirection.received,
      date: today,
    );

    await finance.addEntry(
      idempotencyKey: 'fin-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amount: Money.egp(75033),
      date: today,
    );
    await finance.addEntry(
      idempotencyKey: 'fin-2',
      categoryId: 'seed_salary',
      type: FinanceEntryType.income,
      amount: Money.egp(900001),
      date: today,
    );
    // Outside "this month": must not reach Home's summary either.
    await finance.addEntry(
      idempotencyKey: 'fin-3',
      categoryId: 'seed_rent',
      type: FinanceEntryType.expense,
      amount: Money.egp(400000),
      date: lastMonth,
    );
  });

  tearDown(() => db.close());

  Future<OverviewSummary> directOverview() async =>
      (await getOverview()).getOrElse((f) => throw StateError(f.message));

  Future<FinanceSummary> directFinance() async => (await getFinanceSummary(
    DateRange.thisMonth(),
  )).getOrElse((f) => throw StateError(f.message));

  test('the cubit state surfaces exactly what the source use cases '
      'return, and loading Home changes nothing underneath', () async {
    final expectedOverview = await directOverview();
    final expectedFinance = await directFinance();

    final cubit = homeCubit();
    addTearDown(cubit.close);
    final ready = settled(cubit);
    await cubit.load();
    await ready;

    expect(cubit.state.overviewStatus, LoadStatus.success);
    expect(cubit.state.financeStatus, LoadStatus.success);
    expect(cubit.state.overviewSummary, expectedOverview);
    expect(cubit.state.financeSummary, expectedFinance);
    expect(cubit.state.isCombinedEmpty, isFalse);

    // Reading through Home is side-effect-free: the sources still agree
    // with what they returned before Home ever loaded.
    expect(await directOverview(), expectedOverview);
    expect(await directFinance(), expectedFinance);
  });

  test('a fresh database is the combined empty state end to end', () async {
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final cubit = homeCubit();
    addTearDown(cubit.close);

    await cubit.load();
    await cubit.stream.firstWhere((s) => s.isCombinedEmpty);

    expect(cubit.state.isCombinedEmpty, isTrue);
  });
}
