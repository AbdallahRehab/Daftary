import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/parse_confidence.dart';
import '../entities/parse_result.dart';
import '../entities/pending_sms_import.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_sender_mute.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_repository.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../usecases/load_parser_options.dart';
import '../usecases/parse_messages.dart';
import 'bank_reference_policy.dart';
import 'fingerprint_hasher.dart';
import 'fingerprint_normalizer.dart';
import 'sms_masker.dart';
import 'sms_message_parser.dart';

/// Stages bank messages as pending suggestions (domain-interfaces §5.2).
/// Shared by the scan, catch-up, paste and share paths; not user-facing.
///
/// Per call: parse each message; compute its fingerprint from the FROZEN
/// [FingerprintNormalizer] (never the parser's normalizer, FR-023) and its
/// reference hashes from the UNMASKED values, once; an in-message fee is
/// staged as its own item linked by `parentImportId`, with the `fp1|fee|`
/// fingerprint and no reference hashes (FR-030a); one `findKnown` for the
/// whole page; then mask, and hand each new item to
/// `SmsImportRepository.insertPending`, which seals it and inserts it
/// idempotently. `NonTransactional`, `NotRecognized` and `Unreadable`
/// store nothing.
///
/// It NEVER creates a `MoneyTransaction` or a `FinanceEntry` and has no
/// access to their repositories (FR-022, SC-002): the only write is a
/// pending row.
///
/// - One hostile message never stops the others (FR-098).
/// - Cancellation is checked between messages and keeps every item already
///   created (FR-007).
/// - With [ingest]'s `advanceCursor`, the scan cursor moves to the page's
///   last `(receivedAt, providerId)` only after every message of the page
///   was handled, so an interrupted page is simply read again and its
///   fingerprints absorb the overlap.
/// - Raw bodies live only in this call's locals and are dropped with them.
///
/// Every result is content-free counts; no failure carries message text.
@lazySingleton
class SmsIngestionService {
  SmsIngestionService(
    this._parseMessages,
    this._loadOptions,
    this._fingerprintNormalizer,
    this._hasher,
    this._masker,
    this._policy,
    this._repository,
    this._settings,
    this._clock, {
    @ignoreParam String Function()? newId,
  }) : _newId = newId ?? const Uuid().v4;

  final ParseMessages _parseMessages;
  final LoadParserOptions _loadOptions;
  final FingerprintNormalizer _fingerprintNormalizer;
  final FingerprintHasher _hasher;
  final SmsMasker _masker;
  final BankReferencePolicy _policy;
  final SmsImportRepository _repository;
  final SmsImportSettingsRepository _settings;
  final AppClock _clock;
  final String Function() _newId;

  static const Failure _keysUnavailable = CacheFailure(
    'sms_import_keys_unavailable',
  );

