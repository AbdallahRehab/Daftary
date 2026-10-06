import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/budgets/data/repositories/budgets_repository_impl.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/savings/data/repositories/savings_repository_impl.dart';
import 'package:daftary/features/savings/domain/entities/savings_goal.dart';
import 'package:daftary/features/savings/domain/services/savings_calculator.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:fpdart/fpdart.dart';

import 'test_daos.dart';

/// Seeded 007 category ids (real rows created when the database opens).
const catFood = 'seed_groceries';
const catTransport = 'seed_transportation';

/// Stands in for the checklist's "Gifts" expense category (no allocation).
const catGifts = 'seed_family';
const catSalary = 'seed_salary';
const catRent = 'seed_rent';
const catMedical = 'seed_medical';

/// 022 calculation catalogue: "today" is 2026-10-05.
final DateTime catalogueToday = DateTime(2026, 10, 5);

class CatalogueClock implements AppClock {
  CatalogueClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

T unwrapOrThrow<T>(Either<Failure, T> either) =>
    either.getOrElse((failure) => throw StateError('$failure'));

/// One in-memory Drift database with every real repository wired on top of
/// it, exactly as DI builds them, plus one-line helpers per fact (people,
/// transactions, finance entries, budgets, occasions, savings).
///
/// Pass [database] to reopen an existing file (the T012 upgrade snapshot).
class CatalogueEnv {
  CatalogueEnv._(this.db, this.clock) {
    currency = CurrencyRepositoryImpl(testCurrencyDao(db), clock);
    final conversion = GetConversionContext(currency);
    final peopleDao = testPeopleDao(db);
    people = PeopleRepositoryImpl(
      peopleDao,
      const FindPossibleDuplicatePerson(),
      db,
      getConversionContext: conversion,
    );
    transactions = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: conversion,
    );
    final financeDao = testFinanceDao(db);
    finance = FinanceRepositoryImpl(financeDao);
    categories = CategoryRepositoryImpl(financeDao);
    occasions = OccasionsRepositoryImpl(
      testOccasionsDao(db),
      transactions,
      people,
      db,
      conversion,
      const CurrencyConverterImpl(),
    );
    budgets = BudgetsRepositoryImpl(
      testBudgetsDao(db),
      db,
      finance,
      categories,
      conversion,
      const CurrencyConverterImpl(),
    );
    savings = SavingsRepositoryImpl(
      testSavingsDao(db),
      db,
      conversion,
      const CurrencyConverterImpl(),
      const DefaultSavingsCalculator(),
      clock,
    );
    financeSummary = GetFinanceSummary(
      finance,
      conversion,
      const CurrencyConverterImpl(),
    );
    categoryBreakdown = GetCategoryBreakdown(
      finance,
      conversion,
      const CurrencyConverterImpl(),
    );
  }

  static Future<CatalogueEnv> open({
    AppDatabase? database,
    DateTime? today,
  }) async {
    final db = database ?? AppDatabase.forTesting(NativeDatabase.memory());
    final env = CatalogueEnv._(db, CatalogueClock(today ?? catalogueToday));
    // Forces `beforeOpen` (and therefore the category seed) to run.
    await db.select(db.financeCategories).get();
    return env;
  }

  final AppDatabase db;
  final CatalogueClock clock;
  late final CurrencyRepositoryImpl currency;
  late final PeopleRepositoryImpl people;
  late final TransactionsRepositoryImpl transactions;
  late final FinanceRepositoryImpl finance;
  late final CategoryRepositoryImpl categories;
  late final OccasionsRepositoryImpl occasions;
  late final BudgetsRepositoryImpl budgets;
  late final SavingsRepositoryImpl savings;
  late final GetFinanceSummary financeSummary;
  late final GetCategoryBreakdown categoryBreakdown;

  var _keySeq = 0;
  String nextKey() => 'cat-key-${_keySeq++}';

  Future<void> close() => db.close();

  // ---- currency ----------------------------------------------------------

  /// "1 [from] = [rate] EGP", through 018's real repository.
  Future<void> setRate(Currency from, double rate) async {
    unwrapOrThrow(
      await currency.setExchangeRate(
        currencyCode: from.code,
        relativeToCurrencyCode: Currency.egp.code,
        rate: rate,
      ),
    );
  }

  // ---- people & transactions ---------------------------------------------

  final _knownPeople = <String>{};

  Future<void> person(String id, {String? name, bool archived = false}) async {
    if (_knownPeople.add(id)) {
      await testPeopleDao(
        db,
      ).insertPerson(id: id, name: name ?? id, createdAt: DateTime(2026));
    }
    if (archived) unwrapOrThrow(await people.archivePerson(id));
  }

