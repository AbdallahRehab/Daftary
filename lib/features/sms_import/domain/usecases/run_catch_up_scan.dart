import 'dart:async';

import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_settings.dart';
import '../entities/sms_permission_status.dart';
import '../entities/sms_sender_mute.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../services/app_lifecycle_state_source.dart';
import '../services/lock_status.dart';
import '../services/scan_coordinator.dart';
import '../services/sms_inbox_gateway.dart';
import '../services/sms_ingestion_service.dart';
import '../services/sms_message_parser.dart';
import 'expire_pending_imports.dart';
import 'get_sms_capability.dart';
import 'get_sms_permission_status.dart';
import 'reparse_pending.dart';

/// The automatic catch-up when the app comes to the foreground (FR-013,
/// domain-interfaces §5.2). No prompt, no notification, no background
/// work: the caller (the lifecycle trigger) runs it on a resume, after a
/// post-frame callback, while the app is unlocked.
///
/// It is SKIPPED (a [CatchUpSkipped], never a failure, and with no
/// `queryInbox` call, invariant 6) when the capability is off, the app is
/// locked or not resumed, the feature is off, the last catch-up started
/// less than [debounce] ago, another scan holds the [ScanCoordinator]
/// (an explicit scan or another catch-up), or the permission is not
/// granted.
///
/// Single flight: a call while one is in flight joins it and gets the
/// same outcome. The run itself is inside `ScanCoordinator.runExclusive`,
/// so it never runs beside an explicit scan; an explicit scan cancels it
/// through its token.
///
/// The read starts at the stored cursor minus [overlap] (the fingerprints
/// absorb the re-read messages), never earlier than [maxDays] days ago;
/// with no cursor yet it starts at the user's scan window. It pages until
/// a short page and stops between pages (keeping every item already
/// created and never advancing the cursor for an unfinished page) when
/// the token is cancelled, the app leaves the resumed state (FR-008a),
/// the app is locked (also cancelled as soon as App Lock engages), the
/// feature is turned off or the permission is no longer granted.
///
/// At the end, while the app is still resumed and unlocked, it runs
/// [ExpirePendingImports] and [ReparsePending] (best effort).
///
/// It never throws and never creates a transaction. A read or store
/// failure ends the run as [CatchUpFailed] with a content-free failure;
/// the next resume retries.
///
/// A lazy singleton: the single-flight [_inFlight] and [cancel] must be
/// shared by every caller (the lifecycle trigger, the hub), not held per
/// resolved instance.
@lazySingleton
class RunCatchUpScan {
  RunCatchUpScan(
    this._capability,
    this._permission,
    this._settings,
    this._parser,
    this._gateway,
    this._ingestion,
    this._coordinator,
    this._lifecycle,
    this._lock,
    this._clock,
    this._expire,
    this._reparse,
  );

  final GetSmsCapability _capability;
  final GetSmsPermissionStatus _permission;
  final SmsImportSettingsRepository _settings;
  final SmsMessageParser _parser;
  final SmsInboxGateway _gateway;
  final SmsIngestionService _ingestion;
  final ScanCoordinator _coordinator;
  final AppLifecycleStateSource _lifecycle;
  final LockStatus _lock;
  final AppClock _clock;
  final ExpirePendingImports _expire;
  final ReparsePending _reparse;

  /// At most one catch-up per this period (FR-013, research Decision 12).
  static const Duration debounce = Duration(seconds: 60);

  /// How far before the stored cursor a catch-up re-reads.
  static const Duration overlap = Duration(hours: 24);

  /// A catch-up never reads further back than this many days.
  static const int maxDays = 90;

  /// Rows per `queryInbox` page (the platform maximum).
  static const int pageSize = 200;

  static const Failure _unexpected = UnknownFailure('sms_catch_up_failed');

  Future<CatchUpOutcome>? _inFlight;
  ScanCancellationToken? _token;

  /// Whether a catch-up started by this instance is in flight.
  bool get isRunning => _inFlight != null;

  /// Cancels the running catch-up, if any (for example when the app
  /// locks). It stops before its next message or page and keeps what it
  /// created.
  void cancel() => _token?.cancel();

  Future<CatchUpOutcome> call() {
    final running = _inFlight;
    if (running != null) return running;
    final run = _guarded();
    _inFlight = run;
    unawaited(
      run.whenComplete(() {
        if (identical(_inFlight, run)) _inFlight = null;
      }),
    );
    return run;
  }

  Future<CatchUpOutcome> _guarded() async {
    try {
      return await _run();
    } catch (_) {
      // Never inspected or kept: it may describe message content.
      return CatchUpFailed(_unexpected, ScanSummary());
    }
  }

