import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/overview_summary.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:daftary/features/transactions/domain/usecases/get_overview.dart';
import 'package:daftary/features/transactions/presentation/cubit/overview_cubit.dart';
import 'package:daftary/features/transactions/presentation/cubit/overview_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionsRepository extends Mock
    implements TransactionsRepository {}

void main() {
  late MockTransactionsRepository repository;

  setUp(() {
    repository = MockTransactionsRepository();
  });

  OverviewCubit buildCubit() => OverviewCubit(GetOverview(repository));

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

  blocTest<OverviewCubit, OverviewState>(
    'load() reflects the current totals immediately (FR-014, AC2)',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.getOverview(),
      ).thenAnswer((_) async => const Right(withBalances));
    },
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<OverviewState>().having(
        (s) => s.status,
        'status',
        OverviewStatus.loading,
      ),
      isA<OverviewState>()
          .having((s) => s.status, 'status', OverviewStatus.success)
          .having(
            (s) => s.summary?.totalOwedToUser,
            'summary.totalOwedToUser',
            const Money.egp(150000),
          )
          .having((s) => s.isAllSettled, 'isAllSettled', isFalse),
    ],
  );

  blocTest<OverviewCubit, OverviewState>(
    'a second load() (e.g. after a transaction changes elsewhere) refreshes the totals',
    build: buildCubit,
    act: (cubit) async {
      when(
        () => repository.getOverview(),
      ).thenAnswer((_) async => const Right(withBalances));
      await cubit.load();
      when(
        () => repository.getOverview(),
      ).thenAnswer((_) async => const Right(allSettled));
      await cubit.load();
    },
    verify: (cubit) {
      expect(cubit.state.isAllSettled, isTrue);
    },
  );

  blocTest<OverviewCubit, OverviewState>(
    'exposes an explicit "all settled" state distinct from loading/empty when there are no outstanding balances (AC3)',
    build: buildCubit,
    setUp: () {
      when(
        () => repository.getOverview(),
      ).thenAnswer((_) async => const Right(allSettled));
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, OverviewStatus.success);
      expect(cubit.state.isAllSettled, isTrue);
    },
  );

  blocTest<OverviewCubit, OverviewState>(
    'a blocked overview (missing rate) loads successfully, naming the '
    'currency, and is not "all settled" (018 FR-009)',
    build: buildCubit,
    setUp: () {
      when(() => repository.getOverview()).thenAnswer(
        (_) async => const Right(
          OverviewSummary(
            totalOwedToUser: null,
            totalUserOwes: Money.egp(0),
            peopleTheyOweYou: [
              PersonSummary(
                personId: 'p1',
                name: 'Ahmed',
                net: null,
                isArchived: false,
                nativeNets: [Money.fromMinorUnits(500, Currency.usd)],
                missingRatesFor: [Currency.usd],
              ),
            ],
            peopleYouOweThem: [],
            settledCount: 0,
            missingRatesFor: [Currency.usd],
          ),
        ),
      );
    },
    act: (cubit) => cubit.load(),
    verify: (cubit) {
      expect(cubit.state.status, OverviewStatus.success);
      expect(cubit.state.isAllSettled, isFalse);
      expect(cubit.state.summary!.isBlocked, isTrue);
      expect(cubit.state.summary!.missingRatesFor, [Currency.usd]);
      expect(cubit.state.summary!.totalOwedToUser, isNull);
    },
  );
}
