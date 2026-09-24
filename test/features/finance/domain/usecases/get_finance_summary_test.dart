import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/conversion_fakes.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// T034 — `GetFinanceSummary` over the three periods FR-016 requires, and
/// the exactness guarantee SC-003 states: totals are integer minor units
/// all the way through, so a thousand entries add up to the cent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetFinanceSummary (mocked repository)', () {
    late MockFinanceRepository repository;
    late FakeGetConversionContext getConversionContext;
    late GetFinanceSummary useCase;

    setUpAll(() {
      registerFallbackValue(DateRange.thisMonth());
    });

    setUp(() {
      repository = MockFinanceRepository();
      getConversionContext = FakeGetConversionContext();
      useCase = GetFinanceSummary(
        repository,
        getConversionContext,
        const CurrencyConverterImpl(),
      );
    });

    FinancePeriodTotals summaryFor(DateRange period, int income, int expense) =>
        FinancePeriodTotals(
          income: [Money.egp(income)],
          expense: [Money.egp(expense)],
        );

    test(
      'passes "this month" through as an inclusive day-granular range',
      () async {
        final period = DateRange.thisMonth(DateTime(2026, 3, 18));
        when(
          () => repository.getSummaryTotals(any()),
        ).thenAnswer((_) async => Right(summaryFor(period, 500000, 123456)));

        final result = await useCase(period);

        expect(result.isRight(), isTrue);
        final summary = result.toNullable()!;
        expect(summary.period.start, DateTime(2026, 3, 1));
        expect(summary.period.end, DateTime(2026, 3, 18));
        expect(summary.totalIncome, const Money.egp(500000));
        expect(summary.totalExpense, const Money.egp(123456));
        expect(summary.net, const Money.egp(376544));
        verify(() => repository.getSummaryTotals(period)).called(1);
      },
    );

    test('"last month" is the full previous calendar month', () async {
      final period = DateRange.lastMonth(DateTime(2026, 3, 18));
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, 0, 90000)));

      final result = await useCase(period);

      final summary = result.toNullable()!;
      expect(summary.period.start, DateTime(2026, 2, 1));
      expect(summary.period.end, DateTime(2026, 2, 28));
      // Overspent: the net reads negative rather than as an absolute value.
      expect(summary.net, const Money.egp(-90000));
    });

    test('a custom range is passed through untouched', () async {
      final period = DateRange(
        start: DateTime(2025, 11, 5, 13, 30),
        end: DateTime(2026, 1, 20, 6),
      );
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, 100, 100)));

      final result = await useCase(period);

      final summary = result.toNullable()!;
      expect(summary.period.start, DateTime(2025, 11, 5));
      expect(summary.period.end, DateTime(2026, 1, 20));
      expect(summary.net, const Money.egp(0));
      expect(summary.isEmpty, isFalse);
    });

    test('totals over a large synthetic set carry zero rounding discrepancy '
        '(SC-003)', () async {
      final period = DateRange.thisMonth(DateTime(2026, 3, 31));
      var income = 0;
      var expense = 0;
      for (var i = 1; i <= 1000; i++) {
        // Deliberately awkward piastre values — 0.01, 0.03, 45.75 and the
        // like — that a double-based sum would drift on.
        if (i.isEven) {
          income += i * 7 + 1;
        } else {
          expense += i * 3 + 99;
        }
      }
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, income, expense)));

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.totalIncome!.minorUnits, income);
      expect(summary.totalExpense!.minorUnits, expense);
      expect(summary.net!.minorUnits, income - expense);
    });

    test('surfaces a repository failure as a Left', () async {
      final period = DateRange.thisMonth();
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));

      final result = await useCase(period);

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetFinanceSummary (real in-memory database)', () {
    late AppDatabase db;
    late GetFinanceSummary useCase;
    late FinanceRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
      useCase = summaryUseCase(repository);
    });

    tearDown(() => db.close());

    Future<void> addEntry({
      required int amountMinorUnits,
      required FinanceEntryType type,
      required DateTime date,
      required String key,
      Currency currency = Currency.egp,
    }) async {
      final result = await repository.addEntry(
        idempotencyKey: key,
        categoryId: type == FinanceEntryType.income
            ? 'seed_salary'
            : 'seed_groceries',
        type: type,
        amount: Money.fromMinorUnits(amountMinorUnits, currency),
        date: date,
      );
      expect(result.isRight(), isTrue, reason: 'failed to seed entry $key');
    }

    test('the SQL aggregate itself sums exactly, across 1,000 entries '
        '(SC-003)', () async {
      final today = DateTime.now();
      final inPeriod = DateTime(today.year, today.month, today.day);
      var expectedIncome = 0;
      var expectedExpense = 0;
      for (var i = 1; i <= 1000; i++) {
        final amount = i * 13 + 7;
        final type = i.isEven
            ? FinanceEntryType.income
            : FinanceEntryType.expense;
        if (type == FinanceEntryType.income) {
          expectedIncome += amount;
        } else {
          expectedExpense += amount;
        }
        await addEntry(
          amountMinorUnits: amount,
          type: type,
          date: inPeriod,
          key: 'bulk-$i',
        );
      }

      final summary = (await useCase(DateRange.thisMonth())).toNullable()!;

      expect(summary.totalIncome!.minorUnits, expectedIncome);
      expect(summary.totalExpense!.minorUnits, expectedExpense);
      expect(summary.net!.minorUnits, expectedIncome - expectedExpense);
    });

    test('excludes entries outside the period and soft-deleted ones', () async {
      final today = DateTime.now();
      final inPeriod = DateTime(today.year, today.month, today.day);
      final lastMonthDay = DateTime(today.year, today.month - 1, 15);

      await addEntry(
        amountMinorUnits: 4575,
        type: FinanceEntryType.expense,
        date: inPeriod,
        key: 'keep',
      );
      await addEntry(
        amountMinorUnits: 100000,
        type: FinanceEntryType.expense,
        date: lastMonthDay,
        key: 'other-period',
      );
      final deleted = await repository.addEntry(
        idempotencyKey: 'deleted',
        categoryId: 'seed_groceries',
        type: FinanceEntryType.expense,
        amount: Money.egp(9999),
        date: inPeriod,
      );
      await repository.deleteEntry(deleted.toNullable()!.id);

      final thisMonth = (await useCase(DateRange.thisMonth())).toNullable()!;
      expect(thisMonth.totalExpense!.minorUnits, 4575);

      final lastMonth = (await useCase(DateRange.lastMonth())).toNullable()!;
      expect(lastMonth.totalExpense!.minorUnits, 100000);
    });
  });

  group('GetFinanceSummary multi-currency (018, T026)', () {
    late MockFinanceRepository repository;
    late FakeGetConversionContext getConversionContext;
    late GetFinanceSummary useCase;
    final period = DateRange.thisMonth(DateTime(2026, 3, 18));

    setUpAll(() => registerFallbackValue(DateRange.thisMonth()));

    setUp(() {
      repository = MockFinanceRepository();
      getConversionContext = FakeGetConversionContext();
      useCase = GetFinanceSummary(
        repository,
        getConversionContext,
        const CurrencyConverterImpl(),
      );
    });

    void stubTotals(FinancePeriodTotals totals) {
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => Right(totals));
    }

    test('mixed currencies with every rate set sum exactly in the primary '
        'currency, rounding half-up per conversion (FR-008/FR-013)', () async {
      getConversionContext.context = ConversionContext(
        primary: Currency.egp,
        rates: [
          rate(Currency.usd, Currency.egp, 48.25),
          rate(Currency.eur, Currency.egp, 0.5),
        ],
      );
      stubTotals(
        FinancePeriodTotals(
          income: [
            const Money.egp(100000),
            // 100.00 USD × 48.25 = 4,825.00 EGP.
            Money.fromMinorUnits(10000, Currency.usd),
          ],
          expense: [
            const Money.egp(2500),
            // 0.01 EUR × 0.5 = 0.005 EGP → half-up → 0.01 EGP.
            Money.fromMinorUnits(1, Currency.eur),
          ],
        ),
      );

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.isBlocked, isFalse);
      expect(summary.currency, Currency.egp);
      expect(summary.totalIncome, const Money.egp(100000 + 482500));
      expect(summary.totalExpense, const Money.egp(2500 + 1));
      expect(summary.net, const Money.egp(582500 - 2501));
    });

    test('a missing rate blocks every total and names each missing currency '
        '— never a 1:1 fallback (FR-009)', () async {
      getConversionContext.context = ConversionContext(
        primary: Currency.egp,
        rates: [rate(Currency.usd, Currency.egp, 48)],
      );
      stubTotals(
        FinancePeriodTotals(
          income: [
            const Money.egp(100000),
            Money.fromMinorUnits(100, Currency.usd),
          ],
          expense: [
            Money.fromMinorUnits(700, Currency.sar),
            Money.fromMinorUnits(300, Currency.gbp),
          ],
        ),
      );

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.isBlocked, isTrue);
      expect(summary.missingRatesFor, [Currency.sar, Currency.gbp]);
      expect(summary.totalIncome, isNull);
      expect(summary.totalExpense, isNull);
      expect(summary.net, isNull);
      expect(summary.isEmpty, isFalse);
    });

    test('totals are expressed in a non-EGP primary currency', () async {
      getConversionContext.context = ConversionContext(
        primary: Currency.usd,
        rates: [rate(Currency.egp, Currency.usd, 0.02)],
      );
      stubTotals(
        FinancePeriodTotals(
          income: [Money.fromMinorUnits(5000, Currency.usd)],
          expense: const [Money.egp(10000)],
        ),
      );

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.currency, Currency.usd);
      expect(summary.totalIncome, Money.fromMinorUnits(5000, Currency.usd));
      // 100.00 EGP × 0.02 = 2.00 USD.
      expect(summary.totalExpense, Money.fromMinorUnits(200, Currency.usd));
    });

    test('an empty period is a zero summary in the primary currency', () async {
      getConversionContext.context = const ConversionContext(
        primary: Currency.eur,
        rates: [],
      );
      stubTotals(const FinancePeriodTotals());

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.isEmpty, isTrue);
      expect(summary.totalIncome, Money.zero(Currency.eur));
    });

    test('surfaces a conversion-context failure as a Left', () async {
      getConversionContext.failure = const CacheFailure('no settings');

      expect((await useCase(period)).isLeft(), isTrue);
    });
  });

  group('GetFinanceSummary multi-currency (real in-memory database)', () {
    late AppDatabase db;
    late FinanceRepositoryImpl repository;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
    });

    tearDown(() => db.close());

    test('the SQL aggregate groups by currency, never summing across '
        'currencies', () async {
      final today = DateTime.now();
      final inPeriod = DateTime(today.year, today.month, today.day);
      var n = 0;
      Future<void> add(Money amount, FinanceEntryType type) async {
        final result = await repository.addEntry(
          idempotencyKey: 'mc-${n++}',
          categoryId: type == FinanceEntryType.income
              ? 'seed_salary'
              : 'seed_groceries',
          type: type,
          amount: amount,
          date: inPeriod,
        );
        expect(result.isRight(), isTrue);
      }

      await add(const Money.egp(10000), FinanceEntryType.expense);
      await add(const Money.egp(2500), FinanceEntryType.expense);
      await add(
        Money.fromMinorUnits(333, Currency.usd),
        FinanceEntryType.expense,
      );
      await add(
        Money.fromMinorUnits(1000, Currency.usd),
        FinanceEntryType.income,
      );

      final totals = (await repository.getSummaryTotals(
        DateRange.thisMonth(),
      )).toNullable()!;
      expect(
        totals.expense,
        unorderedEquals([
          const Money.egp(12500),
          Money.fromMinorUnits(333, Currency.usd),
        ]),
      );
      expect(totals.income, [Money.fromMinorUnits(1000, Currency.usd)]);

      final blocked = (await summaryUseCase(repository)(
        DateRange.thisMonth(),
      )).toNullable()!;
      expect(blocked.missingRatesFor, [Currency.usd]);

      final converted = (await summaryUseCase(
        repository,
        ConversionContext(
          primary: Currency.egp,
          rates: [rate(Currency.usd, Currency.egp, 1.5)],
        ),
      )(DateRange.thisMonth())).toNullable()!;
      // 3.33 USD × 1.5 = 4.995 EGP → half-up → 5.00 EGP.
      expect(converted.totalExpense, const Money.egp(12500 + 500));
      expect(converted.totalIncome, const Money.egp(1500));
    });
  });
}
