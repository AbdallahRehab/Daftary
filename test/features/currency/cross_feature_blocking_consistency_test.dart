import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/design_system/tokens.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/datasources/currency_dao.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/data/services/drift_currency_usage_checker.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/remove_exchange_rate.dart';
import 'package:daftary/features/currency/domain/usecases/set_exchange_rate.dart';
import 'package:daftary/features/currency/domain/usecases/set_primary_currency.dart';
import 'package:daftary/features/currency/presentation/widgets/rate_needed_banner.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_categories.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/presentation/widgets/category_breakdown_bar.dart';
import 'package:daftary/features/finance/presentation/widgets/finance_summary_card.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' hide State;

/// 018 T040 + T041 (+ T042 verification) — release-blocking anchors for
/// FR-008 ("no aggregate screen is exempt") and FR-009 (a missing rate
/// blocks the total and names the currency).
///
/// The SAME underlying amounts are seeded into both ledgers of a real
/// in-memory [AppDatabase]:
///
///  - `money_transactions` (via `TransactionsRepositoryImpl`):
///      Ahmed — given 1,000.00 EGP and given 100.00 USD      (they owe you)
///      Mona  — received 300.00 EGP, 10.25 USD and 10.25 USD (you owe them)
///  - `finance_entries` (via `FinanceRepositoryImpl`), mirroring them:
///      income  — salary 1,000.00 EGP, freelance 100.00 USD
///      expense — groceries 300.00 EGP, 10.25 USD and 10.25 USD
///
/// so Ahmed's net ≡ total income ≡ overview "owed to you", and Mona's debt
/// ≡ total expense ≡ overview "you owe". All four aggregates (person
/// balance, overview, finance summary, category breakdown) run through the
/// real `CurrencyRepositoryImpl` → `GetConversionContext` →
/// `CurrencyConverterImpl` stack, wired by hand. The rate 50.25 is picked
/// so USD 20.50 × 50.25 = 1,030.125 EGP lands exactly on a half piastre,
/// making round-half-up (FR-013) observable.
///
/// Scope: the tasks list five aggregate screens, but only Person balance
/// and Overview (001) and Finance summary/breakdown (007) exist in this
/// codebase. Budgets (010), Savings (011) and Occasions (008) are not
/// implemented, so they have no totals to check.
void main() {
  late AppDatabase db;
  late CurrencyRepositoryImpl currencyRepository;
  late SetExchangeRate setExchangeRate;
  late RemoveExchangeRate removeExchangeRate;
  late SetPrimaryCurrency setPrimaryCurrency;
  late TransactionsRepositoryImpl transactions;
  late FinanceRepositoryImpl finance;
  late GetFinanceSummary getFinanceSummary;
  late GetCategoryBreakdown getCategoryBreakdown;
  late GetCategories getCategories;

  const ahmed = 'p-ahmed';
  const mona = 'p-mona';
  final day = DateTime(2026, 9, 10);
  final september = DateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 30),
  );

  Future<void> insertPerson(String id, String name) => db
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

  Future<void> addTransaction(
    String key,
    String personId,
    Money amount,
    TransactionDirection direction,
  ) async {
    final result = await transactions.addTransaction(
      idempotencyKey: key,
      personId: personId,
      amount: amount,
      direction: direction,
      date: day,
    );
    expect(result.isRight(), isTrue, reason: key);
  }

  Future<void> addEntry(
    String key,
    FinanceEntryType type,
    String categoryId,
    Money amount,
  ) async {
    final result = await finance.addEntry(
      idempotencyKey: key,
      categoryId: categoryId,
      type: type,
      amount: amount,
      date: day,
    );
    expect(result.isRight(), isTrue, reason: key);
  }

  Future<void> seed() async {
    await db.select(db.financeCategories).get(); // run the category seed
    await insertPerson(ahmed, 'Ahmed');
    await insertPerson(mona, 'Mona');

    const given = TransactionDirection.given;
    const received = TransactionDirection.received;
    await addTransaction('t1', ahmed, const Money.egp(100000), given);
    await addTransaction(
      't2',
      ahmed,
      const Money.fromMinorUnits(10000, Currency.usd),
      given,
    );
    await addTransaction('t3', mona, const Money.egp(30000), received);
    await addTransaction(
      't4',
      mona,
      const Money.fromMinorUnits(1025, Currency.usd),
      received,
    );
    await addTransaction(
      't5',
      mona,
      const Money.fromMinorUnits(1025, Currency.usd),
      received,
    );

    const income = FinanceEntryType.income;
    const expense = FinanceEntryType.expense;
    await addEntry('f1', income, 'seed_salary', const Money.egp(100000));
    await addEntry(
      'f2',
      income,
      'seed_freelance',
      const Money.fromMinorUnits(10000, Currency.usd),
    );
    await addEntry('f3', expense, 'seed_groceries', const Money.egp(30000));
    await addEntry(
      'f4',
      expense,
      'seed_groceries',
      const Money.fromMinorUnits(1025, Currency.usd),
    );
    await addEntry(
      'f5',
      expense,
      'seed_groceries',
      const Money.fromMinorUnits(1025, Currency.usd),
    );
  }

  Future<void> wire() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    currencyRepository = CurrencyRepositoryImpl(
      CurrencyDao(db),
      const SystemAppClock(),
    );
    final getConversionContext = GetConversionContext(currencyRepository);
    setExchangeRate = SetExchangeRate(currencyRepository);
    removeExchangeRate = RemoveExchangeRate(currencyRepository);
    setPrimaryCurrency = SetPrimaryCurrency(
      currencyRepository,
      DriftCurrencyUsageChecker(db),
      setExchangeRate,
    );
    transactions = TransactionsRepositoryImpl(
      TransactionsDao(db),
      db,
      getConversionContext: getConversionContext,
    );
    finance = FinanceRepositoryImpl(FinanceDao(db));
    getFinanceSummary = GetFinanceSummary(
      finance,
      getConversionContext,
      const CurrencyConverterImpl(),
    );
    getCategoryBreakdown = GetCategoryBreakdown(
      finance,
      getConversionContext,
      const CurrencyConverterImpl(),
    );
    getCategories = GetCategories(CategoryRepositoryImpl(FinanceDao(db)));
    await seed();
  }

  /// One read of every aggregate the app shows, from the same database.
  Future<_Aggregates> readAll() async {
    T unwrap<T>(Either<Failure, T> either) =>
        either.getOrElse((f) => throw StateError(f.message));
    return _Aggregates(
      ahmed: unwrap<PersonBalance>(await transactions.getPersonBalance(ahmed)),
      mona: unwrap<PersonBalance>(await transactions.getPersonBalance(mona)),
      overview: unwrap<OverviewSummary>(await transactions.getOverview()),
      summary: unwrap<FinanceSummary>(await getFinanceSummary(september)),
      incomeBreakdown: unwrap<CategoryBreakdown>(
        await getCategoryBreakdown(september, type: FinanceEntryType.income),
      ),
      expenseBreakdown: unwrap<CategoryBreakdown>(
        await getCategoryBreakdown(september, type: FinanceEntryType.expense),
      ),
      allBreakdown: unwrap<CategoryBreakdown>(
        await getCategoryBreakdown(september),
      ),
    );
  }

  Future<void> setUsdRate() async {
    final result = await setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50.25,
    );
    expect(result.isRight(), isTrue);
  }

  /// Every aggregate is blocked and names exactly [missing] — the specific
  /// currency, never a generic error (T042 / FR-009).
  void expectAllBlocked(_Aggregates a, List<Currency> missing) {
    expect(a.ahmed.isBlocked, isTrue);
    expect(a.ahmed.net, isNull);
    expect(a.ahmed.missingRatesFor, missing);
    expect(a.mona.isBlocked, isTrue);
    expect(a.mona.net, isNull);
    expect(a.mona.missingRatesFor, missing);

    expect(a.overview.isBlocked, isTrue);
    expect(a.overview.missingRatesFor, missing);
    expect(a.overview.totalOwedToUser, isNull);
    expect(a.overview.totalUserOwes, isNull);

    expect(a.summary.isBlocked, isTrue);
    expect(a.summary.missingRatesFor, missing);
    expect(a.summary.totalIncome, isNull);
    expect(a.summary.totalExpense, isNull);
    expect(a.summary.net, isNull);

    for (final breakdown in [
      a.incomeBreakdown,
      a.expenseBreakdown,
      a.allBreakdown,
    ]) {
      expect(breakdown.isBlocked, isTrue);
      expect(breakdown.missingRatesFor, missing);
      expect(breakdown.items.map((i) => i.shareOfPeriod), everyElement(null));
    }
  }

  /// Exact integer round-half-up of `minor × rateMicros / 10^6` for two
  /// currencies with the same minor-unit scale (EGP and USD are both 100).
  int halfUp(int minor, int rateMicros) {
    final product = minor.abs() * rateMicros;
    final rounded = (product * 2 + 1000000) ~/ 2000000;
    return minor.isNegative ? -rounded : rounded;
  }

  group('real in-memory database', () {
    setUp(wire);
    tearDown(() => db.close());

    test(
      '(a) no USD rate: person balance, overview, finance summary and '
      'category breakdown are ALL blocked, each naming exactly [USD]',
      () async {
        final a = await readAll();
        expectAllBlocked(a, const [Currency.usd]);

        // Blocked, not garbage: what IS known is still carried through
        // unconverted, per currency.
        expect(
          a.ahmed.nativeNets,
          unorderedEquals(const [
            Money.egp(100000),
            Money.fromMinorUnits(10000, Currency.usd),
          ]),
        );
        expect(
          a.mona.nativeNets,
          unorderedEquals(const [
            Money.egp(-30000),
            Money.fromMinorUnits(-2050, Currency.usd),
          ]),
        );
        // Same-direction currencies keep a knowable status while blocked.
        expect(a.ahmed.status, RelationshipStatus.theyOweYou);
        expect(a.mona.status, RelationshipStatus.youOweThem);
        // The EGP-only category is still fully convertible; the USD one not.
        final salary = a.incomeBreakdown.items.singleWhere(
          (i) => i.categoryId == 'seed_salary',
        );
        final freelance = a.incomeBreakdown.items.singleWhere(
          (i) => i.categoryId == 'seed_freelance',
        );
        expect(salary.total, const Money.egp(100000));
        expect(freelance.total, isNull);
      },
    );

    test(
      '(b) with USD→EGP 50.25 every aggregate unblocks, and all four '
      'agree with each other and with a round-half-up hand computation',
      () async {
        await setUsdRate();
        final a = await readAll();

        // By hand: 100.00 USD × 50.25 = 5,025.00 EGP exactly;
        //          20.50 USD × 50.25 = 1,030.125 EGP → 1,030.13 (half-up).
        const usdIncome = 502500;
        const usdExpense = 103013;
        expect(halfUp(10000, 50250000), usdIncome);
        expect(halfUp(2050, 50250000), usdExpense);
        const owedToYou = 100000 + usdIncome; // 602,500
        const youOwe = 30000 + usdExpense; // 133,013

        // Person balance (001).
        expect(a.ahmed.isBlocked, isFalse);
        expect(a.ahmed.net, const Money.egp(owedToYou));
        expect(a.mona.isBlocked, isFalse);
        expect(a.mona.net, const Money.egp(-youOwe));

        // Overview (001).
        expect(a.overview.isBlocked, isFalse);
        expect(a.overview.missingRatesFor, isEmpty);
        expect(a.overview.totalOwedToUser, a.ahmed.net);
        expect(a.overview.totalUserOwes, a.mona.net!.negate());

        // Finance summary (007) — the same amounts as income/expense.
        expect(a.summary.isBlocked, isFalse);
        expect(a.summary.currency, Currency.egp);
        expect(a.summary.totalIncome, const Money.egp(owedToYou));
        expect(a.summary.totalExpense, const Money.egp(youOwe));
        expect(a.summary.totalIncome, a.overview.totalOwedToUser);
        expect(a.summary.totalExpense, a.overview.totalUserOwes);
        expect(a.summary.net, const Money.egp(owedToYou - youOwe));
        expect(
          a.summary.net,
          a.ahmed.net!.add(a.mona.net!),
          reason: 'finance net ≡ sum of the mirrored person balances',
        );

        // Category breakdown (007).
        for (final breakdown in [
          a.incomeBreakdown,
          a.expenseBreakdown,
          a.allBreakdown,
        ]) {
          expect(breakdown.isBlocked, isFalse);
          expect(breakdown.currency, Currency.egp);
        }
        expect(a.incomeBreakdown.items.map((i) => (i.categoryId, i.total)), [
          ('seed_freelance', const Money.egp(usdIncome)),
          ('seed_salary', const Money.egp(100000)),
        ]);
        expect(a.expenseBreakdown.items.map((i) => (i.categoryId, i.total)), [
          ('seed_groceries', const Money.egp(youOwe)),
        ]);
        int sumOf(CategoryBreakdown b) =>
            b.items.fold(0, (sum, i) => sum + i.total!.minorUnits);
        expect(sumOf(a.incomeBreakdown), a.summary.totalIncome!.minorUnits);
        expect(sumOf(a.expenseBreakdown), a.summary.totalExpense!.minorUnits);
        expect(
          a.incomeBreakdown.items.first.shareOfPeriod,
          usdIncome / owedToYou,
        );
        expect(a.expenseBreakdown.items.single.shareOfPeriod, 1.0);
      },
    );

    test('(c) removing the USD rate re-blocks every aggregate, again naming '
        'exactly [USD]', () async {
      await setUsdRate();
      final unblocked = await readAll();
      expect(unblocked.overview.isBlocked, isFalse);

      final removed = await removeExchangeRate('USD');
      expect(removed.isRight(), isTrue);

      expectAllBlocked(await readAll(), const [Currency.usd]);
      // No record was touched by adding or removing the rate.
      final rows = await db.select(db.moneyTransactions).get();
      expect(
        rows
            .where((r) => r.currencyCode == 'USD')
            .map((r) => r.amountMinorUnits),
        unorderedEquals([10000, 1025, 1025]),
      );
    });

    test('(d) switching the primary currency to USD (EGP→USD rate supplied) '
        'expresses every total in USD, consistently across features', () async {
      // The USD→EGP rate stays stored but no longer feeds any total.
      await setUsdRate();
      final switched = await setPrimaryCurrency(
        newPrimaryCurrencyCode: 'USD',
        rateForPreviousPrimary: 0.0199,
      );
      expect(switched.isRight(), isTrue);

      final a = await readAll();

      // By hand, EGP → USD at 0.0199 (19,900 micros):
      //   1,000.00 EGP → 19.90 USD;  300.00 EGP → 5.97 USD.
      final egpIncome = halfUp(100000, 19900);
      final egpExpense = halfUp(30000, 19900);
      expect(egpIncome, 1990);
      expect(egpExpense, 597);
      final owedToYou = 10000 + egpIncome; // 11,990 cents
      final youOwe = 2050 + egpExpense; // 2,647 cents

      expect(a.ahmed.net, Money.fromMinorUnits(owedToYou, Currency.usd));
      expect(a.mona.net, Money.fromMinorUnits(-youOwe, Currency.usd));
      expect(a.overview.missingRatesFor, isEmpty);
      expect(
        a.overview.totalOwedToUser,
        Money.fromMinorUnits(owedToYou, Currency.usd),
      );
      expect(
        a.overview.totalUserOwes,
        Money.fromMinorUnits(youOwe, Currency.usd),
      );
      expect(a.summary.currency, Currency.usd);
      expect(a.summary.totalIncome, a.overview.totalOwedToUser);
      expect(a.summary.totalExpense, a.overview.totalUserOwes);
      expect(
        a.summary.net,
        Money.fromMinorUnits(owedToYou - youOwe, Currency.usd),
      );
      expect(a.incomeBreakdown.currency, Currency.usd);
      expect(a.incomeBreakdown.items.map((i) => (i.categoryId, i.total)), [
        ('seed_freelance', const Money.fromMinorUnits(10000, Currency.usd)),
        ('seed_salary', Money.fromMinorUnits(egpIncome, Currency.usd)),
      ]);
      expect(a.expenseBreakdown.items.single.total, a.overview.totalUserOwes);
    });

    test('(d′) after switching to USD, removing the EGP→USD rate blocks every '
        'aggregate naming exactly [EGP]', () async {
      await setPrimaryCurrency(
        newPrimaryCurrencyCode: 'USD',
        rateForPreviousPrimary: 0.0199,
      );
      await removeExchangeRate('EGP');

      expectAllBlocked(await readAll(), const [Currency.egp]);
    });
  });

  group('RateNeededBanner (T040/T042)', () {
    testWidgets('the identical missing-rate scenario renders the identical '
        'banner, naming USD, on every aggregate surface', (tester) async {
      late _Aggregates a;
      late Map<String, Category> categoriesById;
      await tester.runAsync(() async {
        await wire();
        a = await readAll();
        final categories = [
          for (final type in FinanceEntryType.values)
            ...(await getCategories(
              type: type,
            )).getOrElse((f) => throw StateError('$f')),
        ];
        categoriesById = {for (final c in categories) c.id: c};
        await db.close();
      });

      // Person balance and Overview hand `missingRatesFor` straight to a
      // RateNeededBanner (person_detail_page.dart / overview_page.dart);
      // the two finance widgets are rendered for real.
      final surfaces = <String, Widget>{
        'person balance (001)': RateNeededBanner(
          missingRatesFor: a.ahmed.missingRatesFor,
        ),
        'overview (001)': RateNeededBanner(
          missingRatesFor: a.overview.missingRatesFor,
        ),
        'finance summary (007)': FinanceSummaryCard(summary: a.summary),
        'category breakdown (007)': CategoryBreakdownBar(
          breakdown: a.allBreakdown,
          categoriesById: categoriesById,
        ),
      };

      for (final MapEntry(key: name, value: widget) in surfaces.entries) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildLightTheme(),
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SingleChildScrollView(child: widget)),
          ),
        );

        expect(
          find.byKey(RateNeededBanner.rootKey),
          findsOneWidget,
          reason: name,
        );
        final banner = tester.widget<RateNeededBanner>(
          find.byType(RateNeededBanner),
        );
        expect(banner.missingRatesFor, const [Currency.usd], reason: name);
        expect(
          find.text('Total unavailable — exchange rate needed'),
          findsOneWidget,
          reason: name,
        );
        expect(
          find.text(
            'Add an exchange rate for USD to see this total. Your records '
            'are safe and unchanged.',
          ),
          findsOneWidget,
          reason: name,
        );
      }
    });
  });
}

class _Aggregates {
  const _Aggregates({
    required this.ahmed,
    required this.mona,
    required this.overview,
    required this.summary,
    required this.incomeBreakdown,
    required this.expenseBreakdown,
    required this.allBreakdown,
  });

  final PersonBalance ahmed;
  final PersonBalance mona;
  final OverviewSummary overview;
  final FinanceSummary summary;
  final CategoryBreakdown incomeBreakdown;
  final CategoryBreakdown expenseBreakdown;
  final CategoryBreakdown allBreakdown;
}
