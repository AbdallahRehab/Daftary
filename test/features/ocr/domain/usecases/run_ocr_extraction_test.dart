import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/run_ocr_extraction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late RunOcrExtraction runOcrExtraction;

  OcrScan buildScan({ScanStatus status = ScanStatus.needsReview}) {
    return OcrScan(
      id: 'scan-1',
      idempotencyKey: 'key-1',
      sourceImagePath: '/sandbox/scans/scan-1.jpg',
      rotationDegrees: 0,
      status: status,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  void stubExtraction(Either<Failure, OcrScan> response) {
    when(
      () => repository.runExtraction(any()),
    ).thenAnswer((_) async => response);
  }

  setUp(() {
    repository = MockOcrRepository();
    runOcrExtraction = RunOcrExtraction(repository);
  });

  group('RunOcrExtraction', () {
    test('delegates to the repository with the scan id it was given', () async {
      stubExtraction(Right(buildScan()));

      await runOcrExtraction('scan-1');

      verify(() => repository.runExtraction('scan-1')).called(1);
    });

    test('a successful extraction leaves the scan in needsReview: what came '
        'off the page is a suggestion awaiting the user, never a saved row '
        '(FR-003)', () async {
      stubExtraction(Right(buildScan()));

      final result = await runOcrExtraction('scan-1');

      final scan = result.getRight().toNullable();
      expect(scan, isNotNull);
      expect(scan!.status, ScanStatus.needsReview);
      expect(scan.isTerminal, isFalse);
    });

    test('propagates NoTextRecognizedFailure so the UI can offer "retake the '
        'photo" (FR-004)', () async {
      const failure = NoTextRecognizedFailure('No text found in the image');
      stubExtraction(const Left(failure));

      final result = await runOcrExtraction('scan-1');

      expect(result.getLeft().toNullable(), same(failure));
      expect(result.getLeft().toNullable(), isA<OcrFailure>());
    });

    test(
      'propagates NoCandidatesParsedFailure distinctly from the '
      'no-text case, because the two have different recoveries (FR-004)',
      () async {
        const failure = NoCandidatesParsedFailure('No name/amount lines found');
        stubExtraction(const Left(failure));

        final result = await runOcrExtraction('scan-1');

        final leftFailure = result.getLeft().toNullable();
        expect(leftFailure, isA<NoCandidatesParsedFailure>());
        expect(leftFailure, isNot(isA<NoTextRecognizedFailure>()));
      },
    );

    test('involves no transaction-creating collaborator at all on success: '
        'extraction has no path to money, only ConfirmScanBatch does '
        '(constitution Principle X)', () async {
      stubExtraction(Right(buildScan()));

      await runOcrExtraction('scan-1');

      // RunOcrExtraction's only collaborator is the OcrRepository, and the
      // one method there that can create a MoneyTransaction is never
      // reached. Anyone adding an auto-save shortcut breaks this test.
      verify(() => repository.runExtraction('scan-1')).called(1);
      verifyNever(
        () => repository.confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      );
      verifyNoMoreInteractions(repository);
    });

    test('involves no transaction-creating collaborator on failure either, '
        'so a partial read can never half-save a batch', () async {
      stubExtraction(const Left(NoCandidatesParsedFailure('nothing parsed')));

      await runOcrExtraction('scan-1');

      verify(() => repository.runExtraction('scan-1')).called(1);
      verifyNever(
        () => repository.confirmScanBatch(
          idempotencyKey: any(named: 'idempotencyKey'),
          scanId: any(named: 'scanId'),
        ),
      );
      verifyNoMoreInteractions(repository);
    });
  });
}
