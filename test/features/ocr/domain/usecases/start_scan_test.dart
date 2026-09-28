import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/start_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late StartScan startScan;

  OcrScan buildScan({
    String id = 'scan-1',
    String sourceImagePath = '/sandbox/scans/scan-1.jpg',
    String? cropBounds,
    int rotationDegrees = 0,
    ScanStatus status = ScanStatus.processing,
  }) {
    return OcrScan(
      id: id,
      idempotencyKey: 'key-1',
      sourceImagePath: sourceImagePath,
      cropBounds: cropBounds,
      rotationDegrees: rotationDegrees,
      status: status,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  void stubStart(Either<Failure, OcrScan> response) {
    when(
      () => repository.startScan(
        sourceImagePath: any(named: 'sourceImagePath'),
        cropBounds: any(named: 'cropBounds'),
        rotationDegrees: any(named: 'rotationDegrees'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOcrRepository();
    startScan = StartScan(repository);
  });

  group('StartScan', () {
    test('passes the prepared image path, crop bounds and rotation through '
        'to the repository unchanged (FR-001/FR-002)', () async {
      stubStart(Right(buildScan()));

      await startScan(
        sourceImagePath: '/sandbox/scans/scan-1.jpg',
        rotationDegrees: 90,
        cropBounds: '10,20,300,400',
      );

      verify(
        () => repository.startScan(
          sourceImagePath: '/sandbox/scans/scan-1.jpg',
          cropBounds: '10,20,300,400',
          rotationDegrees: 90,
        ),
      ).called(1);
    });

    test('omitting crop bounds forwards null rather than a placeholder, so '
        'an uncropped scan is recorded as uncropped', () async {
      stubStart(Right(buildScan()));

      await startScan(
        sourceImagePath: '/sandbox/scans/scan-1.jpg',
        rotationDegrees: 0,
      );

      verify(
        () => repository.startScan(
          sourceImagePath: '/sandbox/scans/scan-1.jpg',
          cropBounds: null,
          rotationDegrees: 0,
        ),
      ).called(1);
    });

    test(
      'returns the created scan in processing status: starting a scan '
      'records the session only, it never recognizes or saves anything',
      () async {
        stubStart(
          Right(buildScan(cropBounds: '0,0,100,100', rotationDegrees: 180)),
        );

        final result = await startScan(
          sourceImagePath: '/sandbox/scans/scan-1.jpg',
          rotationDegrees: 180,
          cropBounds: '0,0,100,100',
        );

        final scan = result.getRight().toNullable();
        expect(scan, isNotNull);
        expect(scan!.status, ScanStatus.processing);
        expect(scan.cropBounds, '0,0,100,100');
        expect(scan.rotationDegrees, 180);
        // The scan carries no money of its own; that only exists as
        // MoneyTransaction rows created at confirm time.
        expect(scan.occasionId, isNull);
        expect(scan.defaultDirection, isNull);
        expect(scan.completedAt, isNull);
      },
    );

    test('propagates a repository failure as an unchanged Left instead of '
        'throwing, so the caller can offer the right recovery', () async {
      const failure = ImageProcessingFailure('Image file unreadable');
      stubStart(const Left(failure));

      final result = await startScan(
        sourceImagePath: '/sandbox/scans/missing.jpg',
        rotationDegrees: 0,
      );

      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable(), same(failure));
    });
  });
}
