import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_tombstone.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_sender_mute.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_duplicate_lookup.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_settings_repository.dart';
import 'package:daftary/features/sms_import/domain/services/app_lifecycle_state_source.dart';
import 'package:daftary/features/sms_import/domain/services/bank_reference_policy.dart';
import 'package:daftary/features/sms_import/domain/services/clipboard_reader.dart';
import 'package:daftary/features/sms_import/domain/services/external_activity_runner.dart';
import 'package:daftary/features/sms_import/domain/services/fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/domain/services/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/domain/services/lock_status.dart';
import 'package:daftary/features/sms_import/domain/services/raw_text_vault.dart';
import 'package:daftary/features/sms_import/domain/services/review_lease_registry.dart';
import 'package:daftary/features/sms_import/domain/services/scan_coordinator.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_key_store.dart';
import 'package:daftary/features/sms_import/domain/services/sms_masker.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/domain/services/sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_text_normalizer.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

// 023 T034: in-memory test doubles, one per domain port (T030) and
// repository contract (T031), plus a fixed clock and an in-memory secure
// storage. Every fake is deterministic, records the calls tests assert on,
// and never logs.

// ---------------------------------------------------------------------------
// Clock and secure storage
// ---------------------------------------------------------------------------

/// An [AppClock] that returns [current] until a test moves it.
class FixedClock implements AppClock {
  FixedClock(this.current);

  DateTime current;

  void advance(Duration by) => current = current.add(by);

  @override
  DateTime now() => current;
}

/// An in-memory `FlutterSecureStorage`. Set [throwOnAccess] to make every
/// call throw, as a broken keystore does.
class InMemorySecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> values = {};

  bool throwOnAccess = false;
  int reads = 0;
  int writes = 0;
  int deletes = 0;

  void _check() {
    if (throwOnAccess) throw StateError('secure storage unavailable');
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    writes++;
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    reads++;
    return values[key];
  }

  @override
  Future<bool> containsKey({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    return values.containsKey(key);
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    deletes++;
    values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    return Map.of(values);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _check();
    values.clear();
  }
}

// ---------------------------------------------------------------------------
// Platform ports
// ---------------------------------------------------------------------------

/// One recorded `queryInbox` call.
class InboxQueryCall {
  const InboxQueryCall({
    required this.senders,
    required this.afterDate,
    required this.afterId,
    required this.limit,
  });

  final List<String> senders;
  final DateTime afterDate;
  final int? afterId;
  final int limit;
}

/// Pages canned [rows] the way the platform does: only allow-listed
/// senders (canonical comparison), strictly after the `(date, id)` cursor,
/// ordered `(date, id)` ascending, at most `limit` rows. Records every call.
class FakeSmsInboxGateway implements SmsInboxGateway {
  FakeSmsInboxGateway({
    List<InboxSmsMessage> rows = const [],
    this.capability = const SmsCapability(
      readSmsDeclared: true,
      isAndroid: true,
    ),
  }) : rows = List.of(rows);

  final List<InboxSmsMessage> rows;
  SmsCapability capability;

  /// Returned instead of a page by the next query, then cleared.
  Failure? nextFailure;

  final List<InboxQueryCall> calls = [];
  int capabilityChecks = 0;

  @override
  Future<SmsCapability> getCapability() async {
    capabilityChecks++;
    return capability;
  }

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    calls.add(
      InboxQueryCall(
        senders: List.unmodifiable(senders),
        afterDate: afterDate,
        afterId: afterId,
        limit: limit,
      ),
    );
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Left(failure);
    }
    if (!capability.available) {
      return const Left(SmsCapabilityUnavailableFailure());
    }
    final allowed = senders.map(canonicalSmsSenderId).toSet();
    final page =
        rows
            .where((m) => allowed.contains(canonicalSmsSenderId(m.address)))
            .where((m) {
              final cmp = m.date.compareTo(afterDate);
              if (cmp != 0) return cmp > 0;
              return afterId != null && m.id > afterId;
            })
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    return Right(page.take(limit).toList());
  }
}

/// A scripted permission service that counts prompts.
class FakeSmsPermissionService implements SmsPermissionService {
  FakeSmsPermissionService({
    this.status = SmsPermissionStatus.denied,
    SmsPermissionStatus? requestResult,
  }) : requestResult = requestResult ?? SmsPermissionStatus.granted;

  /// What [getStatus] reports.
  SmsPermissionStatus status;

  /// What [request] reports; [status] becomes this value.
  SmsPermissionStatus requestResult;
  Failure? nextFailure;

  int statusChecks = 0;
  int requests = 0;
  int appInfoOpens = 0;

