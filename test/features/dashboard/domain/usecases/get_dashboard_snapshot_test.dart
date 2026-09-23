import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/domain/usecases/get_dashboard_snapshot.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetOverview extends Mock implements GetOverview {}

class MockGetFinanceSummary extends Mock implements GetFinanceSummary {}

class MockGetFinanceHistory extends Mock implements GetFinanceHistory {}

/// T008 — the coordinator runs its three reads concurrently, keeps each
/// aggregate's outcome independent (FR-003), and never lets the cheap
/// existence check fail the whole load (research.md Decision 3).
void main() {
  late MockGetOverview getOverview;
  late MockGetFinanceSummary getFinanceSummary;
  late MockGetFinanceHistory getFinanceHistory;
  late GetDashboardSnapshot useCase;

  final period = DateRange(
    start: DateTime(2026, 9, 1),
    end: DateTime(2026, 9, 23),
  );

  const overview = OverviewSummary(
    totalOwedToUser: Money.fromMinorUnits(150000),
    totalUserOwes: Money.fromMinorUnits(0),
    peopleTheyOweYou: [
      PersonSummary(
        personId: 'p1',
        name: 'Ahmed',
        net: Money.fromMinorUnits(150000),
        isArchived: false,
      ),
    ],
    peopleYouOweThem: [],
    settledCount: 0,
  );

  final finance = FinanceSummary(
    totalIncome: const Money.fromMinorUnits(900000),
    totalExpense: const Money.fromMinorUnits(75000),
    period: period,
  );

  final entry = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k1',
    categoryId: 'seed_groceries',
    type: FinanceEntryType.expense,
    amount: const Money.fromMinorUnits(75000),
    date: DateTime(2026, 9, 3),
    createdAt: DateTime(2026, 9, 3),
  );

  setUpAll(() {
    registerFallbackValue(period);
  });

  setUp(() {
    getOverview = MockGetOverview();
    getFinanceSummary = MockGetFinanceSummary();
    getFinanceHistory = MockGetFinanceHistory();
    useCase = GetDashboardSnapshot(
      getOverview,
      getFinanceSummary,
      getFinanceHistory,
    );

    when(() => getOverview()).thenAnswer((_) async => const Right(overview));
    when(
      () => getFinanceSummary(any()),
    ).thenAnswer((_) async => Right(finance));
    when(
      () => getFinanceHistory(
        filter: any(named: 'filter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => Right([entry]));
  });

  test(
    'returns both aggregates exactly as their use cases produced them, '
    'and asks history for one unfiltered row as the existence check',
    () async {
      final snapshot = await useCase(period: period);

      expect(
        snapshot.overview,
        const Right<Failure, OverviewSummary>(overview),
      );
      expect(snapshot.finance, Right<Failure, FinanceSummary>(finance));
      expect(snapshot.hasAnyFinanceEntry, isTrue);
      verify(() => getFinanceSummary(period)).called(1);
      verify(() => getFinanceHistory(limit: 1, offset: 0)).called(1);
    },
  );

  test('starts all three reads before any of them completes (concurrent, '
      'not sequential)', () async {
    final overviewGate = Completer<Either<Failure, OverviewSummary>>();
    final financeGate = Completer<Either<Failure, FinanceSummary>>();
    final historyGate = Completer<Either<Failure, List<FinanceEntry>>>();
    when(() => getOverview()).thenAnswer((_) => overviewGate.future);
    when(() => getFinanceSummary(any())).thenAnswer((_) => financeGate.future);
    when(
      () => getFinanceHistory(
        filter: any(named: 'filter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) => historyGate.future);

    final pending = useCase(period: period);
    await pumpEventQueue();

    // None has resolved, yet all three have been called: a sequential
    // implementation would still be waiting on the first.
    verify(() => getOverview()).called(1);
    verify(() => getFinanceSummary(period)).called(1);
    verify(() => getFinanceHistory(limit: 1, offset: 0)).called(1);

    historyGate.complete(const Right([]));
    financeGate.complete(Right(finance));
    overviewGate.complete(const Right(overview));
    final snapshot = await pending;
    expect(snapshot.overview.isRight(), isTrue);
    expect(snapshot.finance.isRight(), isTrue);
  });

  test(
    'total time tracks the slowest read, not the sum of all three',
    () async {
      const delay = Duration(milliseconds: 150);
      when(
        () => getOverview(),
      ).thenAnswer((_) => Future.delayed(delay, () => const Right(overview)));
      when(
        () => getFinanceSummary(any()),
      ).thenAnswer((_) => Future.delayed(delay, () => Right(finance)));
      when(
        () => getFinanceHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) => Future.delayed(delay, () => Right([entry])));

      final stopwatch = Stopwatch()..start();
      await useCase(period: period);
      stopwatch.stop();

      expect(stopwatch.elapsed, lessThan(delay * 2.5));
    },
  );

  test('an overview failure leaves the finance result untouched', () async {
    const failure = CacheFailure('overview read failed');
    when(() => getOverview()).thenAnswer((_) async => const Left(failure));

    final snapshot = await useCase(period: period);

    expect(snapshot.overview, const Left<Failure, OverviewSummary>(failure));
    expect(snapshot.finance, Right<Failure, FinanceSummary>(finance));
  });

  test('a finance failure leaves the overview result untouched', () async {
    const failure = CacheFailure('finance read failed');
    when(
      () => getFinanceSummary(any()),
    ).thenAnswer((_) async => const Left(failure));

    final snapshot = await useCase(period: period);

    expect(snapshot.finance, const Left<Failure, FinanceSummary>(failure));
    expect(snapshot.overview, const Right<Failure, OverviewSummary>(overview));
  });

  test('a failed existence check degrades to "assume not empty" instead of '
      'failing the call', () async {
    when(
      () => getFinanceHistory(
        filter: any(named: 'filter'),
        limit: any(named: 'limit'),
        offset: any(named: 'offset'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('history failed')));

    final snapshot = await useCase(period: period);

    expect(snapshot.hasAnyFinanceEntry, isTrue);
    expect(snapshot.overview.isRight(), isTrue);
    expect(snapshot.finance.isRight(), isTrue);
  });

  group('isCombinedEmpty', () {
    const noPeople = OverviewSummary(
      totalOwedToUser: Money.fromMinorUnits(0),
      totalUserOwes: Money.fromMinorUnits(0),
      peopleTheyOweYou: [],
      peopleYouOweThem: [],
      settledCount: 0,
    );

    void stubNoHistory() {
      when(
        () => getFinanceHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Right([]));
    }

    test('is true with zero people and no finance entry ever', () async {
      when(() => getOverview()).thenAnswer((_) async => const Right(noPeople));
      stubNoHistory();

      expect((await useCase(period: period)).isCombinedEmpty, isTrue);
    });

    test('counts settled people: someone at a zero balance is not "no '
        'people"', () async {
      when(() => getOverview()).thenAnswer(
        (_) async => const Right(
          OverviewSummary(
            totalOwedToUser: Money.fromMinorUnits(0),
            totalUserOwes: Money.fromMinorUnits(0),
            peopleTheyOweYou: [],
            peopleYouOweThem: [],
            settledCount: 1,
          ),
        ),
      );
      stubNoHistory();

      expect((await useCase(period: period)).isCombinedEmpty, isFalse);
    });

    test('is false when the existence check failed', () async {
      when(() => getOverview()).thenAnswer((_) async => const Right(noPeople));
      when(
        () => getFinanceHistory(
          filter: any(named: 'filter'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('history failed')));

      expect((await useCase(period: period)).isCombinedEmpty, isFalse);
    });

    test('is false when either aggregate failed', () async {
      when(() => getOverview()).thenAnswer((_) async => const Right(noPeople));
      when(
        () => getFinanceSummary(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('finance failed')));
      stubNoHistory();

      expect((await useCase(period: period)).isCombinedEmpty, isFalse);
    });
  });
}
