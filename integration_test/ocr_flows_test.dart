import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/occasions/domain/repositories/occasions_repository.dart';
import 'package:daftary/features/ocr/domain/entities/candidate_entry.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_failures.dart';
import 'package:daftary/features/ocr/domain/entities/ocr_scan.dart';
import 'package:daftary/features/ocr/domain/repositories/ocr_repository.dart';
import 'package:daftary/features/ocr/domain/repositories/text_recognition_service.dart';
import 'package:daftary/features/ocr/domain/usecases/confirm_scan_batch.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// T072 — end-to-end coverage of 009's User Stories 1-5 against the real
/// app: real DI, real on-device SQLite, the real deterministic parser, and
/// the real `TransactionsRepository`/`OccasionsRepository` write paths.
///
/// **What is deliberately faked, and why.** Only
/// [TextRecognitionService] is swapped, for one test-run's duration. Its
/// output depends on a physical camera capture and on the ML model's
/// accuracy for the specific glyphs in a specific photo, so asserting on
/// it would make every guarantee below hostage to an unrelated, device-
/// dependent variable. The recognizer itself is covered by quickstart.md's
/// manual validation scenarios. Everything *downstream* of it — parsing,
/// persistence, the review gate, idempotency, occasion tagging, history and
/// deletion — runs for real here, and those are the guarantees that matter.
///
/// The load-bearing assertions are the ones no single-layer test can make:
/// that a confirmed batch produces real rows visible from the person's own
/// history (US2), that an incomplete batch produces none at all, that a
/// double-tapped confirm cannot double-save, and that deleting a scan
/// leaves its transactions standing (US5).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // `lib/main.dart`'s own `main()` never runs under an integration test, so
  // DI bootstrap has to be explicit.
  setUpAll(() async => configureDependencies());

  const uuid = Uuid();
  String unique(String base) => '$base ${uuid.v4().substring(0, 8)}';

  OcrRepository ocr() => getIt<OcrRepository>();
  TransactionsRepository transactions() => getIt<TransactionsRepository>();
  OccasionsRepository occasions() => getIt<OccasionsRepository>();
  PeopleRepository people() => getIt<PeopleRepository>();

  late _ScriptedRecognition recognition;

  setUp(() {
    recognition = _ScriptedRecognition();
    if (getIt.isRegistered<TextRecognitionService>()) {
      getIt.unregister<TextRecognitionService>();
    }
    getIt.registerSingleton<TextRecognitionService>(recognition);
    // The repository is a lazy singleton holding the previously-registered
    // recognizer, so it has to be rebuilt against the fake.
    getIt.resetLazySingleton<OcrRepository>();
  });

  /// Writes a small placeholder file so the scan has a real, app-owned path
  /// to point at — the pipeline never reads its bytes here, because the
  /// recognizer is scripted.
  Future<String> writeScanImage() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/ocr_it_${uuid.v4()}.png';
    await File(path).writeAsBytes(const [0x89, 0x50, 0x4E, 0x47]);
    return path;
  }

  Future<OcrScan> startAndExtract(
    List<String> lines, {
    TransactionDirection? defaultDirection = TransactionDirection.received,
  }) async {
    recognition.script = Right(
      RecognizedText(
        blocks: [
          RecognizedBlock(
            lines: [for (final line in lines) RecognizedLine(text: line)],
          ),
        ],
      ),
    );
    final started = await ocr().startScan(
      sourceImagePath: await writeScanImage(),
      rotationDegrees: 0,
    );
    final scan = started.getOrElse((f) => throw StateError(f.message));
    final extracted = await ocr().runExtraction(scan.id);
    final reviewable = extracted.getOrElse((f) => throw StateError(f.message));
    if (defaultDirection != null) {
      await ocr().setBatchDefaultDirection(
        scanId: scan.id,
        direction: defaultDirection,
      );
    }
    return reviewable;
  }

  Future<List<CandidateEntry>> entriesOf(String scanId) async {
    final result = await ocr().getCandidateEntries(scanId);
    return result.getOrElse((f) => throw StateError(f.message));
  }

  Future<int> transactionsForScan(String scanId) async {
    final result = await transactions().getTransactionsForScan(scanId);
    return result.getOrElse((f) => throw StateError(f.message)).length;
  }

  testWidgets('Scenario 1 — capture → extract → review → confirm creates one '
      'transaction per reviewed entry (US1 + US2)', (tester) async {
    final ahmed = unique('Ahmed');
    final mona = unique('Mona');
    final scan = await startAndExtract(['$ahmed 500', '$mona 250']);

    expect(scan.status, ScanStatus.needsReview);
    final entries = await entriesOf(scan.id);
    expect(entries, hasLength(2));
    // Nothing has been saved yet: this is the whole point of the gate.
    expect(await transactionsForScan(scan.id), 0);

    final confirmed = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );
    final created = confirmed.getOrElse((f) => throw StateError(f.message));

    expect(created, hasLength(2));
    expect(created.every((t) => t.source == TransactionSource.ocr), isTrue);
    expect(created.every((t) => t.ocrScanId == scan.id), isTrue);

    // The rows are ordinary transactions, visible from the person's own
    // history exactly like a typed one — the point of extending the ledger
    // rather than building a second one (research.md Decision 5).
    final history = await transactions().getPersonHistory(
      created.first.personId,
    );
    expect(history.getOrElse((f) => throw StateError(f.message)), isNotEmpty);
  });

  testWidgets('Scenario 2 — a correction on review is what gets saved, and a '
      'duplicate check runs on the corrected name (US2, FR-008/FR-009)', (
    tester,
  ) async {
    final typo = unique('Ahmd');
    final scan = await startAndExtract(['$typo 300']);
    final entry = (await entriesOf(scan.id)).single;

    final corrected = unique('Ahmed');
    await ocr().editCandidateEntry(
      entryId: entry.id,
      personName: corrected,
      amountMinorUnits: 45000,
    );

    final confirmed = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );
    final created = confirmed.getOrElse((f) => throw StateError(f.message));

    expect(created.single.amount.minorUnits, 45000);
    final person = await people().getPersonById(created.single.personId);
    expect(
      person.getOrElse((f) => throw StateError(f.message)).name,
      corrected,
      reason: 'the reviewed value is what becomes real, not the OCR read',
    );
  });

  testWidgets('Scenario 3 — discarding one entry confirms only the rest '
      '(FR-010)', (tester) async {
    final scan = await startAndExtract([
      '${unique('Sara')} 100',
      '${unique('Omar')} 200',
    ]);
    final entries = await entriesOf(scan.id);
    await ocr().discardCandidateEntry(entries.first.id);

    final confirmed = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );

    expect(
      confirmed.getOrElse((f) => throw StateError(f.message)),
      hasLength(1),
    );
    expect(await transactionsForScan(scan.id), 1);
  });

  testWidgets('Scenario 4 — one incomplete entry saves nothing at all '
      '(FR-011, all-or-nothing)', (tester) async {
    final scan = await startAndExtract([
      '${unique('Hany')} 150',
      '${unique('Nour')} 400',
    ]);
    final entries = await entriesOf(scan.id);
    await ocr().editCandidateEntry(entryId: entries.first.id, personName: '  ');

    final result = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    expect(await transactionsForScan(scan.id), 0);
  });

  testWidgets('Scenario 5 — a rapid double-confirm saves the batch once '
      '(FR-021, SC-006)', (tester) async {
    final scan = await startAndExtract(['${unique('Laila')} 350']);
    final key = uuid.v4();

    // Fired together, as a double-tap would, rather than sequentially.
    final results = await Future.wait([
      getIt<ConfirmScanBatch>()(idempotencyKey: key, scanId: scan.id),
      getIt<ConfirmScanBatch>()(idempotencyKey: key, scanId: scan.id),
    ]);

    expect(results.any((r) => r.isRight()), isTrue);
    expect(
      await transactionsForScan(scan.id),
      1,
      reason: 'the idempotency key must make the second call a no-op',
    );
  });

  testWidgets('Scenario 6 — cancelling with unsaved corrections keeps the '
      'scan and creates nothing (FR-015)', (tester) async {
    final scan = await startAndExtract(['${unique('Karim')} 600']);
    final entry = (await entriesOf(scan.id)).single;
    await ocr().editCandidateEntry(entryId: entry.id, personName: unique('K'));

    await ocr().cancelScan(scan.id);

    final after = await ocr().getScan(scan.id);
    expect(
      after.getOrElse((f) => throw StateError(f.message)).status,
      ScanStatus.discarded,
    );
    expect(await transactionsForScan(scan.id), 0);
  });

  testWidgets('Scenario 7 — an occasion-tagged batch lands as that '
      "occasion's contributions (FR-014, 008 cross-feature)", (tester) async {
    final occasionResult = await occasions().createOccasion(
      idempotencyKey: uuid.v4(),
      name: unique('Wedding'),
      date: DateTime.now(),
      type: OccasionType.wedding,
    );
    final occasionId = occasionResult
        .getOrElse((f) => throw StateError(f.message))
        .id;

    final scan = await startAndExtract(['${unique('Yasmin')} 1000']);
    await ocr().tagBatchToOccasion(scanId: scan.id, occasionId: occasionId);

    final confirmed = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );
    final created = confirmed.getOrElse((f) => throw StateError(f.message));

    expect(created.single.kind, TransactionKind.occasionContribution);
    expect(created.single.occasionId, occasionId);
    // Both links on one row: 008's occasion and 009's scan are independent.
    expect(created.single.source, TransactionSource.ocr);
    expect(created.single.ocrScanId, scan.id);

    final forOccasion = await transactions().getContributionsForOccasion(
      occasionId,
    );
    expect(
      forOccasion.getOrElse((f) => throw StateError(f.message)),
      hasLength(1),
    );
  });

  testWidgets('Scenario 8 — an unreadable page fails clearly instead of '
      'producing entries (US4, FR-004)', (tester) async {
    recognition.script = const Left(
      NoTextRecognizedFailure('nothing readable'),
    );
    final started = await ocr().startScan(
      sourceImagePath: await writeScanImage(),
      rotationDegrees: 0,
    );
    final scanId = started.getOrElse((f) => throw StateError(f.message)).id;

    final result = await ocr().runExtraction(scanId);

    expect(result.getLeft().toNullable(), isA<NoTextRecognizedFailure>());
    final scan = await ocr().getScan(scanId);
    expect(
      scan.getOrElse((f) => throw StateError(f.message)).status,
      ScanStatus.failed,
      reason: 'a failed scan must not sit in `processing` forever',
    );
    expect(await entriesOf(scanId), isEmpty);
  });

  testWidgets('Scenario 9 — scan history and detail, and deleting a scan '
      'leaves its transactions standing (US5, FR-018/FR-023)', (tester) async {
    final scan = await startAndExtract(['${unique('Rania')} 750']);
    final confirmed = await getIt<ConfirmScanBatch>()(
      idempotencyKey: uuid.v4(),
      scanId: scan.id,
    );
    final createdId = confirmed
        .getOrElse((f) => throw StateError(f.message))
        .single
        .id;

    final history = await ocr().getScanHistory();
    expect(
      history.getOrElse((f) => throw StateError(f.message)).map((s) => s.id),
      contains(scan.id),
    );

    final detail = await ocr().getScanDetail(scan.id);
    final loaded = detail.getOrElse((f) => throw StateError(f.message));
    expect(loaded.entries, hasLength(1));
    expect(loaded.transactions, hasLength(1));

    await ocr().deleteScan(scan.id);

    expect((await ocr().getScan(scan.id)).isLeft(), isTrue);
    final db = getIt<AppDatabase>();
    final stillThere = await (db.select(
      db.moneyTransactions,
    )..where((t) => t.id.equals(createdId))).getSingleOrNull();
    expect(
      stillThere,
      isNotNull,
      reason: 'deleting a scan costs the traceability link, not the money',
    );
  });
}

/// A [TextRecognitionService] that returns whatever the test set, so the
/// deterministic half of the pipeline can be asserted without depending on
/// what a camera and an ML model happen to produce on the device running
/// the suite.
class _ScriptedRecognition implements TextRecognitionService {
  Either<Failure, RecognizedText> script = Right(const RecognizedText.empty());

  @override
  Future<Either<Failure, RecognizedText>> recognize(String imagePath) async =>
      script;

  @override
  Future<bool> isAvailable() async => true;
}
