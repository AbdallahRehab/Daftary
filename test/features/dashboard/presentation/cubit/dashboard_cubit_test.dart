import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/dashboard/domain/entities/dashboard_snapshot.dart';
import 'package:daftary/features/dashboard/domain/usecases/get_dashboard_snapshot.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:daftary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:daftary/features/dashboard/presentation/cubit/load_status.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDashboardSnapshot extends Mock implements GetDashboardSnapshot {}

class MockGetOverview extends Mock implements GetOverview {}

class MockGetFinanceSummary extends Mock implements GetFinanceSummary {}

/// T009–T011, T035–T037, and the assertions carried over from the retired
/// `overview_cubit_test.dart` (T020): Home's two aggregates load together
/// but succeed, fail, and retry independently (FR-001–FR-005, FR-012).
void main() {
  late MockGetDashboardSnapshot getSnapshot;
  late MockGetOverview getOverview;
  late MockGetFinanceSummary getFinanceSummary;

  final period = DateRange.thisMonth();

  const withBalances = OverviewSummary(
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

  const allSettled = OverviewSummary(
    totalOwedToUser: Money.fromMinorUnits(0),
    totalUserOwes: Money.fromMinorUnits(0),
    peopleTheyOweYou: [],
    peopleYouOweThem: [],
    settledCount: 2,
  );

  const noPeople = OverviewSummary(
    totalOwedToUser: Money.fromMinorUnits(0),
    totalUserOwes: Money.fromMinorUnits(0),
    peopleTheyOweYou: [],
    peopleYouOweThem: [],
    settledCount: 0,
  );

  final finance = FinanceSummary(
    totalIncome: const Money.fromMinorUnits(900000),
    totalExpense: const Money.fromMinorUnits(75000),
    period: period,
  );
  final emptyFinance = FinanceSummary.empty(period);

  const overviewFailure = CacheFailure('overview read failed');
  const financeFailure = CacheFailure('finance read failed');

  DashboardSnapshot snapshot({
    Either<Failure, OverviewSummary> overview = const Right(withBalances),
    Either<Failure, FinanceSummary>? financeResult,
    bool hasAnyFinanceEntry = true,
  }) {
    return DashboardSnapshot(
      overview: overview,
      finance: financeResult ?? Right(finance),
      hasAnyFinanceEntry: hasAnyFinanceEntry,
    );
  }

  void stubSnapshot(DashboardSnapshot value) {
    when(
      () => getSnapshot(period: any(named: 'period')),
    ).thenAnswer((_) async => value);
  }

  DashboardCubit buildCubit() =>
      DashboardCubit(getSnapshot, getOverview, getFinanceSummary);

  setUpAll(() {
    registerFallbackValue(period);
  });

  setUp(() {
    getSnapshot = MockGetDashboardSnapshot();
    getOverview = MockGetOverview();
    getFinanceSummary = MockGetFinanceSummary();
  });

  test('starts fully loading, with nothing settled or empty yet', () {
    final state = buildCubit().state;
    expect(state.isFullyLoading, isTrue);
    expect(state.isAllSettled, isFalse);
    expect(state.isCombinedEmpty, isFalse);
  });

  group('load() (T009, FR-001/FR-002)', () {
    blocTest<DashboardCubit, DashboardState>(
      'goes from both loading to both loaded, carrying both summaries',
      build: buildCubit,
      setUp: () => stubSnapshot(snapshot()),
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DashboardState>().having(
          (s) => s.isFullyLoading,
          'isFullyLoading',
          isTrue,
        ),
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: withBalances,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.isFullyLoading, isFalse);
        expect(cubit.state.isAnyPartialError, isFalse);
        verify(() => getSnapshot(period: period)).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'reflects the current balance totals immediately (carried from '
      'OverviewCubit, 001 FR-014)',
      build: buildCubit,
      setUp: () => stubSnapshot(snapshot()),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(
          cubit.state.overviewSummary?.totalOwedToUser,
          const Money.fromMinorUnits(150000),
        );
        expect(cubit.state.isAllSettled, isFalse);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'exposes an explicit "all settled" state distinct from loading/empty '
      '(carried from OverviewCubit, 001 US4 AC3)',
      build: buildCubit,
      setUp: () => stubSnapshot(snapshot(overview: const Right(allSettled))),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.overviewStatus, LoadStatus.success);
        expect(cubit.state.isAllSettled, isTrue);
        expect(cubit.state.isCombinedEmpty, isFalse);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'a failed side carries its failure message; the other side still loads',
      build: buildCubit,
      setUp: () =>
          stubSnapshot(snapshot(overview: const Left(overviewFailure))),
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        DashboardState(
          overviewStatus: LoadStatus.failure,
          overviewError: overviewFailure.message,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
      verify: (cubit) {
        expect(cubit.state.isAnyPartialError, isTrue);
        expect(cubit.state.isFullFailure, isFalse);
      },
    );
  });

  group('combined empty state (T010, FR-005)', () {
    blocTest<DashboardCubit, DashboardState>(
      'is true with zero people and no finance entry ever',
      build: buildCubit,
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Right(noPeople),
          financeResult: Right(emptyFinance),
          hasAnyFinanceEntry: false,
        ),
      ),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isTrue),
    );

    blocTest<DashboardCubit, DashboardState>(
      'is false for a user with finance history from a prior month but no '
      'balance activity (Edge Cases)',
      build: buildCubit,
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Right(noPeople),
          financeResult: Right(emptyFinance),
        ),
      ),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isFalse),
    );

    blocTest<DashboardCubit, DashboardState>(
      'is false when people exist, even with no finance entry ever',
      build: buildCubit,
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Right(allSettled),
          financeResult: Right(emptyFinance),
          hasAnyFinanceEntry: false,
        ),
      ),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isFalse),
    );

    blocTest<DashboardCubit, DashboardState>(
      'is false while either side has failed — a partial error is not empty',
      build: buildCubit,
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Right(noPeople),
          financeResult: const Left(financeFailure),
          hasAnyFinanceEntry: false,
        ),
      ),
      act: (cubit) => cubit.load(),
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isFalse),
    );

    blocTest<DashboardCubit, DashboardState>(
      'settles to true once a retry brings the failed side back and both '
      'are truly empty',
      build: buildCubit,
      setUp: () {
        stubSnapshot(
          snapshot(
            overview: const Right(noPeople),
            financeResult: const Left(financeFailure),
            hasAnyFinanceEntry: false,
          ),
        );
        when(
          () => getFinanceSummary(any()),
        ).thenAnswer((_) async => Right(emptyFinance));
      },
      act: (cubit) async {
        await cubit.load();
        await cubit.retryFinance();
      },
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isTrue),
    );
  });

  group('refresh() (T011, FR-012)', () {
    blocTest<DashboardCubit, DashboardState>(
      're-fetches both aggregates together and replaces the numbers in one '
      'emission, without flashing the loading state',
      build: buildCubit,
      seed: () => DashboardState(
        overviewStatus: LoadStatus.success,
        overviewSummary: withBalances,
        financeStatus: LoadStatus.success,
        financeSummary: finance,
      ),
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Right(allSettled),
          financeResult: Right(emptyFinance),
        ),
      ),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: allSettled,
          financeStatus: LoadStatus.success,
          financeSummary: emptyFinance,
        ),
      ],
      verify: (_) => verify(() => getSnapshot(period: period)).called(1),
    );

    blocTest<DashboardCubit, DashboardState>(
      'a second fetch after a change elsewhere refreshes the totals (carried '
      'from OverviewCubit)',
      build: buildCubit,
      act: (cubit) async {
        stubSnapshot(snapshot());
        await cubit.load();
        stubSnapshot(snapshot(overview: const Right(allSettled)));
        await cubit.refresh();
      },
      verify: (cubit) => expect(cubit.state.isAllSettled, isTrue),
    );

    blocTest<DashboardCubit, DashboardState>(
      'recomputes isCombinedEmpty from the fresh snapshot',
      build: buildCubit,
      act: (cubit) async {
        stubSnapshot(
          snapshot(
            overview: const Right(noPeople),
            financeResult: Right(emptyFinance),
            hasAnyFinanceEntry: false,
          ),
        );
        await cubit.load();
        expect(cubit.state.isCombinedEmpty, isTrue);
        stubSnapshot(
          snapshot(
            overview: const Right(noPeople),
            financeResult: Right(finance),
          ),
        );
        await cubit.refresh();
      },
      verify: (cubit) => expect(cubit.state.isCombinedEmpty, isFalse),
    );

    blocTest<DashboardCubit, DashboardState>(
      'recovers a side that had failed',
      build: buildCubit,
      seed: () => const DashboardState(
        overviewStatus: LoadStatus.failure,
        overviewError: 'old',
        financeStatus: LoadStatus.failure,
        financeError: 'old',
      ),
      setUp: () => stubSnapshot(snapshot()),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: withBalances,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
    );
  });

  group('retryOverview() (T035, FR-003)', () {
    final seeded = DashboardState(
      overviewStatus: LoadStatus.failure,
      overviewError: overviewFailure.message,
      financeStatus: LoadStatus.success,
      financeSummary: finance,
    );

    blocTest<DashboardCubit, DashboardState>(
      're-fetches only the overview; the finance fields never change',
      build: buildCubit,
      seed: () => seeded,
      setUp: () => when(
        () => getOverview(),
      ).thenAnswer((_) async => const Right(withBalances)),
      act: (cubit) => cubit.retryOverview(),
      expect: () => [
        DashboardState(
          overviewStatus: LoadStatus.loading,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: withBalances,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
      verify: (_) {
        verifyNever(() => getSnapshot(period: any(named: 'period')));
        verifyNever(() => getFinanceSummary(any()));
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'leaves a failed finance side failed, with its own error intact',
      build: buildCubit,
      seed: () => DashboardState(
        overviewStatus: LoadStatus.failure,
        overviewError: overviewFailure.message,
        financeStatus: LoadStatus.failure,
        financeError: financeFailure.message,
      ),
      setUp: () => when(
        () => getOverview(),
      ).thenAnswer((_) async => const Right(withBalances)),
      act: (cubit) => cubit.retryOverview(),
      verify: (cubit) {
        expect(cubit.state.overviewStatus, LoadStatus.success);
        expect(cubit.state.financeStatus, LoadStatus.failure);
        expect(cubit.state.financeError, financeFailure.message);
        expect(cubit.state.financeSummary, isNull);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'a retry that fails again surfaces the new failure on that side only',
      build: buildCubit,
      seed: () => seeded,
      setUp: () => when(
        () => getOverview(),
      ).thenAnswer((_) async => const Left(CacheFailure('still failing'))),
      act: (cubit) => cubit.retryOverview(),
      skip: 1,
      expect: () => [
        DashboardState(
          overviewStatus: LoadStatus.failure,
          overviewError: 'still failing',
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
    );
  });

  group('retryFinance() (T036, FR-003)', () {
    final seeded = DashboardState(
      overviewStatus: LoadStatus.success,
      overviewSummary: withBalances,
      financeStatus: LoadStatus.failure,
      financeError: financeFailure.message,
    );

    blocTest<DashboardCubit, DashboardState>(
      're-fetches only this month\'s finance; the overview fields never change',
      build: buildCubit,
      seed: () => seeded,
      setUp: () => when(
        () => getFinanceSummary(any()),
      ).thenAnswer((_) async => Right(finance)),
      act: (cubit) => cubit.retryFinance(),
      expect: () => [
        const DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: withBalances,
          financeStatus: LoadStatus.loading,
        ),
        DashboardState(
          overviewStatus: LoadStatus.success,
          overviewSummary: withBalances,
          financeStatus: LoadStatus.success,
          financeSummary: finance,
        ),
      ],
      verify: (_) {
        verifyNever(() => getSnapshot(period: any(named: 'period')));
        verifyNever(() => getOverview());
        verify(() => getFinanceSummary(period)).called(1);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'leaves a failed overview side failed, with its own error intact',
      build: buildCubit,
      seed: () => DashboardState(
        overviewStatus: LoadStatus.failure,
        overviewError: overviewFailure.message,
        financeStatus: LoadStatus.failure,
        financeError: financeFailure.message,
      ),
      setUp: () => when(
        () => getFinanceSummary(any()),
      ).thenAnswer((_) async => Right(finance)),
      act: (cubit) => cubit.retryFinance(),
      verify: (cubit) {
        expect(cubit.state.financeStatus, LoadStatus.success);
        expect(cubit.state.overviewStatus, LoadStatus.failure);
        expect(cubit.state.overviewError, overviewFailure.message);
        expect(cubit.state.overviewSummary, isNull);
      },
    );
  });

  group('isFullFailure (T037, FR-004)', () {
    test('is true only when both sides have failed', () {
      for (final overview in LoadStatus.values) {
        for (final financeStatus in LoadStatus.values) {
          final state = DashboardState(
            overviewStatus: overview,
            financeStatus: financeStatus,
          );
          expect(
            state.isFullFailure,
            overview == LoadStatus.failure &&
                financeStatus == LoadStatus.failure,
            reason: 'overview=$overview finance=$financeStatus',
          );
        }
      }
    });

    blocTest<DashboardCubit, DashboardState>(
      'load() with both sides failing lands in the full failure state',
      build: buildCubit,
      setUp: () => stubSnapshot(
        snapshot(
          overview: const Left(overviewFailure),
          financeResult: const Left(financeFailure),
        ),
      ),
      act: (cubit) => cubit.load(),
      verify: (cubit) {
        expect(cubit.state.isFullFailure, isTrue);
        expect(cubit.state.isAnyPartialError, isFalse);
        expect(cubit.state.isCombinedEmpty, isFalse);
      },
    );

    blocTest<DashboardCubit, DashboardState>(
      'a single-side retry out of full failure leaves a partial error',
      build: buildCubit,
      seed: () => DashboardState(
        overviewStatus: LoadStatus.failure,
        overviewError: overviewFailure.message,
        financeStatus: LoadStatus.failure,
        financeError: financeFailure.message,
      ),
      setUp: () => when(
        () => getOverview(),
      ).thenAnswer((_) async => const Right(withBalances)),
      act: (cubit) => cubit.retryOverview(),
      verify: (cubit) {
        expect(cubit.state.isFullFailure, isFalse);
        expect(cubit.state.isAnyPartialError, isTrue);
      },
    );
  });

  group('isAnyPartialError', () {
    test('is true only for exactly one failure alongside one success', () {
      for (final overview in LoadStatus.values) {
        for (final financeStatus in LoadStatus.values) {
          final expected =
              {overview, financeStatus}.length == 2 &&
              {
                overview,
                financeStatus,
              }.containsAll({LoadStatus.failure, LoadStatus.success});
          expect(
            DashboardState(
              overviewStatus: overview,
              financeStatus: financeStatus,
            ).isAnyPartialError,
            expected,
            reason: 'overview=$overview finance=$financeStatus',
          );
        }
      }
    });
  });

  test('does not emit after close when a load resolves late', () async {
    final gate = Completer<DashboardSnapshot>();
    when(
      () => getSnapshot(period: any(named: 'period')),
    ).thenAnswer((_) => gate.future);
    final cubit = buildCubit();

    final pending = cubit.load();
    await cubit.close();
    gate.complete(snapshot());

    await expectLater(pending, completes);
  });
}
