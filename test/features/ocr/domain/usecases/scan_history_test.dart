import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan_detail.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/usecases/delete_scan.dart';
import 'package:daftary/features/ocr/domain/usecases/get_scan_detail.dart';
import 'package:daftary/features/ocr/domain/usecases/get_scan_history.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockOcrRepository extends Mock implements OcrRepository {}

void main() {
  late MockOcrRepository repository;
  late GetScanHistory getScanHistory;
  late GetScanDetail getScanDetail;
  late DeleteScan deleteScan;

  OcrScan buildScan({
    String id = 'scan-1',
    ScanStatus status = ScanStatus.confirmed,
    DateTime? createdAt,
  }) {
    return OcrScan(
      id: id,
      idempotencyKey: 'key-$id',
      sourceImagePath: '/sandbox/scans/$id.jpg',
      rotationDegrees: 0,
      status: status,
      createdAt: createdAt ?? DateTime(2026, 3, 1),
    );
  }

  CandidateEntry buildEntry(String id) {
    return CandidateEntry(
      id: id,
      scanId: 'scan-1',
      status: CandidateEntryStatus.confirmed,
      personName: 'Ahmed Ali',
      personNameConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
      amountConfidence: FieldConfidence.read(FieldConfidenceLevel.high),
      directionConfidence: const FieldConfidence.inferred(),
      dateConfidence: const FieldConfidence.inferred(),
      amountMinorUnits: 50000,
      direction: TransactionDirection.received,
      rawOcrText: 'Ahmed Ali 500',
      createdAt: DateTime(2026, 3, 1),
    );
  }

  MoneyTransaction buildTransaction(String id) {
    return MoneyTransaction(
      id: id,
      idempotencyKey: 'tx-key-$id',
      personId: 'person-1',
      amount: const Money.fromMinorUnits(50000),
      direction: TransactionDirection.received,
      kind: TransactionKind.initialExchange,
      date: DateTime(2026, 3, 1),
      createdAt: DateTime(2026, 3, 1),
      source: TransactionSource.ocr,
      ocrScanId: 'scan-1',
    );
  }

  setUp(() {
    repository = MockOcrRepository();
    getScanHistory = GetScanHistory(repository);
    getScanDetail = GetScanDetail(repository);
    deleteScan = DeleteScan(repository);
  });

  group('GetScanHistory', () {
    test('passes the repository list through in the order it arrives, '
        'newest first (FR-018)', () async {
      final newest = buildScan(id: 'scan-3', createdAt: DateTime(2026, 3, 20));
      final middle = buildScan(id: 'scan-2', createdAt: DateTime(2026, 3, 10));
      final oldest = buildScan(id: 'scan-1', createdAt: DateTime(2026, 3, 1));
      when(
        () => repository.getScanHistory(),
      ).thenAnswer((_) async => Right([newest, middle, oldest]));

      final result = await getScanHistory();

      // The ordering rule lives in the repository query; the use case must
      // not re-sort it into a different answer.
      expect(result.getRight().toNullable()?.map((s) => s.id), [
        'scan-3',
        'scan-2',
        'scan-1',
      ]);
      verify(() => repository.getScanHistory()).called(1);
    });

    test('an empty history is a successful empty list, not a failure: a user '
        'who has never scanned is in a normal state', () async {
      when(
        () => repository.getScanHistory(),
      ).thenAnswer((_) async => const Right([]));

      final result = await getScanHistory();

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), isEmpty);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = CacheFailure('Scan table unreadable');
        when(
          () => repository.getScanHistory(),
        ).thenAnswer((_) async => const Left(failure));

        final result = await getScanHistory();

        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });

  group('GetScanDetail', () {
    test(
      'returns the scan together with its entries and the transactions it '
      'produced, which is everything the detail screen shows (FR-018)',
      () async {
        final detail = OcrScanDetail(
          scan: buildScan(),
          entries: [buildEntry('entry-1'), buildEntry('entry-2')],
          transactions: [buildTransaction('tx-1'), buildTransaction('tx-2')],
        );
        when(
          () => repository.getScanDetail(any()),
        ).thenAnswer((_) async => Right(detail));

        final result = await getScanDetail('scan-1');

        final loaded = result.getRight().toNullable();
        expect(loaded, isNotNull);
        expect(loaded!.scan.id, 'scan-1');
        expect(loaded.entries.map((e) => e.id), ['entry-1', 'entry-2']);
        // The link is one-way: transactions are read back through
        // ocr_scan_id, never stored on the entries themselves.
        expect(loaded.transactions.map((t) => t.id), ['tx-1', 'tx-2']);
        expect(
          loaded.transactions.every((t) => t.source == TransactionSource.ocr),
          isTrue,
        );
        verify(() => repository.getScanDetail('scan-1')).called(1);
      },
    );

    test(
      'propagates a NotFoundFailure for a scan that no longer exists',
      () async {
        const failure = NotFoundFailure('Scan not found');
        when(
          () => repository.getScanDetail(any()),
        ).thenAnswer((_) async => const Left(failure));

        final result = await getScanDetail('deleted-scan');

        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });

  group('DeleteScan', () {
    test('delegates to the repository with the scan id and reports success '
        'as Right(unit) (FR-023)', () async {
      when(
        () => repository.deleteScan(any()),
      ).thenAnswer((_) async => const Right(unit));

      final result = await deleteScan('scan-1');

      expect(result.getRight().toNullable(), unit);
      verify(() => repository.deleteScan('scan-1')).called(1);
    });

    test('deleting a scan leaves the transactions it already produced '
        'intact: the use case takes and touches no transactions '
        'collaborator (data-model.md Relationships, FR-023)', () async {
      when(
        () => repository.deleteScan(any()),
      ).thenAnswer((_) async => const Right(unit));

      await deleteScan('scan-1');

      // DeleteScan is constructed from the OcrRepository alone, and the one
      // call it makes is the scan-side delete. There is no transactions
      // repository here to cascade into, by construction.
      verify(() => repository.deleteScan('scan-1')).called(1);
      verifyNoMoreInteractions(repository);
    });

    test(
      'propagates a repository failure unchanged rather than throwing',
      () async {
        const failure = CacheFailure('Could not delete the scan image');
        when(
          () => repository.deleteScan(any()),
        ).thenAnswer((_) async => const Left(failure));

        final result = await deleteScan('scan-1');

        expect(result.isLeft(), isTrue);
        expect(result.getLeft().toNullable(), same(failure));
      },
    );
  });
}