  /// The `previouslyRequested` of each [request], in order.
  final List<bool> previouslyRequestedLog = [];

  @override
  Future<Either<Failure, SmsPermissionStatus>> getStatus() async {
    statusChecks++;
    return Right(status);
  }

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) async {
    requests++;
    previouslyRequestedLog.add(previouslyRequested);
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Left(failure);
    }
    status = requestResult;
    return Right(requestResult);
  }

  @override
  Future<Either<Failure, Unit>> openAppInfo() async {
    appInfoOpens++;
    return const Right(unit);
  }
}

/// A shared-text source: one cold-start [initial] (returned once) and warm
/// shares pushed with [share].
class FakeSharedTextSource implements SharedTextSource {
  FakeSharedTextSource({this.initial});

  SharedText? initial;
  final StreamController<SharedText> _controller = StreamController();
  int initialReads = 0;

  void share(String text, {bool truncated = false}) =>
      _controller.add(SharedText(text: text, truncated: truncated));

  @override
  Future<SharedText?> takeInitial() async {
    initialReads++;
    final value = initial;
    initial = null;
    return value;
  }

  @override
  Stream<SharedText> get stream => _controller.stream;

  Future<void> close() => _controller.close();
}

/// The app lifecycle. [pause] and [resume] flip it; [pauseAfterChecks]
/// flips it to paused after that many [isResumed] reads (mid-scan).
class FakeLifecycle implements AppLifecycleStateSource {
  FakeLifecycle({bool resumed = true}) : _resumed = resumed;

  bool _resumed;
  int checks = 0;
  int? _pauseAfter;

  void pause() => _resumed = false;

  void resume() => _resumed = true;

  void pauseAfterChecks(int count) => _pauseAfter = count;

  @override
  bool get isResumed {
    checks++;
    final limit = _pauseAfter;
    if (limit != null && checks > limit) _resumed = false;
    return _resumed;
  }
}

/// App Lock state that tests flip with [lock] and [unlock].
class FakeLockStatus implements LockStatus {
  FakeLockStatus({bool locked = false}) : _locked = locked;

  bool _locked;
  final StreamController<bool> _changes = StreamController.broadcast();

  void lock() => _set(true);

  void unlock() => _set(false);

  void _set(bool value) {
    if (_locked == value) return;
    _locked = value;
    _changes.add(value);
  }

  @override
  bool get isLocked => _locked;

  @override
  Stream<bool> get changes => _changes.stream;

  Future<void> close() => _changes.close();
}

/// Runs the body directly and counts the runs.
class FakeExternalActivityRunner implements ExternalActivityRunner {
  int runs = 0;

  @override
  Future<T> run<T>(Future<T> Function() body) {
    runs++;
    return body();
  }
}

/// A clipboard that counts reads, so a test can assert zero reads before
/// the Paste tap (FR-015).
class FakeClipboardReader implements ClipboardReader {
  FakeClipboardReader([this.text]);

  String? text;
  int reads = 0;

  @override
  Future<String?> readText() async {
    reads++;
    return text;
  }
}

// ---------------------------------------------------------------------------
// Parsing ports
// ---------------------------------------------------------------------------

/// Returns the scripted result for each raw text, else [fallback]. Records
/// every input.
class FakeSmsMessageParser implements SmsMessageParser {
  FakeSmsMessageParser({
    Map<String, ParseResult> results = const {},
    this.fallback = const NotRecognized(),
    Map<String, int> currentVersions = const {'nbe': 1},
    Set<String> allowedSenders = const {'NBE'},
  }) : results = Map.of(results),
       currentVersions = Map.of(currentVersions),
       allowedSenders = Set.of(allowedSenders);

  final Map<String, ParseResult> results;
  ParseResult fallback;
  final List<SmsParseInput> inputs = [];
  final List<ParserOptions> optionsSeen = [];

  @override
  final Map<String, int> currentVersions;

  @override
  final Set<String> allowedSenders;

  @override
  ParseResult parse(
    SmsParseInput input, {
    ParserOptions options = const ParserOptions(),
  }) {
    inputs.add(input);
    optionsSeen.add(options);
    return results[input.rawText] ?? fallback;
  }
}

/// Collapses whitespace; lower-cases only the matching form.
class FakeSmsTextNormalizer implements SmsTextNormalizer {
  int calls = 0;

  @override
  NormalizedText normalize(String text) {
    calls++;
    final display = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return NormalizedText(
      forMatching: display.toLowerCase(),
      forDisplay: display,
    );
  }
}

