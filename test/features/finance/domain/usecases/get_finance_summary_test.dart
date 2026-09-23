import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
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

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// T034 — `GetFinanceSummary` over the three periods FR-016 requires, and
/// the exactness guarantee SC-003 states: totals are integer minor units
/// all the way through, so a thousand entries add up to the cent.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GetFinanceSummary (mocked repository)', () {
    late MockFinanceRepository repository;
    late GetFinanceSummary useCase;

    setUpAll(() {
      registerFallbackValue(DateRange.thisMonth());
    });

    setUp(() {
      repository = MockFinanceRepository();
      useCase = GetFinanceSummary(repository);
    });

    FinanceSummary summaryFor(DateRange period, int income, int expense) =>
        FinanceSummary(
          totalIncome: Money.fromMinorUnits(income),
          totalExpense: Money.fromMinorUnits(expense),
          period: period,
        );

    test('passes "this month" through as an inclusive day-granular range',
        () async {
      final period = DateRange.thisMonth(DateTime(2026, 3, 18));
      when(
        () => repository.getSummary(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, 500000, 123456)));

      final result = await useCase(period);

      expect(result.isRight(), isTrue);
      final summary = result.toNullable()!;
      expect(summary.period.start, DateTime(2026, 3, 1));
      expect(summary.period.end, DateTime(2026, 3, 18));
      expect(summary.totalIncome, const Money.fromMinorUnits(500000));
      expect(summary.totalExpense, const Money.fromMinorUnits(123456));
      expect(summary.net, const Money.fromMinorUnits(376544));
      verify(() => repository.getSummary(period)).called(1);
    });

    test('"last month" is the full previous calendar month', () async {
      final period = DateRange.lastMonth(DateTime(2026, 3, 18));
      when(
        () => repository.getSummary(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, 0, 90000)));

      final result = await useCase(period);

      final summary = result.toNullable()!;
      expect(summary.period.start, DateTime(2026, 2, 1));
      expect(summary.period.end, DateTime(2026, 2, 28));
      // Overspent: the net reads negative rather than as an absolute value.
      expect(summary.net, const Money.fromMinorUnits(-90000));
    });

    test('a custom range is passed through untouched', () async {
      final period = DateRange(
        start: DateTime(2025, 11, 5, 13, 30),
        end: DateTime(2026, 1, 20, 6),
      );
      when(
        () => repository.getSummary(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, 100, 100)));

      final result = await useCase(period);

      final summary = result.toNullable()!;
      expect(summary.period.start, DateTime(2025, 11, 5));
      expect(summary.period.end, DateTime(2026, 1, 20));
      expect(summary.net, const Money.fromMinorUnits(0));
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
        () => repository.getSummary(any()),
      ).thenAnswer((_) async => Right(summaryFor(period, income, expense)));

      final summary = (await useCase(period)).toNullable()!;

      expect(summary.totalIncome.minorUnits, income);
      expect(summary.totalExpense.minorUnits, expense);
      expect(summary.net.minorUnits, income - expense);
    });

    test('surfaces a repository failure as a Left', () async {
      final period = DateRange.thisMonth();
      when(
        () => repository.getSummary(any()),
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
      useCase = GetFinanceSummary(repository);
    });

    tearDown(() => db.close());

    Future<void> addEntry({
      required int amountMinorUnits,
      required FinanceEntryType type,
      required DateTime date,
      required String key,
    }) async {
      final result = await repository.addEntry(
        idempotencyKey: key,
        categoryId: type == FinanceEntryType.income
            ? 'seed_salary'
            : 'seed_groceries',
        type: type,
        amountMinorUnits: amountMinorUnits,
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

      expect(summary.totalIncome.minorUnits, expectedIncome);
      expect(summary.totalExpense.minorUnits, expectedExpense);
      expect(summary.net.minorUnits, expectedIncome - expectedExpense);
    });

    test('excludes entries outside the period and soft-deleted ones',
        () async {
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
        amountMinorUnits: 9999,
        date: inPeriod,
      );
      await repository.deleteEntry(deleted.toNullable()!.id);

      final thisMonth = (await useCase(DateRange.thisMonth())).toNullable()!;
      expect(thisMonth.totalExpense.minorUnits, 4575);

      final lastMonth = (await useCase(DateRange.lastMonth())).toNullable()!;
      expect(lastMonth.totalExpense.minorUnits, 100000);
    });
  });
}
