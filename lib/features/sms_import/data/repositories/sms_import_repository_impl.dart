import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/domain/repositories/finance_repository.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../../domain/entities/sms_import_tombstone.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/repositories/sms_import_repository.dart';
import '../../domain/rules/calendar_days.dart';
import '../../domain/services/bank_reference_policy.dart';
import '../../domain/services/raw_text_vault.dart';
import '../../domain/services/sms_masker.dart';
import '../datasources/sms_import_dao.dart';
import '../datasources/sms_import_settings_dao.dart';
import '../models/pending_import_mapper.dart';
import '../models/tombstone_mapper.dart';

/// Pending imports, tombstones and decisions (domain-interfaces §3.1).
///
/// The core part (T058): idempotent staging, the exact-tier lookups, reads,
/// the original-text open, delete-all-pending and the transition guard of
/// data-model §6. The decisions are [confirm] (T074), [closeAsDuplicate]
/// (T100), [ignore] and [undo] (T131); maintenance is [expireDue] and
/// [purgeDecided] (T077) and [replaceParsedFields] (T127).
///
/// Ingestion never creates a `MoneyTransaction` or a `FinanceEntry`
/// (FR-022): [confirm] is the only path, and only after an explicit Add on
/// one item (FR-052). Every
/// failure is a fixed, content-free token: SQLite errors embed bound
/// parameters and crypto errors may describe inputs, so no exception text
/// is ever passed on, logged or kept.
@LazySingleton(as: SmsImportRepository)
class SmsImportRepositoryImpl implements SmsImportRepository {
  SmsImportRepositoryImpl(
    this._dao,
    this._settingsDao,
    this._vault,
    this._masker,
    this._policy,
    this._clock,
    this._transactions,
    this._finance,
  );

  final SmsImportDao _dao;
  final SmsImportSettingsDao _settingsDao;
  final RawTextVault _vault;
  final SmsMasker _masker;
  final BankReferencePolicy _policy;
  final AppClock _clock;

  /// Used only by [confirm] (the single review gate, invariant 2).
  final TransactionsRepository _transactions;
  final FinanceRepository _finance;

  static const Failure _storeFailure = CacheFailure('sms_import_store_failed');
  static const Failure _invalidItem = ValidationFailure('sms_pending_invalid');
  static const Failure _notFound = NotFoundFailure('sms_import_not_found');

  /// The content-free failures [confirm] maps every inner failure to
  /// (inner messages can carry SQLite bound parameters or a category name;
  /// discovery transactions.md F5, finance.md G3).
  static const Failure _confirmFailed = CacheFailure('sms_confirm_failed');
  static const Failure _confirmRejected = ValidationFailure(
    'sms_confirm_rejected',
  );
  static const Failure _confirmTargetMissing = NotFoundFailure(
    'sms_confirm_target_missing',
  );

  /// How long a decided row stays for the Undo list and retried Adds.
  static const Duration decidedRetention = Duration(days: 30);

