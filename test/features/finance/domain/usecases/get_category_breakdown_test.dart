import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/conversion_fakes.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// T035 — FR-015: per-category totals for a period, largest first, each
/// carrying its share of the period. 018 (T026): per-currency totals are
/// converted into the primary currency; a missing rate blocks the shares.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetCategoryBreakdown (mocked repository)', () {
    late MockFinanceRepository repository;
    late FakeGetConversionContext getConversionContext;
    late GetCategoryBreakdown useCase;

    setUpAll(() => registerFallbackValue(DateRange.thisMonth()));

    setUp(() {
      repository = MockFinanceRepository();
      getConversionContext = FakeGetConversionContext();
      useCase = GetCategoryBreakdown(
        repository,
        getConversionContext,
        const CurrencyConverterImpl(),
      );
    });

    void stubTotals(List<CategoryCurrencyTotals> rows) {
      when(
        () => repository.getCategoryTotals(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => Right(rows));
    }

    CategoryCurrencyTotals row(String id, List<Money> totals) =>
        CategoryCurrencyTotals(
          categoryId: id,
          categoryName: id,
          icon: 'other',
          totals: totals,
        );

    test(
      'returns per-category totals descending, each with its share',
      () async {
        final period = DateRange.thisMonth(DateTime(2026, 3, 31));
        stubTotals([
          row('seed_rent', [const Money.egp(600000)]),
          row('seed_groceries', [const Money.egp(300000)]),
          row('seed_fuel', [const Money.egp(100000)]),
        ]);

        final result = await useCase(period, type: FinanceEntryType.expense);

        final breakdown = result.toNullable()!;
        expect(breakdown.isBlocked, isFalse);
        expect(breakdown.currency, Currency.egp);
        expect(breakdown.items.map((i) => i.categoryId), [
          'seed_rent',
          'seed_groceries',
          'seed_fuel',
        ]);
        expect(breakdown.items.map((i) => i.total!.minorUnits), [
          600000,
          300000,
          100000,
        ]);
        expect(breakdown.items.map((i) => i.shareOfPeriod), [0.6, 0.3, 0.1]);
        verify(
          () => repository.getCategoryTotals(
            period,
            type: FinanceEntryType.expense,
          ),
        ).called(1);
      },
    );

    test('surfaces a repository failure as a Left', () async {
      when(
        () => repository.getCategoryTotals(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));

      final result = await useCase(DateRange.thisMonth());

      expect(result.isLeft(), isTrue);
    });

    test('surfaces a conversion-context failure as a Left', () async {
      getConversionContext.failure = const CacheFailure('no settings');

      final result = await useCase(DateRange.thisMonth());

      expect(result.isLeft(), isTrue);
      verifyNever(
        () => repository.getCategoryTotals(any(), type: any(named: 'type')),
      );
    });

    test('mixed currencies with every rate set are converted, re-ordered by '
        'converted total, and share the converted period total', () async {
      getConversionContext.context = ConversionContext(
        primary: Currency.egp,
        rates: [rate(Currency.usd, Currency.egp, 48.5)],
      );
      stubTotals([
        // SQL order is by single-currency SUM: 1,000.00 EGP first...
        row('seed_rent', [const Money.egp(100000)]),
        // ...but 50.00 USD + 100.00 EGP = 2,425.00 + 100.00 EGP is larger.
        row('seed_groceries', [
          Money.fromMinorUnits(5000, Currency.usd),
          const Money.egp(10000),
        ]),
      ]);

      final breakdown = (await useCase(DateRange.thisMonth())).toNullable()!;

      expect(breakdown.isBlocked, isFalse);
      expect(breakdown.items.map((i) => i.categoryId), [
        'seed_groceries',
        'seed_rent',
      ]);
      expect(breakdown.items.first.total, const Money.egp(252500));
      expect(breakdown.items.first.shareOfPeriod, 252500 / 352500);
      expect(breakdown.items.last.shareOfPeriod, 100000 / 352500);
    });

    test('a missing rate blocks the shares and names the currency, keeping '
        'fully-convertible category totals', () async {
      stubTotals([
        row('seed_rent', [const Money.egp(100000)]),
        row('seed_groceries', [
          Money.fromMinorUnits(5000, Currency.usd),
          const Money.egp(10000),
        ]),
      ]);

      final breakdown = (await useCase(DateRange.thisMonth())).toNullable()!;

      expect(breakdown.isBlocked, isTrue);
      expect(breakdown.missingRatesFor, [Currency.usd]);
      // Never a 1:1 fallback, never a partial sum.
      final groceries = breakdown.items.firstWhere(
        (i) => i.categoryId == 'seed_groceries',
      );
      expect(groceries.total, isNull);
      final rent = breakdown.items.firstWhere(
        (i) => i.categoryId == 'seed_rent',
      );
      expect(rent.total, const Money.egp(100000));
      // Blocked rows sort last; no row carries a share.
      expect(breakdown.items.last.categoryId, 'seed_groceries');
      expect(breakdown.items.every((i) => i.shareOfPeriod == null), isTrue);
    });
  });

  group('GetCategoryBreakdown (real in-memory database)', () {
    late AppDatabase db;
    late FinanceRepositoryImpl repository;
    late GetCategoryBreakdown useCase;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
      useCase = breakdownUseCase(repository);
    });

    tearDown(() => db.close());

    final today = DateTime.now();
    final inPeriod = DateTime(today.year, today.month, today.day);

    Future<void> add(
      String categoryId,
      FinanceEntryType type,
      int amount,
      String key, {
      Currency currency = Currency.egp,
    }) async {
      final result = await repository.addEntry(
        idempotencyKey: key,
        categoryId: categoryId,
        type: type,
        amount: Money.fromMinorUnits(amount, currency),
        date: inPeriod,
      );
      expect(result.isRight(), isTrue, reason: 'failed to seed $key');
    }

    test(
      'the GROUP BY aggregate orders largest-first and shares sum to 1',
      () async {
        await add('seed_groceries', FinanceEntryType.expense, 15000, 'g1');
        await add('seed_groceries', FinanceEntryType.expense, 5000, 'g2');
        await add('seed_rent', FinanceEntryType.expense, 500000, 'r1');
        await add('seed_fuel', FinanceEntryType.expense, 7500, 'f1');

        final breakdown = (await useCase(
          DateRange.thisMonth(),
          type: FinanceEntryType.expense,
        )).toNullable()!;
        final items = breakdown.items;

        expect(items.map((i) => i.categoryId), [
          'seed_rent',
          'seed_groceries',
          'seed_fuel',
        ]);
        expect(items.first.total!.minorUnits, 500000);
        // Groceries' two entries are one grouped row of 200.00 EGP.
        expect(items[1].total!.minorUnits, 20000);
        expect(items[1].categoryName, 'Groceries');
        expect(items[1].icon, 'groceries');
        expect(
          items.fold<double>(0, (sum, i) => sum + i.shareOfPeriod!),
          closeTo(1.0, 1e-9),
        );
        expect(items.first.shareOfPeriod, closeTo(500000 / 527500, 1e-9));
      },
    );

    test('the type argument narrows the breakdown to one direction', () async {
      await add('seed_groceries', FinanceEntryType.expense, 20000, 'e1');
      await add('seed_salary', FinanceEntryType.income, 1000000, 'i1');

      final incomeOnly = (await useCase(
        DateRange.thisMonth(),
        type: FinanceEntryType.income,
      )).toNullable()!;
      expect(incomeOnly.items.map((i) => i.categoryId), ['seed_salary']);

      final both = (await useCase(DateRange.thisMonth())).toNullable()!;
      expect(both.items.length, 2);
      expect(both.items.first.categoryId, 'seed_salary');
    });

    test('is empty for a period with no entries', () async {
      await add('seed_groceries', FinanceEntryType.expense, 20000, 'e1');

      final lastMonth = (await useCase(DateRange.lastMonth())).toNullable()!;

      expect(lastMonth.items, isEmpty);
      expect(lastMonth.isBlocked, isFalse);
    });

    test('groups one category per currency, then converts (018)', () async {
      await add('seed_groceries', FinanceEntryType.expense, 10000, 'e1');
      await add(
        'seed_groceries',
        FinanceEntryType.expense,
        1001,
        'u1',
        currency: Currency.usd,
      );

      final blocked = (await useCase(DateRange.thisMonth())).toNullable()!;
      expect(blocked.missingRatesFor, [Currency.usd]);
      expect(blocked.items.single.total, isNull);

      final converted = (await breakdownUseCase(
        repository,
        ConversionContext(
          primary: Currency.egp,
          rates: [rate(Currency.usd, Currency.egp, 0.5)],
        ),
      )(DateRange.thisMonth())).toNullable()!;
      // 10.01 USD × 0.5 = 5.005 EGP → round-half-up → 5.01 EGP.
      expect(converted.items.single.total, const Money.egp(10000 + 501));
      expect(converted.items.single.shareOfPeriod, 1.0);
    });
  });
}
