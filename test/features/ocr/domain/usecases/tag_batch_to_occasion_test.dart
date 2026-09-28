import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/tag_batch_to_occasion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late TagBatchToOccasion tagBatchToOccasion;

  OcrScan buildScan({String? occasionId}) {
    return OcrScan(
      id: 'scan-1',
      idempotencyKey: 'key-1',
      sourceImagePath: '/sandbox/scans/scan-1.jpg',
      rotationDegrees: 0,
      status: ScanStatus.needsReview,
      occasionId: occasionId,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  void stubTag(Either<Failure, OcrScan> response) {
    when(
      () => repository.tagBatchToOccasion(
        scanId: any(named: 'scanId'),
        occasionId: any(named: 'occasionId'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOcrRepository();
    tagBatchToOccasion = TagBatchToOccasion(repository);
  });

  group('TagBatchToOccasion', () {
    test('passes the scan id and occasion id through, and the returned scan '
        'reports itself as occasion-tagged (FR-014)', () async {
      stubTag(Right(buildScan(occasionId: 'occasion-7')));

      final result = await tagBatchToOccasion(
        scanId: 'scan-1',
        occasionId: 'occasion-7',
      );

      final scan = result.getRight().toNullable();
      expect(scan, isNotNull);
      expect(scan!.occasionId, 'occasion-7');
      expect(scan.isOccasionTagged, isTrue);
      verify(
        () => repository.tagBatchToOccasion(
          scanId: 'scan-1',
          occasionId: 'occasion-7',
        ),
      ).called(1);
    });

    test('a null occasion id clears the tag rather than being treated as '
        '"no change", so the batch goes back to plain transactions', () async {
      stubTag(Right(buildScan()));

      final result = await tagBatchToOccasion(scanId: 'scan-1');

      expect(result.getRight().toNullable()?.isOccasionTagged, isFalse);
      verify(
        () => repository.tagBatchToOccasion(scanId: 'scan-1', occasionId: null),
      ).called(1);
    });

    test('tagging only records the choice on the scan; no contribution is '
        'created until the user confirms the batch (constitution '
        'Principle X)', () async {
      stubTag(Right(buildScan(occasionId: 'occasion-7')));

      await tagBatchToOccasion(scanId: 'scan-1', occasionId: 'occasion-7');

      verify(
        () => repository.tagBatchToOccasion(
          scanId: 'scan-1',
          occasionId: 'occasion-7',
        ),
      ).called(1);
      verifyNever(
        () => repository.confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = NotFoundFailure('Occasion not found');
        stubTag(const Left(failure));

        final result = await tagBatchToOccasion(
          scanId: 'scan-1',
          occasionId: 'missing',
        );

        expect(result.isLeft(), isTrue);
        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });
}
