import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/watch_savings_overview.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_overview_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_overview_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/savings_test_data.dart';

/// T058 — `SavingsOverviewCubit`: loads the active overview, live-updates
/// through `watchSavingsOverview`, and exposes the empty and
/// incomplete-total states.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;

  final egpGoal = testGoal(id: 'g1', target: 1000000);
  final usdGoal = testGoal(id: 'g2', currency: Currency.usd, target: 100000);
  final complete = SavingsOverview(
    primaryCurrency: Currency.egp,
    goals: [
      testOverviewLine(egpGoal, saved: 100000),
      testOverviewLine(usdGoal, saved: 10000, converted: 500000),
    ],
  );
  final incomplete = SavingsOverview(
    primaryCurrency: Currency.egp,
    goals: [
      testOverviewLine(egpGoal, saved: 100000),
      testOverviewLine(usdGoal, saved: 10000, missing: [Currency.usd]),
    ],
  );
  const empty = SavingsOverview(goals: [], primaryCurrency: Currency.egp);

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
  });

  tearDown(() => changes.close());

  SavingsOverviewCubit buildCubit() =>
      SavingsOverviewCubit(WatchSavingsOverview(repository));

  void answer(SavingsOverview Function() overview) => when(
    () => repository.getSavingsOverview(
      includeArchived: any(named: 'includeArchived'),
    ),
  ).thenAnswer((_) async => Right(overview()));

  blocTest<SavingsOverviewCubit, SavingsOverviewState>(
    'subscribe emits loading then the active overview',
    setUp: () => answer(() => complete),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(),
    expect: () => [
      const SavingsOverviewState(),
      SavingsOverviewState(
        status: SavingsOverviewStatus.success,
        overview: complete,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.overview!.totalSavedMinorUnits, 600000);
      expect(cubit.state.isIncomplete, isFalse);
      expect(cubit.state.isEmpty, isFalse);
      verify(() => repository.watchSavingsOverview()).called(1);
    },
  );

  blocTest<SavingsOverviewCubit, SavingsOverviewState>(
    'FR-019: a missing rate yields the incomplete-total state naming it',
    setUp: () => answer(() => incomplete),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(),
    skip: 1,
    expect: () => [
      SavingsOverviewState(
        status: SavingsOverviewStatus.success,
        overview: incomplete,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.isIncomplete, isTrue);
      expect(cubit.state.overview!.missingRatesFor, [Currency.usd]);
      expect(cubit.state.overview!.totalSavedMinorUnits, 100000);
    },
  );

  blocTest<SavingsOverviewCubit, SavingsOverviewState>(
    'FR-023: no goals is the empty state',
    setUp: () => answer(() => empty),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(),
    verify: (cubit) => expect(cubit.state.isEmpty, isTrue),
  );

  test('live: a rate set elsewhere re-emits the completed total with no '
      'reload', () async {
    var current = incomplete;
    answer(() => current);
    final cubit = buildCubit();
    await cubit.subscribe();
    expect(cubit.state.isIncomplete, isTrue);

    current = complete;
    changes.notify();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isIncomplete, isFalse);
    expect(cubit.state.overview!.totalSavedMinorUnits, 600000);
    await cubit.close();
  });

  blocTest<SavingsOverviewCubit, SavingsOverviewState>(
    'a load failure is the failure state',
    setUp: () => when(
      () => repository.getSavingsOverview(
        includeArchived: any(named: 'includeArchived'),
      ),
    ).thenAnswer((_) async => const Left(CacheFailure('boom'))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(),
    skip: 1,
    expect: () => [
      const SavingsOverviewState(
        status: SavingsOverviewStatus.failure,
        failure: CacheFailure('boom'),
      ),
    ],
  );
}
