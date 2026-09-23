import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_failures.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/occasions/domain/usecases/add_occasion_attachment.dart';
import 'package:daftary/features/occasions/domain/usecases/remove_occasion_attachment.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOccasionsRepository extends Mock implements OccasionsRepository {}

void main() {
  late MockOccasionsRepository repository;
  late AddOccasionAttachment addOccasionAttachment;
  late RemoveOccasionAttachment removeOccasionAttachment;

  const appOwnedPath = '/data/user/0/com.daftary/app_flutter/occasions/a1.jpg';

  OccasionAttachment buildAttachment({
    String id = 'a1',
    String filePath = appOwnedPath,
    DateTime? deletedAt,
  }) {
    return OccasionAttachment(
      id: id,
      occasionId: 'o1',
      filePath: filePath,
      createdAt: DateTime(2026, 3, 14),
      deletedAt: deletedAt,
    );
  }

  void stubAdd(Either<Failure, OccasionAttachment> response) {
    when(
      () => repository.addOccasionAttachment(
        occasionId: any(named: 'occasionId'),
        filePath: any(named: 'filePath'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOccasionsRepository();
    addOccasionAttachment = AddOccasionAttachment(repository);
    removeOccasionAttachment = RemoveOccasionAttachment(repository);
  });

  group('AddOccasionAttachment', () {
    test('persists the app-owned local file path against the occasion '
        '(FR-017)', () async {
      stubAdd(Right(buildAttachment()));

      final result = await addOccasionAttachment(
        occasionId: 'o1',
        filePath: appOwnedPath,
      );

      final attachment = result.toNullable()!;
      expect(attachment.occasionId, 'o1');
      expect(attachment.filePath, appOwnedPath);
      expect(attachment.isDeleted, isFalse);
      verify(
        () => repository.addOccasionAttachment(
          occasionId: 'o1',
          filePath: appOwnedPath,
        ),
      ).called(1);
      // Persisting the reference only — no picker is opened from the domain
      // layer.
      verifyNoMoreInteractions(repository);
    });

    test('attaches more than one photo to the same occasion '
        '(FR-017)', () async {
      stubAdd(Right(buildAttachment()));
      final first = await addOccasionAttachment(
        occasionId: 'o1',
        filePath: appOwnedPath,
      );

      stubAdd(
        Right(
          buildAttachment(
            id: 'a2',
            filePath: '/data/user/0/com.daftary/app_flutter/occasions/a2.jpg',
          ),
        ),
      );
      final second = await addOccasionAttachment(
        occasionId: 'o1',
        filePath: '/data/user/0/com.daftary/app_flutter/occasions/a2.jpg',
      );

      expect(first.toNullable()!.id, isNot(second.toNullable()!.id));
      expect(second.toNullable()!.occasionId, 'o1');
    });

    test('forwards the repository ValidationFailure for a blank file '
        'path (FR-017)', () async {
      stubAdd(const Left(ValidationFailure('File path is required')));

      final result = await addOccasionAttachment(
        occasionId: 'o1',
        filePath: '',
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });

    test('surfaces an unknown occasion as an '
        'OccasionNotFoundFailure', () async {
      stubAdd(const Left(OccasionNotFoundFailure('Occasion is gone')));

      final result = await addOccasionAttachment(
        occasionId: 'gone',
        filePath: appOwnedPath,
      );

      expect(result.getLeft().toNullable(), isA<OccasionNotFoundFailure>());
    });

    test('forwards a CacheFailure from local file I/O', () async {
      stubAdd(const Left(CacheFailure('Could not write to app storage')));

      final result = await addOccasionAttachment(
        occasionId: 'o1',
        filePath: appOwnedPath,
      );

      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });

  group('RemoveOccasionAttachment', () {
    test('soft-deletes the attachment after the caller confirms '
        '(FR-017)', () async {
      when(
        () => repository.removeOccasionAttachment(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await removeOccasionAttachment('a1');

      expect(result.isRight(), isTrue);
      verify(() => repository.removeOccasionAttachment('a1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test('a removed attachment keeps a deletedAt tombstone rather than '
        'vanishing from the record (FR-017)', () {
      final removed = buildAttachment(deletedAt: DateTime(2026, 3, 16));

      expect(removed.isDeleted, isTrue);
      expect(removed.filePath, appOwnedPath);
    });

    test('surfaces an unknown attachment as a NotFoundFailure', () async {
      when(() => repository.removeOccasionAttachment(any())).thenAnswer(
        (_) async => const Left(NotFoundFailure('Attachment is gone')),
      );

      final result = await removeOccasionAttachment('gone');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });
}
