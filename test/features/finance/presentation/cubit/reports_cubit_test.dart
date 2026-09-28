import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/database/watch_tables.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:daftary/features/currency/domain/repositories/currency_repository.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:daftary/features/finance/domain/entities/category_breakdown_item.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/entities/finance_history_filter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/entities/spending_trend_point.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_category_breakdown.dart';
import 'package:daftary/features/finance/domain/usecases/watch_spending_trend.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/reports_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';

class MockWatchSpendingTrend extends Mock implements WatchSpendingTrend {}

class MockWatchCategoryBreakdown extends Mock
    implements WatchCategoryBreakdown {}

class MockFinanceRepository extends Mock implements FinanceRepository {}

class MockCurrencyRepository extends Mock implements CurrencyRepository {}

/// 013 T006 + 021 FR-031 — the Reports Cubit: loading → success/empty/
/// failure (FR-004, FR-005), a breakdown period switch that never touches
/// the trend (spec US1 AC3), and a live screen that follows changes made
/// elsewhere.
void main() {
  late MockWatchSpendingTrend watchTrend;
  late MockWatchCategoryBreakdown watchBreakdown;
  late MockFinanceRepository repository;
  late FakeTableChanges changes;

  // What the stubbed watches answer on every (re-)read.
  late Either<Failure, bool> hasAnyEntry;
  late Either<Failure, List<SpendingTrendPoint>> trendResult;
  late Either<Failure, CategoryBreakdown> Function(DateRange period)
  breakdownFor;

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

  final success = ReportsState(
    status: ReportsStatus.success,
    trend: trend,
    breakdown: thisMonthBreakdown,
    breakdownStatus: ReportsBreakdownStatus.success,
  );

  setUpAll(() {
    registerFallbackValue(DateRange.thisMonth());
  });

  setUp(() {
    watchTrend = MockWatchSpendingTrend();
    watchBreakdown = MockWatchCategoryBreakdown();
    repository = MockFinanceRepository();
    changes = FakeTableChanges();

    hasAnyEntry = right(true);
    trendResult = Right(trend);
    breakdownFor = (_) => const Right(thisMonthBreakdown);

    when(
      repository.watchHasAnyEntry,
    ).thenAnswer((_) => changes.signal().reRead(() async => hasAnyEntry));
    when(
      () => watchTrend(monthsBack: any(named: 'monthsBack')),
    ).thenAnswer((_) => changes.signal().reRead(() async => trendResult));
    when(() => watchBreakdown(any(), type: any(named: 'type'))).thenAnswer(
      (invocation) => changes.signal().reRead(
        () async =>
            breakdownFor(invocation.positionalArguments.first as DateRange),
      ),
    );
  });

  tearDown(() => changes.close());

  ReportsCubit build() => ReportsCubit(watchTrend, watchBreakdown, repository);

  group('subscribe', () {
    blocTest<ReportsCubit, ReportsState>(
      'loading → success with both the trend and the breakdown populated',
      build: build,
      act: (cubit) => cubit.subscribe(),
      expect: () => [const ReportsState(), success],
      verify: (_) {
        verify(
          () => watchTrend(monthsBack: ReportsCubit.trendMonths),
        ).called(1);
        // The breakdown is 007's own expense breakdown for this month —
        // no new aggregation (FR-003).
        verify(
          () => watchBreakdown(
            ReportsPeriod.thisMonth.range(),
            type: FinanceEntryType.expense,
          ),
        ).called(1);
      },
    );

    test('subscribes to the trend and the breakdown concurrently', () async {
      final trendGate = Completer<Either<Failure, List<SpendingTrendPoint>>>();
      final breakdownGate = Completer<Either<Failure, CategoryBreakdown>>();
      when(
        () => watchTrend(monthsBack: any(named: 'monthsBack')),
      ).thenAnswer((_) => Stream.fromFuture(trendGate.future));
      when(
        () => watchBreakdown(any(), type: any(named: 'type')),
      ).thenAnswer((_) => Stream.fromFuture(breakdownGate.future));

      final cubit = build();
      addTearDown(cubit.close);
      final pending = cubit.subscribe();
      await Future<void>.delayed(Duration.zero);

      verify(() => watchTrend(monthsBack: any(named: 'monthsBack'))).called(1);
      verify(() => watchBreakdown(any(), type: any(named: 'type'))).called(1);
      expect(cubit.state.status, ReportsStatus.loading);

      trendGate.complete(Right(trend));
      breakdownGate.complete(const Right(thisMonthBreakdown));
      await pending;
      expect(cubit.state.status, ReportsStatus.success);
    });

    blocTest<ReportsCubit, ReportsState>(
      'the true empty state when no finance entry exists anywhere (FR-004)',
      setUp: () => hasAnyEntry = right(false),
      build: build,
      act: (cubit) => cubit.subscribe(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>()
            .having((s) => s.status, 'status', ReportsStatus.empty)
            .having((s) => s.isEmpty, 'isEmpty', isTrue),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed trend read is an error state with retry (FR-005)',
      setUp: () => trendResult = const Left(failure),
      build: build,
      act: (cubit) => cubit.subscribe(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>()
            .having((s) => s.status, 'status', ReportsStatus.failure)
            .having((s) => s.failure, 'failure', failure),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'a failed breakdown read is an error state too — never a half screen',
      setUp: () => breakdownFor = (_) => const Left(failure),
      build: build,
      act: (cubit) => cubit.subscribe(),
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
      setUp: () => hasAnyEntry = const Left(failure),
      build: build,
      act: (cubit) => cubit.subscribe(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>().having(
          (s) => s.status,
          'status',
          ReportsStatus.failure,
        ),
      ],
    );

    test(
      'retrying after a failure (resubscribe) recovers to success',
      () async {
        trendResult = const Left(failure);
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.subscribe();
        expect(cubit.state.status, ReportsStatus.failure);

        trendResult = Right(trend);
        await cubit.resubscribe();
        expect(cubit.state.status, ReportsStatus.success);
        expect(cubit.state.trend, trend);
        expect(cubit.state.failure, isNull);
      },
    );

    test('resubscribing keeps the selected breakdown period', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();
      await cubit.changeBreakdownPeriod(ReportsPeriod.last3Months);

      await cubit.resubscribe();

      expect(cubit.state.breakdownPeriod, ReportsPeriod.last3Months);
      verify(
        () => watchBreakdown(
          ReportsPeriod.last3Months.range(),
          type: FinanceEntryType.expense,
        ),
      ).called(2);
    });

    test('close cancels every subscription', () async {
      final cubit = build();
      await cubit.subscribe();
      await cubit.close();

      // Nothing is listening any more, so a change reaches nobody (and
      // emitting on a closed cubit would throw).
      trendResult = const Left(failure);
      changes.notify();
      await pumpEventQueue();
      expect(cubit.state, success);
    });
  });

  group('changeBreakdownPeriod', () {
    test('re-subscribes only the breakdown for the new period; the trend is '
        'untouched (spec US1 AC3)', () async {
      breakdownFor = (period) => period == ReportsPeriod.lastMonth.range()
          ? const Right(lastMonthBreakdown)
          : const Right(thisMonthBreakdown);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();
      clearInteractions(watchTrend);
      clearInteractions(repository);
      final states = <ReportsState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);

      await cubit.changeBreakdownPeriod(ReportsPeriod.lastMonth);

      expect(states, [
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
      ]);
      verifyNever(() => watchTrend(monthsBack: any(named: 'monthsBack')));
      verifyNever(repository.watchHasAnyEntry);
      verify(
        () => watchBreakdown(
          ReportsPeriod.lastMonth.range(),
          type: FinanceEntryType.expense,
        ),
      ).called(1);
    });

    test('a failed breakdown switch fails only the breakdown section; the '
        'trend stays on screen and retryBreakdown recovers it', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();

      breakdownFor = (_) => const Left(failure);
      await cubit.changeBreakdownPeriod(ReportsPeriod.last3Months);
      expect(cubit.state.status, ReportsStatus.success);
      expect(cubit.state.trend, trend);
      expect(cubit.state.breakdownStatus, ReportsBreakdownStatus.failure);

      breakdownFor = (_) => const Right(lastMonthBreakdown);
      final states = <ReportsState>[];
      final subscription = cubit.stream.listen(states.add);
      addTearDown(subscription.cancel);
      await cubit.retryBreakdown();

      expect(states, [
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
      ]);
    });

    test('a slower, superseded period switch never overwrites the newer '
        'one', () async {
      final slow = Completer<Either<Failure, CategoryBreakdown>>();
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();
      when(
        () => watchBreakdown(
          ReportsPeriod.lastMonth.range(),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) => Stream.fromFuture(slow.future));

      final first = cubit.changeBreakdownPeriod(ReportsPeriod.lastMonth);
      await cubit.changeBreakdownPeriod(ReportsPeriod.thisMonth);
      slow.complete(const Right(lastMonthBreakdown));
      await first;
      await pumpEventQueue();

      expect(cubit.state.breakdownPeriod, ReportsPeriod.thisMonth);
      expect(cubit.state.breakdown, thisMonthBreakdown);
    });

    test('a change elsewhere updates the newly selected period only', () async {
      var lastMonth = lastMonthBreakdown;
      breakdownFor = (period) => period == ReportsPeriod.lastMonth.range()
          ? Right(lastMonth)
          : const Right(thisMonthBreakdown);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();
      await cubit.changeBreakdownPeriod(ReportsPeriod.lastMonth);
      clearInteractions(watchBreakdown);

      lastMonth = thisMonthBreakdown;
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state.breakdownPeriod, ReportsPeriod.lastMonth);
      expect(cubit.state.breakdown, thisMonthBreakdown);
      // Updated through the existing subscription, not a new one.
      verifyNever(() => watchBreakdown(any(), type: any(named: 'type')));
    });
  });

  group('live (021 FR-031)', () {
    test(
      'a change elsewhere updates the open screen with no loading state',
      () async {
        final cubit = build();
        addTearDown(cubit.close);
        await cubit.subscribe();
        final states = <ReportsState>[];
        final subscription = cubit.stream.listen(states.add);
        addTearDown(subscription.cancel);

        final newerTrend = [
          ...trend.take(1),
          SpendingTrendPoint(
            period: trend.last.period,
            totalIncomeMinorUnits: 1000000,
            totalExpenseMinorUnits: 200050,
            netMinorUnits: 799950,
          ),
        ];
        trendResult = Right(newerTrend);
        breakdownFor = (_) => const Right(lastMonthBreakdown);
        changes.notify();
        await pumpEventQueue();

        expect(cubit.state.status, ReportsStatus.success);
        expect(cubit.state.trend, newerTrend);
        expect(cubit.state.breakdown, lastMonthBreakdown);
        expect(
          states.map((s) => s.status),
          everyElement(ReportsStatus.success),
        );
        expect(
          states.map((s) => s.breakdownStatus),
          isNot(contains(ReportsBreakdownStatus.loading)),
        );
      },
    );

    test('the first entry recorded elsewhere turns the empty state into the '
        'report', () async {
      hasAnyEntry = right(false);
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();
      expect(cubit.state.status, ReportsStatus.empty);

      hasAnyEntry = right(true);
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state, success);
    });

    test('a breakdown failing later stays inside its card', () async {
      final cubit = build();
      addTearDown(cubit.close);
      await cubit.subscribe();

      breakdownFor = (_) => const Left(failure);
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state.status, ReportsStatus.success);
      expect(cubit.state.trend, trend);
      expect(cubit.state.breakdownStatus, ReportsBreakdownStatus.failure);
    });
  });

  group('live, through the real watch use cases (021 FR-031)', () {
    late MockCurrencyRepository currency;
    late List<ExchangeRate> rates;
    late FinancePeriodTotals thisMonthTotals;
    late List<CategoryCurrencyTotals> thisMonthCategories;

    ExchangeRate usdRate(double rate) => ExchangeRate(
      currency: Currency.usd,
      relativeTo: Currency.egp,
      rateMicros: ExchangeRate.toMicros(rate),
      lastUpdatedAt: DateTime(2026),
    );

    setUp(() {
      currency = MockCurrencyRepository();
      rates = [];
      thisMonthTotals = const FinancePeriodTotals(
        income: [Money.egp(1000000)],
        expense: [Money.egp(4575)],
      );
      thisMonthCategories = const [
        CategoryCurrencyTotals(
          categoryId: 'seed_groceries',
          categoryName: 'Groceries',
          icon: 'groceries',
          totals: [Money.egp(4575)],
        ),
      ];
      stubFinanceWatches(repository, changes);
      stubCurrencyWatches(currency, changes);
      when(currency.getPrimaryCurrency).thenAnswer(
        (_) async =>
            const Right(PrimaryCurrencySetting(currency: Currency.egp)),
      );
      when(currency.getExchangeRates).thenAnswer((_) async => Right(rates));
      when(
        () => repository.hasAnyEntry(),
      ).thenAnswer((_) async => const Right(true));
      when(() => repository.getSummaryTotals(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first == DateRange.thisMonth()
            ? Right(thisMonthTotals)
            : const Right(FinancePeriodTotals(income: [], expense: [])),
      );
      when(
        () => repository.getCategoryTotals(any(), type: any(named: 'type')),
      ).thenAnswer((_) async => Right(thisMonthCategories));
    });

    ReportsCubit buildLive() {
      final context = GetConversionContext(currency);
      final watchContext = WatchConversionContext(currency);
      const converter = CurrencyConverterImpl();
      return ReportsCubit(
        WatchSpendingTrend(
          repository,
          watchContext,
          GetFinanceSummary(repository, context, converter),
        ),
        WatchCategoryBreakdown(
          repository,
          watchContext,
          GetCategoryBreakdown(repository, context, converter),
        ),
        repository,
      );
    }

    test('an entry added elsewhere updates the trend and the breakdown '
        'with no reload', () async {
      final cubit = buildLive();
      addTearDown(cubit.close);
      await cubit.subscribe();
      expect(cubit.state.trend.last.totalExpenseMinorUnits, 4575);
      expect(cubit.state.breakdown.items.single.total, const Money.egp(4575));

      thisMonthTotals = const FinancePeriodTotals(
        income: [Money.egp(1000000)],
        expense: [Money.egp(14575)],
      );
      thisMonthCategories = const [
        CategoryCurrencyTotals(
          categoryId: 'seed_fuel',
          categoryName: 'Fuel',
          icon: 'fuel',
          totals: [Money.egp(10000)],
        ),
        CategoryCurrencyTotals(
          categoryId: 'seed_groceries',
          categoryName: 'Groceries',
          icon: 'groceries',
          totals: [Money.egp(4575)],
        ),
      ];
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state.status, ReportsStatus.success);
      expect(cubit.state.trend.last.totalExpenseMinorUnits, 14575);
      expect(cubit.state.breakdown.items.map((i) => i.categoryId), [
        'seed_fuel',
        'seed_groceries',
      ]);
    });

    test('a category renamed elsewhere relabels its breakdown row', () async {
      final cubit = buildLive();
      addTearDown(cubit.close);
      await cubit.subscribe();

      thisMonthCategories = const [
        CategoryCurrencyTotals(
          categoryId: 'seed_groceries',
          categoryName: 'Supermarket',
          icon: 'groceries',
          totals: [Money.egp(4575)],
        ),
      ];
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state.breakdown.items.single.categoryName, 'Supermarket');
    });

    test('a rate set elsewhere clears the rate-needed state and converts '
        'the figures (018 FR-009)', () async {
      thisMonthTotals = const FinancePeriodTotals(
        income: [],
        expense: [Money.egp(4575), Money.fromMinorUnits(2000, Currency.usd)],
      );
      thisMonthCategories = const [
        CategoryCurrencyTotals(
          categoryId: 'seed_groceries',
          categoryName: 'Groceries',
          icon: 'groceries',
          totals: [Money.egp(4575), Money.fromMinorUnits(2000, Currency.usd)],
        ),
      ];
      final cubit = buildLive();
      addTearDown(cubit.close);
      await cubit.subscribe();
      // The trend needs the USD rate: a screen-level rate banner.
      expect(cubit.state.status, ReportsStatus.failure);
      expect(cubit.state.failure, isA<RatesMissingFailure>());

      rates = [usdRate(50)];
      changes.notify();
      await pumpEventQueue();

      expect(cubit.state.status, ReportsStatus.success);
      expect(cubit.state.failure, isNull);
      // 45.75 EGP + 20.00 USD × 50.
      expect(cubit.state.trend.last.totalExpenseMinorUnits, 4575 + 100000);
      expect(cubit.state.breakdown.isBlocked, isFalse);
      expect(
        cubit.state.breakdown.items.single.total,
        const Money.egp(4575 + 100000),
      );

      // A rate edited elsewhere re-converts the open screen too.
      rates = [usdRate(60)];
      changes.notify();
      await pumpEventQueue();
      expect(cubit.state.trend.last.totalExpenseMinorUnits, 4575 + 120000);
    });

    test(
      'a primary currency changed elsewhere re-converts every figure',
      () async {
        rates = [
          ExchangeRate(
            currency: Currency.egp,
            relativeTo: Currency.usd,
            rateMicros: ExchangeRate.toMicros(0.02),
            lastUpdatedAt: DateTime(2026),
          ),
        ];
        final cubit = buildLive();
        addTearDown(cubit.close);
        await cubit.subscribe();
        expect(cubit.state.trend.last.currency, Currency.egp);

        when(currency.getPrimaryCurrency).thenAnswer(
          (_) async =>
              const Right(PrimaryCurrencySetting(currency: Currency.usd)),
        );
        changes.notify();
        await pumpEventQueue();

        expect(cubit.state.status, ReportsStatus.success);
        expect(cubit.state.trend.last.currency, Currency.usd);
        expect(cubit.state.breakdown.currency, Currency.usd);
      },
    );
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