  Future<CatchUpOutcome> _run() async {
    final capability = await _capability();
    if (!capability.available) {
      return const CatchUpSkipped(ScanBlockReason.capabilityOff);
    }
    if (_lock.isLocked) return const CatchUpSkipped(ScanBlockReason.locked);
    if (!_lifecycle.isResumed) {
      return const CatchUpSkipped(ScanBlockReason.notResumed);
    }

    final loaded = await _settings.getSettings();
    final SmsImportSettings settings;
    switch (loaded) {
      case Left(:final value):
        return CatchUpFailed(value, ScanSummary());
      case Right(:final value):
        settings = value;
    }
    if (!settings.isEnabled) {
      return const CatchUpSkipped(ScanBlockReason.disabled);
    }
    final now = _clock.now();
    final last = settings.lastCatchUpAt;
    if (last != null) {
      final elapsed = now.difference(last);
      if (!elapsed.isNegative && elapsed < debounce) {
        return const CatchUpSkipped(ScanBlockReason.debounced);
      }
    }
    if (_coordinator.isRunning) {
      return const CatchUpSkipped(ScanBlockReason.alreadyRunning);
    }
    final permission = await _permission();
    switch (permission) {
      case Left(:final value):
        return CatchUpFailed(value, ScanSummary());
      case Right(:final value) when value != SmsPermissionStatus.granted:
        return const CatchUpSkipped(ScanBlockReason.noPermission);
      case Right():
        break;
    }

    final token = ScanCancellationToken();
    _token = token;
    final lockWatch = _lock.changes.listen((locked) {
      if (locked) token.cancel();
    });
    try {
      final outcome = await _coordinator.runExclusive(
        ScanKind.catchUp,
        token,
        () => _scan(token, settings, now),
      );
      return outcome ?? const CatchUpSkipped(ScanBlockReason.alreadyRunning);
    } finally {
      await lockWatch.cancel();
      if (identical(_token, token)) _token = null;
    }
  }

  Future<CatchUpOutcome> _scan(
    ScanCancellationToken token,
    SmsImportSettings settings,
    DateTime now,
  ) async {
    // The debounce counts from the START of a run, so the resumes caused
    // by the permission dialog, App info or the share sheet fall inside
    // it. Best effort: a failed write never stops the catch-up.
    await _settings.recordScan(at: now, catchUp: true);

    final mutes = await _settings.watchMutedSenders().first;
    if (mutes case Left(:final value)) {
      return CatchUpFailed(value, ScanSummary());
    }
    final muted = mutes.getOrElse((_) => const {}).map(canonicalSmsSenderId);
    final allowed = {
      for (final sender in _parser.allowedSenders) canonicalSmsSenderId(sender),
    }..removeAll(muted);
    final senders = allowed.toList()..sort();

    var afterDate = startFor(settings, now);
    int? afterId;
    var total = ScanSummary();
    var cancelled = false;

    if (senders.isNotEmpty) {
      for (var page = 0; ; page++) {
        if (token.isCancelled || !_lifecycle.isResumed || _lock.isLocked) {
          cancelled = true;
          break;
        }
        if (page > 0 && !await _stillAllowed()) {
          cancelled = true;
          break;
        }

        final rows = await _gateway.queryInbox(
          senders: senders,
          afterDate: afterDate,
          afterId: afterId,
          limit: pageSize,
        );
        if (rows case Left(:final value)) return CatchUpFailed(value, total);
        final messages = rows.getOrElse((_) => const []);

        // Defensive sender re-check (FR-020).
        final kept = [
          for (final m in messages)
            if (allowed.contains(canonicalSmsSenderId(m.address)))
              RawIncoming(
                text: m.body,
                sender: m.address,
                receivedAt: m.date,
                providerId: m.id,
              ),
        ];
        final ingested = await _ingestion.ingest(
          messages: kept,
          source: SmsSource.catchUpScan,
          token: token,
          advanceCursor: true,
        );
        if (ingested case Left(:final value)) {
          return CatchUpFailed(value, total);
        }
        final summary = ingested.getOrElse((_) => ScanSummary());
        total = _merge(total, summary);

        if (summary.cancelled) {
          cancelled = true;
          break;
        }
        if (messages.length < pageSize) break;
        afterDate = messages.last.date;
        afterId = messages.last.id;
      }
    }

    if (_lifecycle.isResumed && !_lock.isLocked) {
      // Maintenance, best effort: their failures are retried next time.
      await _expire();
      await _reparse();
    }
    return CatchUpRan(
      cancelled ? _merge(total, ScanSummary(cancelled: true)) : total,
    );
  }

  /// Where a catch-up starts reading: the stored cursor minus [overlap],
  /// or `now - scanWindow` when there is no cursor yet; never before
  /// `now - maxDays` (calendar days, so DST never shifts it).
  static DateTime startFor(SmsImportSettings settings, DateTime now) {
    DateTime daysBack(int days) => DateTime(
      now.year,
      now.month,
      now.day - days,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
    final floor = daysBack(maxDays);
    final cursor = settings.cursorDate;
    final start = cursor == null
        ? daysBack(settings.scanWindow.days)
        : cursor.subtract(overlap);
    return start.isBefore(floor) ? floor : start;
  }

  /// Between pages: the feature is still on and the permission still
  /// granted. A failed read counts as "no", so the run stops.
  Future<bool> _stillAllowed() async {
    final settings = await _settings.getSettings();
    if (!settings.map((s) => s.isEnabled).getOrElse((_) => false)) {
      return false;
    }
    final permission = await _permission();
    return permission.getOrElse((_) => SmsPermissionStatus.denied) ==
        SmsPermissionStatus.granted;
  }

  static ScanSummary _merge(ScanSummary a, ScanSummary b) => ScanSummary(
    scanned: a.scanned + b.scanned,
    recognized: a.recognized + b.recognized,
    createdPending: a.createdPending + b.createdPending,
    ready: a.ready + b.ready,
    needsReview: a.needsReview + b.needsReview,
    alreadyKnown: a.alreadyKnown + b.alreadyKnown,
    nonTransactional: a.nonTransactional + b.nonTransactional,
    unreadable: a.unreadable + b.unreadable,
    mutedSkipped: a.mutedSkipped + b.mutedSkipped,
    cancelled: a.cancelled || b.cancelled,
    processedBeforeInterruption:
        a.processedBeforeInterruption + b.processedBeforeInterruption,
    skipped: [...a.skipped, ...b.skipped],
  );
}