/// Keeps the last four digits of every ASCII digit run of at least the
/// threshold; everything else is untouched.
class FakeSmsMasker implements SmsMasker {
  int calls = 0;

  @override
  String mask(String original, {int threshold = 12}) {
    calls++;
    return original.replaceAllMapped(RegExp('[0-9]{$threshold,}'), (m) {
      final run = m.group(0)!;
      return '${'•' * (run.length - 4)}${run.substring(run.length - 4)}';
    });
  }
}

/// Splits on blank lines and enforces the FR-017 bounds.
class FakeSmsMessageSplitter implements SmsMessageSplitter {
  int calls = 0;

  @override
  Either<Failure, List<SplitMessage>> split(String text) {
    calls++;
    if (text.length > InputLimit.characters.max) {
      return const Left(InputTooLargeFailure(InputLimit.characters));
    }
    final chunks = text
        .split(RegExp(r'\n\s*\n'))
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (chunks.length > InputLimit.messages.max) {
      return const Left(InputTooLargeFailure(InputLimit.messages));
    }
    return Right([
      for (var i = 0; i < chunks.length; i++)
        SplitMessage(text: chunks[i], index: i),
    ]);
  }
}

/// Collapses whitespace only (the frozen-normalizer stand-in).
class FakeFingerprintNormalizer implements FingerprintNormalizer {
  @override
  String normalize(String body) => body.replaceAll(RegExp(r'\s+'), ' ').trim();
}

// ---------------------------------------------------------------------------
// Crypto ports
// ---------------------------------------------------------------------------

/// Deterministic, content-free hex digests (FNV-1a 32-bit), so a test can
/// compare hashes without real keys.
class FakeFingerprintHasher implements FingerprintHasher {
  int calls = 0;

  static String digest(String input) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(input)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  @override
  Future<String> fingerprint(String normalizedBody) async {
    calls++;
    return digest('fp1|$normalizedBody');
  }

  @override
  Future<String> feeFingerprint(String normalizedBody) async {
    calls++;
    return digest('fp1|fee|$normalizedBody');
  }

  @override
  Future<String> refHash(String bank, String ref) async {
    calls++;
    return digest('ref|$bank|$ref');
  }

  @override
  Future<String> refAmountHash({
    required String bank,
    required String ref,
    required String currency,
    required int amountMinor,
    required String direction,
  }) async {
    calls++;
    return digest('ra|$bank|$ref|$currency|$amountMinor|$direction');
  }
}

/// A reversible stand-in for AES-GCM: `0x01 | aadLength | aad | utf8`.
/// [failOpen] makes every open return `null`, as a lost key does.
class FakeRawTextVault implements RawTextVault {
  bool failOpen = false;
  bool failSeal = false;
  int seals = 0;
  int opens = 0;

  @override
  Future<Uint8List> seal(String masked, {required String aad}) async {
    seals++;
    if (failSeal) throw StateError('seal failed');
    final aadBytes = utf8.encode(aad);
    return Uint8List.fromList([
      0x01,
      aadBytes.length,
      ...aadBytes,
      ...utf8.encode(masked),
    ]);
  }

  @override
  Future<String?> open(Uint8List blob, {required String aad}) async {
    opens++;
    if (failOpen || blob.length < 2 || blob[0] != 0x01) return null;
    final aadLength = blob[1];
    if (blob.length < 2 + aadLength) return null;
    final storedAad = utf8.decode(blob.sublist(2, 2 + aadLength));
    if (storedAad != aad) return null;
    return utf8.decode(blob.sublist(2 + aadLength));
  }
}

/// Fixed 32-byte keys; [throwOnAccess] simulates a broken keystore.
class FakeSmsKeyStore implements SmsKeyStore {
  bool throwOnAccess = false;
  int purges = 0;

  Uint8List _encKey = Uint8List.fromList(List.filled(32, 1));
  Uint8List _macKey = Uint8List.fromList(List.filled(32, 2));

  @override
  Future<Uint8List> encKey() async {
    if (throwOnAccess) throw StateError('key store unavailable');
    return _encKey;
  }

  @override
  Future<Uint8List> macKey() async {
    if (throwOnAccess) throw StateError('key store unavailable');
    return _macKey;
  }

  @override
  Future<void> purge() async {
    purges++;
    _encKey = Uint8List.fromList(List.filled(32, 3));
    _macKey = Uint8List.fromList(List.filled(32, 4));
  }
}

// ---------------------------------------------------------------------------
// Coordination ports
// ---------------------------------------------------------------------------

class _FakeLease implements ReviewLease {
  _FakeLease(this.importId, this._registry);

