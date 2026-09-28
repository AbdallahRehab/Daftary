import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/add_participant_contribution.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late AddParticipantContribution addParticipantContribution;

  MoneyTransaction buildContribution({
    String id = 't1',
    String idempotencyKey = 'key-1',
    String personId = 'p1',
    String occasionId = 'o1',
    int amountMinorUnits = 50000,
    TransactionDirection direction = TransactionDirection.received,
    bool countsTowardBalance = true,
  }) {
    return MoneyTransaction(
      id: id,
      idempotencyKey: idempotencyKey,
      personId: personId,
      amount: Money.egp(amountMinorUnits),
      direction: direction,
      kind: TransactionKind.occasionContribution,
      date: DateTime(2026, 3, 14),
      createdAt: DateTime(2026, 3, 14),
      occasionId: occasionId,
      countsTowardBalance: countsTowardBalance,
    );
  }

  void stubAdd(Either<Failure, MoneyTransaction> response) {
    when(
      () => repository.addParticipantContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        occasionId: any(named: 'occasionId'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        countsTowardBalance: any(named: 'countsTowardBalance'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => response);
  }

  Future<Either<Failure, MoneyTransaction>> add({
    String idempotencyKey = 'key-1',
    String occasionId = 'o1',
    String personId = 'p1',
    int amountMinorUnits = 50000,
    TransactionDirection direction = TransactionDirection.received,
    bool? countsTowardBalance,
    String? note,
  }) {
    return addParticipantContribution(
      idempotencyKey: idempotencyKey,
      occasionId: occasionId,
      personId: personId,
      amount: Money.egp(amountMinorUnits),
      direction: direction,
      date: DateTime(2026, 3, 14),
      countsTowardBalance: countsTowardBalance,
      note: note,
    );
  }

  setUpAll(() {
    registerFallbackValue(const Money.egp(0));
    registerFallbackValue(TransactionDirection.received);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockOccasionsRepository();
    addParticipantContribution = AddParticipantContribution(repository);
  });

  test('forwards the repository ValidationFailure for a zero amount '
      '(FR-004)', () async {
    stubAdd(const Left(ValidationFailure('Amount must be greater than zero')));

    final result = await add(amountMinorUnits: 0);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('forwards the repository ValidationFailure for a negative amount '
      '(FR-004)', () async {
    stubAdd(const Left(ValidationFailure('Amount must be greater than zero')));

    final result = await add(amountMinorUnits: -2500);

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('records the contribution as an occasionContribution carrying the '
      'occasionId and personId (FR-005)', () async {
    stubAdd(Right(buildContribution()));

    final result = await add(occasionId: 'o1', personId: 'p1');

    final transaction = result.toNullable()!;
    expect(transaction.kind, TransactionKind.occasionContribution);
    expect(transaction.isOccasionContribution, isTrue);
    expect(transaction.occasionId, 'o1');
    expect(transaction.personId, 'p1');
    verify(
      () => repository.addParticipantContribution(
        idempotencyKey: 'key-1',
        occasionId: 'o1',
        personId: 'p1',
        amount: const Money.egp(50000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
        countsTowardBalance: null,
        note: null,
      ),
    ).called(1);
  });

  test('passes countsTowardBalance as null so the repository applies the '
      "occasion type's default (FR-018)", () async {
    // Under a condolence occasion that default is `false`.
    stubAdd(Right(buildContribution(countsTowardBalance: false)));

    final result = await add();

    expect(result.toNullable()!.countsTowardBalance, isFalse);
    verify(
      () => repository.addParticipantContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        occasionId: any(named: 'occasionId'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        // Never substituted with a guessed `true`/`false` here — only the
        // repository knows the parent occasion's type.
        countsTowardBalance: null,
        note: any(named: 'note'),
      ),
    ).called(1);
  });

  test('an explicit countsTowardBalance override reaches the repository '
      'and wins over the condolence default (FR-018)', () async {
    stubAdd(Right(buildContribution(countsTowardBalance: true)));

    final result = await add(countsTowardBalance: true);

    expect(result.toNullable()!.countsTowardBalance, isTrue);
    verify(
      () => repository.addParticipantContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        occasionId: any(named: 'occasionId'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        countsTowardBalance: true,
        note: any(named: 'note'),
      ),
    ).called(1);
  });

  test('an explicit false override is forwarded for a non-condolence '
      'occasion too (FR-018)', () async {
    stubAdd(Right(buildContribution(countsTowardBalance: false)));

    await add(countsTowardBalance: false);

    verify(
      () => repository.addParticipantContribution(
        idempotencyKey: any(named: 'idempotencyKey'),
        occasionId: any(named: 'occasionId'),
        personId: any(named: 'personId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        countsTowardBalance: false,
        note: any(named: 'note'),
      ),
    ).called(1);
  });

  test('allows a second contribution for the same person in the same '
      'occasion (FR-006)', () async {
    stubAdd(Right(buildContribution()));
    await add(idempotencyKey: 'key-1');

    stubAdd(Right(buildContribution(id: 't2', idempotencyKey: 'key-2')));
    final topUp = await add(idempotencyKey: 'key-2', amountMinorUnits: 10000);

    expect(topUp.toNullable()!.id, 't2');
    expect(topUp.toNullable()!.personId, 'p1');
    expect(topUp.toNullable()!.occasionId, 'o1');
  });

  test('a retried call with the same idempotencyKey returns the existing '
      'row rather than a second contribution (FR-019)', () async {
    stubAdd(Right(buildContribution()));

    final first = await add(idempotencyKey: 'key-1');
    final retried = await add(idempotencyKey: 'key-1');

    expect(first.toNullable()!.id, retried.toNullable()!.id);
    expect(first.toNullable(), retried.toNullable());
  });

  test('surfaces an unknown occasion as an OccasionNotFoundFailure', () async {
    stubAdd(const Left(OccasionNotFoundFailure('Occasion no longer exists')));

    final result = await add(occasionId: 'gone');

    expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
  });

  test('forwards a given-direction contribution untouched', () async {
    stubAdd(Right(buildContribution(direction: TransactionDirection.given)));

    final result = await add(direction: TransactionDirection.given);

    expect(result.toNullable()!.direction, TransactionDirection.given);
  });
}
