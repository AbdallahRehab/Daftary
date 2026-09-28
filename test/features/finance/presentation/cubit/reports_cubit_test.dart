import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/spending_trend_point.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetSpendingTrend extends Mock implements GetSpendingTrend {}

class MockGetCategoryBreakdown extends Mock implements GetCategoryBreakdown {}

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// 013 T006 — the Reports Cubit: loading → success/empty/failure (FR-004,
/// FR-005), and a breakdown period switch that never touches the trend
/// (spec US1 AC3).
void main() {
  late MockGetSpendingTrend getTrend;
  late MockGetCategoryBreakdown getBreakdown;
  late MockFinanceRepository repository;

  final trend = [
    SpendingTrendPoint(
      period: DateRange(start: DateTime(2026, 8), end: DateTime(2026, 8, 31)),
      totalIncomeMinorUnits: 900000,
      totalExpenseMinorUnits: 450000,
      netMinorUnits: 450000,
    ),
    SpendingTrendPoint(
      period: DateRange(start: DateTime(2026, 9), end: DateTime(2026, 9, 24)),
      totalIncomeMinorUnits: 1000000,
      totalExpenseMinorUnits: 120050,
      netMinorUnits: 879950,
    ),
  ];

  const thisMonthBreakdown = CategoryBreakdown(
    items: [
      CategoryBreakdownItem(
        categoryId: 'seed_groceries',
        categoryName: 'Groceries',
        icon: 'groceries',
        total: Money.egp(80000),
        shareOfPeriod: 0.8,
      ),
      CategoryBreakdownItem(
        categoryId: 'seed_fuel',
        categoryName: 'Fuel',
        icon: 'fuel',
        total: Money.egp(20000),
        shareOfPeriod: 0.2,
      ),
    ],
  );

  const lastMonthBreakdown = CategoryBreakdown(
    items: [
      CategoryBreakdownItem(
        categoryId: 'seed_rent',
        categoryName: 'Rent',
        icon: 'rent',
        total: Money.egp(400000),
        shareOfPeriod: 1,
      ),
    ],
  );

  const failure = CacheFailure('read failed');

  setUpAll(() {
    registerFallbackValue(DateRange.thisMonth());
  });

  setUp(() {
    getTrend = MockGetSpendingTrend();
    getBreakdown = MockGetCategoryBreakdown();
    repository = MockFinanceRepository();

    when(() => repository.hasAnyEntry()).thenAnswer((_) async => right(true));
    when(
      () => getTrend(monthsBack: any(named: 'monthsBack')),
    ).thenAnswer((_) async => Right(trend));
    when(
      () => getBreakdown(any(), type: any(named: 'type')),
    ).thenAnswer((_) async => const Right(thisMonthBreakdown));
  });

  ReportsCubit build() => ReportsCubit(getTrend, getBreakdown, repository);

  group('load', () {
    blocTest<ReportsCubit, ReportsState>(
      'loading → success with both the trend and the breakdown populated',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        ReportsState(
          status: ReportsStatus.success,
          trend: trend,
          breakdown: thisMonthBreakdown,
          breakdownStatus: ReportsBreakdownStatus.success,
        ),
      ],
      verify: (_) {
        verify(() => getTrend(monthsBack: ReportsCubit.trendMonths)).called(1);
        // The breakdown is 007's own expense breakdown for this month —
        // no new aggregation (FR-003).
        verify(
          () => getBreakdown(
            ReportsPeriod.thisMonth.range(),
            type: FinanceEntryType.expense,
          ),
        ).called(1);
      },
    );

    test('issues the trend and breakdown reads concurrently', () async {
      final trendGate = Completer<Either<Failure, List<SpendingTrendPoint>>>();
      final breakdownGate = Completer<Either<Failure, CategoryBreakdown>>();
      when(
        () => getTrend(monthsBack: any(named: 'monthsBack')),
      ).thenAnswer((_) => trendGate.future);
      when(
        () => getBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) => breakdownGate.future);

      final cubit = build();
      addTearDown(cubit.close);
      final pending = cubit.load();
      await Future<void>.delayed(Duration.zero);

      verify(() => getTrend(monthsBack: any(named: 'monthsBack'))).called(1);
      verify(() => getBreakdown(any(), type: any(named: 'type'))).called(1);

      trendGate.complete(Right(trend));
      breakdownGate.complete(const Right(thisMonthBreakdown));
      await pending;
      expect(cubit.state.status, ReportsStatus.success);
    });

    blocTest<ReportsCubit, ReportsState>(
      'the true empty state when no finance entry exists anywhere (FR-004)',
      setUp: () => when(
        () => repository.hasAnyEntry(),
      ).thenAnswer((_) async => right(false)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>()
            .having((s) => s.status, 'status', ReportsStatus.empty)
            .having((s) => s.isEmpty, 'isEmpty', isTrue),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed trend read is an error state with retry (FR-005)',
      setUp: () => when(
        () => getTrend(monthsBack: any(named: 'monthsBack')),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>()
            .having((s) => s.status, 'status', ReportsStatus.failure)
            .having((s) => s.failure, 'failure', failure),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed breakdown read is an error state too — never a half screen',
      setUp: () => when(
        () => getBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>().having(
          (s) => s.status,
          'status',
          ReportsStatus.failure,
        ),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed existence check is an error state, not a false empty state',
      setUp: () => when(
        () => repository.hasAnyEntry(),
      ).thenAnswer((_) async => const Left(failure)),
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>().having(
          (s) => s.status,
          'status',
          ReportsStatus.failure,
        ),
      ],
    );

    test('retrying after a failure (load again) recovers to success', () async {
      var calls = 0;
      when(() => getTrend(monthsBack: any(named: 'monthsBack'))).thenAnswer((
        _,
      ) async {
        calls++;
        return calls == 1 ? const Left(failure) : Right(trend);
      });

      final cubit = build();
      addTearDown(cubit.close);
      await cubit.load();
      expect(cubit.state.status, ReportsStatus.failure);

      await cubit.load();
      expect(cubit.state.status, ReportsStatus.success);
      expect(cubit.state.trend, trend);
      expect(cubit.state.failure, isNull);
    });
  });

  group('changeBreakdownPeriod', () {
    blocTest<ReportsCubit, ReportsState>(
      're-fetches only the breakdown for the new period; the trend is '
      'untouched (spec US1 AC3)',
      setUp: () => when(
        () => getBreakdown(
          ReportsPeriod.lastMonth.range(),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => const Right(lastMonthBreakdown)),
      build: build,
      seed: () => ReportsState(
        status: ReportsStatus.success,
        trend: trend,
        breakdown: thisMonthBreakdown,
        breakdownStatus: ReportsBreakdownStatus.success,
      ),
      act: (cubit) => cubit.changeBreakdownPeriod(ReportsPeriod.lastMonth),
      expect: () => [
        ReportsState(
          status: ReportsStatus.success,
          trend: trend,
          breakdownPeriod: ReportsPeriod.lastMonth,
          breakdown: thisMonthBreakdown,
        ),
        ReportsState(
          status: ReportsStatus.success,
          trend: trend,
          breakdownPeriod: ReportsPeriod.lastMonth,
          breakdown: lastMonthBreakdown,
          breakdownStatus: ReportsBreakdownStatus.success,
        ),
      ],
      verify: (_) {
        verifyNever(() => getTrend(monthsBack: any(named: 'monthsBack')));
        verifyNever(() => repository.hasAnyEntry());
        verify(
          () => getBreakdown(
            ReportsPeriod.lastMonth.range(),
            type: FinanceEntryType.expense,
          ),
        ).called(1);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed breakdown switch fails only the breakdown section; the trend '
      'stays on screen and retryBreakdown recovers it',
      build: build,
      seed: () => ReportsState(
        status: ReportsStatus.success,
        trend: trend,
        breakdown: thisMonthBreakdown,
        breakdownStatus: ReportsBreakdownStatus.success,
      ),
      act: (cubit) async {
        when(
          () => getBreakdown(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => const Left(failure));
        await cubit.changeBreakdownPeriod(ReportsPeriod.last3Months);
        when(
          () => getBreakdown(any(), type: any(named: 'type')),
        ).thenAnswer((_) async => const Right(lastMonthBreakdown));
        await cubit.retryBreakdown();
      },
      skip: 1,
      expect: () => [
        isA<ReportsState>()
            .having((s) => s.status, 'status', ReportsStatus.success)
            .having((s) => s.trend, 'trend', trend)
            .having(
              (s) => s.breakdownStatus,
              'breakdownStatus',
              ReportsBreakdownStatus.failure,
            ),
        isA<ReportsState>().having(
          (s) => s.breakdownStatus,
          'breakdownStatus',
          ReportsBreakdownStatus.loading,
        ),
        isA<ReportsState>()
            .having(
              (s) => s.breakdownStatus,
              'breakdownStatus',
              ReportsBreakdownStatus.success,
            )
            .having((s) => s.breakdown, 'breakdown', lastMonthBreakdown)
            .having(
              (s) => s.breakdownPeriod,
              'breakdownPeriod',
              ReportsPeriod.last3Months,
            )
            .having((s) => s.trend, 'trend', trend),
      ],
    );

    test('a slower, superseded period switch never overwrites the newer '
        'one', () async {
      final slow = Completer<Either<Failure, CategoryBreakdown>>();
      when(
        () => getBreakdown(
          ReportsPeriod.lastMonth.range(),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => slow.future);
      when(
        () => getBreakdown(
          ReportsPeriod.last6Months.range(),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => const Right(thisMonthBreakdown));

      final cubit = build();
      addTearDown(cubit.close);
      final first = cubit.changeBreakdownPeriod(ReportsPeriod.lastMonth);
      await cubit.changeBreakdownPeriod(ReportsPeriod.last6Months);
      slow.complete(const Right(lastMonthBreakdown));
      await first;

      expect(cubit.state.breakdownPeriod, ReportsPeriod.last6Months);
      expect(cubit.state.breakdown, thisMonthBreakdown);
    });
  });

  group('ReportsPeriod.range', () {
    final reference = DateTime(2026, 2, 15);

    test('resolves each preset to its calendar span, ending today', () {
      expect(
        ReportsPeriod.thisMonth.range(reference),
        DateRange.thisMonth(reference),
      );
      expect(
        ReportsPeriod.lastMonth.range(reference),
        DateRange.lastMonth(reference),
      );
      expect(
        ReportsPeriod.last3Months.range(reference),
        DateRange(start: DateTime(2025, 12), end: reference),
      );
      expect(
        ReportsPeriod.last6Months.range(reference),
        DateRange(start: DateTime(2025, 9), end: reference),
      );
    });
  });
}
