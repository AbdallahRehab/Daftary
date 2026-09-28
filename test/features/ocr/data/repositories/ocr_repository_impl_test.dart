import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/ocr/data/datasources/ocr_dao.dart';
import 'package:daftary/features/ocr/data/parsing/candidate_entry_parser.dart';
import 'package:daftary/features/ocr/data/repositories/ocr_repository_impl.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';
import '../../../transactions/helpers/currency_test_doubles.dart';
import 'package:daftary/features/currency/domain/services/currency_converter.dart';

/// Returns whatever it was constructed with, so these tests exercise the
/// repository's own composition and persistence rather than the on-device
/// recognizer — which cannot run in a headless test at all (research.md
/// Decision 6).
class _FakeTextRecognitionService implements TextRecognitionService {
  _FakeTextRecognitionService(this.result);

  Either<Failure, RecognizedText> result;
  int recognizeCalls = 0;

  @override
  Future<Either<Failure, RecognizedText>> recognize(String imagePath) async {
    recognizeCalls++;
    return result;
  }

  @override
  Future<bool> isAvailable() async => true;
}

RecognizedText _textOf(List<String> lines) => RecognizedText(
  blocks: [
    RecognizedBlock(
      lines: [for (final line in lines) RecognizedLine(text: line)],
    ),
  ],
);