  Future<MoneyTransaction> give(
    String personId,
    int minor, {
    Currency currency = Currency.egp,
    DateTime? date,
  }) => _add(personId, minor, TransactionDirection.given, currency, date);

  Future<MoneyTransaction> receive(
    String personId,
    int minor, {
    Currency currency = Currency.egp,
    DateTime? date,
  }) => _add(personId, minor, TransactionDirection.received, currency, date);

  Future<MoneyTransaction> _add(
    String personId,
    int minor,
    TransactionDirection direction,
    Currency currency,
    DateTime? date,
  ) async {
    await person(personId);
    return unwrapOrThrow(
      await transactions.addTransaction(
        idempotencyKey: nextKey(),
        personId: personId,
        amount: Money.fromMinorUnits(minor, currency),
        direction: direction,
        date: date ?? catalogueToday,
      ),
    );
  }

  Future<Either<Failure, MoneyTransaction>> repay(
    String personId,
    int minor, {
    Currency currency = Currency.egp,
    DateTime? date,
  }) => transactions.recordRepayment(
    idempotencyKey: nextKey(),
    personId: personId,
    amount: Money.fromMinorUnits(minor, currency),
    date: date ?? catalogueToday,
  );

  /// The converted net of [personId] in the primary currency, in minor
  /// units. Throws when the balance is blocked.
  Future<int> net(String personId) async {
    final balance = unwrapOrThrow(
      await transactions.getPersonBalance(personId),
    );
    return balance.net!.minorUnits;
  }

  /// CHK013: Mona with "I gave" 2,000.00 and "I received" 500.00
  /// (net +150000).
  Future<void> seedChk013({String personId = 'mona'}) async {
    await give(personId, 200000);
    await receive(personId, 50000);
  }

  /// CHK014: Ahmed with "I received" 2,000.00 and "I gave" 500.00
  /// (net -150000).
  Future<void> seedChk014({String personId = 'ahmed'}) async {
    await receive(personId, 200000);
    await give(personId, 50000);
  }

  // ---- finance -----------------------------------------------------------

  Future<void> income(int minor, DateTime date, {String? category}) async {
    unwrapOrThrow(
      await finance.addEntry(
        idempotencyKey: nextKey(),
        categoryId: category ?? catSalary,
        type: FinanceEntryType.income,
        amount: Money.egp(minor),
        date: date,
      ),
    );
  }

  Future<FinanceEntry> expense(
    String categoryId,
    int minor,
    DateTime date, {
    Currency currency = Currency.egp,
  }) async {
    return unwrapOrThrow(
      await finance.addEntry(
        idempotencyKey: nextKey(),
        categoryId: categoryId,
        type: FinanceEntryType.expense,
        amount: Money.fromMinorUnits(minor, currency),
        date: date,
      ),
    );
  }

  // ---- budgets -----------------------------------------------------------

  Future<String> budget(String month, Map<String, int> planned) async {
    final created = unwrapOrThrow(
      await budgets.createBudget(idempotencyKey: nextKey(), month: month),
    );
    for (final entry in planned.entries) {
      unwrapOrThrow(
        await budgets.addBudgetCategoryAllocation(
          idempotencyKey: nextKey(),
          budgetId: created.id,
          categoryId: entry.key,
          plannedAmountMinorUnits: entry.value,
        ),
      );
    }
    return created.id;
  }

  // ---- occasions ---------------------------------------------------------

  Future<Occasion> occasion({
    String name = 'Wedding',
    String type = OccasionType.wedding,
    DateTime? date,
  }) async => unwrapOrThrow(
    await occasions.createOccasion(
      idempotencyKey: nextKey(),
      name: name,
      date: date ?? DateTime(2026, 9, 20),
      type: type,
    ),
  );

  Future<MoneyTransaction> contribution(
    String occasionId,
    String personId,
    int minor,
    TransactionDirection direction, {
    bool? countsTowardBalance,
  }) async {
    await person(personId);
    return unwrapOrThrow(
      await occasions.addParticipantContribution(
        idempotencyKey: nextKey(),
        occasionId: occasionId,
        personId: personId,
        amount: Money.egp(minor),
        direction: direction,
        date: DateTime(2026, 9, 20),
        countsTowardBalance: countsTowardBalance,
      ),
    );
  }

