import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_history.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_summary.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/usecases/watch_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchOverview extends Mock implements WatchOverview {}

class MockWatchFinanceSummary extends Mock implements WatchFinanceSummary {}

class MockWatchFinanceHistory extends Mock implements WatchFinanceHistory {}

/// Home's two aggregates are live subscriptions (012 + 021 FR-031) that
/// succeed, fail and retry independently (FR-001–FR-005, FR-012).
void main() {
  late MockWatchOverview watchOverview;
  late MockWatchFinanceSummary watchFinanceSummary;
  late MockWatchFinanceHistory watchFinanceHistory;
  late StreamController<Either<Failure, OverviewSummary>> overview;
  late StreamController<Either<Failure, FinanceSummary>> finance;
  late StreamController<Either<Failure, List<FinanceEntry>>> history;

  final period = DateRange.thisMonth();

  const withBalances = OverviewSummary(
    totalOwedToUser: Money.egp(150000),
    totalUserOwes: Money.egp(0),
    peopleTheyOweYou: [
      PersonSummary(
        personId: 'p1',
        name: 'Ahmed',
        net: Money.egp(150000),
        isArchived: false,
      ),
    ],
    peopleYouOweThem: [],
    settledCount: 0,
  );

  const allSettled = OverviewSummary(
    totalOwedToUser: Money.egp(0),
    totalUserOwes: Money.egp(0),
    peopleTheyOweYou: [],
    peopleYouOweThem: [],
    settledCount: 2,
  );

  const noPeople = OverviewSummary(
    totalOwedToUser: Money.egp(0),
    totalUserOwes: Money.egp(0),
    peopleTheyOweYou: [],
    peopleYouOweThem: [],
    settledCount: 0,
  );

  final thisMonth = FinanceSummary(
    totalIncome: const Money.egp(900000),
    totalExpense: const Money.egp(75000),
    period: period,
  );

  final anEntry = FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k1',
    categoryId: 'c1',
    type: FinanceEntryType.expense,
    amount: const Money.egp(100),
    date: DateTime(2026),
    createdAt: DateTime(2026),
  );

  const overviewFailure = CacheFailure('overview read failed');
  const financeFailure = CacheFailure('finance read failed');

  setUpAll(() => registerFallbackValue(period));

  setUp(() {
    watchOverview = MockWatchOverview();
    watchFinanceSummary = MockWatchFinanceSummary();
    watchFinanceHistory = MockWatchFinanceHistory();
    overview = StreamController.broadcast();
    finance = StreamController.broadcast();
    history = StreamController.broadcast();
    when(() => watchOverview()).thenAnswer((_) => overview.stream);
    when(() => watchFinanceSummary(any())).thenAnswer((_) => finance.stream);
    when(
      () => watchFinanceHistory(limit: any(named: 'limit')),
    ).thenAnswer((_) => history.stream);
  });

  tearDown(() async {
    await overview.close();
    await finance.close();
    await history.close();
  });

  DashboardCubit buildCubit() =>
      DashboardCubit(watchOverview, watchFinanceSummary, watchFinanceHistory);

  Future<void> pump() => Future<void>.delayed(Duration.zero);

  test('starts fully loading, with nothing settled or empty yet', () {
    final state = buildCubit().state;
    expect(state.isFullyLoading, isTrue);
    expect(state.isAllSettled, isFalse);
    expect(state.isCombinedEmpty, isFalse);
  });

  test('load() shows both aggregates once both have arrived', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    await cubit.load();
    overview.add(const Right(withBalances));
    finance.add(Right(thisMonth));
    history.add(Right([anEntry]));
    await pump();

    expect(cubit.state.overviewStatus, LoadStatus.success);
    expect(cubit.state.overviewSummary, withBalances);
    expect(cubit.state.financeStatus, LoadStatus.success);
    expect(cubit.state.financeSummary, thisMonth);
    expect(cubit.state.isAnyPartialError, isFalse);
    verify(() => watchFinanceSummary(period)).called(1);
  });

  test('a change after the first result updates Home with no reload '
      '(021 FR-031)', () async {
    final cubit = buildCubit();
    addTearDown(cubit.close);
    await cubit.load();
    overview.add(const Right(withBalances));
    finance.add(Right(thisMonth));
    await pump();

    overview.add(const Right(allSettled));
    await pump();

    expect(cubit.state.overviewSummary, allSettled);
    expect(cubit.state.isAllSettled, isTrue);
    verify(() => watchOverview()).called(1);
  });

  group('combined empty state (FR-005)', () {
    test(
      'no people and no finance entry at all is the first-run state',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.load();
        overview.add(const Right(noPeople));
        finance.add(Right(FinanceSummary.empty(period)));
        history.add(const Right([]));
        await pump();

        expect(cubit.state.isCombinedEmpty, isTrue);
      },
    );

    test(
      'any finance entry, in any period, is not the first-run state',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.load();
        overview.add(const Right(noPeople));
        finance.add(Right(FinanceSummary.empty(period)));
        history.add(Right([anEntry]));
        await pump();

        expect(cubit.state.isCombinedEmpty, isFalse);
      },
    );

    test(
      'a failed existence check assumes data, never the first-run state',
      () async {
        final cubit = buildCubit();
        addTearDown(cubit.close);
        await cubit.load();
        overview.add(const Right(noPeople));
        finance.add(Right(FinanceSummary.empty(period)));
        history.add(const Left(financeFailure));
        await pump();

        expect(cubit.state.isCombinedEmpty, isFalse);
      },
    );
  });

  group('independent failures (FR-003/FR-004)', () {
    test('an overview failure leaves finance showing', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.load();
      overview.add(const Left(overviewFailure));
      finance.add(Right(thisMonth));
      await pump();

      expect(cubit.state.overviewStatus, LoadStatus.failure);
      expect(cubit.state.financeStatus, LoadStatus.success);
      expect(cubit.state.isAnyPartialError, isTrue);
      expect(cubit.state.isFullFailure, isFalse);
    });

    test('both failing is a full failure', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.load();
      overview.add(const Left(overviewFailure));
      finance.add(const Left(financeFailure));
      await pump();

      expect(cubit.state.isFullFailure, isTrue);
    });

    test('retryOverview re-subscribes only the overview', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.load();
      overview.add(const Left(overviewFailure));
      finance.add(Right(thisMonth));
      await pump();

      await cubit.retryOverview();
      expect(cubit.state.overviewStatus, LoadStatus.loading);
      expect(cubit.state.financeStatus, LoadStatus.success);
      overview.add(const Right(withBalances));
      await pump();

      expect(cubit.state.overviewStatus, LoadStatus.success);
      verify(() => watchOverview()).called(2);
      verify(() => watchFinanceSummary(any())).called(1);
    });

    test('retryFinance re-subscribes only the finance summary', () async {
      final cubit = buildCubit();
      addTearDown(cubit.close);
      await cubit.load();
      overview.add(const Right(withBalances));
      finance.add(const Left(financeFailure));
      await pump();

      await cubit.retryFinance();
      expect(cubit.state.financeStatus, LoadStatus.loading);
      finance.add(Right(thisMonth));
      await pump();

      expect(cubit.state.financeStatus, LoadStatus.success);
      verify(() => watchFinanceSummary(any())).called(2);
      verify(() => watchOverview()).called(1);
    });
  });

  test('does not emit after close', () async {
    final cubit = buildCubit();
    await cubit.load();
    await cubit.close();

    overview.add(const Right(withBalances));
    await pump();

    expect(cubit.isClosed, isTrue);
    expect(cubit.state.overviewStatus, LoadStatus.loading);
  });
}
