import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_summary.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';

/// 021 T031: finance history, totals and categories are live.
void main() {
  late AppDatabase db;
  late FinanceRepositoryImpl finance;
  late CategoryRepositoryImpl categories;
  late CurrencyRepositoryImpl currency;

  const groceries = 'seed_groceries';
  final period = DateRange(
    start: DateTime(2026, 1, 1),
    end: DateTime(2026, 1, 31),
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    finance = FinanceRepositoryImpl(testFinanceDao(db));
    categories = CategoryRepositoryImpl(testFinanceDao(db));
    currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    await db.select(db.financeCategories).get();
  });

  tearDown(() => db.close());

  Future<String> spend(int minorUnits, String key, {Currency? currency}) async {
    final entry = await finance.addEntry(
      idempotencyKey: key,
      categoryId: groceries,
      type: FinanceEntryType.expense,
      amount: Money.fromMinorUnits(minorUnits, currency ?? Currency.egp),
      date: DateTime(2026, 1, 15),
    );
    return rightOf(entry).id;
  }

  test('history re-emits after add, delete and restore', () async {
    final history = StreamRecorder(finance.watchHistory(limit: 50));
    addTearDown(history.cancel);
    await history.waitFor((r) => rightOf(r).isEmpty);

    final id = await spend(1000, 'k1');
    await history.waitFor((r) => rightOf(r).length == 1);

    await finance.deleteEntry(id);
    await history.waitForNext((r) => rightOf(r).isEmpty);

    await finance.restoreEntry(id);
    await history.waitForNext((r) => rightOf(r).length == 1);
  });

  test('watchHistory(limit: 50) never emits more than 50 rows', () async {
    for (var i = 0; i < 55; i++) {
      await spend(100 + i, 'k$i');
    }
    final history = StreamRecorder(finance.watchHistory(limit: 50));
    addTearDown(history.cancel);
    await history.waitFor((r) => rightOf(r).isNotEmpty);

    await spend(999, 'extra');
    await StreamRecorder.settle();

    expect(history.values.map((r) => rightOf(r).length), everyElement(50));
  });

  test('summary totals re-emit after an entry write', () async {
    final totals = StreamRecorder(finance.watchSummaryTotals(period));
    addTearDown(totals.cancel);
    await totals.waitFor((r) => rightOf(r).expense.isEmpty);

    await spend(2500, 'k1');

    await totals.waitFor(
      (r) => rightOf(r).expense.contains(const Money.egp(2500)),
    );
  });

  test('categories re-emit after create, edit and remove', () async {
    final expense = StreamRecorder(
      categories.watchCategories(type: CategoryType.expense),
    );
    addTearDown(expense.cancel);
    final initial = rightOf(
      await expense.waitFor((r) => rightOf(r).isNotEmpty),
    );

    final created = rightOf(
      await categories.createCategory(
        name: 'Books',
        type: CategoryType.expense,
        icon: 'book',
      ),
    );
    await expense.waitFor((r) => rightOf(r).any((c) => c.name == 'Books'));

    await categories.editCategory(
      categoryId: created.id,
      name: 'Novels',
      icon: 'book',
    );
    await expense.waitFor((r) => rightOf(r).any((c) => c.name == 'Novels'));

    await categories.removeCategory(created.id);
    await expense.waitForNext((r) => rightOf(r).length == initial.length);
  });

  test('WatchFinanceSummary re-emits when a rate changes', () async {
    await currency.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    await spend(100, 'k1', currency: Currency.usd);
    final watch = WatchFinanceSummary(
      finance,
      WatchConversionContext(currency),
      GetFinanceSummary(
        finance,
        GetConversionContext(currency),
        const CurrencyConverterImpl(),
      ),
    );
    final summary = StreamRecorder(watch(period));
    addTearDown(summary.cancel);
    await summary.waitFor(
      (r) => rightOf(r).totalExpense == const Money.egp(5000),
    );

    await currency.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 60,
    );

    await summary.waitFor(
      (r) => rightOf(r).totalExpense == const Money.egp(6000),
    );
  });
}
