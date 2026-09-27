import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';
import 'package:daftary/features/finance/domain/entities/finance_summary.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/get_finance_summary.dart';
import 'package:daftary/features/finance/domain/usecases/watch_finance_summary.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_month_summary_cubit.dart';
import 'package:daftary/features/finance/presentation/cubit/finance_month_summary_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/conversion_fakes.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

/// 021 T038: the Overview's finance card follows entry writes live.
void main() {
  late MockFinanceRepository repository;
  late FakeTableChanges changes;
  late FakeGetConversionContext getConversionContext;

  setUp(() {
    repository = MockFinanceRepository();
    changes = FakeTableChanges();
    getConversionContext = FakeGetConversionContext();
    stubFinanceWatches(repository, changes);
  });

  tearDown(() => changes.close());

  FinanceMonthSummaryCubit buildCubit() => FinanceMonthSummaryCubit(
    WatchFinanceSummary(
      repository,
      FakeWatchConversionContext(getConversionContext),
      GetFinanceSummary(
        repository,
        getConversionContext,
        const CurrencyConverterImpl(),
      ),
    ),
  );

  blocTest<FinanceMonthSummaryCubit, FinanceMonthSummaryState>(
    'subscribe() shows this month\'s converted totals',
    build: buildCubit,
    setUp: () {
      when(() => repository.getSummaryTotals(any())).thenAnswer(
        (_) async => const Right(
          FinancePeriodTotals(
            income: [Money.egp(10000)],
            expense: [Money.egp(2500)],
          ),
        ),
      );
    },
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      isA<FinanceMonthSummaryState>()
          .having((s) => s.status, 'status', FinanceMonthSummaryStatus.success)
          .having(
            (s) => s.summary?.totalExpense,
            'totalExpense',
            const Money.egp(2500),
          ),
    ],
  );

  blocTest<FinanceMonthSummaryCubit, FinanceMonthSummaryState>(
    'an entry written elsewhere updates the totals with no reload',
    build: buildCubit,
    setUp: () {
      var expense = const Money.egp(2500);
      when(() => repository.getSummaryTotals(any())).thenAnswer(
        (_) async => Right(
          FinancePeriodTotals(
            income: const [Money.egp(10000)],
            expense: [expense],
          ),
        ),
      );
      when(() => repository.hasAnyEntry()).thenAnswer((_) async {
        expense = const Money.egp(4000);
        changes.notify();
        return const Right(true);
      });
    },
    act: (cubit) async {
      cubit.subscribe();
      await pumpEventQueue();
      // Stands in for a write on another screen.
      await repository.hasAnyEntry();
    },
    wait: const Duration(milliseconds: 10),
    verify: (cubit) =>
        expect(cubit.state.summary?.totalExpense, const Money.egp(4000)),
  );

  blocTest<FinanceMonthSummaryCubit, FinanceMonthSummaryState>(
    'a failed read hides the card',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.getSummaryTotals(any()),
      ).thenAnswer((_) async => const Left(CacheFailure('db')));
    },
    act: (cubit) => cubit.subscribe(),
    wait: const Duration(milliseconds: 10),
    verify: (cubit) =>
        expect(cubit.state.status, FinanceMonthSummaryStatus.failure),
  );
}
