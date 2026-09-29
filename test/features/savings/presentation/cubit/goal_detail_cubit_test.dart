import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/watch_goal_detail.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/goal_detail_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/watch_stubs.dart';
import '../../helpers/savings_test_data.dart';

/// T035 — `GoalDetailCubit`: loads and live-updates progress (a change
/// arriving through `watchGoalDetail`), deletes entries with duplicate-tap
/// protection, and exposes the archived and deleted-goal states.
void main() {
  late MockSavingsRepository repository;
  late FakeTableChanges changes;

  final goal = testGoal(target: 1000000, monthly: 100000);
  final first = testDetail(goal, history: [testEntry(amount: 200000)]);
  final second = testDetail(
    goal,
    history: [
      testEntry(amount: 200000),
      testEntry(id: 'c2', amount: 300000),
    ],
  );

  setUp(() {
    repository = MockSavingsRepository();
    changes = FakeTableChanges();
    stubSavingsWatches(repository, changes);
  });

  tearDown(() => changes.close());

  GoalDetailCubit buildCubit() => GoalDetailCubit(
    WatchGoalDetail(repository),
    DeleteContribution(repository),
  );

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  blocTest<GoalDetailCubit, GoalDetailState>(
    'subscribe emits loading then success with the goal detail',
    setUp: () => when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(first)),
    build: buildCubit,
    act: (cubit) => cubit.subscribe('g1'),
    expect: () => [
      const GoalDetailState(goalId: 'g1'),
      GoalDetailState(
        goalId: 'g1',
        status: GoalDetailStatus.success,
        detail: first,
      ),
    ],
    verify: (cubit) {
      expect(cubit.state.detail!.progress.currentAmountMinorUnits, 200000);
      expect(cubit.state.isEmpty, isFalse);
    },
  );

  test('live: an entry logged elsewhere re-emits the recalculated detail '
      'with no reload', () async {
    var current = first;
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(current));
    final cubit = buildCubit();
    await cubit.subscribe('g1');
    expect(cubit.state.detail!.progress.currentAmountMinorUnits, 200000);

    current = second;
    changes.notify();
    await flush();

    expect(cubit.state.detail, second);
    expect(cubit.state.detail!.progress.currentAmountMinorUnits, 500000);
    await cubit.close();
  });

  test('close cancels the subscription', () async {
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(first));
    final cubit = buildCubit();
    await cubit.subscribe('g1');
    await cubit.close();

    changes.notify();
    await flush();
    verify(() => repository.getGoalDetail('g1')).called(1);
  });

  blocTest<GoalDetailCubit, GoalDetailState>(
    'a goal with no entries is the history empty state, not an error',
    setUp: () => when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(testDetail(goal))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe('g1'),
    verify: (cubit) {
      expect(cubit.state.status, GoalDetailStatus.success);
      expect(cubit.state.isEmpty, isTrue);
    },
  );

  blocTest<GoalDetailCubit, GoalDetailState>(
    'a load failure is the error state',
    setUp: () => when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => const Left(CacheFailure('boom'))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe('g1'),
    verify: (cubit) {
      expect(cubit.state.status, GoalDetailStatus.failure);
      expect(cubit.state.failure, const CacheFailure('boom'));
      expect(cubit.state.isDeleted, isFalse);
    },
  );

  test('a goal on screen that stops existing marks the page deleted', () async {
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(first));
    final cubit = buildCubit();
    await cubit.subscribe('g1');

    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => const Left(GoalNotFoundFailure('gone')));
    changes.notify();
    await flush();

    expect(cubit.state.isDeleted, isTrue);
    await cubit.close();
  });

  blocTest<GoalDetailCubit, GoalDetailState>(
    'an archived goal is exposed as archived',
    setUp: () => when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(testDetail(testGoal(isArchived: true)))),
    build: buildCubit,
    act: (cubit) => cubit.subscribe('g1'),
    verify: (cubit) => expect(cubit.state.isArchived, isTrue),
  );

  group('deleteEntry (FR-009)', () {
    setUp(
      () => when(
        () => repository.getGoalDetail('g1'),
      ).thenAnswer((_) async => Right(first)),
    );

    test('deletes through the use case; the live read recalculates', () async {
      when(
        () => repository.deleteContribution('c1'),
      ).thenAnswer((_) async => const Right(unit));
      final cubit = buildCubit();
      await cubit.subscribe('g1');

      expect(await cubit.deleteEntry('c1'), isTrue);

      verify(() => repository.deleteContribution('c1')).called(1);
      expect(cubit.state.deletingEntryIds, isEmpty);
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a rejected delete is surfaced without losing the detail', () async {
      when(() => repository.deleteContribution('c1')).thenAnswer(
        (_) async => const Left(
          WithdrawalExceedsBalanceFailure('neg', availableMinorUnits: 10),
        ),
      );
      final cubit = buildCubit();
      await cubit.subscribe('g1');

      expect(await cubit.deleteEntry('c1'), isFalse);

      expect(cubit.state.failure, isA<WithdrawalExceedsBalanceFailure>());
      expect(cubit.state.detail, first);
      cubit.failureShown();
      expect(cubit.state.failure, isNull);
      await cubit.close();
    });

    test('a double-tap deletes once', () async {
      final pending = Completer<Either<Failure, Unit>>();
      when(
        () => repository.deleteContribution('c1'),
      ).thenAnswer((_) => pending.future);
      final cubit = buildCubit();
      await cubit.subscribe('g1');

      final a = cubit.deleteEntry('c1');
      final b = cubit.deleteEntry('c1');
      pending.complete(const Right(unit));

      expect(await a, isTrue);
      expect(await b, isFalse);
      verify(() => repository.deleteContribution('c1')).called(1);
      await cubit.close();
    });
  });

  test('entries are shown in the order the repository returns them '
      '(date, then creation — FR-008)', () async {
    final ordered = testDetail(
      goal,
      history: [
        testEntry(id: 'a', date: DateTime(2026, 8, 1)),
        testEntry(
          id: 'b',
          type: ContributionType.withdrawal,
          amount: 10,
          date: DateTime(2026, 9, 1),
        ),
      ],
    );
    when(
      () => repository.getGoalDetail('g1'),
    ).thenAnswer((_) async => Right(ordered));
    final cubit = buildCubit();
    await cubit.subscribe('g1');

    expect(cubit.state.detail!.history.map((e) => e.id), ['a', 'b']);
    await cubit.close();
  });
}
