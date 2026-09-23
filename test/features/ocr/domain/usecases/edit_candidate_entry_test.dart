import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/edit_candidate_entry.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late EditCandidateEntry editCandidateEntry;

  CandidateEntry buildEntry({
    String id = 'entry-1',
    String personName = 'Ahmed Ali',
    String? matchedPersonId,
    int? amountMinorUnits = 50000,
    TransactionDirection? direction,
    DateTime? date,
    String? notes,
  }) {
    return CandidateEntry(
      id: id,
      scanId: 'scan-1',
      status: CandidateEntryStatus.pendingReview,
      personName: personName,
      personNameConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
      amountConfidence: FieldConfidence.read(FieldConfidenceLevel.medium),
      directionConfidence: const FieldConfidence.inferred(),
      dateConfidence: const FieldConfidence.inferred(),
      matchedPersonId: matchedPersonId,
      amountMinorUnits: amountMinorUnits,
      direction: direction,
      date: date,
      notes: notes,
      rawOcrText: 'Ahmed Ali 500',
      createdAt: DateTime(2026, 3, 1),
      editedAt: DateTime(2026, 3, 2),
    );
  }

  void stubEdit(Either<Failure, CandidateEntry> response) {
    when(
      () => repository.editCandidateEntry(
        entryId: any(named: 'entryId'),
        personName: any(named: 'personName'),
        matchedPersonId: any(named: 'matchedPersonId'),
        clearMatchedPersonId: any(named: 'clearMatchedPersonId'),
        amountMinorUnits: any(named: 'amountMinorUnits'),
        direction: any(named: 'direction'),
        date: any(named: 'date'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(TransactionDirection.given);
  });

  setUp(() {
    repository = MockOcrRepository();
    editCandidateEntry = EditCandidateEntry(repository);
  });

  group('EditCandidateEntry', () {
    test('passes every edited field through to the repository unchanged '
        '(FR-008)', () async {
      stubEdit(Right(buildEntry()));

      await editCandidateEntry(
        entryId: 'entry-1',
        personName: 'Ahmed Ali',
        matchedPersonId: 'person-9',
        amountMinorUnits: 50000,
        direction: TransactionDirection.received,
        date: DateTime(2026, 3, 14),
        notes: 'front page',
      );

      verify(
        () => repository.editCandidateEntry(
          entryId: 'entry-1',
          personName: 'Ahmed Ali',
          matchedPersonId: 'person-9',
          clearMatchedPersonId: false,
          amountMinorUnits: 50000,
          direction: TransactionDirection.received,
          date: DateTime(2026, 3, 14),
          notes: 'front page',
        ),
      ).called(1);
    });

    test('an omitted field forwards null, meaning "leave it alone" rather '
        'than "blank it out"', () async {
      stubEdit(Right(buildEntry()));

      await editCandidateEntry(entryId: 'entry-1', amountMinorUnits: 12345);

      verify(
        () => repository.editCandidateEntry(
          entryId: 'entry-1',
          personName: null,
          matchedPersonId: null,
          clearMatchedPersonId: false,
          amountMinorUnits: 12345,
          direction: null,
          date: null,
          notes: null,
        ),
      ).called(1);
    });

    test('forwards clearMatchedPersonId distinctly from a null '
        'matchedPersonId: unlinking a person is not the same as not '
        'touching the link (FR-009)', () async {
      stubEdit(Right(buildEntry()));

      await editCandidateEntry(entryId: 'entry-1', clearMatchedPersonId: true);

      // matchedPersonId is null in both cases, so the flag is the only
      // signal that tells "create a new person at confirm time" apart from
      // "keep whoever is already matched".
      verify(
        () => repository.editCandidateEntry(
          entryId: 'entry-1',
          personName: null,
          matchedPersonId: null,
          clearMatchedPersonId: true,
          amountMinorUnits: null,
          direction: null,
          date: null,
          notes: null,
        ),
      ).called(1);
    });

    test('returns the updated entry the repository produced, including its '
        'editedAt stamp, which is what makes cancelling prompt first '
        '(FR-015)', () async {
      stubEdit(Right(buildEntry(amountMinorUnits: 77700)));

      final result = await editCandidateEntry(
        entryId: 'entry-1',
        amountMinorUnits: 77700,
      );

      final entry = result.getRight().toNullable();
      expect(entry, isNotNull);
      expect(entry!.amountMinorUnits, 77700);
      expect(entry.isEdited, isTrue);
    });

    test('propagates the repository ValidationFailure for a non-positive '
        'amount instead of throwing, keeping the rule in one place '
        '(FR-008)', () async {
      const failure = ValidationFailure('Amount must be greater than zero');
      stubEdit(const Left(failure));

      final result = await editCandidateEntry(
        entryId: 'entry-1',
        amountMinorUnits: 0,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), same(failure));
      // The invalid value still reaches the repository untouched: the use
      // case does not pre-judge it.
      verify(
        () => repository.editCandidateEntry(
          entryId: 'entry-1',
          personName: null,
          matchedPersonId: null,
          clearMatchedPersonId: false,
          amountMinorUnits: 0,
          direction: null,
          date: null,
          notes: null,
        ),
      ).called(1);
    });
  });
}
