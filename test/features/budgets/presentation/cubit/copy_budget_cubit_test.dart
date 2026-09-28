import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/budgets/domain/repositories/budgets_repository.dart';
import 'package:daftary/features/budgets/domain/usecases/copy_budget_to_month.dart';
import 'package:daftary/features/budgets/domain/usecases/get_most_recent_budget_before.dart';
import 'package:daftary/features/budgets/presentation/cubit/copy_budget_cubit.dart';
import 'package:daftary/features/budgets/presentation/cubit/copy_budget_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetsRepository extends Mock implements BudgetsRepository {}

void main() {
  late MockBudgetsRepository repository;

  final now = DateTime(2026, 9);
  Budget budget(String id, String month) => Budget(
    id: id,
    idempotencyKey: 'key-$id',
    month: month,
    createdAt: now,
    updatedAt: now,
  );

  final august = budget('b-aug', '2026-08');
  final september = budget('b-sep', '2026-09');

  setUp(() {
    repository = MockBudgetsRepository();
  });

  CopyBudgetCubit buildCubit() => CopyBudgetCubit(
    GetMostRecentBudgetBefore(repository),
    CopyBudgetToMonth(repository),
  );

  void stubSource(Budget? source) {
    when(
      () => repository.getMostRecentBudgetBefore(any()),
    ).thenAnswer((_) async => Right(source));
  }

  void stubCopy(Either<Failure, Budget> result) {
    when(
      () => repository.copyBudgetToMonth(
        idempotencyKey: any(named: 'idempotencyKey'),
        sourceBudgetId: any(named: 'sourceBudgetId'),
        targetMonth: any(named: 'targetMonth'),
      ),
    ).thenAnswer((_) async => result);
  }

  test('starts with a fresh idempotency key, before any load', () {
    final a = buildCubit();
    final b = buildCubit();
    expect(a.state.idempotencyKey, isNotEmpty);
    expect(a.state.idempotencyKey, isNot(b.state.idempotencyKey));
    expect(a.state.canCopy, isFalse);
  });

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'load() offers the most recent earlier budget as the copy source (FR-012)',
    build: buildCubit,
    setUp: () => stubSource(august),
    act: (cubit) => cubit.load('2026-09'),
    expect: () => [
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.loading)
          .having((s) => s.targetMonth, 'targetMonth', '2026-09'),
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.ready)
          .having((s) => s.source, 'source', august)
          .having((s) => s.canCopy, 'canCopy', isTrue),
    ],
    verify: (_) {
      verify(() => repository.getMostRecentBudgetBefore('2026-09')).called(1);
    },
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'load() with no earlier budget offers no copy (US4 scenario 3)',
    build: buildCubit,
    setUp: () => stubSource(null),
    act: (cubit) => cubit.load('2026-09'),
    expect: () => [
      isA<CopyBudgetState>().having(
        (s) => s.status,
        'status',
        CopyBudgetStatus.loading,
      ),
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.ready)
          .having((s) => s.hasSource, 'hasSource', isFalse)
          .having((s) => s.canCopy, 'canCopy', isFalse),
    ],
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'load() surfaces a lookup failure as loadFailure',
    build: buildCubit,
    setUp: () => when(
      () => repository.getMostRecentBudgetBefore(any()),
    ).thenAnswer((_) async => const Left(CacheFailure('db'))),
    act: (cubit) => cubit.load('2026-09'),
    expect: () => [
      isA<CopyBudgetState>().having(
        (s) => s.status,
        'status',
        CopyBudgetStatus.loading,
      ),
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.loadFailure)
          .having((s) => s.failure, 'failure', const CacheFailure('db')),
    ],
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'copy() creates the target month budget from the source, then rotates '
    'the idempotency key',
    build: buildCubit,
    setUp: () {
      stubSource(august);
      stubCopy(Right(september));
    },
    act: (cubit) async {
      await cubit.load('2026-09');
      await cubit.copy();
    },
    skip: 2,
    expect: () => [
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.copying)
          .having((s) => s.canCopy, 'canCopy', isFalse),
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.success)
          .having((s) => s.copiedBudget, 'copiedBudget', september),
    ],
    verify: (cubit) {
      final captured = verify(
        () => repository.copyBudgetToMonth(
          idempotencyKey: captureAny(named: 'idempotencyKey'),
          sourceBudgetId: 'b-aug',
          targetMonth: '2026-09',
        ),
      ).captured;
      expect(captured.single, isA<String>());
      expect(cubit.state.idempotencyKey, isNot(captured.single));
    },
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'a rapid double-tap copies exactly once (FR-017)',
    build: buildCubit,
    setUp: () {
      stubSource(august);
      final completer = Completer<Either<Failure, Budget>>();
      when(
        () => repository.copyBudgetToMonth(
          idempotencyKey: any(named: 'idempotencyKey'),
          sourceBudgetId: any(named: 'sourceBudgetId'),
          targetMonth: any(named: 'targetMonth'),
        ),
      ).thenAnswer((_) {
        Future<void>.delayed(
          Duration.zero,
          () => completer.complete(Right(september)),
        );
        return completer.future;
      });
    },
    act: (cubit) async {
      await cubit.load('2026-09');
      final first = cubit.copy();
      final second = cubit.copy();
      await Future.wait([first, second]);
    },
    verify: (cubit) {
      verify(
        () => repository.copyBudgetToMonth(
          idempotencyKey: any(named: 'idempotencyKey'),
          sourceBudgetId: any(named: 'sourceBudgetId'),
          targetMonth: any(named: 'targetMonth'),
        ),
      ).called(1);
      expect(cubit.state.status, CopyBudgetStatus.success);
    },
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'copy() before a source is loaded is a no-op',
    build: buildCubit,
    setUp: () => stubSource(null),
    act: (cubit) async {
      await cubit.load('2026-09');
      await cubit.copy();
    },
    skip: 2,
    expect: () => <CopyBudgetState>[],
    verify: (_) {
      verifyNever(
        () => repository.copyBudgetToMonth(
          idempotencyKey: any(named: 'idempotencyKey'),
          sourceBudgetId: any(named: 'sourceBudgetId'),
          targetMonth: any(named: 'targetMonth'),
        ),
      );
    },
  );

  blocTest<CopyBudgetCubit, CopyBudgetState>(
    'a failed copy keeps the source and key so the retry is the same copy',
    build: buildCubit,
    setUp: () {
      stubSource(august);
      stubCopy(
        Left(BudgetAlreadyExistsForMonthFailure('taken', existing: september)),
      );
    },
    act: (cubit) async {
      await cubit.load('2026-09');
      await cubit.copy();
      await cubit.copy();
    },
    skip: 2,
    expect: () => [
      isA<CopyBudgetState>().having(
        (s) => s.status,
        'status',
        CopyBudgetStatus.copying,
      ),
      isA<CopyBudgetState>()
          .having((s) => s.status, 'status', CopyBudgetStatus.copyFailure)
          .having(
            (s) => s.failure,
            'failure',
            isA<BudgetAlreadyExistsForMonthFailure>(),
          )
          .having((s) => s.source, 'source', august)
          .having((s) => s.canCopy, 'canCopy', isTrue),
      isA<CopyBudgetState>().having(
        (s) => s.status,
        'status',
        CopyBudgetStatus.copying,
      ),
      isA<CopyBudgetState>().having(
        (s) => s.status,
        'status',
        CopyBudgetStatus.copyFailure,
      ),
    ],
    verify: (_) {
      final keys = verify(
        () => repository.copyBudgetToMonth(
          idempotencyKey: captureAny(named: 'idempotencyKey'),
          sourceBudgetId: any(named: 'sourceBudgetId'),
          targetMonth: any(named: 'targetMonth'),
        ),
      ).captured;
      expect(keys, hasLength(2));
      expect(keys.first, keys.last);
    },
  );

  test('loading a different target month uses a fresh key', () async {
    stubSource(august);
    final cubit = buildCubit();
    await cubit.load('2026-09');
    final septemberKey = cubit.state.idempotencyKey;
    await cubit.load('2026-09');
    expect(cubit.state.idempotencyKey, septemberKey);
    await cubit.load('2026-10');
    expect(cubit.state.idempotencyKey, isNot(septemberKey));
    await cubit.close();
  });
}
