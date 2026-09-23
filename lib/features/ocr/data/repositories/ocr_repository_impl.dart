import 'dart:io';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/failure.dart';
import '../../../../core/money/money.dart';
import '../../../occasions/domain/repositories/occasions_repository.dart';
import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/data/models/transaction_mapper.dart'
    show TransactionDirectionDb;
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/field_confidence.dart';
import '../../domain/entities/ocr_failures.dart';
import '../../domain/entities/ocr_scan.dart';
import '../../domain/entities/ocr_scan_detail.dart';
import '../../domain/repositories/ocr_repository.dart';
import '../../domain/repositories/text_recognition_service.dart';
import '../datasources/ocr_dao.dart';
import '../models/candidate_entry_mapper.dart';
import '../models/ocr_scan_mapper.dart';
import '../parsing/candidate_entry_parser.dart';

/// The only implementation of [OcrRepository].
///
/// Worth reading with constitution Principle X in mind: every method here
/// except [confirmScanBatch] deals purely in scans and candidate entries —
/// suggestions, which cost nothing if wrong. [confirmScanBatch] is the sole
/// crossing point into the ledger, and even it does not write a
/// transaction row itself: it delegates to the same repository methods
/// manual entry uses, so there is exactly one insert path for money in the
/// whole app.
@LazySingleton(as: OcrRepository)
class OcrRepositoryImpl implements OcrRepository {
  OcrRepositoryImpl(
    this._dao,
    this._recognitionService,
    this._parser,
    this._transactionsRepository,
    this._occasionsRepository,
    this._peopleRepository,
  );

  final OcrDao _dao;
  final TextRecognitionService _recognitionService;
  final CandidateEntryParser _parser;
  final TransactionsRepository _transactionsRepository;
  final OccasionsRepository _occasionsRepository;
  final PeopleRepository _peopleRepository;

  static const _uuid = Uuid();

  /// FR-024: the review screen stays usable, and a paper list stays a
  /// plausible thing to review by hand, only up to a point.
  static const int maxEntriesPerScan = 50;

  @override
  Future<Either<Failure, OcrScan>> startScan({
    required String sourceImagePath,
    String? cropBounds,
    required int rotationDegrees,
  }) async {
    try {
      final now = DateTime.now();
      final scan = OcrScan(
        id: _uuid.v4(),
        // Replaced with a fresh key on each confirm attempt; the value here
        // just keeps the NOT NULL column honest until then.
        idempotencyKey: _uuid.v4(),
        sourceImagePath: sourceImagePath,
        cropBounds: cropBounds,
        rotationDegrees: rotationDegrees,
        status: ScanStatus.processing,
        createdAt: now,
      );
      await _dao.insertScan(
        db.OcrScansCompanion.insert(
          id: scan.id,
          idempotencyKey: scan.idempotencyKey,
          sourceImagePath: scan.sourceImagePath,
          cropBounds: db.Value(scan.cropBounds),
          rotationDegrees: db.Value(scan.rotationDegrees),
          status: scan.status.dbValue,
          createdAt: now.millisecondsSinceEpoch,
        ),
      );
      return Right(scan);
    } catch (e) {
      return Left(CacheFailure('Failed to start scan: $e'));
    }
  }

  @override
  Future<Either<Failure, OcrScan>> runExtraction(String scanId) async {
    final db.OcrScan? row;
    try {
      row = await _dao.getScanById(scanId);
    } catch (e) {
      return Left(CacheFailure('Failed to load scan: $e'));
    }
    if (row == null) return const Left(NotFoundFailure('Scan not found'));
    final scan = row.toDomain();

    final recognized = await _recognitionService.recognize(
      scan.sourceImagePath,
    );
    return recognized.match(
      (failure) async {
        // A scan that produced nothing is recorded as `failed` rather than
        // left in `processing`: a user returning to their history should
        // see what happened, not a session that looks stuck forever.
        await _markFailed(scanId);
        return Left(failure);
      },
      (text) async {
        if (text.isEmpty) {
          await _markFailed(scanId);
          return const Left(
            NoTextRecognizedFailure('No readable text was found in the image'),
          );
        }
        final parsed = _parser.parse(
          text,
          scanId: scanId,
          scanCreatedAt: scan.createdAt,
          now: DateTime.now(),
          generateId: _uuid.v4,
        );
        if (parsed.isEmpty) {
          await _markFailed(scanId);
          return const Left(
            NoCandidatesParsedFailure(
              'Text was found, but no name and amount lines could be read '
              'from it',
            ),
          );
        }
        final entries = parsed.entries.take(maxEntriesPerScan).toList();
        try {
          await _dao.insertCandidateEntries([
            for (final entry in entries) _companionFor(entry),
          ]);
          await _dao.updateScan(
            scanId,
            db.OcrScansCompanion(
              status: db.Value(ScanStatus.needsReview.dbValue),
            ),
          );
        } catch (e) {
          return Left(CacheFailure('Failed to save candidate entries: $e'));
        }
        return Right(scan.copyWith(status: ScanStatus.needsReview));
      },
    );
  }