  @override
  final String importId;
  final FakeReviewLeaseRegistry _registry;
  bool _released = false;

  @override
  void release() {
    if (_released) return;
    _released = true;
    _registry._release(importId);
  }
}

/// Counted leases per import id.
class FakeReviewLeaseRegistry implements ReviewLeaseRegistry {
  final Map<String, int> _counts = {};

  @override
  ReviewLease acquire(String importId) {
    _counts[importId] = (_counts[importId] ?? 0) + 1;
    return _FakeLease(importId, this);
  }

  void _release(String importId) {
    final count = (_counts[importId] ?? 0) - 1;
    if (count <= 0) {
      _counts.remove(importId);
    } else {
      _counts[importId] = count;
    }
  }

  @override
  bool isLeased(String importId) => _counts.containsKey(importId);
}

/// The FR-013 rules in memory: a catch-up never runs beside another scan;
/// an explicit scan cancels a running catch-up and waits for it.
class FakeScanCoordinator implements ScanCoordinator {
  ScanKind? _runningKind;
  ScanCancellationToken? _runningToken;
  Future<void>? _running;
  final List<ScanKind> started = [];
  final List<ScanKind> skipped = [];

  @override
  bool get isRunning => _runningKind != null;

  @override
  Future<T?> runExclusive<T>(
    ScanKind kind,
    ScanCancellationToken token,
    Future<T> Function() body,
  ) async {
    while (_runningKind != null) {
      if (kind == ScanKind.catchUp) {
        skipped.add(kind);
        return null;
      }
      if (_runningKind == ScanKind.catchUp) _runningToken?.cancel();
      await _running;
    }
    final done = Completer<void>();
    _runningKind = kind;
    _runningToken = token;
    _running = done.future;
    started.add(kind);
    try {
      return await body();
    } finally {
      _runningKind = null;
      _runningToken = null;
      _running = null;
      done.complete();
    }
  }
}

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

/// Rebuilds [item] with a new status and decision fields; the entity has no
/// `copyWith` on purpose.
PendingSmsImport pendingWithDecision(
  PendingSmsImport item, {
  required SmsImportStatus status,
  DateTime? decidedAt,
  String? savedRecordId,
  SavedRecordType? savedRecordType,
  bool? hasRawText,
}) {
  return PendingSmsImport(
    id: item.id,
    parentImportId: item.parentImportId,
    fingerprint: item.fingerprint,
    status: status,
    source: item.source,
    senderId: item.senderId,
    bankId: item.bankId,
    parserId: item.parserId,
    ruleVersion: item.ruleVersion,
    kind: item.kind,
    direction: item.direction,
    amount: item.amount,
    amountCandidates: item.amountCandidates,
    foreignAmountText: item.foreignAmountText,
    foreignAmount: item.foreignAmount,
    occurredOn: item.occurredOn,
    timeMinutes: item.timeMinutes,
    merchant: item.merchant,
    merchantKey: item.merchantKey,
    counterparty: item.counterparty,
    cardLast4: item.cardLast4,
    suggestedCategoryId: item.suggestedCategoryId,
    suggestedPersonId: item.suggestedPersonId,
    suggestedType: item.suggestedType,
    confidence: item.confidence,
    warnings: item.warnings,
    refHash: item.refHash,
    refAmountHash: item.refAmountHash,
    receivedAt: item.receivedAt,
    createdAt: item.createdAt,
    expiresAt: item.expiresAt,
    decidedAt: decidedAt ?? item.decidedAt,
    savedRecordId: savedRecordId ?? item.savedRecordId,
    savedRecordType: savedRecordType ?? item.savedRecordType,
    hasRawText: hasRawText ?? item.hasRawText,
  );
}

/// Emits [read]'s value now and after every [changes] event.
Stream<Either<Failure, T>> _watch<T>(
  Stream<void> changes,
  T Function() read,
) async* {
  yield Right(read());
  await for (final _ in changes) {
    yield Right(read());
  }
}

/// An in-memory `SmsImportRepository` with the status machine of
/// data-model §6. [confirm] writes no real record: it records the call and
/// returns a generated reference.
class FakeSmsImportRepository implements SmsImportRepository {
  FakeSmsImportRepository({FixedClock? clock})
    : clock = clock ?? FixedClock(DateTime(2026, 3, 4, 12));

  final FixedClock clock;
  final Map<String, PendingSmsImport> rows = {};
  final Map<String, Uint8List?> blobs = {};
  final Map<String, SmsImportTombstone> tombstones = {};
  final List<({String pendingId, ConfirmedImport confirmed})> confirmCalls = [];
  final StreamController<void> _changes = StreamController.broadcast();

