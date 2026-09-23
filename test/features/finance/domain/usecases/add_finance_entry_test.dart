import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/finance/domain/usecases/add_finance_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockFinanceRepository extends Mock implements FinanceRepository {}

void main() {
  late MockFinanceRepository repository;
  late AddFinanceEntry addFinanceEntry;

  FinanceEntry buildEntry({
    String id = 'e1',
    String idempotencyKey = 'key-1',
    String categoryId = 'seed_groceries',
    FinanceEntryType type = FinanceEntryType.expense,
    int amountMinorUnits = 15050,
    DateTime? date,
  }) {
    return FinanceEntry(
      id: id,
      idempotencyKey: idempotencyKey,
      categoryId: categoryId,
      type: type,
      amount: Money.fromMinorUnits(amountMinorUnits),
      date: date ?? DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
    );
  }

  void stubAddEntry(Either<Failure, FinanceEntry> response) {
    when(
      () => repository.addEntry(
        idempotencyKey: any(named: 'idempotencyKey'),
        categoryId: any(named: 'categoryId'),
        type: any(named: 'type'),
        amountMinorUnits: any(named: 'amountMinorUnits'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => response);
  }

  DateTime capturedDate() {
    return verify(
          () => repository.addEntry(
            idempotencyKey: any(named: 'idempotencyKey'),
            categoryId: any(named: 'categoryId'),
            type: any(named: 'type'),
            amountMinorUnits: any(named: 'amountMinorUnits'),
            date: captureAny(named: 'date'),
            note: any(named: 'note'),
          ),
        ).captured.single
        as DateTime;
  }

  setUpAll(() {
    registerFallbackValue(FinanceEntryType.expense);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockFinanceRepository();
    addFinanceEntry = AddFinanceEntry(repository);
  });

  test('rejects a zero or negative amount with a ValidationFailure '
      '(FR-003)', () async {
    stubAddEntry(
      const Left(ValidationFailure('Amount must be greater than zero')),
    );

    final result = await addFinanceEntry(
      idempotencyKey: 'key-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 0,
    );

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('rejects a category whose type does not match the entry type', () async {
    stubAddEntry(
      const Left(
        ValidationFailure(
          'Category "Salary" is a income category and cannot be used for a '
          'expense entry',
        ),
      ),
    );

    final result = await addFinanceEntry(
      idempotencyKey: 'key-1',
      // An income category used for an expense entry.
      categoryId: 'seed_salary',
      type: FinanceEntryType.expense,
      amountMinorUnits: 15050,
    );

    expect(result.isLeft(), isTrue);
    verify(
      () => repository.addEntry(
        idempotencyKey: 'key-1',
        categoryId: 'seed_salary',
        type: FinanceEntryType.expense,
        amountMinorUnits: 15050,
        date: any(named: 'date'),
        note: null,
      ),
    ).called(1);
  });

  test('defaults the date to today when none is given (FR-001)', () async {
    stubAddEntry(Right(buildEntry()));

    await addFinanceEntry(
      idempotencyKey: 'key-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 15050,
    );

    final date = capturedDate();
    final today = DateTime.now();
    expect(date.year, today.year);
    expect(date.month, today.month);
    expect(date.day, today.day);
  });

  test('accepts a future date as a planned entry', () async {
    final future = DateTime.now().add(const Duration(days: 30));
    stubAddEntry(Right(buildEntry(date: future)));

    final result = await addFinanceEntry(
      idempotencyKey: 'key-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 15050,
      date: future,
    );

    expect(result.isRight(), isTrue);
    expect(capturedDate(), future);
  });

  test('a retried call with the same idempotencyKey returns the already '
      'persisted entry rather than a second one (FR-021)', () async {
    final persisted = buildEntry();
    stubAddEntry(Right(persisted));

    final first = await addFinanceEntry(
      idempotencyKey: 'key-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 15050,
    );
    final retried = await addFinanceEntry(
      idempotencyKey: 'key-1',
      categoryId: 'seed_groceries',
      type: FinanceEntryType.expense,
      amountMinorUnits: 15050,
    );

    expect(first.toNullable()!.id, retried.toNullable()!.id);
    expect(first.toNullable(), retried.toNullable());
  });

  test('income entries go through exactly the same path as expenses, with '
      'no branching by type (FR-002)', () async {
    final income = buildEntry(
      id: 'e2',
      categoryId: 'seed_salary',
      type: FinanceEntryType.income,
      amountMinorUnits: 800000,
    );
    stubAddEntry(Right(income));

    final result = await addFinanceEntry(
      idempotencyKey: 'key-2',
      categoryId: 'seed_salary',
      type: FinanceEntryType.income,
      amountMinorUnits: 800000,
    );

    expect(result.toNullable(), income);
    // Same call shape as the expense cases above — the use case forwards
    // `type` untouched instead of taking a different branch for income.
    verify(
      () => repository.addEntry(
        idempotencyKey: 'key-2',
        categoryId: 'seed_salary',
        type: FinanceEntryType.income,
        amountMinorUnits: 800000,
        date: any(named: 'date'),
        note: null,
      ),
    ).called(1);
  });

  test('a non-positive income amount is rejected by the same rule as an '
      'expense (FR-003)', () async {
    stubAddEntry(
      const Left(ValidationFailure('Amount must be greater than zero')),
    );

    final result = await addFinanceEntry(
      idempotencyKey: 'key-3',
      categoryId: 'seed_salary',
      type: FinanceEntryType.income,
      amountMinorUnits: -1,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });
}