  @override
  Future<Either<Failure, OcrScan>> setBatchDefaultDirection({
    required String scanId,
    required TransactionDirection direction,
  }) async {
    // Only the scan's own column is written. Entries that already carry a
    // direction are untouched by construction — the default is read as a
    // fallback at confirm time rather than copied onto each row, so
    // changing it can never overwrite a correction the user already made
    // (FR-005).
    return _updateScan(
      scanId,
      db.OcrScansCompanion(defaultDirection: db.Value(direction.dbValue)),
      'Failed to set the batch direction',
    );
  }

  @override
  Future<Either<Failure, OcrScan>> tagBatchToOccasion({
    required String scanId,
    String? occasionId,
  }) {
    return _updateScan(
      scanId,
      db.OcrScansCompanion(occasionId: db.Value(occasionId)),
      'Failed to tag the batch to an occasion',
    );
  }

  @override
  Future<Either<Failure, OcrScan>> getScan(String scanId) async {
    try {
      final row = await _dao.getScanById(scanId);
      if (row == null) return const Left(NotFoundFailure('Scan not found'));
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to load scan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<CandidateEntry>>> getCandidateEntries(
    String scanId,
  ) async {
    try {
      final rows = await _dao.getEntriesForScan(scanId);
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load candidate entries: $e'));
    }
  }

  @override
  Future<Either<Failure, CandidateEntry>> editCandidateEntry({
    required String entryId,
    String? personName,
    String? matchedPersonId,
    bool clearMatchedPersonId = false,
    int? amountMinorUnits,
    TransactionDirection? direction,
    DateTime? date,
    String? notes,
  }) async {
    // The same rule manual entry applies (001 FR-005), applied here for the
    // same reason: a value the user typed deserves the same scrutiny
    // whether or not a scan suggested it first.
    if (amountMinorUnits != null && amountMinorUnits <= 0) {
      return const Left(ValidationFailure('Amount must be greater than zero'));
    }
    final db.CandidateEntry? row;
    try {
      row = await _dao.getEntryById(entryId);
    } catch (e) {
      return Left(CacheFailure('Failed to load candidate entry: $e'));
    }
    if (row == null) {
      return const Left(NotFoundFailure('Candidate entry not found'));
    }
    if (row.status == CandidateEntryStatus.confirmed.dbValue) {
      // A confirmed entry has already become a real transaction. Editing it
      // here would change the suggestion while leaving the money as it was,
      // so the honest answer is to send the user to the transaction itself.
      return const Left(
        ValidationFailure(
          'This entry has already been confirmed; edit the transaction '
          'instead',
        ),
      );
    }

    // Any user edit makes the field a user-set value, not a recognition
    // result — so its confidence becomes `inferred`, which the review
    // screen renders differently from an OCR read (FR-013). Showing a
    // typed-in name under a "high confidence OCR read" badge would be a
    // small lie with a large effect on how carefully it gets checked.
    final edited = const FieldConfidence.inferred();
    final changes = db.CandidateEntriesCompanion(
      personName: personName == null
          ? const db.Value.absent()
          : db.Value(personName),
      personNameConfidenceKind: personName == null
          ? const db.Value.absent()
          : db.Value(edited.kindDbValue),
      personNameConfidenceLevel: personName == null
          ? const db.Value.absent()
          : db.Value(edited.levelDbValue),
      matchedPersonId: clearMatchedPersonId
          ? const db.Value(null)
          : (matchedPersonId == null
                ? const db.Value.absent()
                : db.Value(matchedPersonId)),
      amountMinorUnits: amountMinorUnits == null
          ? const db.Value.absent()
          : db.Value(amountMinorUnits),
      amountConfidenceKind: amountMinorUnits == null
          ? const db.Value.absent()
          : db.Value(edited.kindDbValue),
      amountConfidenceLevel: amountMinorUnits == null
          ? const db.Value.absent()
          : db.Value(edited.levelDbValue),
      direction: direction == null
          ? const db.Value.absent()
          : db.Value(direction.dbValue),
      directionConfidenceKind: direction == null
          ? const db.Value.absent()
          : db.Value(edited.kindDbValue),
      directionConfidenceLevel: direction == null
          ? const db.Value.absent()
          : db.Value(edited.levelDbValue),
      date: date == null
          ? const db.Value.absent()
          : db.Value(date.millisecondsSinceEpoch),
      dateConfidenceKind: date == null
          ? const db.Value.absent()
          : db.Value(edited.kindDbValue),
      dateConfidenceLevel: date == null
          ? const db.Value.absent()
          : db.Value(edited.levelDbValue),
      notes: notes == null ? const db.Value.absent() : db.Value(notes),
      editedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
    );
    try {
      await _dao.updateEntry(entryId, changes);
      final updated = await _dao.getEntryById(entryId);
      return Right(updated!.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to save the correction: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> discardCandidateEntry(String entryId) async {
    try {
      final row = await _dao.getEntryById(entryId);
      if (row == null) {
        return const Left(NotFoundFailure('Candidate entry not found'));
      }
      await _dao.updateEntry(
        entryId,
        db.CandidateEntriesCompanion(
          status: db.Value(CandidateEntryStatus.discarded.dbValue),
          editedAt: db.Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to discard the entry: $e'));
    }
  }

  /// **The gate** (constitution Principle X, FR-007).
  ///
  /// The structure here is the safety property, so it is worth stating what
  /// each step is load-bearing for:
  ///
  /// 1. The idempotency check comes first, so a second tap returns the
  ///    first batch instead of creating another (FR-021).
  /// 2. Eligibility is checked across *every* non-discarded entry before
  ///    anything is written, and a single ineligible entry aborts the whole
  ///    call (FR-011). A partial save would leave the user unable to tell
  ///    which lines made it in.
  /// 3. The writes happen inside one database transaction, so a failure
  ///    part-way through rolls the whole batch back.
  /// 4. Each row is created by `TransactionsRepository` or
  ///    `OccasionsRepository` — never by this method — so an OCR-sourced
  ///    transaction is built by exactly the code that builds a manual one.
  @override
  Future<Either<Failure, List<MoneyTransaction>>> confirmScanBatch({
    required String idempotencyKey,
    required String scanId,
  }) async {
    final db.OcrScan? scanRow;
    try {
      scanRow = await _dao.getScanById(scanId);
    } catch (e) {
      return Left(CacheFailure('Failed to load scan: $e'));
    }
    if (scanRow == null) return const Left(NotFoundFailure('Scan not found'));
    final scan = scanRow.toDomain();

    // (1) A retried confirm returns what the first one created rather than
    // a second batch. Checked against the scan's own recorded key, so the
    // guarantee survives the app being killed between the two taps.
    if (scan.status == ScanStatus.confirmed &&
        scan.idempotencyKey == idempotencyKey) {
      return _transactionsRepository.getTransactionsForScan(scanId);
    }
    if (scan.status == ScanStatus.confirmed) {
      return const Left(
        ValidationFailure('This scan has already been confirmed'),
      );
    }

    final List<db.CandidateEntry> entryRows;
    try {
      entryRows = await _dao.getEntriesForScan(scanId);
    } catch (e) {
      return Left(CacheFailure('Failed to load candidate entries: $e'));
    }
    final pending = [
      for (final row in entryRows)
        if (row.status != CandidateEntryStatus.discarded.dbValue)
          row.toDomain(),
    ];
    if (pending.isEmpty) {
      return const Left(
        ValidationFailure('There is nothing left to confirm in this scan'),
      );
    }

    // (2) All-or-nothing eligibility, using the entity's own rule so the
    // UI's enabled/disabled state and this check can never disagree.
    final ineligible = [
      for (final entry in pending)
        if (!entry.isConfirmEligible(scan.defaultDirection)) entry,
    ];
    if (ineligible.isNotEmpty) {
      final names = ineligible
          .map((e) => e.personName.trim().isEmpty ? e.rawOcrText : e.personName)
          .join(', ');
      return Left(
        ValidationFailure(
          'These entries are not complete yet, so nothing was saved: $names',
        ),
      );
    }

    try {
      // (3) One transaction around the whole batch.
      final saved = await _dao.transaction(() async {
        final created = <MoneyTransaction>[];
        for (final entry in pending) {
          final personResult = await _resolvePersonId(entry);
          final personId = personResult.getOrElse((failure) => '');
          if (personId.isEmpty) {
            throw _BatchAborted(
              personResult.getLeft().getOrElse(
                () => const UnknownFailure('Could not resolve a person'),
              ),
            );
          }

          final direction = entry.effectiveDirection(scan.defaultDirection)!;
          final date = entry.effectiveDate(scan.createdAt);
          final amount = Money.fromMinorUnits(entry.amountMinorUnits!);
          // One idempotency key per entry, derived from the batch's key so
          // the whole retried batch — not just its first row — is a no-op
          // the second time.
          final entryKey = '$idempotencyKey:${entry.id}';

          // (4) Delegated, never inserted here. Which of the two paths is
          // taken is 008's question, answered by 008's code.
          final result = scan.isOccasionTagged
              ? await _occasionsRepository.addParticipantContribution(
                  idempotencyKey: entryKey,
                  occasionId: scan.occasionId!,
                  personId: personId,
                  amount: amount,
                  direction: direction,
                  date: date,
                  note: entry.notes,
                  ocrScanId: scanId,
                )
              : await _transactionsRepository.addOcrSourcedTransaction(
                  idempotencyKey: entryKey,
                  personId: personId,
                  ocrScanId: scanId,
                  amount: amount,
                  direction: direction,
                  date: date,
                  note: entry.notes,
                );
          result.match((failure) => throw _BatchAborted(failure), created.add);

          await _dao.updateEntry(
            entry.id,
            db.CandidateEntriesCompanion(
              status: db.Value(CandidateEntryStatus.confirmed.dbValue),
              matchedPersonId: db.Value(personId),
            ),
          );
        }

        final now = DateTime.now();
        await _dao.updateScan(
          scanId,
          db.OcrScansCompanion(
            status: db.Value(ScanStatus.confirmed.dbValue),
            // Recorded so a retry of this same confirm is recognized as one.
            idempotencyKey: db.Value(idempotencyKey),
            completedAt: db.Value(now.millisecondsSinceEpoch),
          ),
        );
        return created;
      });
      return Right(saved);
    } on _BatchAborted catch (aborted) {
      return Left(aborted.failure);
    } catch (e) {
      return Left(CacheFailure('Failed to confirm the batch: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> cancelScan(String scanId) async {
    try {
      final scanRow = await _dao.getScanById(scanId);
      if (scanRow == null) {
        return const Left(NotFoundFailure('Scan not found'));
      }
      if (scanRow.status == ScanStatus.confirmed.dbValue) {
        return const Left(
          ValidationFailure('A confirmed scan cannot be cancelled'),
        );
      }
      final entries = await _dao.getEntriesForScan(scanId);
      final hasCorrections = entries.any((e) => e.editedAt != null);
      final now = DateTime.now();
      if (hasCorrections) {
        // The user put work into this one. Keeping it as `discarded` means
        // a mis-tap on "cancel" costs a trip to scan history, not the
        // corrections themselves (FR-015).
        await _dao.updateScan(
          scanId,
          db.OcrScansCompanion(
            status: db.Value(ScanStatus.discarded.dbValue),
            completedAt: db.Value(now.millisecondsSinceEpoch),
          ),
        );
      } else {
        // Nothing worth keeping: an abandoned scan with no corrections is
        // just a photo the user changed their mind about.
        await _deleteScanAndImage(scanId, scanRow.sourceImagePath);
      }
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to cancel the scan: $e'));
    }
  }

  @override
  Future<Either<Failure, List<OcrScan>>> getScanHistory() async {
    try {
      final rows = await _dao.getScanHistory();
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load scan history: $e'));
    }
  }

  @override
  Future<Either<Failure, OcrScanDetail>> getScanDetail(String scanId) async {
    try {
      final scanRow = await _dao.getScanById(scanId);
      if (scanRow == null) {
        return const Left(NotFoundFailure('Scan not found'));
      }
      final entryRows = await _dao.getEntriesForScan(scanId);
      final transactions = await _transactionsRepository.getTransactionsForScan(
        scanId,
      );
      return transactions.map(
        (rows) => OcrScanDetail(
          scan: scanRow.toDomain(),
          entries: [for (final row in entryRows) row.toDomain()],
          transactions: rows,
        ),
      );
    } catch (e) {
      return Left(CacheFailure('Failed to load the scan: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteScan(String scanId) async {
    try {
      final scanRow = await _dao.getScanById(scanId);
      if (scanRow == null) {
        return const Left(NotFoundFailure('Scan not found'));
      }
      // Deliberately does not touch `money_transactions`: by the time a row
      // exists there the user confirmed it, and it is a financial record in
      // its own right. Deleting the scan costs the "view original scan"
      // link and nothing else (data-model.md Relationships).
      await _deleteScanAndImage(scanId, scanRow.sourceImagePath);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to delete the scan: $e'));
    }
  }

  // --- helpers -------------------------------------------------------------

  /// Resolves the person a confirmed entry belongs to: the one the user
  /// matched it to, or a newly created person carrying the reviewed name —
  /// exactly what manual entry does when the typed name is new.
  Future<Either<Failure, String>> _resolvePersonId(CandidateEntry entry) async {
    final matched = entry.matchedPersonId;
    if (matched != null && matched.isNotEmpty) return Right(matched);
    // `confirmCreateDespiteDuplicate` rather than `createPerson`: the
    // duplicate check already ran on the review screen (FR-009), where the
    // user could see the candidates and decide. Re-running it here would
    // fail the batch over a question that has already been answered.
    final created = await _peopleRepository.confirmCreateDespiteDuplicate(
      name: entry.personName.trim(),
    );
    return created.map((person) => person.id);
  }

  Future<Either<Failure, OcrScan>> _updateScan(
    String scanId,
    db.OcrScansCompanion changes,
    String errorMessage,
  ) async {
    try {
      final existing = await _dao.getScanById(scanId);
      if (existing == null) {
        return const Left(NotFoundFailure('Scan not found'));
      }
      await _dao.updateScan(scanId, changes);
      final updated = await _dao.getScanById(scanId);
      return Right(updated!.toDomain());
    } catch (e) {
      return Left(CacheFailure('$errorMessage: $e'));
    }
  }

  Future<void> _markFailed(String scanId) async {
    try {
      await _dao.updateScan(
        scanId,
        db.OcrScansCompanion(status: db.Value(ScanStatus.failed.dbValue)),
      );
    } catch (_) {
      // The extraction failure the caller is already returning is the more
      // useful thing to report; failing to record the status on top of it
      // should not replace it with a storage error.
    }
  }

  Future<void> _deleteScanAndImage(String scanId, String imagePath) async {
    await _dao.deleteEntriesForScan(scanId);
    await _dao.deleteScanRow(scanId);
    try {
      final file = File(imagePath);
      if (file.existsSync()) await file.delete();
    } catch (_) {
      // The record is gone, which is what the user asked for. A leftover
      // file in private storage is not worth failing the delete over.
    }
  }

  db.CandidateEntriesCompanion _companionFor(CandidateEntry entry) {
    return db.CandidateEntriesCompanion.insert(
      id: entry.id,
      scanId: entry.scanId,
      status: db.Value(entry.status.dbValue),
      personName: entry.personName,
      personNameConfidenceKind: entry.personNameConfidence.kindDbValue,
      personNameConfidenceLevel: entry.personNameConfidence.levelDbValue,
      matchedPersonId: db.Value(entry.matchedPersonId),
      amountMinorUnits: db.Value(entry.amountMinorUnits),
      amountConfidenceKind: entry.amountConfidence.kindDbValue,
      amountConfidenceLevel: entry.amountConfidence.levelDbValue,
      direction: db.Value(entry.direction?.dbValue),
      directionConfidenceKind: entry.directionConfidence.kindDbValue,
      directionConfidenceLevel: entry.directionConfidence.levelDbValue,
      date: db.Value(entry.date?.millisecondsSinceEpoch),
      dateConfidenceKind: entry.dateConfidence.kindDbValue,
      dateConfidenceLevel: entry.dateConfidence.levelDbValue,
      notes: db.Value(entry.notes),
      rawOcrText: entry.rawOcrText,
      createdAt: entry.createdAt.millisecondsSinceEpoch,
      editedAt: db.Value(entry.editedAt?.millisecondsSinceEpoch),
    );
  }
}

/// Unwinds the batch loop from inside the database transaction so the whole
/// confirm rolls back. Private to this file: it is a control-flow device,
/// not a failure type anyone else should see — callers get the [Failure] it
/// carries.
class _BatchAborted implements Exception {
  const _BatchAborted(this.failure);

  final Failure failure;
}
