import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_history.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

class _FilterFallback extends Fake implements FinanceHistoryFilter {}

/// T036 — FR-012/FR-013: type, category, and date-range filters combine,
/// soft-deleted rows never appear, ordering is newest-first, and
/// `limit`/`offset` page through the result.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetFinanceHistory (mocked repository)', () {
    late MockFinanceRepository repository;
    late GetFinanceHistory useCase;

    setUpAll(() => registerFallbackValue(_FilterFallback()));

    setUp(() {
      repository = MockFinanceRepository();
      useCase = GetFinanceHistory(repository);
    });

    test(
      'passes the combined filter and the paging window straight through',
      () async {
        final filter = FinanceHistoryFilter(
          type: FinanceEntryType.expense,
          categoryId: 'seed_groceries',
          dateRange: DateRange.thisMonth(DateTime(2026, 3, 31)),
        );
        when(
          () => repository.getHistory(
            filter: any(named: 'filter'),
            limit: any(named: 'limit'),
            offset: any(named: 'offset'),
          ),
        ).thenAnswer((_) async => const Right(<FinanceEntry>[]));

        await useCase(filter: filter, limit: 20, offset: 40);

        verify(
          () => repository.getHistory(filter: filter, limit: 20, offset: 40),
        ).called(1);
      },
    );

    test('defaults to the first page of 50 with no filter at all', () async {
      when(
        () => repository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right(<FinanceEntry>[]));

      await useCase();

      verify(
        () => repository.getHistory(filter: null, limit: 50, offset: 0),
      ).called(1);
    });

    test('surfaces a repository failure as a Left', () async {
      when(
        () => repository.getHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('boom')));

      final result = await useCase();

      expect(result.isLeft(), isTrue);
    });
  });

  group('GetFinanceHistory (real in-memory database)', () {
    late AppDatabase db;
    late FinanceRepositoryImpl repository;
    late GetFinanceHistory useCase;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repository = FinanceRepositoryImpl(FinanceDao(db));
      useCase = GetFinanceHistory(repository);
    });

    tearDown(() => db.close());

    final today = DateTime.now();
    final thisMonthStart = DateTime(today.year, today.month, 1);
    final lastMonthDay = DateTime(today.year, today.month - 1, 15);

    Future<FinanceEntry> add({
      required String categoryId,
      required FinanceEntryType type,
      required int amount,
      required DateTime date,
      required String key,
    }) async {
      final result = await repository.addEntry(
        idempotencyKey: key,
        categoryId: categoryId,
        type: type,
        amount: Money.egp(amount),
        date: date,
      );
      expect(result.isRight(), isTrue, reason: 'failed to seed $key');
      return result.toNullable()!;
    }

    test(
      'type, category, and date-range filters narrow the list together',
      () async {
        await add(
          categoryId: 'seed_groceries',
          type: FinanceEntryType.expense,
          amount: 4575,
          date: thisMonthStart,
          key: 'match',
        );
        await add(
          categoryId: 'seed_fuel',
          type: FinanceEntryType.expense,
          amount: 20000,
          date: thisMonthStart,
          key: 'other-category',
        );
        await add(
          categoryId: 'seed_salary',
          type: FinanceEntryType.income,
          amount: 1000000,
          date: thisMonthStart,
          key: 'other-type',
        );
        await add(
          categoryId: 'seed_groceries',
          type: FinanceEntryType.expense,
          amount: 3000,
          date: lastMonthDay,
          key: 'other-period',
        );

        final byTypeOnly = (await useCase(
          filter: const FinanceHistoryFilter(type: FinanceEntryType.expense),
        )).toNullable()!;
        expect(byTypeOnly.length, 3);

        final combined = (await useCase(
          filter: FinanceHistoryFilter(
            type: FinanceEntryType.expense,
            categoryId: 'seed_groceries',
            dateRange: DateRange.thisMonth(),
          ),
        )).toNullable()!;
        expect(combined.map((e) => e.idempotencyKey), ['match']);
        expect(combined.single.amount, const Money.egp(4575));
      },
    );

    test(
      'soft-deleted entries are excluded, and reappear once restored',
      () async {
        final entry = await add(
          categoryId: 'seed_groceries',
          type: FinanceEntryType.expense,
          amount: 5000,
          date: thisMonthStart,
          key: 'deletable',
        );
        await add(
          categoryId: 'seed_fuel',
          type: FinanceEntryType.expense,
          amount: 6000,
          date: thisMonthStart,
          key: 'kept',
        );

        await repository.deleteEntry(entry.id);
        var entries = (await useCase()).toNullable()!;
        expect(entries.map((e) => e.idempotencyKey), ['kept']);

        await repository.restoreEntry(entry.id);
        entries = (await useCase()).toNullable()!;
        expect(entries.map((e) => e.idempotencyKey), contains('deletable'));
        expect(entries.length, 2);
      },
    );

    test('orders newest date first and pages with limit/offset', () async {
      for (var day = 1; day <= 5; day++) {
        await add(
          categoryId: 'seed_groceries',
          type: FinanceEntryType.expense,
          amount: day * 100,
          date: DateTime(today.year, today.month, day),
          key: 'day-$day',
        );
      }

      final firstPage = (await useCase(limit: 2)).toNullable()!;
      expect(firstPage.map((e) => e.idempotencyKey), ['day-5', 'day-4']);

      final secondPage = (await useCase(limit: 2, offset: 2)).toNullable()!;
      expect(secondPage.map((e) => e.idempotencyKey), ['day-3', 'day-2']);

      final lastPage = (await useCase(limit: 2, offset: 4)).toNullable()!;
      expect(lastPage.map((e) => e.idempotencyKey), ['day-1']);
    });
  });
}
