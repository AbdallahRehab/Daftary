import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/watch_savings_overview.dart';
import 'package:daftary/features/savings/presentation/cubit/archived_goals_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/archived_goals_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/savings_test_data.dart';

/// T058 — `ArchivedGoalsCubit`: lists only archived goals and follows
/// archives/restores live.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;

  final active = testGoal(id: 'a');
  final paused = testGoal(id: 'p', name: 'Vacation', isArchived: true);

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
  });

  tearDown(() => changes.close());

  ArchivedGoalsCubit buildCubit() =>
      ArchivedGoalsCubit(WatchSavingsOverview(repository));

  SavingsOverview overviewOf(List<GoalOverviewLine> lines) =>
      SavingsOverview(goals: lines, primaryCurrency: Currency.egp);

  blocTest<ArchivedGoalsCubit, ArchivedGoalsState>(
    'reads with archived goals included and keeps only the archived ones',
    setUp: () =>
        when(
          () => repository.getSavingsOverview(includeArchived: true),
        ).thenAnswer(
          (_) async => Right(
            overviewOf([
              testOverviewLine(active, saved: 100),
              testOverviewLine(paused, saved: 200),
            ]),
          ),
        ),
    build: buildCubit,
    act: (cubit) => cubit.subscribe(),
    expect: () => [
      const ArchivedGoalsState(),
      ArchivedGoalsState(
        status: ArchivedGoalsStatus.success,
        goals: [testOverviewLine(paused, saved: 200)],
      ),
    ],
    verify: (_) => verify(
      () => repository.watchSavingsOverview(includeArchived: true),
    ).called(1),
  );

  test('live: a goal restored elsewhere leaves the list; an empty list is '
      'the empty state', () async {
    var lines = [testOverviewLine(paused)];
    when(
      () => repository.getSavingsOverview(includeArchived: true),
    ).thenAnswer((_) async => Right(overviewOf(lines)));
    final cubit = buildCubit();
    await cubit.subscribe();
    expect(cubit.state.goals, hasLength(1));

    lines = [testOverviewLine(testGoal(id: 'p', name: 'Vacation'))];
    changes.notify();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.goals, isEmpty);
    expect(cubit.state.isEmpty, isTrue);
    await cubit.close();
  });
}
