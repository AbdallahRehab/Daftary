import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/budgets/domain/entities/budget_failures.dart';
import 'package:daftary/features/budgets/domain/usecases/create_budget.dart';
import 'package:daftary/features/budgets/domain/usecases/delete_budget.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/budgets_harness.dart';

/// T013 — exercised through the real repository and an in-memory database,
/// since every rule under test (one budget per month, idempotent retry)
/// is enforced there and by the schema, not in the use case.
void main() {
  late BudgetsHarness h;
  late CreateBudget createBudget;

  setUp(() async {
    h = await BudgetsHarness.open();
    createBudget = CreateBudget(h.repository);
  });

  tearDown(() => h.close());

  test('creates a budget for a month with an optional income', () async {
    final result = await createBudget(
      idempotencyKey: 'k1',
      month: '2026-03',
      expectedIncomeMinorUnits: 1500000,
    );

    final budget = result.toNullable()!;
    expect(budget.month, '2026-03');
    expect(budget.expectedIncomeMinorUnits, 1500000);
    expect(budget.idempotencyKey, 'k1');
    expect(budget.isDeleted, isFalse);
  });

  test('income is optional, and zero is a valid income', () async {
    final none = await createBudget(idempotencyKey: 'k1', month: '2026-03');
    final zero = await createBudget(
      idempotencyKey: 'k2',
      month: '2026-04',
      expectedIncomeMinorUnits: 0,
    );

    expect(none.toNullable()!.expectedIncomeMinorUnits, isNull);
    expect(zero.toNullable()!.expectedIncomeMinorUnits, 0);
  });

  test('rejects a second budget for a month that already has one, carrying '
      'the existing budget', () async {
    final first = await createBudget(idempotencyKey: 'k1', month: '2026-03');
    final second = await createBudget(idempotencyKey: 'k2', month: '2026-03');

    final failure = second.getLeft().toNullable();
    expect(failure, isA<BudgetAlreadyExistsForMonthFailure>());
    expect(
      (failure! as BudgetAlreadyExistsForMonthFailure).existing,
      first.toNullable(),
    );
    expect(await h.db.select(h.db.budgets).get(), hasLength(1));
  });

  test('a retried call with the same idempotencyKey returns the existing '
      'budget rather than failing or duplicating (FR-017)', () async {
    final first = await createBudget(
      idempotencyKey: 'k1',
      month: '2026-03',
      expectedIncomeMinorUnits: 100,
    );
    final retried = await createBudget(
      idempotencyKey: 'k1',
      month: '2026-03',
      // Deliberately different: the retry returns the persisted row
      // untouched rather than overwriting it.
      expectedIncomeMinorUnits: 999,
    );

    expect(retried.toNullable(), first.toNullable());
    expect(await h.db.select(h.db.budgets).get(), hasLength(1));
  });

  test('a month freed by deleting its budget can be budgeted again', () async {
    final first = await createBudget(idempotencyKey: 'k1', month: '2026-03');
    await DeleteBudget(h.repository)(first.toNullable()!.id);

    final again = await createBudget(idempotencyKey: 'k2', month: '2026-03');

    expect(again.isRight(), isTrue);
    // 022: the month's derived id comes back, active again.
    expect(again.toNullable()!.id, first.toNullable()!.id);
    expect(again.toNullable()!.isDeleted, isFalse);
    expect(again.toNullable()!.idempotencyKey, 'k2');
  });

  test('rejects a malformed month and a negative income', () async {
    for (final month in ['2026-3', '2026-13', '26-03', '2026-00', '']) {
      final result = await createBudget(idempotencyKey: month, month: month);
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    }
    final negative = await createBudget(
      idempotencyKey: 'k',
      month: '2026-03',
      expectedIncomeMinorUnits: -1,
    );
    expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
    expect(await h.db.select(h.db.budgets).get(), isEmpty);
  });
}