  /// Returned by the next mutating call, then cleared.
  Failure? nextFailure;
  DateTime? expiredNoticeSeenAt;
  int _savedCounter = 0;

  void _changed() => _changes.add(null);

  Failure? _takeFailure() {
    final failure = nextFailure;
    nextFailure = null;
    return failure;
  }

  /// Seeds rows directly (bypassing [insertPending]).
  void seed(Iterable<PendingSmsImport> items) {
    for (final item in items) {
      rows[item.id] = item;
    }
    _changed();
  }

  List<PendingSmsImport> get _pendingSorted =>
      rows.values.where((r) => r.isPending).toList()..sort((a, b) {
        final byConfidence = a.confidence.overall.index.compareTo(
          b.confidence.overall.index,
        );
        return byConfidence != 0
            ? byConfidence
            : a.createdAt.compareTo(b.createdAt);
      });

  void _tombstone(PendingSmsImport item, TombstoneOutcome outcome) {
    final now = clock.now();
    tombstones[item.fingerprint] = SmsImportTombstone(
      fingerprint: item.fingerprint,
      outcome: outcome,
      bankId: item.bankId,
      refHash: item.refHash,
      refAmountHash: item.refAmountHash,
      savedRecordId: item.savedRecordId,
      savedRecordType: item.savedRecordType,
      createdAt: now,
      purgeAfter: SmsImportTombstone.minimumPurgeAfter(now),
    );
  }

  void _decide(PendingSmsImport item, SmsImportStatus status) {
    rows[item.id] = pendingWithDecision(
      item,
      status: status,
      decidedAt: clock.now(),
      hasRawText: false,
    );
    blobs[item.id] = null;
  }

  @override
  Future<Either<Failure, InsertOutcome>> insertPending(
    NewPendingImport item,
  ) async {
    final failure = _takeFailure();
    if (failure != null) return Left(failure);
    final row = item.item;
    final known =
        rows.values.any((r) => r.fingerprint == row.fingerprint) ||
        tombstones.containsKey(row.fingerprint) ||
        (row.refAmountHash != null &&
            (rows.values.any((r) => r.refAmountHash == row.refAmountHash) ||
                tombstones.values.any(
                  (t) => t.refAmountHash == row.refAmountHash,
                )));
    if (known) return const Right(InsertOutcome.alreadyKnown);
    final masked = item.rawMasked;
    rows[row.id] = pendingWithDecision(
      row,
      status: row.status,
      hasRawText: masked != null,
    );
    blobs[row.id] = masked == null
        ? null
        : Uint8List.fromList(utf8.encode(masked));
    _changed();
    return const Right(InsertOutcome.inserted);
  }

  @override
  Future<Either<Failure, KnownKeys>> findKnown({
    required Set<String> fingerprints,
    required Set<String> refAmountHashes,
  }) async {
    final knownFingerprints = {
      ...rows.values.map((r) => r.fingerprint),
      ...tombstones.keys,
    }.intersection(fingerprints);
    final knownRefAmount = {
      ...rows.values.map((r) => r.refAmountHash).whereType<String>(),
      ...tombstones.values.map((t) => t.refAmountHash).whereType<String>(),
    }.intersection(refAmountHashes);
    return Right(
      KnownKeys(
        fingerprints: knownFingerprints,
        refAmountHashes: knownRefAmount,
      ),
    );
  }

  @override
  Future<Either<Failure, Set<String>>> refHashesForBank(String bankId) async {
    return Right({
      ...rows.values
          .where((r) => r.bankId == bankId)
          .map((r) => r.refHash)
          .whereType<String>(),
      ...tombstones.values
          .where((t) => t.bankId == bankId)
          .map((t) => t.refHash)
          .whereType<String>(),
    });
  }

  @override
  Stream<Either<Failure, List<PendingSmsImport>>> watchPending() =>
      _watch(_changes.stream, () => _pendingSorted);

  @override
  Stream<Either<Failure, int>> watchPendingCount() =>
      _watch(_changes.stream, () => _pendingSorted.length);

  @override
  Future<Either<Failure, PendingSmsImport>> getById(String id) async {
    final row = rows[id];
    if (row == null) return const Left(NotFoundFailure('sms_import_missing'));
    return Right(row);
  }

  @override
  Stream<Either<Failure, List<PendingSmsImport>>> watchUndoList() => _watch(
    _changes.stream,
    () => rows.values.where((r) => r.status.isUndoable).toList(),
  );