  db.AppDatabase get _db => _dao.database;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Right(await body());
    } catch (_) {
      // Never inspected or kept (see the class doc).
      return const Left(_storeFailure);
    }
  }

  // --------------------------------------------------------- transitions

  /// The legal moves of data-model §6: only `pending` may move, and only to
  /// a terminal status. Terminal -> pending, terminal -> another terminal
  /// and any move of `added` are illegal (row deletion by purge or Undo is
  /// not a transition).
  static bool canTransition(SmsImportStatus from, SmsImportStatus to) =>
      from == SmsImportStatus.pending && to.isTerminal;

  /// The single write path of a status change, for the decision methods:
  /// in ONE transaction it re-reads the row, refuses an illegal move with
  /// `ImportAlreadyDecidedFailure(current)`, writes [changes] with the new
  /// status and `decided_at`, and always nulls `raw_blob` (FR-075).
  @visibleForTesting
  Future<Either<Failure, Unit>> transitionRow(
    String id,
    SmsImportStatus to, {
    db.PendingSmsImportsCompanion changes =
        const db.PendingSmsImportsCompanion(),
  }) async {
    try {
      return await _db.transaction(() async {
        final row = await _dao.getPendingById(id);
        if (row == null) return const Left(_notFound);
        final current = SmsImportStatus.fromDb(row.status);
        if (!canTransition(current, to)) {
          return Left(ImportAlreadyDecidedFailure(current));
        }
        await _dao.updatePending(
          id,
          changes.copyWith(
            status: db.Value(to.dbValue),
            decidedAt: db.Value(_clock.now().millisecondsSinceEpoch),
            rawBlob: const db.Value(null),
          ),
        );
        return const Right(unit);
      });
    } catch (_) {
      return const Left(_storeFailure);
    }
  }

  // ------------------------------------------------------------ ingestion

  @override
  Future<Either<Failure, InsertOutcome>> insertPending(
    NewPendingImport item,
  ) async {
    final row = item.item;
    if (!row.isPending || row.invariantViolations.isNotEmpty) {
      return const Left(_invalidItem);
    }
    return _guard(
      () => _db.transaction(() async {
        if (await _isKnown(row)) return InsertOutcome.alreadyKnown;
        final blob = await _sealOrNull(item.rawMasked, aad: row.id);
        final inserted = await _dao.insertPendingIfAbsent(
          pendingImportToCompanion(row).copyWith(rawBlob: db.Value(blob)),
        );
        return inserted ? InsertOutcome.inserted : InsertOutcome.alreadyKnown;
      }),
    );
  }

  /// Exact tiers 1-2 at staging (FR-059, FR-059b): the fingerprint is in a
  /// pending row or a tombstone; or the reference-amount hash is, for a
  /// bank whose references are unique, or (for any other bank) on a
  /// pending row dated within one calendar day. A tombstone keeps no date,
  /// so for a non-unique bank it never collapses a message by reference.
  Future<bool> _isKnown(PendingSmsImport row) async {
    final fingerprint = {row.fingerprint};
    if ((await _dao.pendingFingerprintsIn(fingerprint)).isNotEmpty) {
      return true;
    }
    if ((await _dao.tombstonedFingerprintsIn(fingerprint)).isNotEmpty) {
      return true;
    }
    final refAmountHash = row.refAmountHash;
    if (refAmountHash == null) return false;
    if (_policy.refIsUnique(row.bankId)) {
      final hashes = {refAmountHash};
      return (await _dao.pendingRefAmountHashesIn(hashes)).isNotEmpty ||
          (await _dao.tombstonedRefAmountHashesIn(hashes)).isNotEmpty;
    }
    final date = row.occurredOn;
    if (date == null) return false;
    final others = await _dao.pendingWithRefAmountHash(refAmountHash);
    return others.any((other) {
      final otherDate = other.occurredOn;
      return otherDate != null &&
          withinOneCalendarDay(
            date,
            DateTime.fromMillisecondsSinceEpoch(otherDate),
          );
    });
  }

  /// Masks again (idempotent, defence in depth), then seals. Any failure
  /// stores the row with no original rather than failing the insert.
  Future<Uint8List?> _sealOrNull(String? raw, {required String aad}) async {
    if (raw == null) return null;
    try {
      return await _vault.seal(_masker.mask(raw), aad: aad);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Either<Failure, KnownKeys>> findKnown({
    required Set<String> fingerprints,
    required Set<String> refAmountHashes,
  }) => _guard(() async {
    final knownFingerprints = {
      ...await _dao.pendingFingerprintsIn(fingerprints),
      ...await _dao.tombstonedFingerprintsIn(fingerprints),
    };
    final knownRefAmount = {
      ...await _dao.pendingRefAmountHashesIn(refAmountHashes),
      ...await _dao.tombstonedRefAmountHashesIn(refAmountHashes),
    };
    return KnownKeys(
      fingerprints: knownFingerprints,
      refAmountHashes: knownRefAmount,
    );
  });

  @override
  Future<Either<Failure, Set<String>>> refHashesForBank(String bankId) =>
      _guard(
        () async => {
          ...await _dao.pendingRefHashesForBank(bankId),
          ...await _dao.tombstoneRefHashesForBank(bankId),
        },
      );

  // -------------------------------------------------------------- reading

  Future<Either<Failure, List<PendingSmsImport>>> _pendingSorted() =>
      _guard(() async {
        final rows = await _dao.getByStatus(SmsImportStatus.pending.dbValue);
        final items = [for (final row in rows) row.toDomain()];
        items.sort((a, b) {
          final byConfidence = a.confidence.overall.index.compareTo(
            b.confidence.overall.index,
          );
          if (byConfidence != 0) return byConfidence;
          final byAge = a.createdAt.compareTo(b.createdAt);
          return byAge != 0 ? byAge : a.id.compareTo(b.id);
        });
        return items;
      });

  @override
  Stream<Either<Failure, List<PendingSmsImport>>> watchPending() =>
      _db.watchEither({_db.pendingSmsImports}, _pendingSorted);

  @override
  Stream<Either<Failure, int>> watchPendingCount() => _db.watchEither({
    _db.pendingSmsImports,
  }, () => _guard(() => _dao.countByStatus(SmsImportStatus.pending.dbValue)));

  @override
  Future<Either<Failure, PendingSmsImport>> getById(String id) async {
    try {
      final row = await _dao.getPendingById(id);
      return row == null ? const Left(_notFound) : Right(row.toDomain());
    } catch (_) {
      return const Left(_storeFailure);
    }
  }

  Future<Either<Failure, List<PendingSmsImport>>> _undoList() =>
      _guard(() async {
        final since = _clock.now().subtract(decidedRetention);
        final rows = await _dao.decidedSince({
          SmsImportStatus.ignored.dbValue,
          SmsImportStatus.expired.dbValue,
        }, since.millisecondsSinceEpoch);
        return [for (final row in rows) row.toDomain()];
      });

  @override
  Stream<Either<Failure, List<PendingSmsImport>>> watchUndoList() =>
      _db.watchEither({_db.pendingSmsImports}, _undoList);

  @override
  Future<Either<Failure, int>> unseenExpiredCount() => _guard(() async {
    final settings = await _settingsDao.getSettings();
    final seenAt = settings?.expiredNoticeSeenAt;
    final rows = await _dao.getByStatus(SmsImportStatus.expired.dbValue);
    return rows.where((row) {
      final decidedAt = row.decidedAt;
      return decidedAt != null && (seenAt == null || decidedAt > seenAt);
    }).length;
  });

  @override
  Future<Either<Failure, Unit>> markExpiredNoticeSeen() => _guard(() async {
    await _settingsDao.updateSettings(
      db.SmsImportSettingsCompanion(
        expiredNoticeSeenAt: db.Value(_clock.now().millisecondsSinceEpoch),
      ),
    );
    return unit;
  });

  @override
  Future<Either<Failure, String>> openOriginal(String id) async {
    db.PendingSmsImportRow? row;
    try {
      row = await _dao.getPendingById(id);
    } catch (_) {
      return const Left(_storeFailure);
    }
    final blob = row?.rawBlob;
    if (row == null ||
        blob == null ||
        SmsImportStatus.fromDb(row.status) != SmsImportStatus.pending) {
      return const Left(OriginalUnavailableFailure());
    }
    String? text;
    try {
      text = await _vault.open(blob, aad: id);
    } catch (_) {
      text = null;
    }
    if (text != null) return Right(text);
    // First failed open: the original is gone for good (key loss, tag
    // failure); the parsed fields stay (FR-074a).
    try {
      await _dao.clearRawBlobIfPending(id);
    } catch (_) {
      // The read already failed; the user sees "unavailable" either way.
    }
    return const Left(OriginalUnavailableFailure());
  }

  // ------------------------------------------------------------ decisions

  /// THE gate (FR-052, FR-075a). One database transaction:
  ///
  /// 1. re-read the row INSIDE the transaction and require `pending`
  ///    (drift serializes top-level transactions on the one database, so a
  ///    second, concurrent confirm sees `added` here; discovery F3);
  /// 2. for a person transaction, require that the person exists;
  /// 3. create the record through `addSmsSourcedTransaction` or
  ///    `addSmsSourcedEntry` with key `sms-import:<id>`;
  /// 4. write the `added` tombstone, mark the row added, null `raw_blob`
  ///    and scrub the content columns (identity shell, data-model §6);
  /// 5. upsert the learned mapping when the chosen category differs from
  ///    the suggestion (FR-056), and increment `addedCount`.
  ///
  /// The inner repositories run as savepoints and return `Left` instead of
  /// throwing (discovery F2), so EVERY `Left` is turned into a thrown
  /// [_ConfirmAborted]: the whole transaction, outbox rows included, rolls
  /// back. Every failure is mapped to a fixed token; no inner message is
  /// ever passed on.
  @override
  Future<Either<Failure, SavedRecordRef>> confirm({
    required String pendingId,
    required ConfirmedImport confirmed,
  }) async {
    try {
      final ref = await _db.transaction(() async {
        final row = await _dao.getPendingById(pendingId);
        if (row == null) throw const _ConfirmAborted(_notFound);
        final current = SmsImportStatus.fromDb(row.status);
        if (current != SmsImportStatus.pending) {
          throw _ConfirmAborted(ImportAlreadyDecidedFailure(current));
        }
        final key = 'sms-import:$pendingId';

        final SavedRecordRef saved;
        switch (confirmed) {
          case ConfirmedPersonTransaction():
            if (!await _personExists(confirmed.personId)) {
              throw const _ConfirmAborted(_confirmTargetMissing);
            }
            final result = await _transactions.addSmsSourcedTransaction(
              idempotencyKey: key,
              personId: confirmed.personId,
              amount: confirmed.amount,
              direction: confirmed.direction,
              date: confirmed.date,
              note: confirmed.note,
            );
            final record = result.fold(
              (f) => throw _ConfirmAborted(f),
              (t) => t,
            );
            saved = SavedRecordRef(
              id: record.id,
              type: SavedRecordType.moneyTransaction,
            );
          case ConfirmedFinanceEntry():
            final result = await _finance.addSmsSourcedEntry(
              idempotencyKey: key,
              categoryId: confirmed.categoryId,
              type: confirmed.type,
              amount: confirmed.amount,
              date: confirmed.date,
              note: confirmed.note,
            );
            final record = result.fold(
              (f) => throw _ConfirmAborted(f),
              (e) => e,
            );
            saved = SavedRecordRef(
              id: record.id,
              type: SavedRecordType.financeEntry,
            );
        }

        final now = _clock.now();
        await _dao.insertTombstone(
          tombstoneToCompanion(
            SmsImportTombstone(
              fingerprint: row.fingerprint,
              outcome: TombstoneOutcome.added,
              bankId: row.bankId,
              refHash: row.refHash,
              refAmountHash: row.refAmountHash,
              savedRecordId: saved.id,
              savedRecordType: saved.type,
              createdAt: now,
              purgeAfter: SmsImportTombstone.minimumPurgeAfter(now),
            ),
          ),
        );

        final changed = await _dao.updatePending(
          pendingId,
          _identityShell.copyWith(
            status: db.Value(SmsImportStatus.added.dbValue),
            decidedAt: db.Value(now.millisecondsSinceEpoch),
            savedRecordId: db.Value(saved.id),
            savedRecordType: db.Value(saved.type.dbValue),
          ),
        );
        if (changed != 1) throw const _ConfirmAborted(_confirmFailed);

        // Learned mapping (FR-056): only an own-money entry with a
        // merchant key, and only when the user changed the suggestion.
        final merchantKey = row.merchantKey;
        if (confirmed is ConfirmedFinanceEntry &&
            merchantKey != null &&
            merchantKey.isNotEmpty &&
            confirmed.categoryId != row.suggestedCategoryId) {
          await _settingsDao.upsertMapping(
            db.SmsMerchantCategoryMappingsCompanion.insert(
              merchantKey: merchantKey,
              entryType: confirmed.type.dbValue,
              categoryId: confirmed.categoryId,
              updatedAt: now.millisecondsSinceEpoch,
            ),
          );
        }
        await _settingsDao.addCounts(added: 1);
        return saved;
      });
      return Right(ref);
    } on _ConfirmAborted catch (aborted) {
      return Left(_contentFree(aborted.failure));
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_confirmFailed);
    }
  }

  Future<bool> _personExists(String personId) async {
    final row = await (_db.select(
      _db.people,
    )..where((p) => p.id.equals(personId))).getSingleOrNull();
    return row != null;
  }

  /// Keeps only the type of an inner failure, never its message.
  static Failure _contentFree(Failure failure) => switch (failure) {
    ImportAlreadyDecidedFailure() => failure,
    SmsImportFailure() => _confirmFailed,
    ValidationFailure() => _confirmRejected,
    _ when failure == _notFound => _notFound,
    NotFoundFailure() => _confirmTargetMissing,
    _ => _confirmFailed,
  };

  /// An `added`/`duplicateClosed` row keeps only its identity (id,
  /// status, hashes, saved record) so a retried Add can answer
  /// `ImportAlreadyDecided`; every parsed content column is cleared
  /// (data-model §6 refinement, review A9). `confidence_json` is NOT NULL
  /// with no default, so it is written as `'{}'`.
  static const db.PendingSmsImportsCompanion _identityShell =
      db.PendingSmsImportsCompanion(
        rawBlob: db.Value(null),
        senderId: db.Value(null),
        kind: db.Value('unknown'),
        direction: db.Value('unknown'),
        amountMinorUnits: db.Value(null),
        currencyCode: db.Value(null),
        occurredOn: db.Value(null),
        timeMinutes: db.Value(null),
        merchant: db.Value(null),
        merchantKey: db.Value(null),
        counterparty: db.Value(null),
        cardLast4: db.Value(null),
        suggestedCategoryId: db.Value(null),
        suggestedPersonId: db.Value(null),
        suggestedAction: db.Value('unset'),
        confidenceJson: db.Value('{}'),
        warningsJson: db.Value('{}'),
      );

  /// An `ignored`/`expired` row keeps only what the Undo list shows:
  /// amount, currency, date, merchant/counterparty, bank and kind
  /// (FR-025, data-model §6). Everything else is cleared.
  static const db.PendingSmsImportsCompanion _undoShell =
      db.PendingSmsImportsCompanion(
        rawBlob: db.Value(null),
        senderId: db.Value(null),
        direction: db.Value('unknown'),
        timeMinutes: db.Value(null),
        merchantKey: db.Value(null),
        cardLast4: db.Value(null),
        suggestedCategoryId: db.Value(null),
        suggestedPersonId: db.Value(null),
        suggestedAction: db.Value('unset'),
        confidenceJson: db.Value('{}'),
        warningsJson: db.Value('{}'),
      );

  /// Ignore one item or a batch (FR-064, data-model §6), in ONE
  /// transaction. For every id: re-read the row and require `pending`;
  /// write the `ignored` tombstone (so the message never resurfaces,
  /// FR-066); mark the row `ignored` with `decided_at`; null `raw_blob`;
  /// keep only the six Undo-list fields (amount, currency, date,
  /// merchant/counterparty, bank, kind) and clear the rest ([_undoShell]).
  /// `ignoredCount` grows by the number ignored.
  ///
  /// All or nothing: a missing id (`NotFoundFailure`) or an item that is
  /// no longer pending (`ImportAlreadyDecidedFailure(current)`) rolls the
  /// whole batch back, so nothing is half-ignored and a decided item's
  /// tombstone is never overwritten. An empty set is a no-op. Every
  /// failure is a fixed token.
  @override
  Future<Either<Failure, Unit>> ignore(Set<String> ids) async {
    if (ids.isEmpty) return const Right(unit);
    try {
      await _db.transaction(() async {
        final now = _clock.now();
        for (final id in ids) {
          final row = await _dao.getPendingById(id);
          if (row == null) throw const _DecisionAborted(_notFound);
          final current = SmsImportStatus.fromDb(row.status);
          if (!canTransition(current, SmsImportStatus.ignored)) {
            throw _DecisionAborted(ImportAlreadyDecidedFailure(current));
          }
          await _dao.insertTombstone(
            tombstoneToCompanion(
              SmsImportTombstone(
                fingerprint: row.fingerprint,
                outcome: TombstoneOutcome.ignored,
                bankId: row.bankId,
                refHash: row.refHash,
                refAmountHash: row.refAmountHash,
                createdAt: now,
                purgeAfter: SmsImportTombstone.minimumPurgeAfter(now),
              ),
            ),
          );
          final changed = await _dao.updatePending(
            id,
            _undoShell.copyWith(
              status: db.Value(SmsImportStatus.ignored.dbValue),
              decidedAt: db.Value(now.millisecondsSinceEpoch),
            ),
          );
          if (changed != 1) throw const _DecisionAborted(_storeFailure);
        }
        await _settingsDao.addCounts(ignored: ids.length);
      });
      return const Right(unit);
    } on _DecisionAborted catch (aborted) {
      return Left(aborted.failure);
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_storeFailure);
    }
  }

  /// "It's the same, don't add" (FR-061, data-model §6). One transaction:
  /// re-read the row and require `pending` (else
  /// `ImportAlreadyDecidedFailure(current)`), write the `duplicate`
  /// tombstone (so the message never resurfaces, FR-059), mark the row
  /// `duplicateClosed`, null `raw_blob` and scrub it to the identity shell.
  /// No saved record is read, created, changed or deleted; no counter
  /// moves. Every failure is a fixed token.
  @override
  Future<Either<Failure, Unit>> closeAsDuplicate(String id) async {
    try {
      return await _db.transaction(() async {
        final row = await _dao.getPendingById(id);
        if (row == null) return const Left(_notFound);
        final current = SmsImportStatus.fromDb(row.status);
        if (!canTransition(current, SmsImportStatus.duplicateClosed)) {
          return Left(ImportAlreadyDecidedFailure(current));
        }
        final now = _clock.now();
        await _dao.insertTombstone(
          tombstoneToCompanion(
            SmsImportTombstone(
              fingerprint: row.fingerprint,
              outcome: TombstoneOutcome.duplicate,
              bankId: row.bankId,
              refHash: row.refHash,
              refAmountHash: row.refAmountHash,
              createdAt: now,
              purgeAfter: SmsImportTombstone.minimumPurgeAfter(now),
            ),
          ),
        );
        await _dao.updatePending(
          id,
          _identityShell.copyWith(
            status: db.Value(SmsImportStatus.duplicateClosed.dbValue),
            decidedAt: db.Value(now.millisecondsSinceEpoch),
          ),
        );
        return const Right(unit);
      });
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_storeFailure);
    }
  }

  /// Undo an ignore or an expiry (FR-067, FR-068, data-model §6), in ONE
  /// transaction: re-read the row and require `ignored` or `expired` (else
  /// `ImportAlreadyDecidedFailure(current)`; `added` and `duplicateClosed`
  /// are never undone here), then delete its tombstone and the row. The
  /// raw text was purged at the decision, so the message comes back only
  /// when it is scanned, pasted or shared again; nothing is re-created
  /// here. Counters are monotonic and do not move.
  @override
  Future<Either<Failure, Unit>> undo(String id) async {
    try {
      return await _db.transaction(() async {
        final row = await _dao.getPendingById(id);
        if (row == null) return const Left(_notFound);
        final current = SmsImportStatus.fromDb(row.status);
        if (!current.isUndoable) {
          return Left(ImportAlreadyDecidedFailure(current));
        }
        await _dao.deleteTombstone(row.fingerprint);
        await _dao.deletePendingRow(id);
        return const Right(unit);
      });
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_storeFailure);
    }
  }

  // ---------------------------------------------------------- maintenance

  /// Expires every pending row with `expires_at <= now` in one
  /// transaction (FR-025): tombstone `expired`, status `expired`,
  /// `decided_at = now`, `raw_blob = NULL`, and only the Undo-list fields
  /// kept. Idempotent: an expired row is no longer pending.
  @override
  Future<Either<Failure, int>> expireDue(DateTime now) => _guard(
    () => _db.transaction(() async {
      final nowMillis = now.millisecondsSinceEpoch;
      final due = await _dao.pendingExpiredBy(nowMillis);
      for (final row in due) {
        await _dao.insertTombstone(
          tombstoneToCompanion(
            SmsImportTombstone(
              fingerprint: row.fingerprint,
              outcome: TombstoneOutcome.expired,
              bankId: row.bankId,
              refHash: row.refHash,
              refAmountHash: row.refAmountHash,
              createdAt: now,
              purgeAfter: SmsImportTombstone.minimumPurgeAfter(now),
            ),
          ),
        );
        await _dao.updatePending(
          row.id,
          _undoShell.copyWith(
            status: db.Value(SmsImportStatus.expired.dbValue),
            decidedAt: db.Value(nowMillis),
          ),
        );
      }
      return due.length;
    }),
  );

  /// Deletes decided rows decided 30 days or more before [now] (FR-067)
  /// and tombstones whose `purge_after <= now` (FR-066). Pending rows and
  /// saved records are never touched.
  @override
  Future<Either<Failure, PurgeResult>> purgeDecided(DateTime now) => _guard(
    () => _db.transaction(() async {
      final rows = await _dao.deleteDecidedBy(
        now.subtract(decidedRetention).millisecondsSinceEpoch,
      );
      final tombstones = await _dao.deleteTombstonesDueBy(
        now.millisecondsSinceEpoch,
      );
      return PurgeResult(rows: rows, tombstones: tombstones);
    }),
  );

  /// Replaces ONLY the parsed-field columns and the rule version of one
  /// pending row, in one transaction (FR-026, research Decision 7). The
  /// fingerprint, both reference hashes, the bank, the source, the sender,
  /// the receipt time, the creation and expiry times, the fee link and the
  /// sealed original are never written. The row must still be `pending`
  /// (else `ImportAlreadyDecidedFailure(current)`), and the result must
  /// keep the entity rules of data-model §3.1 (else a content-free
  /// `ValidationFailure`, nothing written).
  @override
  Future<Either<Failure, Unit>> replaceParsedFields(
    String id,
    ReparsedFields fields,
  ) async {
    try {
      return await _db.transaction(() async {
        final row = await _dao.getPendingById(id);
        if (row == null) return const Left(_notFound);
        final current = SmsImportStatus.fromDb(row.status);
        if (current != SmsImportStatus.pending) {
          return Left(ImportAlreadyDecidedFailure(current));
        }
        final merged = _withFields(row.toDomain(), fields);
        if (merged == null) return const Left(_invalidItem);
        final full = pendingImportToCompanion(merged);
        // Only the parsed-field columns of the full companion.
        await _dao.updatePending(
          id,
          db.PendingSmsImportsCompanion(
            parserId: full.parserId,
            ruleVersion: full.ruleVersion,
            kind: full.kind,
            direction: full.direction,
            amountMinorUnits: full.amountMinorUnits,
            currencyCode: full.currencyCode,
            occurredOn: full.occurredOn,
            timeMinutes: full.timeMinutes,
            merchant: full.merchant,
            merchantKey: full.merchantKey,
            counterparty: full.counterparty,
            cardLast4: full.cardLast4,
            suggestedCategoryId: full.suggestedCategoryId,
            suggestedPersonId: full.suggestedPersonId,
            suggestedAction: full.suggestedAction,
            confidenceJson: full.confidenceJson,
            warningsJson: full.warningsJson,
          ),
        );
        return const Right(unit);
      });
    } catch (_) {
      // Never inspected or kept: SQLite errors embed bound parameters.
      return const Left(_storeFailure);
    }
  }

  /// [item] with the parsed fields of [fields]; every immutable field is
  /// copied from [item]. `null` when the result breaks an entity rule (the
  /// constructor asserts them in debug builds, which is treated the same).
  static PendingSmsImport? _withFields(
    PendingSmsImport item,
    ReparsedFields fields,
  ) {
    try {
      final merged = PendingSmsImport(
        id: item.id,
        parentImportId: item.parentImportId,
        fingerprint: item.fingerprint,
        status: item.status,
        source: item.source,
        senderId: item.senderId,
        bankId: item.bankId,
        parserId: fields.parserId,
        ruleVersion: fields.ruleVersion,
        kind: fields.kind,
        direction: fields.direction,
        amount: fields.amount,
        amountCandidates: fields.amountCandidates,
        foreignAmountText: fields.foreignAmountText,
        foreignAmount: fields.foreignAmount,
        occurredOn: fields.occurredOn,
        timeMinutes: fields.timeMinutes,
        merchant: fields.merchant,
        merchantKey: fields.merchantKey,
        counterparty: fields.counterparty,
        cardLast4: fields.cardLast4,
        suggestedCategoryId: fields.suggestedCategoryId,
        suggestedPersonId: fields.suggestedPersonId,
        suggestedType: fields.suggestedType,
        confidence: fields.confidence,
        warnings: fields.warnings,
        refHash: item.refHash,
        refAmountHash: item.refAmountHash,
        receivedAt: item.receivedAt,
        createdAt: item.createdAt,
        expiresAt: item.expiresAt,
        decidedAt: item.decidedAt,
        savedRecordId: item.savedRecordId,
        savedRecordType: item.savedRecordType,
        hasRawText: item.hasRawText,
      );
      return merged.invariantViolations.isEmpty ? merged : null;
      // ignore: avoid_catching_errors
    } on AssertionError {
      return null;
    }
  }

  @override
  Future<Either<Failure, List<ReparseCandidate>>> pendingNeedingReparse(
    Map<String, int> currentVersions,
  ) => _guard(() async {
    final rows = await _dao.getByStatus(SmsImportStatus.pending.dbValue);
    return [
      for (final row in rows)
        if (_needsReparse(row, currentVersions))
          ReparseCandidate(
            id: row.id,
            source: SmsSource.fromDb(row.origin),
            senderId: row.senderId,
            receivedAt: row.receivedAt == null
                ? null
                : DateTime.fromMillisecondsSinceEpoch(row.receivedAt!),
            ruleVersion: row.ruleVersion,
          ),
    ];
  });

  static bool _needsReparse(
    db.PendingSmsImportRow row,
    Map<String, int> currentVersions,
  ) {
    final current = currentVersions[row.parserId];
    return current != null && row.ruleVersion != '${row.parserId}@$current';
  }

  @override
  Future<Either<Failure, int>> deleteAllPending() => _guard(
    () => _db.transaction(
      () => _dao.deleteByStatus(SmsImportStatus.pending.dbValue),
    ),
  );
}

/// Unwinds [SmsImportRepositoryImpl.confirm] from inside its database
/// transaction so everything rolls back (the `_BatchAborted` idiom of the
/// OCR confirm). A control-flow device carrying the inner failure, never
/// surfaced as is.
class _ConfirmAborted implements Exception {
  const _ConfirmAborted(this.failure);

  final Failure failure;

  /// Never the message (it may carry bound parameters).
  @override
  String toString() => '_ConfirmAborted(${failure.runtimeType})';
}

/// Unwinds a multi-row decision ([SmsImportRepositoryImpl.ignore]) from
/// inside its database transaction so every row rolls back. Carries a
/// fixed, content-free failure.
class _DecisionAborted implements Exception {
  const _DecisionAborted(this.failure);

  final Failure failure;

  @override
  String toString() => '_DecisionAborted(${failure.runtimeType})';
}
