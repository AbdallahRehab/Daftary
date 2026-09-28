import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/discard_candidate_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late DiscardCandidateEntry discardCandidateEntry;

  void stubDiscard(Either<Failure, Unit> response) {
    when(
      () => repository.discardCandidateEntry(any()),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOcrRepository();
    discardCandidateEntry = DiscardCandidateEntry(repository);
  });

  group('DiscardCandidateEntry', () {
    test('delegates to the repository with the entry id and reports success '
        'as Right(unit) (FR-010)', () async {
      stubDiscard(const Right(unit));

      final result = await discardCandidateEntry('entry-1');

      expect(result.getRight().toNullable(), unit);
      verify(() => repository.discardCandidateEntry('entry-1')).called(1);
    });

    test('touches only the one entry it was given: discarding a misread line '
        'leaves its siblings and the scan itself alone (FR-010)', () async {
      stubDiscard(const Right(unit));

      await discardCandidateEntry('entry-2');

      verify(() => repository.discardCandidateEntry('entry-2')).called(1);
      // No cancelScan, no batch-level write, no second entry.
      verifyNoMoreInteractions(repository);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = NotFoundFailure('Candidate entry not found');
        stubDiscard(const Left(failure));

        final result = await discardCandidateEntry('missing');

        expect(result.isLeft(), isTrue);
        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });
}
