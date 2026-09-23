import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/create_occasion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late CreateOccasion createOccasion;

  Occasion buildOccasion({
    String id = 'o1',
    String idempotencyKey = 'key-1',
    String name = 'Ahmed wedding',
    DateTime? date,
    String type = OccasionType.wedding,
    String? notes,
  }) {
    return Occasion(
      id: id,
      idempotencyKey: idempotencyKey,
      name: name,
      date: date ?? DateTime(2026, 3, 14),
      type: type,
      notes: notes,
      createdAt: DateTime(2026, 3, 1),
      updatedAt: DateTime(2026, 3, 1),
    );
  }

  void stubCreate(Either<Failure, Occasion> response) {
    when(
      () => repository.createOccasion(
        idempotencyKey: any(named: 'idempotencyKey'),
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
    createOccasion = CreateOccasion(repository);
  });

  test('forwards the repository ValidationFailure for an empty-after-trim '
      'name (FR-001)', () async {
    stubCreate(const Left(ValidationFailure('Name is required')));

    final result = await createOccasion(
      idempotencyKey: 'key-1',
      name: '   ',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    // The untrimmed value reaches the repository untouched: the rule lives
    // there, so there is exactly one place that decides what "empty" means.
    verify(
      () => repository.createOccasion(
        idempotencyKey: 'key-1',
        name: '   ',
        date: DateTime(2026, 3, 14),
        type: OccasionType.wedding,
        notes: null,
      ),
    ).called(1);
  });

  test('forwards the repository ValidationFailure for an empty type '
      '(FR-002)', () async {
    stubCreate(const Left(ValidationFailure('Type is required')));

    final result = await createOccasion(
      idempotencyKey: 'key-1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: '',
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
  });

  test('accepts a free-text custom type alongside the standard set '
      '(FR-002)', () async {
    final custom = buildOccasion(type: 'graduation party');
    stubCreate(Right(custom));

    final result = await createOccasion(
      idempotencyKey: 'key-1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: 'graduation party',
    );

    expect(result.toNullable()!.type, 'graduation party');
    expect(OccasionType.isStandard('graduation party'), isFalse);
  });

  test('a retried call with the same idempotencyKey returns the existing '
      'occasion rather than a duplicate (FR-019)', () async {
    final persisted = buildOccasion();
    stubCreate(Right(persisted));

    final first = await createOccasion(
      idempotencyKey: 'key-1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );
    final retried = await createOccasion(
      idempotencyKey: 'key-1',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
    );

    expect(first.toNullable()!.id, retried.toNullable()!.id);
    expect(first.toNullable(), retried.toNullable());
  });

  test('accepts a future date — pre-planned occasions are supported '
      '(spec Edge Cases)', () async {
    final future = DateTime.now().add(const Duration(days: 60));
    stubCreate(Right(buildOccasion(date: future)));

    final result = await createOccasion(
      idempotencyKey: 'key-2',
      name: 'Mona engagement',
      date: future,
      type: OccasionType.engagement,
    );

    expect(result.isRight(), isTrue);
    expect(result.toNullable()!.date, future);
    verify(
      () => repository.createOccasion(
        idempotencyKey: 'key-2',
        name: 'Mona engagement',
        date: future,
        type: OccasionType.engagement,
        notes: null,
      ),
    ).called(1);
  });

  test('passes optional notes through unchanged (FR-001)', () async {
    stubCreate(Right(buildOccasion(notes: 'Cash envelope in the drawer')));

    final result = await createOccasion(
      idempotencyKey: 'key-3',
      name: 'Ahmed wedding',
      date: DateTime(2026, 3, 14),
      type: OccasionType.wedding,
      notes: 'Cash envelope in the drawer',
    );

    expect(result.toNullable()!.notes, 'Cash envelope in the drawer');
  });
}
