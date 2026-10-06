import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/egp_formatter.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/get_primary_currency.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/edit_finance_entry.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_entry_form_state.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/people/domain/usecases/watch_person.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_person_balance.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/usecases/create_person.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/models/transaction_mapper.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/usecases/add_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/find_possible_duplicate.dart';
import 'package:daftary/features/transactions/domain/usecases/edit_transaction.dart';
import 'package:daftary/features/transactions/domain/usecases/record_repayment.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/repayment_form_state.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../helpers/test_daos.dart';

/// 018 T038 — release-blocking regression anchor for FR-015 / SC-008: a
/// user who only ever uses EGP must see NO behavior change from the
/// multi-currency feature.
///
/// Everything below runs against a real in-memory [AppDatabase] with the
/// real currency stack (`CurrencyRepositoryImpl` → `GetPrimaryCurrency` /
/// `GetConversionContext`, `CurrencyConverterImpl`) wired by hand — no
/// fakes, no DI. Records are created through the real form cubits exactly
/// as the UI does, and the currency picker (`currencyChanged`) is NEVER
/// touched; neither is any currency setting or exchange rate. The test then
/// asserts:
///
///  - every stored row's `currency_code` is `'EGP'`, and no primary-currency
///    row or exchange rate was ever written;
///  - person balances, the overview, the finance summary and the category
///    breakdown are plain, never-blocked totals whose values equal the
///    pre-018 formulas (net = Σgiven − Σreceived; income/expense = Σ per
///    type; share = category / period total), computed by hand here;
///  - `EgpFormatter.formatWithSymbol` renders those figures as the exact
///    literal strings a pre-018 build displayed.
///
/// Scope: the task names five features, but only people/transactions (001)
/// and finance (007) exist in this codebase. Occasions (008), Budgets (010)
/// and Savings goals (011) are not implemented, so there is nothing of
/// theirs to create or assert on.
void main() {
  late AppDatabase db;
  late CurrencyRepositoryImpl currencyRepository;
  late GetPrimaryCurrency getPrimaryCurrency;
  late GetConversionContext getConversionContext;
  late PeopleRepositoryImpl peopleRepository;
  late TransactionsRepositoryImpl transactionsRepository;
  late FinanceRepositoryImpl financeRepository;
  late CategoryRepositoryImpl categoryRepository;
  late GetFinanceSummary getFinanceSummary;
  late GetCategoryBreakdown getCategoryBreakdown;

  final formatter = EgpFormatter();
  final recordDate = DateTime(2026, 9, 10);
  final september = DateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30),
  );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Forces `beforeOpen` (category seed) before any assertion.
    await db.select(db.financeCategories).get();

    currencyRepository = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    getPrimaryCurrency = GetPrimaryCurrency(currencyRepository);
    getConversionContext = GetConversionContext(currencyRepository);
    peopleRepository = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: getConversionContext,
    );
    transactionsRepository = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: getConversionContext,
    );
    financeRepository = FinanceRepositoryImpl(testFinanceDao(db));
    categoryRepository = CategoryRepositoryImpl(testFinanceDao(db));
    getFinanceSummary = GetFinanceSummary(
      financeRepository,
      getConversionContext,
      const CurrencyConverterImpl(),
    );
    getCategoryBreakdown = GetCategoryBreakdown(
      financeRepository,
      getConversionContext,
      const CurrencyConverterImpl(),
    );
  });

  tearDown(() => db.close());

  // ---------------------------------------------------------------- helpers
  // Each helper drives a fresh form cubit the way its page does — including
  // the page's default-currency load — and never calls `currencyChanged`.

  TransactionFormCubit transactionForm() => TransactionFormCubit(
    peopleRepository,
    CreatePerson(peopleRepository),
    AddTransaction(transactionsRepository),
    EditTransaction(transactionsRepository),
    getPrimaryCurrency,
    FindPossibleDuplicate(transactionsRepository),
  );

  /// Creates [name] inline from the transaction form (FR-002) and records
  /// one exchange with them.
  Future<Person> recordWithNewPerson(
    String name, {
    required String amount,
    required TransactionDirection direction,
  }) async {
    final cubit = transactionForm();
    addTearDown(cubit.close);
    await cubit.loadDefaultCurrency();
    await cubit.createNewPerson(name);
    final person = cubit.state.selectedPerson!;
    await _submitTransaction(cubit, amount: amount, direction: direction);
    return person;
  }

  Future<void> recordForPerson(
    Person person, {
    required String amount,
    required TransactionDirection direction,
  }) async {
    final cubit = transactionForm();
    addTearDown(cubit.close);
    await cubit.loadDefaultCurrency();
    cubit.selectExistingPerson(person);
    await _submitTransaction(cubit, amount: amount, direction: direction);
  }

  Future<void> recordRepayment(Person person, String amount) async {
    final cubit = RepaymentFormCubit(
      RecordRepayment(transactionsRepository),
      getPrimaryCurrency,
      WatchPersonBalance(transactionsRepository),
      WatchConversionContext(currencyRepository),
      WatchPerson(peopleRepository),
      person.id,
    );
    addTearDown(cubit.close);
    await cubit.loadDefaultCurrency();
    cubit.subscribe();
    // Saving waits for the balance and the rates to load (022 A2).
    await cubit.stream.firstWhere((s) => s.balanceLoaded);
    cubit
      ..amountChanged(amount)
      ..dateChanged(recordDate);
    await cubit.submit();
    expect(cubit.state.status, RepaymentFormStatus.success);
  }

  Future<void> recordFinanceEntry(
    FinanceEntryType type,
    String categoryId,
    String amount,
  ) async {
    final cubit = FinanceEntryFormCubit(
      AddFinanceEntry(financeRepository),
      EditFinanceEntry(financeRepository),
      GetCategories(categoryRepository),
      formatter,
      getPrimaryCurrency,
    );
    addTearDown(cubit.close);
    await cubit.initialize(type: type);
    cubit
      ..categorySelected(categoryId)
      ..amountChanged(amount)
      ..dateChanged(recordDate);
    await cubit.submit();
    expect(cubit.state.status, FinanceEntryFormStatus.success);
  }

  /// The EGP-only user's whole flow. Pre-018 expected figures (piastres):
  ///
  ///  Ahmed: given 1,500.00, repaid 400.00   → net +110,000 (they owe you)
  ///  Mona:  received 750.25                 → net  −75,025 (you owe them)
  ///  Karim: given 200.00, received 200.00   → net        0 (settled)
  ///
  ///  Income:  salary 10,000.00 + freelance 2,500.50  = 1,250,050
  ///  Expense: rent 4,000.00 + groceries 1,234.56 + 65.44 = 530,000
  ///           (groceries 130,000; rent 400,000)
  Future<Map<String, Person>> runEgpOnlyFlow() async {
    final ahmed = await recordWithNewPerson(
      'Ahmed',
      amount: '1500',
      direction: TransactionDirection.given,
    );
    await recordRepayment(ahmed, '400');
    final mona = await recordWithNewPerson(
      'Mona',
      amount: '750.25',
      direction: TransactionDirection.received,
    );
    final karim = await recordWithNewPerson(
      'Karim',
      amount: '200',
      direction: TransactionDirection.given,
    );
    await recordForPerson(
      karim,
      amount: '200',
      direction: TransactionDirection.received,
    );

    await recordFinanceEntry(FinanceEntryType.income, 'seed_salary', '10000');
    await recordFinanceEntry(
      FinanceEntryType.income,
      'seed_freelance',
      '2500.50',
    );
    await recordFinanceEntry(FinanceEntryType.expense, 'seed_rent', '4000');
    await recordFinanceEntry(
      FinanceEntryType.expense,
      'seed_groceries',
      '1234.56',
    );
    await recordFinanceEntry(
      FinanceEntryType.expense,
      'seed_groceries',
      '65.44',
    );
    return {'ahmed': ahmed, 'mona': mona, 'karim': karim};
  }

  Future<PersonBalance> balanceOf(Person person) async =>
      (await transactionsRepository.getPersonBalance(
        person.id,
      )).getOrElse((f) => throw StateError(f.message));

  // ------------------------------------------------------------------ tests

  test('every saved record is stored in EGP, and no currency setting or '
      'exchange rate is ever written', () async {
    await runEgpOnlyFlow();

    final transactions = await db.select(db.moneyTransactions).get();
    expect(transactions, hasLength(5));
    expect(transactions.map((r) => r.currencyCode).toSet(), {'EGP'});
    expect(transactions.map((r) => r.amountMinorUnits).toList()..sort(), [
      20000,
      20000,
      40000,
      75025,
      150000,
    ]);

    final entries = await db.select(db.financeEntries).get();
    expect(entries, hasLength(5));
    expect(entries.map((r) => r.currencyCode).toSet(), {'EGP'});
    expect(entries.map((r) => r.amountMinorUnits).toList()..sort(), [
      6544,
      123456,
      250050,
      400000,
      1000000,
    ]);

    expect(await db.select(db.primaryCurrencySettings).get(), isEmpty);
    expect(await db.select(db.exchangeRates).get(), isEmpty);
  });

  test('the repayment direction is derived exactly as before 018 (they owe '
      'you ⇒ received)', () async {
    final people = await runEgpOnlyFlow();

    final history = (await transactionsRepository.getPersonHistory(
      people['ahmed']!.id,
    )).getOrElse((f) => throw StateError(f.message));
    final repayment = history.singleWhere(
      (t) => t.kind == TransactionKind.repayment,
    );
    expect(repayment.direction, TransactionDirection.received);
    expect(repayment.amount, const Money.egp(40000));
  });

  test('person balances are plain EGP totals equal to Σgiven − Σreceived, '
      'never blocked', () async {
    final people = await runEgpOnlyFlow();

    // The pre-018 formula, straight off the stored rows.
    final rows = await db.select(db.moneyTransactions).get();
    int preFeatureNet(String personId) => rows
        .where((r) => r.personId == personId && r.deletedAt == null)
        .fold(
          0,
          (sum, r) =>
              sum +
              (r.direction == TransactionDirection.given.dbValue
                  ? r.amountMinorUnits
                  : -r.amountMinorUnits),
        );

    final expected = {'ahmed': 110000, 'mona': -75025, 'karim': 0};
    final expectedText = {
      'ahmed': '1,100.00 EGP',
      'mona': '-750.25 EGP',
      'karim': '0.00 EGP',
    };
    final expectedStatus = {
      'ahmed': RelationshipStatus.theyOweYou,
      'mona': RelationshipStatus.youOweThem,
      'karim': RelationshipStatus.settled,
    };

    for (final MapEntry(key: key, value: person) in people.entries) {
      final balance = await balanceOf(person);
      expect(balance.isBlocked, isFalse, reason: key);
      expect(balance.missingRatesFor, isEmpty, reason: key);
      expect(balance.nativeNets, isEmpty, reason: key);
      expect(balance.net, Money.egp(expected[key]!), reason: key);
      expect(balance.net!.minorUnits, preFeatureNet(person.id), reason: key);
      expect(balance.status, expectedStatus[key], reason: key);
      expect(
        formatter.formatWithSymbol(balance.net!),
        expectedText[key],
        reason: key,
      );
    }
  });

  test('the overview totals are plain EGP sums, never blocked', () async {
    final people = await runEgpOnlyFlow();

    final overview = (await transactionsRepository.getOverview()).getOrElse(
      (f) => throw StateError(f.message),
    );

    expect(overview.isBlocked, isFalse);
    expect(overview.missingRatesFor, isEmpty);
    expect(overview.peopleRateNeeded, isEmpty);
    expect(overview.totalOwedToUser, const Money.egp(110000));
    expect(overview.totalUserOwes, const Money.egp(75025));
    expect(overview.settledCount, 1);
    expect(overview.peopleTheyOweYou.map((p) => p.personId), [
      people['ahmed']!.id,
    ]);
    expect(overview.peopleYouOweThem.map((p) => p.personId), [
      people['mona']!.id,
    ]);
    for (final PersonSummary summary in [
      ...overview.peopleTheyOweYou,
      ...overview.peopleYouOweThem,
    ]) {
      expect(summary.isBlocked, isFalse);
      expect(summary.nativeNets, isEmpty);
    }

    expect(
      formatter.formatWithSymbol(overview.totalOwedToUser!),
      '1,100.00 EGP',
    );
    expect(formatter.formatWithSymbol(overview.totalUserOwes!), '750.25 EGP');
  });

  test('the finance summary is a plain EGP total per direction, never '
      'blocked', () async {
    await runEgpOnlyFlow();

    final FinanceSummary summary = (await getFinanceSummary(
      september,
    )).getOrElse((f) => throw StateError(f.message));

    expect(summary.isBlocked, isFalse);
    expect(summary.missingRatesFor, isEmpty);
    expect(summary.currency, Currency.egp);
    expect(summary.totalIncome, const Money.egp(1250050));
    expect(summary.totalExpense, const Money.egp(530000));
    expect(summary.net, const Money.egp(720050));

    expect(formatter.formatWithSymbol(summary.totalIncome!), '12,500.50 EGP');
    expect(formatter.formatWithSymbol(summary.totalExpense!), '5,300.00 EGP');
    expect(formatter.formatWithSymbol(summary.net!), '7,200.50 EGP');
  });

  test('the category breakdown is plain EGP totals with pre-018 shares, '
      'largest first, never blocked', () async {
    await runEgpOnlyFlow();

    final CategoryBreakdown expenses = (await getCategoryBreakdown(
      september,
      type: FinanceEntryType.expense,
    )).getOrElse((f) => throw StateError(f.message));

    expect(expenses.isBlocked, isFalse);
    expect(expenses.missingRatesFor, isEmpty);
    expect(expenses.currency, Currency.egp);
    expect(expenses.items.map((i) => i.categoryId), [
      'seed_rent',
      'seed_groceries',
    ]);
    expect(expenses.items.map((i) => i.total), [
      const Money.egp(400000),
      const Money.egp(130000),
    ]);
    expect(expenses.items[0].shareOfPeriod, 400000 / 530000);
    expect(expenses.items[1].shareOfPeriod, 130000 / 530000);
    expect(expenses.items.map((i) => formatter.formatWithSymbol(i.total!)), [
      '4,000.00 EGP',
      '1,300.00 EGP',
    ]);

    final CategoryBreakdown income = (await getCategoryBreakdown(
      september,
      type: FinanceEntryType.income,
    )).getOrElse((f) => throw StateError(f.message));

    expect(income.isBlocked, isFalse);
    expect(income.items.map((i) => i.categoryId), [
      'seed_salary',
      'seed_freelance',
    ]);
    expect(income.items[0].shareOfPeriod, 1000000 / 1250050);
    expect(income.items[1].shareOfPeriod, 250050 / 1250050);
    expect(income.items.map((i) => formatter.formatWithSymbol(i.total!)), [
      '10,000.00 EGP',
      '2,500.50 EGP',
    ]);
  });

  test(
    'the forms defaulted to EGP without the user choosing it, and the '
    'effective primary currency is still the never-set EGP default',
    () async {
      final primary = (await getPrimaryCurrency()).getOrElse(
        (f) => throw StateError(f.message),
      );
      expect(primary.currency, Currency.egp);
      expect(primary.updatedAt, isNull);

      final cubit = transactionForm();
      addTearDown(cubit.close);
      await cubit.loadDefaultCurrency();
      expect(cubit.state.currency, Currency.egp);
      expect(cubit.state.currencyChosenByUser, isFalse);
    },
  );
}

Future<void> _submitTransaction(
  TransactionFormCubit cubit, {
  required String amount,
  required TransactionDirection direction,
}) async {
  cubit
    ..amountChanged(amount)
    ..directionChanged(direction)
    ..dateChanged(DateTime(2026, 9, 10));
  await cubit.submit();
  expect(cubit.state.status, TransactionFormStatus.success);
}
