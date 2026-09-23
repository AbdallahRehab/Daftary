import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/domain/usecases/get_dashboard_snapshot.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T043 / FR-016 — Home is a read-only composition layer.
///
/// Whatever `GetDashboardSnapshot` and `DashboardCubit` surface must be
/// exactly what `GetOverview` and `GetFinanceSummary` return when called
/// directly against the same database — no re-derived totals, no rounding,
/// no filtering. Real repositories over one in-memory SQLite file, so the
/// guarantee covers the whole read path rather than a stub's echo.
void main() {
  late AppDatabase db;
  late GetOverview getOverview;
  late GetFinanceSummary getFinanceSummary;
  late GetFinanceHistory getFinanceHistory;
  late GetDashboardSnapshot getSnapshot;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final finance = FinanceRepositoryImpl(FinanceDao(db));
    final transactions = TransactionsRepositoryImpl(TransactionsDao(db), db);
    getOverview = GetOverview(transactions);
    getFinanceSummary = GetFinanceSummary(finance);
    getFinanceHistory = GetFinanceHistory(finance);
    getSnapshot = GetDashboardSnapshot(
      getOverview,
      getFinanceSummary,
      getFinanceHistory,
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
      amount: const Money.fromMinorUnits(50025),
      direction: TransactionDirection.given,
      date: today,
    );
    await transactions.addTransaction(
      idempotencyKey: 'tx-2',
      personId: 'p2',
      amount: const Money.fromMinorUnits(20010),
      direction: TransactionDirection.received,
      date: today,
    );

    await finance.addEntry(
      idempotencyKey: 'fin-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 75033,
      date: today,
    );
    await finance.addEntry(
      idempotencyKey: 'fin-2',
      categoryId: 'seed_salary',
      type: FinanceEntryType.income,
      amountMinorUnits: 900001,
      date: today,
    );
    // Outside "this month": must not reach Home's summary either.
    await finance.addEntry(
      idempotencyKey: 'fin-3',
      categoryId: 'seed_rent',
      type: FinanceEntryType.expense,
      amountMinorUnits: 400000,
      date: lastMonth,
    );
  });

  tearDown(() => db.close());

  Future<OverviewSummary> directOverview() async =>
      (await getOverview()).getOrElse((f) => throw StateError(f.message));

  Future<FinanceSummary> directFinance() async => (await getFinanceSummary(
    DateRange.thisMonth(),
  )).getOrElse((f) => throw StateError(f.message));

  test(
    'the snapshot carries exactly what the source use cases return',
    () async {
      final expectedOverview = await directOverview();
      final expectedFinance = await directFinance();

      final snapshot = await getSnapshot(period: DateRange.thisMonth());

      expect(
        snapshot.overview.getOrElse((f) => throw StateError(f.message)),
        expectedOverview,
      );
      expect(
        snapshot.finance.getOrElse((f) => throw StateError(f.message)),
        expectedFinance,
      );
      expect(snapshot.hasAnyFinanceEntry, isTrue);
      expect(snapshot.isCombinedEmpty, isFalse);
    },
  );

  test('the cubit state surfaces the same values, and loading Home changes '
      'nothing underneath', () async {
    final expectedOverview = await directOverview();
    final expectedFinance = await directFinance();

    final cubit = DashboardCubit(getSnapshot, getOverview, getFinanceSummary);
    addTearDown(cubit.close);
    await cubit.load();
    await cubit.refresh();
    await cubit.retryOverview();
    await cubit.retryFinance();

    expect(cubit.state.overviewStatus, LoadStatus.success);
    expect(cubit.state.financeStatus, LoadStatus.success);
    expect(cubit.state.overviewSummary, expectedOverview);
    expect(cubit.state.financeSummary, expectedFinance);

    // Reading through Home is side-effect-free: the sources still agree
    // with what they returned before Home ever loaded.
    expect(await directOverview(), expectedOverview);
    expect(await directFinance(), expectedFinance);
  });

  test('a fresh database is the combined empty state end to end', () async {
    await db.close();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final finance = FinanceRepositoryImpl(FinanceDao(db));
    final transactions = TransactionsRepositoryImpl(TransactionsDao(db), db);
    final cubit = DashboardCubit(
      GetDashboardSnapshot(
        GetOverview(transactions),
        GetFinanceSummary(finance),
        GetFinanceHistory(finance),
      ),
      GetOverview(transactions),
      GetFinanceSummary(finance),
    );
    addTearDown(cubit.close);

    await cubit.load();

    expect(cubit.state.isCombinedEmpty, isTrue);
  });
}
