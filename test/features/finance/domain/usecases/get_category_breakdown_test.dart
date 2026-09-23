import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
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

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// T035 — FR-015: per-category totals for a period, largest first, each
/// carrying its share of the period.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetCategoryBreakdown (mocked repository)', () {
    late MockFinanceRepository repository;
    late GetCategoryBreakdown useCase;

    setUpAll(() => registerFallbackValue(DateRange.thisMonth()));

    setUp(() {
      repository = MockFinanceRepository();
      useCase = GetCategoryBreakdown(repository);
    });

    test('returns per-category totals descending, each with its share',
        () async {
      final period = DateRange.thisMonth(DateTime(2026, 3, 31));
      const items = [
        CategoryBreakdownItem(
          categoryId: 'seed_rent',
          categoryName: 'Rent',
          icon: 'rent',
          total: Money.fromMinorUnits(600000),
          shareOfPeriod: 0.6,
        ),
        CategoryBreakdownItem(
          categoryId: 'seed_groceries',
          categoryName: 'Groceries',
          icon: 'groceries',
          total: Money.fromMinorUnits(300000),
          shareOfPeriod: 0.3,
        ),
        CategoryBreakdownItem(
          categoryId: 'seed_fuel',
          categoryName: 'Fuel',
          icon: 'fuel',
          total: Money.fromMinorUnits(100000),
          shareOfPeriod: 0.1,
        ),
      ];
      when(
        () => repository.getCategoryBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => const Right(items));

      final result = await useCase(period, type: FinanceEntryType.expense);

      final breakdown = result.toNullable()!;
      expect(
        breakdown.map((i) => i.categoryId),
        ['seed_rent', 'seed_groceries', 'seed_fuel'],
      );
      expect(breakdown.map((i) => i.total.minorUnits), [600000, 300000, 100000]);
      expect(
        breakdown.fold<double>(0, (sum, i) => sum + i.shareOfPeriod),
        closeTo(1.0, 1e-9),
      );
      verify(
        () => repository.getCategoryBreakdown(
          period,
          type: FinanceEntryType.expense,
        ),
      ).called(1);
    });

    test('surfaces a repository failure as a Left', () async {
      when(
        () => repository.getCategoryBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));

      final result = await useCase(DateRange.thisMonth());

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetCategoryBreakdown (real in-memory database)', () {
    late AppDatabase db;
    late FinanceRepositoryImpl repository;
    late GetCategoryBreakdown useCase;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
      useCase = GetCategoryBreakdown(repository);
    });

    tearDown(() => db.close());

    final today = DateTime.now();
    final inPeriod = DateTime(today.year, today.month, today.day);

    Future<void> add(
      String categoryId,
      FinanceEntryType type,
      int amount,
      String key,
    ) async {
      final result = await repository.addEntry(
        idempotencyKey: key,
        categoryId: categoryId,
        type: type,
        amountMinorUnits: amount,
        date: inPeriod,
      );
      expect(result.isRight(), isTrue, reason: 'failed to seed $key');
    }

    test('the GROUP BY aggregate orders largest-first and shares sum to 1',
        () async {
      await add('seed_groceries', FinanceEntryType.expense, 15000, 'g1');
      await add('seed_groceries', FinanceEntryType.expense, 5000, 'g2');
      await add('seed_rent', FinanceEntryType.expense, 500000, 'r1');
      await add('seed_fuel', FinanceEntryType.expense, 7500, 'f1');

      final breakdown =
          (await useCase(
            DateRange.thisMonth(),
            type: FinanceEntryType.expense,
          )).toNullable()!;

      expect(
        breakdown.map((i) => i.categoryId),
        ['seed_rent', 'seed_groceries', 'seed_fuel'],
      );
      expect(breakdown.first.total.minorUnits, 500000);
      // Groceries' two entries are one grouped row of 200.00 EGP.
      expect(breakdown[1].total.minorUnits, 20000);
      expect(breakdown[1].categoryName, 'Groceries');
      expect(breakdown[1].icon, 'groceries');
      expect(
        breakdown.fold<double>(0, (sum, i) => sum + i.shareOfPeriod),
        closeTo(1.0, 1e-9),
      );
      expect(
        breakdown.first.shareOfPeriod,
        closeTo(500000 / 527500, 1e-9),
      );
    });

    test('the type argument narrows the breakdown to one direction',
        () async {
      await add('seed_groceries', FinanceEntryType.expense, 20000, 'e1');
      await add('seed_salary', FinanceEntryType.income, 1000000, 'i1');

      final incomeOnly =
          (await useCase(
            DateRange.thisMonth(),
            type: FinanceEntryType.income,
          )).toNullable()!;
      expect(incomeOnly.map((i) => i.categoryId), ['seed_salary']);

      final both = (await useCase(DateRange.thisMonth())).toNullable()!;
      expect(both.length, 2);
      expect(both.first.categoryId, 'seed_salary');
    });

    test('is empty for a period with no entries', () async {
      await add('seed_groceries', FinanceEntryType.expense, 20000, 'e1');

      final lastMonth = (await useCase(DateRange.lastMonth())).toNullable()!;

      expect(lastMonth, isEmpty);
    });
  });
}
