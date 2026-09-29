import 'dart:async';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/restore_savings_goal.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_goal_actions_cubit.dart';
import 'package:daftary/features/savings/presentation/cubit/savings_goal_actions_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/savings_test_data.dart';

/// `SavingsGoalActionsCubit` — archive, restore and delete (FR-020/
/// FR-021), with FR-021's history block surfaced as its own outcome and
/// repeated taps ignored.
void main() {
  late MockSavingsRepository repository;
  late SavingsGoalActionsCubit cubit;

  setUp(() {
    repository = MockSavingsRepository();
    cubit = SavingsGoalActionsCubit(
      ArchiveSavingsGoal(repository),
      RestoreSavingsGoal(repository),
      DeleteSavingsGoal(repository),
    );
  });

  tearDown(() => cubit.close());

  test('archive and restore succeed through their use cases', () async {
    when(
      () => repository.archiveSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));
    when(
      () => repository.restoreSavingsGoal('g1'),
    ).thenAnswer((_) async => const Right(unit));

    expect((await cubit.archive('g1')).status, GoalActionStatus.done);
    expect((await cubit.restore('g1')).status, GoalActionStatus.done);
    expect(cubit.state.processingGoalIds, isEmpty);
  });

  test(
    'FR-021: a delete blocked by history is hasHistory, not failed',
    () async {
      when(
        () => repository.deleteSavingsGoal('g1'),
      ).thenAnswer((_) async => const Left(GoalHasHistoryFailure('history')));

      final result = await cubit.delete('g1');

      expect(result.status, GoalActionStatus.hasHistory);
      expect(result.failure, isA<GoalHasHistoryFailure>());
    },
  );

  test('any other failure is failed, carrying it', () async {
    when(
      () => repository.deleteSavingsGoal('g1'),
    ).thenAnswer((_) async => const Left(CacheFailure('disk')));

    final result = await cubit.delete('g1');

    expect(
      result,
      const GoalActionResult(GoalActionStatus.failed, CacheFailure('disk')),
    );
  });

  test('a second action on a goal while one is in flight is ignored', () async {
    final gate = Completer<Either<Failure, Unit>>();
    when(
      () => repository.archiveSavingsGoal('g1'),
    ).thenAnswer((_) => gate.future);

    final first = cubit.archive('g1');
    expect(cubit.state.isProcessing('g1'), isTrue);
    final second = await cubit.delete('g1');
    gate.complete(const Right(unit));

    expect(second.status, GoalActionStatus.ignored);
    expect((await first).status, GoalActionStatus.done);
    expect(cubit.state.isProcessing('g1'), isFalse);
    verifyNever(() => repository.deleteSavingsGoal(any()));
  });
}