  Future<Either<Failure, ScanSummary>> ingest({
    required List<RawIncoming> messages,
    required SmsSource source,
    required ScanCancellationToken token,
    void Function(ScanProgress)? onProgress,
    bool advanceCursor = false,
    void Function(List<String> createdIds)? onCreated,
  }) async {
    if (messages.isEmpty) return Right(ScanSummary());

    final options = await _loadOptions();
    if (options case Left(:final value)) return Left(value);
    final parserOptions = options.getOrElse((_) => const ParserOptions());

    var muted = const <String>{};
    if (source.hasSender) {
      final mutes = await _settings.watchMutedSenders().first;
      if (mutes case Left(:final value)) return Left(value);
      muted = mutes.getOrElse((_) => const {});
    }

    final tally = _Tally();
    final staged = <_Staged>[];
    var cancelled = false;

    // --- 1. parse and hash (unmasked), message by message ---------------
    for (var i = 0; i < messages.length; i++) {
      if (token.isCancelled) {
        cancelled = true;
        break;
      }
      final message = messages[i];
      final sender = source.hasSender && message.sender != null
          ? canonicalSmsSenderId(message.sender!)
          : null;
      if (sender != null && muted.contains(sender)) {
        tally.mutedSkipped++;
        tally.handled++;
        onProgress?.call(
          ScanProgress(processed: i + 1, total: messages.length),
        );
        continue;
      }
      final result = _parseMessages.parseOne(
        message,
        source: source,
        options: parserOptions,
      );
      switch (result) {
        case NonTransactional():
          tally.nonTransactional++;
        case NotRecognized():
          tally.skipped.add(
            SkippedEntry(
              reason: SkipReason.notRecognized,
              receivedAt: source.hasReceivedAt ? message.receivedAt : null,
            ),
          );
        case Unreadable(:final reason, :final bankId):
          tally.unreadable++;
          tally.skipped.add(
            SkippedEntry(
              reason: SkipReason.fromUnreadable(reason),
              bankId: bankId,
              receivedAt: source.hasReceivedAt ? message.receivedAt : null,
            ),
          );
        case ParsedTransaction():
          final _Hashes hashes;
          try {
            hashes = await _hash(message.text, result);
          } catch (_) {
            // The keyed hashes need the MAC key; without it nothing can be
            // staged safely. Never inspected or kept.
            return const Left(_keysUnavailable);
          }
          final rows = _rowsFor(
            message,
            result,
            hashes,
            source: source,
            sender: sender,
            options: parserOptions,
          );
          if (rows == null) {
            // A parse that breaks an entity rule is never stored.
            tally.unreadable++;
            tally.skipped.add(
              SkippedEntry(
                reason: SkipReason.parserError,
                bankId: result.bankId,
                receivedAt: source.hasReceivedAt ? message.receivedAt : null,
              ),
            );
          } else {
            tally.recognized++;
            staged.add(rows);
          }
      }
      tally.handled++;
      onProgress?.call(ScanProgress(processed: i + 1, total: messages.length));
    }

    // --- 2. one exact-tier lookup for the page --------------------------
    final fingerprints = <String>{};
    final refAmountHashes = <String>{};
    for (final item in staged) {
      for (final row in item.rows) {
        fingerprints.add(row.item.fingerprint);
        final hash = row.item.refAmountHash;
        if (hash != null && _policy.refIsUnique(row.item.bankId)) {
          refAmountHashes.add(hash);
        }
      }
    }
    var known = KnownKeys();
    if (fingerprints.isNotEmpty) {
      final result = await _repository.findKnown(
        fingerprints: fingerprints,
        refAmountHashes: refAmountHashes,
      );
      if (result case Left(:final value)) return Left(value);
      known = result.getOrElse((_) => KnownKeys());
    }

    // --- 3. mask, seal (in the repository) and insert -------------------
    final created = <PendingSmsImport>[];
    // Every staged message was fully handled before any cancellation, so
    // all of them are stored: a cancel stops between messages in step 1
    // and keeps what was handled (FR-007). This step is bounded by the
    // page size.
    for (final item in staged) {
      for (final row in item.rows) {
        final pending = row.item;
        final isKnown =
            known.fingerprints.contains(pending.fingerprint) ||
            (pending.refAmountHash != null &&
                known.refAmountHashes.contains(pending.refAmountHash));
        if (isKnown) {
          tally.alreadyKnown++;
          continue;
        }
        final outcome = await _repository.insertPending(row);
        if (outcome case Left(:final value)) return Left(value);
        if (outcome.getOrElse((_) => InsertOutcome.alreadyKnown) ==
            InsertOutcome.inserted) {
          created.add(pending);
        } else {
          tally.alreadyKnown++;
        }
      }
    }

    final summary = ScanSummary(
      scanned: tally.handled,
      recognized: tally.recognized,
      createdPending: created.length,
      ready: created.where(_isReady).length,
      needsReview: created.where((p) => !_isReady(p)).length,
      alreadyKnown: tally.alreadyKnown,
      nonTransactional: tally.nonTransactional,
      unreadable: tally.unreadable,
      mutedSkipped: tally.mutedSkipped,
      cancelled: cancelled,
      processedBeforeInterruption: cancelled ? tally.handled : 0,
      skipped: tally.skipped,
    );

    // The ids of the items this call created (paste and share route to
    // the review of a single new item). Ids only, never content.
    onCreated?.call([for (final item in created) item.id]);

    // Content-free counters (FR-102); best effort, never content.
    await _settings.addCounts(
      scanned: summary.scanned,
      recognized: summary.recognized,
    );

    if (advanceCursor && source.hasSender && !cancelled) {
      final cursor = _lastCursor(messages);
      if (cursor != null) {
        final advanced = await _settings.advanceCursor(
          date: cursor.$1,
          id: cursor.$2,
        );
        if (advanced case Left(:final value)) return Left(value);
      }
    }
    return Right(summary);
  }

  /// The keyed hashes of one message, from the UNMASKED body and values,
  /// computed once (FR-023, research Decision 6). Throws when the MAC key
  /// is unavailable.
  Future<_Hashes> _hash(String body, ParsedTransaction parsed) async {
    final fingerprintInput = _fingerprintNormalizer.normalize(body);
    final reference = parsed.referenceId;
    final amount = parsed.amount;
    return (
      fingerprint: await _hasher.fingerprint(fingerprintInput),
      feeFingerprint: parsed.fee == null
          ? null
          : await _hasher.feeFingerprint(fingerprintInput),
      refHash: reference == null
          ? null
          : await _hasher.refHash(parsed.bankId, reference),
      refAmountHash: reference == null || amount == null
          ? null
          : await _hasher.refAmountHash(
              bank: parsed.bankId,
              ref: reference,
              currency: amount.currency.code,
              amountMinor: amount.minorUnits,
              direction: parsed.direction.dbValue,
            ),
    );
  }

  /// The pending row (and its fee item) of one parsed message, or `null`
  /// when the parse breaks an entity rule.
  _Staged? _rowsFor(
    RawIncoming message,
    ParsedTransaction parsed,
    _Hashes hashes, {
    required SmsSource source,
    required String? sender,
    required ParserOptions options,
  }) {
    String? masked;
    try {
      masked = _masker.mask(message.text);
    } catch (_) {
      // Pure, but one hostile message must never stop the page: the item
      // is then stored with no original (FR-098).
      masked = null;
    }
    return _rowsWithMask(
      message,
      parsed,
      hashes,
      masked,
      source: source,
      sender: sender,
      options: options,
    );
  }

