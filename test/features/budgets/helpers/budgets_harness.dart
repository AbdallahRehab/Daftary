import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/features/budgets/data/repositories/budgets_repository_impl.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_category_allocation.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:drift/native.dart';
import '../../../helpers/test_daos.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';

/// Seeded 007 category ids — real rows created when the database opens,
/// not fixtures these tests insert.
const groceries = 'seed_groceries';
const rent = 'seed_rent';
const fuel = 'seed_fuel';
const restaurants = 'seed_restaurants';
const salary = 'seed_salary';

/// A real in-memory database with the real 007 repositories behind a real
/// [BudgetsRepositoryImpl] — so every "actual" figure in these tests is
/// produced by 007's own aggregation, exactly as in the app (FR-016).
///
/// 018: the primary currency and exchange rates are 018's real repository
/// on the same database (EGP and no rates until a test sets them), so a
/// rate set here is exactly what a rate set in settings would be — table
/// writes included, for the 021 live-update tests.
class BudgetsHarness {
  BudgetsHarness._(
    this.db,
    this.finance,
    this.categories,
    this.currency,
    this.repository,
  );

  static Future<BudgetsHarness> open() async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final financeDao = testFinanceDao(db);
    final finance = FinanceRepositoryImpl(financeDao);
    final categories = CategoryRepositoryImpl(financeDao);
    final currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    final repository = BudgetsRepositoryImpl(
      testBudgetsDao(db),
      db,
      finance,
      categories,
      GetConversionContext(currency),
      const CurrencyConverterImpl(),
    );
    // Forces `beforeOpen` (and therefore the category seed) to run.
    await db.select(db.financeCategories).get();
    return BudgetsHarness._(db, finance, categories, currency, repository);
  }

  final AppDatabase db;
  final FinanceRepositoryImpl finance;
  final CategoryRepositoryImpl categories;
  final CurrencyRepositoryImpl currency;
  final BudgetsRepositoryImpl repository;

  var _keySeq = 0;
  String nextKey() => 'key-${_keySeq++}';

  Future<void> close() => db.close();

  Future<Budget> createBudget(String month, {int? income}) async {
    final result = await repository.createBudget(
      idempotencyKey: nextKey(),
      month: month,
      expectedIncomeMinorUnits: income,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<BudgetCategoryAllocation> allocate(
    String budgetId,
    String categoryId,
    int plannedMinorUnits,
  ) async {
    final result = await repository.addBudgetCategoryAllocation(
      idempotencyKey: nextKey(),
      budgetId: budgetId,
      categoryId: categoryId,
      plannedAmountMinorUnits: plannedMinorUnits,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<FinanceEntry> spend(
    String categoryId,
    int amountMinorUnits,
    DateTime date, {
    Currency currency = Currency.egp,
  }) async {
    final result = await finance.addEntry(
      idempotencyKey: nextKey(),
      categoryId: categoryId,
      type: FinanceEntryType.expense,
      amount: Money.fromMinorUnits(amountMinorUnits, currency),
      date: date,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }

  /// "1 [from] = [rate] [to]", through 018's repository.
  Future<void> setRate(Currency from, double rate, {Currency? to}) async {
    final result = await currency.setExchangeRate(
      currencyCode: from.code,
      relativeToCurrencyCode: (to ?? Currency.egp).code,
      rate: rate,
    );
    result.getOrElse((f) => throw StateError(f.message));
  }

  Future<void> setPrimary(Currency primary) async {
    final result = await currency.setPrimaryCurrency(primary.code);
    result.getOrElse((f) => throw StateError(f.message));
  }

  Future<FinanceEntry> earn(int amountMinorUnits, DateTime date) async {
    final result = await finance.addEntry(
      idempotencyKey: nextKey(),
      categoryId: salary,
      type: FinanceEntryType.income,
      amount: Money.egp(amountMinorUnits),
      date: date,
    );
    return result.getOrElse((f) => throw StateError(f.message));
  }
}
