import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/edit_participant_contribution.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_participant_contribution.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late EditParticipantContribution editParticipantContribution;
  late RemoveParticipantContribution removeParticipantContribution;

  MoneyTransaction buildContribution({
    int amountMinorUnits = 50000,
    TransactionDirection direction = TransactionDirection.received,
    DateTime? date,
    String? note,
    DateTime? editedAt,
    DateTime? deletedAt,
  }) {
    return MoneyTransaction(
      id: 't1',
      idempotencyKey: 'key-1',
      personId: 'p1',
      amount: Money.fromMinorUnits(amountMinorUnits),
      direction: direction,
      kind: TransactionKind.occasionContribution,
      date: date ?? DateTime(2026, 3, 14),
      createdAt: DateTime(2026, 3, 14),
      note: note,
      occasionId: 'o1',
      editedAt: editedAt,
      deletedAt: deletedAt,
    );
  }

  void stubEdit(Either<Failure, MoneyTransaction> response) {
    when(
      () => repository.editParticipantContribution(
        transactionId: any(named: 'transactionId'),
        amount: any(named: 'amount'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => response);
  }

  void stubRemove(Either<Failure, Unit> response) {
    when(
      () => repository.removeParticipantContribution(any()),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(const Money.fromMinorUnits(0));
    registerFallbackValue(TransactionDirection.received);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockOccasionsRepository();
    editParticipantContribution = EditParticipantContribution(repository);
    removeParticipantContribution = RemoveParticipantContribution(repository);
  });

  group('EditParticipantContribution', () {
    test('updates the single underlying MoneyTransaction, keeping its id, '
        'person, occasion and kind (FR-010)', () async {
      stubEdit(
        Right(
          buildContribution(
            amountMinorUnits: 75000,
            note: 'Topped up in cash',
            editedAt: DateTime(2026, 3, 15),
          ),
        ),
      );

      final result = await editParticipantContribution(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(75000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
        note: 'Topped up in cash',
      );

      final updated = result.toNullable()!;
      // Same row, new values — not a new record standing beside the old one.
      expect(updated.id, 't1');
      expect(updated.personId, 'p1');
      expect(updated.occasionId, 'o1');
      expect(updated.kind, TransactionKind.occasionContribution);
      expect(updated.amount, const Money.fromMinorUnits(75000));
      expect(updated.note, 'Topped up in cash');
      expect(updated.isEdited, isTrue);
    });

    test('flips the direction on the same row rather than creating an '
        'offsetting one (FR-010)', () async {
      stubEdit(Right(buildContribution(direction: TransactionDirection.given)));

      final result = await editParticipantContribution(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(50000),
        direction: TransactionDirection.given,
        date: DateTime(2026, 3, 14),
      );

      expect(result.toNullable()!.id, 't1');
      expect(result.toNullable()!.direction, TransactionDirection.given);
      verify(
        () => repository.editParticipantContribution(
          transactionId: 't1',
          amount: const Money.fromMinorUnits(50000),
          direction: TransactionDirection.given,
          date: DateTime(2026, 3, 14),
          note: null,
        ),
      ).called(1);
      // Exactly one write: an edit is never add + remove under the hood.
      verifyNoMoreInteractions(repository);
    });

    test('edits by transactionId, so the occasion screen and the person '
        'profile act on one record (FR-010)', () async {
      stubEdit(Right(buildContribution(amountMinorUnits: 60000)));

      // The occasion detail screen edits it…
      await editParticipantContribution(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(60000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
      );
      // …and the person's own profile edits "its" copy — the same id.
      await editParticipantContribution(
        transactionId: 't1',
        amount: const Money.fromMinorUnits(60000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
      );

      verify(
        () => repository.editParticipantContribution(
          transactionId: 't1',
          amount: any(named: 'amount'),
          direction: any(named: 'direction'),
          date: any(named: 'date'),
          note: any(named: 'note'),
        ),
      ).called(2);
    });

    test('forwards the repository ValidationFailure for a non-positive '
        'amount (FR-004)', () async {
      stubEdit(
        const Left(ValidationFailure('Amount must be greater than zero')),
      );

      final result = await editParticipantContribution(
        transactionId: 't1',
        amount: Money.zero(),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('surfaces a row already removed elsewhere as a '
        'ParticipantNotFoundFailure', () async {
      stubEdit(
        const Left(ParticipantNotFoundFailure('Contribution was removed')),
      );

      final result = await editParticipantContribution(
        transactionId: 'gone',
        amount: const Money.fromMinorUnits(1000),
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
      );

      expect(result.getLeft().toNullable(), isA<ParticipantNotFoundFailure>());
    });
  });

  group('RemoveParticipantContribution', () {
    test('soft-deletes the single row, so it leaves the occasion list and '
        "the person's history together (FR-011)", () async {
      stubRemove(const Right(unit));

      final result = await removeParticipantContribution('t1');

      expect(result.isRight(), isTrue);
      verify(() => repository.removeParticipantContribution('t1')).called(1);
      // One soft-delete of one row — never a second write to "also" remove
      // it from the person's side.
      verifyNoMoreInteractions(repository);
    });

    test('the removed row carries a deletedAt tombstone rather than being '
        'erased (FR-011)', () async {
      final removed = buildContribution(deletedAt: DateTime(2026, 3, 16));

      expect(removed.isDeleted, isTrue);
      expect(removed.id, 't1');
      expect(removed.occasionId, 'o1');
    });

    test('surfaces an already-removed contribution as a '
        'ParticipantNotFoundFailure', () async {
      stubRemove(
        const Left(ParticipantNotFoundFailure('Contribution was removed')),
      );

      final result = await removeParticipantContribution('gone');

      expect(result.getLeft().toNullable(), isA<ParticipantNotFoundFailure>());
    });
  });
}