  _Staged? _rowsWithMask(
    RawIncoming message,
    ParsedTransaction parsed,
    _Hashes hashes,
    String? masked, {
    required SmsSource source,
    required String? sender,
    required ParserOptions options,
  }) {
    final amount = parsed.amount;
    final now = _clock.now();
    final receivedAt = source.hasReceivedAt ? message.receivedAt : null;
    final parent = _build(
      () => PendingSmsImport(
        id: _newId(),
        fingerprint: hashes.fingerprint,
        status: SmsImportStatus.pending,
        source: source,
        senderId: sender,
        bankId: parsed.bankId,
        parserId: parsed.parserId,
        ruleVersion: parsed.ruleVersion,
        kind: parsed.kind,
        direction: parsed.direction,
        amount: amount,
        amountCandidates: parsed.amountCandidatesMinor,
        foreignAmountText: parsed.foreignAmountText,
        foreignAmount: parsed.foreignAmount,
        occurredOn: parsed.occurredOn,
        timeMinutes: parsed.timeMinutes,
        merchant: parsed.merchant,
        merchantKey: parsed.merchantKey,
        counterparty: parsed.counterparty,
        cardLast4: parsed.cardLast4,
        suggestedCategoryId: parsed.suggestedCategoryKeyOrId,
        suggestedPersonId: parsed.suggestedPersonId,
        suggestedType: parsed.suggestedType,
        confidence: parsed.confidence,
        warnings: parsed.warnings,
        refHash: hashes.refHash,
        refAmountHash: hashes.refAmountHash,
        receivedAt: receivedAt,
        createdAt: now,
        expiresAt: PendingSmsImport.expiryFor(now),
        hasRawText: true,
      ),
    );
    if (parent == null) return null;
    final rows = [NewPendingImport(item: parent, rawMasked: masked)];

    final fee = parsed.fee;
    final feeFingerprint = hashes.feeFingerprint;
    if (fee != null && fee.minorUnits > 0 && feeFingerprint != null) {
      final feeItem = _build(
        () => PendingSmsImport(
          id: _newId(),
          parentImportId: parent.id,
          fingerprint: feeFingerprint,
          status: SmsImportStatus.pending,
          source: source,
          senderId: sender,
          bankId: parsed.bankId,
          parserId: parsed.parserId,
          ruleVersion: parsed.ruleVersion,
          kind: SmsKind.fee,
          direction: SmsDirection.debit,
          amount: fee,
          occurredOn: parsed.occurredOn,
          timeMinutes: parsed.timeMinutes,
          cardLast4: parsed.cardLast4,
          suggestedCategoryId: options.activeCategoryIdsBySeedKey['other'],
          suggestedType: SuggestedRecordType.expense,
          confidence: parsed.confidence,
          warnings: const {SmsWarning.feeFromMessage},
          receivedAt: receivedAt,
          createdAt: now,
          expiresAt: PendingSmsImport.expiryFor(now),
          hasRawText: true,
        ),
      );
      if (feeItem == null) return null;
      rows.add(NewPendingImport(item: feeItem, rawMasked: masked));
    }
    return _Staged(rows);
  }

  /// `null` when the item breaks an entity rule (data-model §3.1). The
  /// entity asserts its rules in debug builds, so that assertion is
  /// treated the same way.
  static PendingSmsImport? _build(PendingSmsImport Function() create) {
    try {
      final item = create();
      return item.invariantViolations.isEmpty ? item : null;
      // ignore: avoid_catching_errors
    } on AssertionError {
      return null;
    }
  }

  /// Complete required fields and not Low (FR-024, data-model §2.9).
  static bool _isReady(PendingSmsImport item) =>
      item.amount != null &&
      item.occurredOn != null &&
      item.direction != SmsDirection.unknown &&
      item.suggestedType != SuggestedRecordType.unset &&
      item.confidence.overall != OverallConfidence.low;

  /// The highest `(receivedAt, providerId)` of the page, or `null` when the
  /// page carries no provider cursor.
  static (DateTime, int)? _lastCursor(List<RawIncoming> messages) {
    (DateTime, int)? best;
    for (final message in messages) {
      final at = message.receivedAt;
      final id = message.providerId;
      if (at == null || id == null) continue;
      if (best == null ||
          at.isAfter(best.$1) ||
          (at.isAtSameMomentAs(best.$1) && id > best.$2)) {
        best = (at, id);
      }
    }
    return best;
  }
}

/// The rows staged from one parsed message: the item, then its fee.
class _Staged {
  const _Staged(this.rows);

  final List<NewPendingImport> rows;
}

class _Tally {
  int handled = 0;
  int recognized = 0;
  int alreadyKnown = 0;
  int nonTransactional = 0;
  int unreadable = 0;
  int mutedSkipped = 0;
  final List<SkippedEntry> skipped = [];
}

typedef _Hashes = ({
  String fingerprint,
  String? feeFingerprint,
  String? refHash,
  String? refAmountHash,
});