  /// CHK068: a Wedding with 500.00 received from Ahmed, 300.00 received
  /// from Mona and 200.00 given to Karim.
  Future<Occasion> seedChk068() async {
    final wedding = await occasion();
    await contribution(
      wedding.id,
      'ahmed',
      50000,
      TransactionDirection.received,
    );
    await contribution(
      wedding.id,
      'mona',
      30000,
      TransactionDirection.received,
    );
    await contribution(wedding.id, 'karim', 20000, TransactionDirection.given);
    return wedding;
  }

  // ---- savings -----------------------------------------------------------

  Future<SavingsGoal> goal({
    String name = 'Car',
    Currency currency = Currency.egp,
    int target = 1200000,
    int? monthly,
    DateTime? targetDate,
  }) async => unwrapOrThrow(
    await savings.createSavingsGoal(
      idempotencyKey: nextKey(),
      name: name,
      currency: currency,
      targetAmountMinorUnits: target,
      monthlyContributionMinorUnits: monthly,
      targetDate: targetDate,
    ),
  );

  Future<void> contribute(
    String goalId,
    int minor, {
    Currency currency = Currency.egp,
  }) async {
    unwrapOrThrow(
      await savings.logContribution(
        idempotencyKey: nextKey(),
        goalId: goalId,
        amount: Money.fromMinorUnits(minor, currency),
        date: catalogueToday,
      ),
    );
  }

  // ---- whole world (T012) --------------------------------------------------

  /// Every dataset together: CHK013, CHK014, CHK068 occasions, a settled
  /// person, a USD lender with a rate, an archived debtor, a repayment,
  /// soft-deleted rows, a non-counting condolence contribution, a person
  /// whose balance needs a missing GBP rate, October income, expenses, a
  /// budget with an on-track, a nearFull and an overBudget line, an
  /// unbudgeted category, and two savings goals (one achieved) with a USD
  /// contribution and a withdrawal. Only the T012 upgrade snapshot uses it.
  Future<void> seedSnapshotWorld() async {
    await setRate(Currency.usd, 48.5);
    await seedChk013(); // mona +150000
    await seedChk014(); // ahmed -150000
    await give('karim', 75000);
    await receive('karim', 75000); // net 0 before the wedding gives +20000
    await give('salma', 40000);
    await receive('salma', 40000); // genuinely settled, no occasion
    await give('sara', 10000, currency: Currency.usd); // +485000 EGP
    await give('laila', 150000);
    await person('laila', archived: true); // archived, still counted
    await give('omar', 10000, currency: Currency.usd);
    await receive('omar', 100000); // opposite directions, converted
    await give('nadia', 100000);
    unwrapOrThrow(await repay('nadia', 40000)); // repayment: nadia +60000
    final removed = await give('nadia', 77700);
    unwrapOrThrow(await transactions.deleteTransaction(removed.id));
    // No GBP rate: the net is blocked and per-currency nets are reported.
    await give('tom', 5000, currency: Currency.gbp);
    await receive('tom', 100000);
    await seedChk068(); // wedding: ahmed -50000, mona -30000, karim +20000
    final condolence = await occasion(
      name: 'Condolence',
      type: OccasionType.condolence,
    );
    await contribution(
      condolence.id,
      'ahmed',
      40000,
      TransactionDirection.given,
      countsTowardBalance: false,
    ); // listed in the occasion, absent from ahmed's balance

    await income(1000000, DateTime(2026, 10, 1));
    await expense(catFood, 120000, DateTime(2026, 10, 3));
    await expense(catTransport, 30000, DateTime(2026, 10, 4));
    await expense(catGifts, 25000, DateTime(2026, 10, 31));
    await expense(catRent, 90000, DateTime(2026, 10, 2)); // nearFull
    await expense(catMedical, 8000, DateTime(2026, 10, 6)); // unbudgeted
    await expense(catFood, 99999, DateTime(2026, 11, 1));
    final removedEntry = await expense(catFood, 55555, DateTime(2026, 10, 7));
    unwrapOrThrow(await finance.deleteEntry(removedEntry.id));
    await budget('2026-10', {
      catFood: 200000, // on track
      catTransport: 50000,
      catRent: 100000, // nearFull
      catGifts: 20000, // overBudget
    });

    final goalRow = await goal(
      monthly: 100000,
      targetDate: DateTime(2027, 4, 5),
    );
    await contribute(goalRow.id, 200000);
    await contribute(goalRow.id, 10000, currency: Currency.usd); // 485000
    unwrapOrThrow(
      await savings.logWithdrawal(
        idempotencyKey: nextKey(),
        goalId: goalRow.id,
        amount: Money.egp(50000),
        date: catalogueToday,
      ),
    );
    final phone = await goal(name: 'Phone', target: 300000);
    await contribute(phone.id, 300000); // achieved
  }
}
