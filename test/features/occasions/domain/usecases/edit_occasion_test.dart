import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/edit_occasion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late EditOccasion editOccasion;

  Occasion buildOccasion({
    String name = 'Ahmed wedding',
    DateTime? date,
    String type = OccasionType.wedding,
    String? notes,
  }) {
    return Occasion(
      id: 'o1',
      idempotencyKey: 'key-1',
      name: name,
      date: date ?? DateTime(2026, 3, 14),
      type: type,
      notes: notes,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 20),
    );
  }

  void stubEdit(Either<Failure, Occasion> response) {
    when(
      () => repository.editOccasion(
        occasionId: any(named: 'occasionId'),
        name: any(named: 'name'),
        date: any(named: 'date'),
        type: any(named: 'type'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repository = MockOccasionsRepository();
    editOccasion = EditOccasion(repository);
  });

  test('updates name, date, type and notes together (FR-012)', () async {
    stubEdit(
      Right(
        buildOccasion(
          name: 'Ahmed & Mona wedding',
          date: DateTime(2026, 3, 21),
          type: OccasionType.celebration,
          notes: 'Moved a week later',
        ),
      ),
    );

    final result = await editOccasion(
      occasionId: 'o1',
      name: 'Ahmed & Mona wedding',
      date: DateTime(2026, 3, 21),
      type: OccasionType.celebration,
      notes: 'Moved a week later',
    );

    final updated = result.toNullable()!;
    expect(updated.id, 'o1');
    expect(updated.name, 'Ahmed & Mona wedding');
    expect(updated.date, DateTime(2026, 3, 21));
    expect(updated.type, OccasionType.celebration);
    expect(updated.notes, 'Moved a week later');
  });

  test('clears notes when null is passed (FR-012)', () async {
    stubEdit(Right(buildOccasion()));

    await editOccasion(
      occasionId: 'o1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    verify(
      () => repository.editOccasion(
        occasionId: 'o1',
        name: 'Ahmed wedding',
        date: DateTime(2026, 3, 14),
        type: OccasionType.wedding,
        notes: null,
      ),
    ).called(1);
  });

  test('changing the type TO condolence touches nothing but the occasion '
      'row — existing countsTowardBalance flags stay put '
      '(research.md Decision 3, FR-018)', () async {
    stubEdit(Right(buildOccasion(type: OccasionType.condolence)));

    final result = await editOccasion(
      occasionId: 'o1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.condolence,
    );

    expect(result.toNullable()!.type, OccasionType.condolence);
    verify(
      () => repository.editOccasion(
        occasionId: 'o1',
        name: 'Ahmed wedding',
        date: DateTime(2026, 3, 14),
        type: OccasionType.condolence,
        notes: null,
      ),
    ).called(1);
    // The only call made. Nothing that could rewrite a contribution — no
    // edit/remove/re-add of a participant row — is reachable from here, so
    // an unrelated type correction cannot move anybody's balance.
    verifyNoMoreInteractions(repository);
  });

  test('changing the type AWAY FROM condolence likewise leaves existing '
      'contributions alone (research.md Decision 3, FR-018)', () async {
    stubEdit(Right(buildOccasion(type: OccasionType.wedding)));

    await editOccasion(
      occasionId: 'o1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    verify(
      () => repository.editOccasion(
        occasionId: 'o1',
        name: any(named: 'name'),
        date: any(named: 'date'),
        type: OccasionType.wedding,
        notes: any(named: 'notes'),
      ),
    ).called(1);
    verifyNoMoreInteractions(repository);
  });

  test('accepts a free-text custom type on edit (FR-002/FR-012)', () async {
    stubEdit(Right(buildOccasion(type: 'graduation party')));

    final result = await editOccasion(
      occasionId: 'o1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: 'graduation party',
    );

    expect(result.toNullable()!.type, 'graduation party');
  });

  test('forwards the repository ValidationFailure for an empty name '
      '(FR-001)', () async {
    stubEdit(const Left(ValidationFailure('Name is required')));

    final result = await editOccasion(
      occasionId: 'o1',
      name: '  ',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('surfaces an unknown occasion as an OccasionNotFoundFailure', () async {
    stubEdit(const Left(OccasionNotFoundFailure('Occasion is gone')));

    final result = await editOccasion(
      occasionId: 'gone',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
  });
}