void main() {
  late AppDatabase db;
  late OcrDao dao;
  late TransactionsRepositoryImpl transactionsRepository;
  late OccasionsRepositoryImpl occasionsRepository;
  late PeopleRepositoryImpl peopleRepository;
  late _FakeTextRecognitionService recognition;
  late OcrRepositoryImpl repository;
  late Directory tempDir;
  late String imagePath;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dao = OcrDao(db);
    transactionsRepository = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
    );
    peopleRepository = PeopleRepositoryImpl(
      testPeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
    occasionsRepository = OccasionsRepositoryImpl(
      testOccasionsDao(db),
      transactionsRepository,
      peopleRepository,
      db,
      getConversionContextWith(),
      const CurrencyConverterImpl(),
    );
    recognition = _FakeTextRecognitionService(
      Right(_textOf(const ['Ahmed 500', 'Mona 250'])),
    );
    repository = OcrRepositoryImpl(
      dao,
      recognition,
      const CandidateEntryParser(),
      transactionsRepository,
      occasionsRepository,
      peopleRepository,
      getPrimaryCurrencyReturning(),
      db,
    );

    tempDir = await Directory.systemTemp.createTemp('ocr_repo_test');
    imagePath = '${tempDir.path}/scan.png';
    await File(imagePath).writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Starts a scan and extracts it, returning the scan id — the state every
  /// review-related test begins from.
  Future<String> startAndExtract({
    TransactionDirection? defaultDirection = TransactionDirection.received,
  }) async {
    final started = await repository.startScan(
      sourceImagePath: imagePath,
      rotationDegrees: 0,
    );
    final scanId = started
        .getOrElse((_) => throw StateError('start failed'))
        .id;
    await repository.runExtraction(scanId);
    if (defaultDirection != null) {
      await repository.setBatchDefaultDirection(
        scanId: scanId,
        direction: defaultDirection,
      );
    }
    return scanId;
  }

  Future<List<CandidateEntry>> entriesOf(String scanId) async {
    final result = await repository.getCandidateEntries(scanId);
    return result.getOrElse((_) => throw StateError('load failed'));
  }

  Future<int> transactionCount() async =>
      (await db.select(db.moneyTransactions).get()).length;

  group('startScan / runExtraction (US1)', () {
    test('a new scan is persisted as processing and round-trips', () async {
      final result = await repository.startScan(
        sourceImagePath: imagePath,
        rotationDegrees: 90,
        cropBounds: '{"width":100,"height":200}',
      );
      final scan = result.getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.processing);

      final reloaded = await repository.getScan(scan.id);
      final stored = reloaded.getOrElse((_) => throw StateError('failed'));
      expect(stored.rotationDegrees, 90);
      expect(stored.cropBounds, '{"width":100,"height":200}');
      expect(stored.sourceImagePath, imagePath);
      expect(stored.status, ScanStatus.processing);
    });

    test('extraction persists candidate entries and moves the scan to '
        'needsReview', () async {
      final scanId = await startAndExtract();
      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.needsReview);

      final entries = await entriesOf(scanId);
      expect(entries, hasLength(2));
      expect(entries.map((e) => e.personName), containsAll(['Ahmed', 'Mona']));
      expect(
        entries.every((e) => e.status == CandidateEntryStatus.pendingReview),
        isTrue,
        reason: 'extraction produces suggestions, never confirmed entries',
      );
    });

    test('extraction creates no transaction under any circumstances', () async {
      await startAndExtract();
      expect(await transactionCount(), 0);
    });

    test('no recognizable text fails the scan rather than leaving it '
        'processing forever', () async {
      recognition.result = Right(const RecognizedText.empty());
      final started = await repository.startScan(
        sourceImagePath: imagePath,
        rotationDegrees: 0,
      );
      final scanId = started.getOrElse((_) => throw StateError('failed')).id;

      final result = await repository.runExtraction(scanId);
      expect(result.getLeft().toNullable(), isA<NoTextRecognizedFailure>());
      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.failed);
    });

    test('text with no name/amount lines returns NoCandidatesParsedFailure '
        '(FR-004)', () async {
      recognition.result = Right(_textOf(const ['Total', 'Subtotal']));
      final started = await repository.startScan(
        sourceImagePath: imagePath,
        rotationDegrees: 0,
      );
      final scanId = started.getOrElse((_) => throw StateError('failed')).id;

      final result = await repository.runExtraction(scanId);
      expect(result.getLeft().toNullable(), isA<NoCandidatesParsedFailure>());
      expect(await transactionCount(), 0);
    });
  });

  group('setBatchDefaultDirection (FR-005)', () {
    test('never overwrites an entry that already carries its own '
        'direction', () async {
      final scanId = await startAndExtract(defaultDirection: null);
      final entries = await entriesOf(scanId);
      await repository.editCandidateEntry(
        entryId: entries.first.id,
        direction: TransactionDirection.given,
      );

      await repository.setBatchDefaultDirection(
        scanId: scanId,
        direction: TransactionDirection.received,
      );

      final after = await entriesOf(scanId);
      final corrected = after.firstWhere((e) => e.id == entries.first.id);
      expect(
        corrected.direction,
        TransactionDirection.given,
        reason: 'setting a batch default must not undo a correction',
      );
    });
  });

  group('editCandidateEntry (US2)', () {
    test(
      'a non-positive amount is refused exactly as in manual entry',
      () async {
        final scanId = await startAndExtract();
        final entries = await entriesOf(scanId);
        final result = await repository.editCandidateEntry(
          entryId: entries.first.id,
          amountMinorUnits: 0,
        );
        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      },
    );

    test('an edited field becomes inferred, so a typed value is never shown '
        'as a confident OCR read (FR-013)', () async {
      final scanId = await startAndExtract();
      final entries = await entriesOf(scanId);
      final result = await repository.editCandidateEntry(
        entryId: entries.first.id,
        personName: 'Ahmed Ali',
      );
      final updated = result.getOrElse((_) => throw StateError('failed'));
      expect(updated.personName, 'Ahmed Ali');
      expect(updated.personNameConfidence.isInferred, isTrue);
      expect(updated.personNameConfidence.level, FieldConfidenceLevel.none);
      expect(updated.isEdited, isTrue);
    });
  });

  group('discardCandidateEntry (FR-010)', () {
    test('discards one entry without touching its siblings', () async {
      final scanId = await startAndExtract();
      final entries = await entriesOf(scanId);
      await repository.discardCandidateEntry(entries.first.id);

      final after = await entriesOf(scanId);
      expect(
        after.firstWhere((e) => e.id == entries.first.id).isDiscarded,
        isTrue,
      );
      expect(
        after.firstWhere((e) => e.id == entries.last.id).status,
        CandidateEntryStatus.pendingReview,
      );
      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.needsReview);
    });
  });

  // ---------------------------------------------------------------------
  // T037: the critical-path tests. This group is the primary automated
  // evidence for SC-002 and constitution Principle X. Treat a failure here
  // as release-blocking, not as a test to adjust.
  // ---------------------------------------------------------------------
  group('confirmScanBatch — THE gate (constitution Principle X, FR-007)', () {
    test('(a) creates exactly one transaction per confirmed entry, each '
        'marked source = ocr and linked to its scan', () async {
      final scanId = await startAndExtract();

      final result = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final created = result.getOrElse(
        (f) => throw StateError('confirm failed: ${f.message}'),
      );

      expect(created, hasLength(2));
      expect(created.every((t) => t.source == TransactionSource.ocr), isTrue);
      expect(created.every((t) => t.ocrScanId == scanId), isTrue);
      expect(await transactionCount(), 2);

      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.confirmed);
      expect(scan.completedAt, isNotNull);
    });

    test('(b) creates zero transactions for discarded entries', () async {
      final scanId = await startAndExtract();
      final entries = await entriesOf(scanId);
      await repository.discardCandidateEntry(entries.first.id);

      final result = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final created = result.getOrElse((_) => throw StateError('failed'));

      expect(created, hasLength(1));
      expect(await transactionCount(), 1);
      final after = await entriesOf(scanId);
      expect(
        after.firstWhere((e) => e.id == entries.first.id).isConfirmed,
        isFalse,
        reason: 'a discarded entry is never promoted to confirmed',
      );
    });

    test('(c) one incomplete entry saves NOTHING at all — all-or-nothing '
        '(FR-011)', () async {
      final scanId = await startAndExtract();
      final entries = await entriesOf(scanId);
      // Blank the name on one entry, leaving the other perfectly valid.
      await repository.editCandidateEntry(
        entryId: entries.first.id,
        personName: '   ',
      );

      final result = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(
        await transactionCount(),
        0,
        reason:
            'a partial save would leave the user unable to tell what '
            'was recorded',
      );
      final after = await entriesOf(scanId);
      expect(after.any((e) => e.isConfirmed), isFalse);
      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.needsReview);
    });

    test('an entry with no resolvable direction blocks the batch rather than '
        'guessing which way the money went', () async {
      // No batch default set, and the parser never infers a direction.
      final scanId = await startAndExtract(defaultDirection: null);

      final result = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(await transactionCount(), 0);
    });

    test('(d) a retried confirm with the same key returns the first batch, '
        'never a second one (FR-021, SC-006)', () async {
      final scanId = await startAndExtract();

      final first = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final second = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );

      final firstIds = first
          .getOrElse((_) => throw StateError('failed'))
          .map((t) => t.id)
          .toSet();
      final secondIds = second
          .getOrElse((_) => throw StateError('failed'))
          .map((t) => t.id)
          .toSet();

      expect(secondIds, firstIds);
      expect(
        await transactionCount(),
        2,
        reason: 'a double-tapped confirm must not double-save the batch',
      );
    });

    test('(e) an occasion-tagged scan goes through the occasions path, so '
        '008 rules are applied once', () async {
      final occasion = await occasionsRepository.createOccasion(
        idempotencyKey: 'occ-1',
        name: 'Wedding',
        date: DateTime(2026, 3, 1),
        type: OccasionType.wedding,
      );
      final occasionId = occasion
          .getOrElse((_) => throw StateError('failed'))
          .id;
      final scanId = await startAndExtract();
      await repository.tagBatchToOccasion(
        scanId: scanId,
        occasionId: occasionId,
      );

      final result = await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final created = result.getOrElse((_) => throw StateError('failed'));

      expect(
        created.every((t) => t.kind == TransactionKind.occasionContribution),
        isTrue,
      );
      expect(created.every((t) => t.occasionId == occasionId), isTrue);
      // The two extensions compose: 008's occasion link and 009's scan link
      // are independent columns on the same row.
      expect(created.every((t) => t.source == TransactionSource.ocr), isTrue);
      expect(created.every((t) => t.ocrScanId == scanId), isTrue);
    });

    test(
      'a pendingReview entry is only ever promoted by this method — an '
      'already-confirmed scan cannot be confirmed again under a new key',
      () async {
        final scanId = await startAndExtract();
        await repository.confirmScanBatch(
          idempotencyKey: 'batch-1',
          scanId: scanId,
        );

        final again = await repository.confirmScanBatch(
          idempotencyKey: 'batch-2',
          scanId: scanId,
        );

        expect(again.getLeft().toNullable(), isA<ValidationFailure>());
        expect(await transactionCount(), 2);
      },
    );

    test('a confirmed entry can no longer be edited — the money is the '
        'record now', () async {
      final scanId = await startAndExtract();
      await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final entries = await entriesOf(scanId);

      final result = await repository.editCandidateEntry(
        entryId: entries.first.id,
        amountMinorUnits: 999999,
      );

      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    });
  });

  group('cancelScan (FR-015)', () {
    test(
      'creates no transactions and hard-deletes an untouched scan',
      () async {
        final scanId = await startAndExtract();

        final result = await repository.cancelScan(scanId);

        expect(result.isRight(), isTrue);
        expect(await transactionCount(), 0);
        final scan = await repository.getScan(scanId);
        expect(scan.getLeft().toNullable(), isA<NotFoundFailure>());
      },
    );

    test('keeps a scan the user corrected, so their work is not silently '
        'thrown away', () async {
      final scanId = await startAndExtract();
      final entries = await entriesOf(scanId);
      await repository.editCandidateEntry(
        entryId: entries.first.id,
        personName: 'Ahmed Ali',
      );

      await repository.cancelScan(scanId);

      final scan = (await repository.getScan(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));
      expect(scan.status, ScanStatus.discarded);
      expect(await transactionCount(), 0);
    });
  });

  group('scan history and deletion (US5, FR-018/FR-023)', () {
    test('history is newest first and excludes deleted scans', () async {
      final older = await startAndExtract();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final newer = await startAndExtract();

      final history = (await repository.getScanHistory()).getOrElse(
        (_) => throw StateError('failed'),
      );
      expect(history.first.id, newer);
      expect(history.last.id, older);

      await repository.deleteScan(older);
      final after = (await repository.getScanHistory()).getOrElse(
        (_) => throw StateError('failed'),
      );
      expect(after.map((s) => s.id), [newer]);
    });

    test('scan detail carries the scan, its entries, and the transactions it '
        'produced', () async {
      final scanId = await startAndExtract();
      await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );

      final detail = (await repository.getScanDetail(
        scanId,
      )).getOrElse((_) => throw StateError('failed'));

      expect(detail.scan.id, scanId);
      expect(detail.entries, hasLength(2));
      expect(detail.transactions, hasLength(2));
      expect(detail.transactions.every((t) => t.ocrScanId == scanId), isTrue);
    });

    test('deleting a scan leaves the transactions it created intact — by then '
        'they are financial records of their own', () async {
      final scanId = await startAndExtract();
      await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      expect(await transactionCount(), 2);

      await repository.deleteScan(scanId);

      expect(await transactionCount(), 2);
      expect(File(imagePath).existsSync(), isFalse);
      final gone = await repository.getScan(scanId);
      expect(gone.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('live history and detail (021 FR-031)', () {
    test(
      'watchScanHistory follows a scan started and deleted elsewhere',
      () async {
        final history = StreamRecorder(repository.watchScanHistory());
        addTearDown(history.cancel);
        await history.waitFor((r) => rightOf(r).isEmpty);

        final scanId = await startAndExtract();
        await history.waitFor(
          (r) =>
              rightOf(r).map((s) => s.id).toList().contains(scanId) &&
              rightOf(r).single.status == ScanStatus.needsReview,
        );

        await repository.deleteScan(scanId);
        await history.waitForNext((r) => rightOf(r).isEmpty);
      },
    );

    test('watchScanDetail drops a produced transaction deleted from its '
        'person\'s screen', () async {
      final scanId = await startAndExtract();
      await repository.confirmScanBatch(
        idempotencyKey: 'batch-1',
        scanId: scanId,
      );
      final detail = StreamRecorder(repository.watchScanDetail(scanId));
      addTearDown(detail.cancel);
      final first = rightOf(
        await detail.waitFor((r) => rightOf(r).transactions.length == 2),
      );

      await transactionsRepository.deleteTransaction(
        first.transactions.first.id,
      );
      await detail.waitFor((r) => rightOf(r).transactions.length == 1);
    });
  });
}
