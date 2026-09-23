import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/set_batch_default_direction.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late SetBatchDefaultDirection setBatchDefaultDirection;

  OcrScan buildScan({TransactionDirection? defaultDirection}) {
    return OcrScan(
      id: 'scan-1',
      idempotencyKey: 'key-1',
      sourceImagePath: '/sandbox/scans/scan-1.jpg',
      rotationDegrees: 0,
      status: ScanStatus.needsReview,
      defaultDirection: defaultDirection,
      createdAt: DateTime(2026, 3, 1),
    );
  }

  void stubSet(Either<Failure, OcrScan> response) {
    when(
      () => repository.setBatchDefaultDirection(
        scanId: any(named: 'scanId'),
        direction: any(named: 'direction'),
      ),
    ).thenAnswer((_) async => response);
  }

  setUpAll(() {
    registerFallbackValue(TransactionDirection.given);
  });

  setUp(() {
    repository = MockOcrRepository();
    setBatchDefaultDirection = SetBatchDefaultDirection(repository);
  });

  group('SetBatchDefaultDirection', () {
    test(
      'passes the scan id and direction straight through (FR-005)',
      () async {
        stubSet(Right(buildScan(defaultDirection: TransactionDirection.given)));

        await setBatchDefaultDirection(
          scanId: 'scan-1',
          direction: TransactionDirection.given,
        );

        verify(
          () => repository.setBatchDefaultDirection(
            scanId: 'scan-1',
            direction: TransactionDirection.given,
          ),
        ).called(1);
      },
    );

    test(
      'returns the updated scan carrying the new batch default, which is '
      'what makes entries without their own direction confirm-eligible',
      () async {
        stubSet(
          Right(buildScan(defaultDirection: TransactionDirection.received)),
        );

        final result = await setBatchDefaultDirection(
          scanId: 'scan-1',
          direction: TransactionDirection.received,
        );

        final scan = result.getRight().toNullable();
        expect(scan, isNotNull);
        expect(scan!.defaultDirection, TransactionDirection.received);
      },
    );

    test('never edits a candidate entry, so setting the batch default cannot '
        "overwrite a row the user already corrected (FR-005)", () async {
      stubSet(Right(buildScan(defaultDirection: TransactionDirection.given)));

      await setBatchDefaultDirection(
        scanId: 'scan-1',
        direction: TransactionDirection.given,
      );

      // The default lives on the scan only; an entry's own direction wins
      // when it is resolved, and nothing here touches an entry to change it.
      verifyNever(
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
      );
      verify(
        () => repository.setBatchDefaultDirection(
          scanId: 'scan-1',
          direction: TransactionDirection.given,
        ),
      ).called(1);
      verifyNoMoreInteractions(repository);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = NotFoundFailure('Scan not found');
        stubSet(const Left(failure));

        final result = await setBatchDefaultDirection(
          scanId: 'missing',
          direction: TransactionDirection.given,
        );

        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });
}