  @override
  Future<Either<Failure, int>> unseenExpiredCount() async {
    final seen = expiredNoticeSeenAt;
    return Right(
      rows.values
          .where((r) => r.status == SmsImportStatus.expired)
          .where(
            (r) =>
                seen == null ||
                (r.decidedAt != null && r.decidedAt!.isAfter(seen)),
          )
          .length,
    );
  }

  @override
  Future<Either<Failure, Unit>> markExpiredNoticeSeen() async {
    expiredNoticeSeenAt = clock.now();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, String>> openOriginal(String id) async {
    final row = rows[id];
    final blob = blobs[id];
    if (row == null || !row.isPending || blob == null) {
      return const Left(OriginalUnavailableFailure());
    }
    return Right(utf8.decode(blob));
  }

  @override
  Future<Either<Failure, SavedRecordRef>> confirm({
    required String pendingId,
    required ConfirmedImport confirmed,
  }) async {
    final failure = _takeFailure();
    if (failure != null) return Left(failure);
    final row = rows[pendingId];
    if (row == null) return const Left(NotFoundFailure('sms_import_missing'));
    if (!row.isPending) return Left(ImportAlreadyDecidedFailure(row.status));
    confirmCalls.add((pendingId: pendingId, confirmed: confirmed));
    final ref = SavedRecordRef(
      id: 'saved-${++_savedCounter}',
      type: switch (confirmed) {
        ConfirmedFinanceEntry() => SavedRecordType.financeEntry,
        ConfirmedPersonTransaction() => SavedRecordType.moneyTransaction,
      },
    );
    final added = pendingWithDecision(
      row,
      status: SmsImportStatus.added,
      decidedAt: clock.now(),
      savedRecordId: ref.id,
      savedRecordType: ref.type,
      hasRawText: false,
    );
    rows[pendingId] = added;
    blobs[pendingId] = null;
    _tombstone(added, TombstoneOutcome.added);
    _changed();
    return Right(ref);
  }

  @override
  Future<Either<Failure, Unit>> ignore(Set<String> ids) async {
    final failure = _takeFailure();
    if (failure != null) return Left(failure);
    for (final id in ids) {
      final row = rows[id];
      if (row == null || !row.isPending) continue;
      _decide(row, SmsImportStatus.ignored);
      _tombstone(row, TombstoneOutcome.ignored);
    }
    _changed();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> closeAsDuplicate(String id) async {
    final row = rows[id];
    if (row == null) return const Left(NotFoundFailure('sms_import_missing'));
    if (!row.isPending) return Left(ImportAlreadyDecidedFailure(row.status));
    _decide(row, SmsImportStatus.duplicateClosed);
    _tombstone(row, TombstoneOutcome.duplicate);
    _changed();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> undo(String id) async {
    final row = rows[id];
    if (row == null) return const Left(NotFoundFailure('sms_import_missing'));
    if (!row.status.isUndoable) {
      return Left(ImportAlreadyDecidedFailure(row.status));
    }
    rows.remove(id);
    blobs.remove(id);
    tombstones.remove(row.fingerprint);
    _changed();
    return const Right(unit);
  }

  @override
  Future<Either<Failure, int>> expireDue(DateTime now) async {
    final due = rows.values
        .where((r) => r.isPending && !r.expiresAt.isAfter(now))
        .toList();
    for (final row in due) {
      _decide(row, SmsImportStatus.expired);
      _tombstone(row, TombstoneOutcome.expired);
    }
    if (due.isNotEmpty) _changed();
    return Right(due.length);
  }

  @override
  Future<Either<Failure, PurgeResult>> purgeDecided(DateTime now) async {
    final cutoff = now.subtract(const Duration(days: 30));
    final oldRows = rows.values
        .where((r) => r.status.isTerminal)
        .where((r) => r.decidedAt != null && !r.decidedAt!.isAfter(cutoff))
        .map((r) => r.id)
        .toList();
    oldRows.forEach(rows.remove);
    final oldTombstones = tombstones.values
        .where((t) => !t.purgeAfter.isAfter(now))
        .map((t) => t.fingerprint)
        .toList();
    oldTombstones.forEach(tombstones.remove);
    if (oldRows.isNotEmpty) _changed();
    return Right(
      PurgeResult(rows: oldRows.length, tombstones: oldTombstones.length),
    );
  }

  final Map<String, ReparsedFields> replacedFields = {};

  @override
  Future<Either<Failure, Unit>> replaceParsedFields(
    String id,
    ReparsedFields fields,
  ) async {
    final row = rows[id];
    if (row == null) return const Left(NotFoundFailure('sms_import_missing'));
    replacedFields[id] = fields;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, List<ReparseCandidate>>> pendingNeedingReparse(
    Map<String, int> currentVersions,
  ) async {
    return Right([
      for (final row in rows.values.where((r) => r.isPending))
        if (row.ruleVersion !=
            '${row.parserId}@${currentVersions[row.parserId]}')
          ReparseCandidate(
            id: row.id,
            source: row.source,
            senderId: row.senderId,
            receivedAt: row.receivedAt,
            ruleVersion: row.ruleVersion,
          ),
    ]);
  }

  @override
  Future<Either<Failure, int>> deleteAllPending() async {
    final ids = rows.values.where((r) => r.isPending).map((r) => r.id).toList();
    for (final id in ids) {
      rows.remove(id);
      blobs.remove(id);
    }
    _changed();
    return Right(ids.length);
  }

  /// Deletes the pending rows of one sender (no tombstones), as the
  /// settings repository's `muteSender` does in the same transaction.
  int deletePendingFromSender(String senderId) {
    final canonical = canonicalSmsSenderId(senderId);
    final ids = rows.values
        .where((r) => r.isPending && r.senderId == canonical)
        .map((r) => r.id)
        .toList();
    for (final id in ids) {
      rows.remove(id);
      blobs.remove(id);
    }
    if (ids.isNotEmpty) _changed();
    return ids.length;
  }

  Future<void> close() => _changes.close();
}

/// An in-memory `SmsImportSettingsRepository`. When [pending] is given,
/// [muteSender] deletes that sender's pending rows there, as the real
/// repository does in one transaction.
class FakeSmsImportSettingsRepository implements SmsImportSettingsRepository {
  FakeSmsImportSettingsRepository({
    SmsImportSettings settings = const SmsImportSettings(),
    this.pending,
  }) : _settings = settings;

  SmsImportSettings _settings;
  final FakeSmsImportRepository? pending;
  final Set<String> mutedSenders = {};
  final Map<(String, String), MerchantCategoryMapping> mappings = {};
  final StreamController<void> _changes = StreamController.broadcast();
  DateTime mappingTime = DateTime(2026, 3, 4);

  /// Returned by the next write, then cleared.
  Failure? nextFailure;

  SmsImportSettings get settings => _settings;

  Either<Failure, Unit> _update(
    SmsImportSettings Function(SmsImportSettings) change,
  ) {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Left(failure);
    }
    _settings = change(_settings);
    _changes.add(null);
    return const Right(unit);
  }

  @override
  Stream<Either<Failure, SmsImportSettings>> watchSettings() =>
      _watch(_changes.stream, () => _settings);

  @override
  Future<Either<Failure, SmsImportSettings>> getSettings() async =>
      Right(_settings);

  @override
  Future<Either<Failure, Unit>> setEnabled(bool enabled) async =>
      _update((s) => s.copyWith(isEnabled: enabled));

  @override
  Future<Either<Failure, Unit>> dismissOnboarding() async =>
      _update((s) => s.copyWith(onboardingDismissed: true));

  @override
  Future<Either<Failure, Unit>> setScanWindow(ScanWindow window) async =>
      _update((s) => s.copyWith(scanWindow: window));

  @override
  Future<Either<Failure, Unit>> setCountCashWithdrawals(bool value) async =>
      _update((s) => s.copyWith(countCashWithdrawals: value));

  @override
  Future<Either<Failure, Unit>> markPermissionRequested() async =>
      _update((s) => s.copyWith(permissionRequested: true));

  @override
  Future<Either<Failure, Unit>> advanceCursor({
    required DateTime date,
    required int id,
  }) async => _update((s) => s.copyWith(cursorDate: date, cursorId: id));

  @override
  Future<Either<Failure, Unit>> recordScan({
    required DateTime at,
    required bool catchUp,
  }) async => _update(
    (s) => catchUp ? s.copyWith(lastCatchUpAt: at) : s.copyWith(lastScanAt: at),
  );

  @override
  Future<Either<Failure, Unit>> addCounts({
    int scanned = 0,
    int recognized = 0,
    int added = 0,
    int ignored = 0,
  }) async => _update(
    (s) => s.copyWith(
      scannedCount: s.scannedCount + scanned,
      recognizedCount: s.recognizedCount + recognized,
      addedCount: s.addedCount + added,
      ignoredCount: s.ignoredCount + ignored,
    ),
  );

  @override
  Future<Either<Failure, Unit>> setRulesSeen(Map<String, int> versions) async =>
      _update((s) => s.copyWith(rulesSeen: Map.unmodifiable(versions)));

  @override
  Stream<Either<Failure, Set<String>>> watchMutedSenders() =>
      _watch(_changes.stream, () => Set.unmodifiable(mutedSenders));

  @override
  Future<Either<Failure, int>> muteSender(String senderId) async {
    mutedSenders.add(canonicalSmsSenderId(senderId));
    final deleted = pending?.deletePendingFromSender(senderId) ?? 0;
    _changes.add(null);
    return Right(deleted);
  }

  @override
  Future<Either<Failure, Unit>> unmuteSender(String senderId) async {
    mutedSenders.remove(canonicalSmsSenderId(senderId));
    _changes.add(null);
    return const Right(unit);
  }

  @override
  Stream<Either<Failure, List<MerchantCategoryMapping>>> watchMappings() =>
      _watch(_changes.stream, () => mappings.values.toList());

  @override
  Future<Either<Failure, Map<(String, String), String>>>
  getMappingMap() async => Right({
    for (final entry in mappings.entries) entry.key: entry.value.categoryId,
  });

  @override
  Future<Either<Failure, Unit>> removeMapping(
    String merchantKey,
    String entryType,
  ) async => _write(() => mappings.remove((merchantKey, entryType)));

  @override
  Future<Either<Failure, Unit>> clearMappings() async => _write(mappings.clear);

  /// A mapping write that honours [nextFailure] (T139 tests).
  Either<Failure, Unit> _write(void Function() change) {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      return Left(failure);
    }
    change();
    _changes.add(null);
    return const Right(unit);
  }

  Future<void> close() => _changes.close();
}

/// Scripted duplicate lookups that record their inputs.
class FakeSmsDuplicateLookup implements SmsDuplicateLookup {
  List<DuplicateRecordRef> savedMatches = const [];
  List<DuplicateRecordRef> windowRecords = const [];
  PendingSmsImport? pendingPair;
  Map<String, String> refHashBySavedRecord = const {};
  List<ImportKeyMatch> keyMatches = const [];
  List<PendingSmsImport> pendingWithAmount = const [];
  Map<String, List<DuplicateRecordRef>> savedByRefHash = const {};
  Map<String, String> bankBySavedRecord = const {};

  final List<({Money amount, DateTime date, SuggestedRecordType type})>
  savedMatchCalls = [];
  int windowLoads = 0;

  @override
  Future<Either<Failure, List<DuplicateRecordRef>>> findSavedMatches({
    required Money amount,
    required DateTime date,
    required SuggestedRecordType type,
  }) async {
    savedMatchCalls.add((amount: amount, date: date, type: type));
    return Right(savedMatches);
  }

  @override
  Future<Either<Failure, SavedRecordWindow>> loadWindow(
    DateTime minDate,
    DateTime maxDate,
  ) async {
    windowLoads++;
    return Right(SavedRecordWindow(windowRecords));
  }

  @override
  Future<Either<Failure, PendingSmsImport?>> findPendingPair(
    PendingSmsImport item,
  ) async => Right(pendingPair);

  @override
  Future<Either<Failure, String?>> refHashForSavedRecord(
    String savedRecordId,
  ) async => Right(refHashBySavedRecord[savedRecordId]);

  /// Applies the same key and exclusion filter as the real lookup.
  @override
  Future<Either<Failure, List<ImportKeyMatch>>> findKeyMatches({
    required String excludeId,
    required String fingerprint,
    String? refAmountHash,
  }) async => Right([
    for (final match in keyMatches)
      if (match.pendingId != excludeId &&
          (match.fingerprint == fingerprint ||
              (refAmountHash != null && match.refAmountHash == refAmountHash)))
        match,
  ]);

  /// Applies the same amount and exclusion filter as the real lookup.
  @override
  Future<Either<Failure, List<PendingSmsImport>>> findPendingWithAmount(
    Money amount, {
    required String excludeId,
  }) async => Right([
    for (final item in pendingWithAmount)
      if (item.id != excludeId && item.amount == amount && item.isPending) item,
  ]);

  @override
  Future<Either<Failure, List<DuplicateRecordRef>>> savedRecordsForRefHash(
    String refHash,
  ) async => Right(savedByRefHash[refHash] ?? const []);

  @override
  Future<Either<Failure, String?>> bankForSavedRecord(
    String savedRecordId,
  ) async => Right(bankBySavedRecord[savedRecordId]);
}

/// Banks listed in [uniqueBanks] have unique reference IDs (FR-059b).
class FakeBankReferencePolicy implements BankReferencePolicy {
  FakeBankReferencePolicy([this.uniqueBanks = const {}]);

  final Set<String> uniqueBanks;

  @override
  bool refIsUnique(String bankId) => uniqueBanks.contains(bankId);
}
