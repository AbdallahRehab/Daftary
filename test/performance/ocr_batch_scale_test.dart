import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/data/datasources/occasions_dao.dart';
import 'package:daftary/features/occasions/data/repositories/occasions_repository_impl.dart';
import 'package:daftary/features/ocr/data/datasources/ocr_dao.dart';
import 'package:daftary/features/ocr/data/parsing/candidate_entry_parser.dart';
import 'package:daftary/features/ocr/data/repositories/ocr_repository_impl.dart';
import 'package:daftary/features/ocr/domain/entities/field_confidence.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

/// T071 — behaviour at the 50-entry ceiling (009 FR-024, plan.md
/// Performance Goals).
///
/// Two questions, both of which only matter at the ceiling: does a page
/// with more lines than the app will accept get truncated honestly rather
/// than silently mangled, and does confirming a full 50-entry batch — 50
/// person creations and 50 transaction inserts inside one database
/// transaction — finish fast enough that the review screen does not appear
/// to hang.
///
/// The timing bound is deliberately loose. This runs on developer and CI
/// hardware of wildly varying speed, so it is a regression alarm for an
/// accidental O(n²) or a per-row round trip, not a benchmark of the
/// target device.
class _FakeRecognition implements TextRecognitionService {
  _FakeRecognition(this.text);

  final RecognizedText text;

  @override
  Future<Either<Failure, RecognizedText>> recognize(String imagePath) async =>
      Right(text);

  @override
  Future<bool> isAvailable() async => true;
}

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late String imagePath;

  RecognizedText pageOf(int lineCount) => RecognizedText(
    blocks: [
      RecognizedBlock(
        lines: [
          for (var i = 0; i < lineCount; i++)
            RecognizedLine(
              text: 'Person $i ${100 + i}',
              confidence: FieldConfidenceLevel.high,
            ),
        ],
      ),
    ],
  );

  OcrRepositoryImpl repositoryFor(RecognizedText text) {
    final transactionsRepository = TransactionsRepositoryImpl(
      TransactionsDao(db),
      db,
    );
    final peopleRepository = PeopleRepositoryImpl(
      PeopleDao(db),
      const FindPossibleDuplicatePerson(),
      db,
    );
    return OcrRepositoryImpl(
      OcrDao(db),
      _FakeRecognition(text),
      const CandidateEntryParser(),
      transactionsRepository,
      OccasionsRepositoryImpl(
        OccasionsDao(db),
        transactionsRepository,
        peopleRepository,
        db,
      ),
      peopleRepository,
    );
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    tempDir = await Directory.systemTemp.createTemp('ocr_scale_test');
    imagePath = '${tempDir.path}/scan.png';
    await File(imagePath).writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('a page with more lines than the ceiling is truncated to 50 rather '
      'than partially mangled (FR-024)', () async {
    final repository = repositoryFor(pageOf(80));

    final started = await repository.startScan(
      sourceImagePath: imagePath,
      rotationDegrees: 0,
    );
    final scanId = started.getOrElse((f) => throw StateError(f.message)).id;
    await repository.runExtraction(scanId);

    final entries = (await repository.getCandidateEntries(
      scanId,
    )).getOrElse((f) => throw StateError(f.message));

    expect(entries, hasLength(OcrRepositoryImpl.maxEntriesPerScan));
    // The kept entries are the first 50 in page order, so the user reviews
    // the top of their list rather than an arbitrary sample of it.
    expect(entries.first.personName, 'Person 0');
    expect(entries.last.personName, 'Person 49');
  });

  test('confirming a full 50-entry batch stays responsive', () async {
    final repository = repositoryFor(pageOf(50));

    final started = await repository.startScan(
      sourceImagePath: imagePath,
      rotationDegrees: 0,
    );
    final scanId = started.getOrElse((f) => throw StateError(f.message)).id;
    await repository.runExtraction(scanId);
    await repository.setBatchDefaultDirection(
      scanId: scanId,
      direction: TransactionDirection.received,
    );

    final stopwatch = Stopwatch()..start();
    final result = await repository.confirmScanBatch(
      idempotencyKey: 'batch-1',
      scanId: scanId,
    );
    stopwatch.stop();

    final created = result.getOrElse((f) => throw StateError(f.message));
    expect(created, hasLength(50));
    expect(created.every((t) => t.source == TransactionSource.ocr), isTrue);
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 5)),
      reason:
          'a 50-entry confirm that takes seconds means a per-row round '
          'trip crept into the batch',
    );
  });

  test(
    'loading a full 50-entry batch for review is a single fast read',
    () async {
      final repository = repositoryFor(pageOf(50));
      final started = await repository.startScan(
        sourceImagePath: imagePath,
        rotationDegrees: 0,
      );
      final scanId = started.getOrElse((f) => throw StateError(f.message)).id;
      await repository.runExtraction(scanId);

      final stopwatch = Stopwatch()..start();
      final entries = (await repository.getCandidateEntries(
        scanId,
      )).getOrElse((f) => throw StateError(f.message));
      stopwatch.stop();

      expect(entries, hasLength(50));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    },
  );
}
