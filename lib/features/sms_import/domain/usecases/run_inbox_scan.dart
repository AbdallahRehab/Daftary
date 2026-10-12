import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/sms_import_enums.dart';
import '../entities/sms_import_failures.dart';
import '../entities/sms_permission_status.dart';
import '../entities/sms_sender_mute.dart';
import '../entities/sms_value_types.dart';
import '../repositories/sms_import_settings_repository.dart';
import '../services/app_lifecycle_state_source.dart';
import '../services/scan_coordinator.dart';
import '../services/sms_inbox_gateway.dart';
import '../services/sms_ingestion_service.dart';
import '../services/sms_message_parser.dart';
import 'get_sms_capability.dart';
import 'get_sms_permission_status.dart';

/// The user-initiated inbox scan (domain-interfaces §5.2; FR-006, FR-007,
/// FR-008a, FR-013, FR-020).
///
/// - Runs inside `ScanCoordinator.runExclusive(explicit)`, which cancels a
///   running catch-up and waits for it. If this scan's own token is
///   cancelled while it waits, nothing runs and the summary is
///   `cancelled`.
/// - Preconditions, checked inside the slot: the capability
///   (`SmsCapabilityUnavailableFailure`), the feature enabled
///   (`ScanNotAllowedFailure(disabled)`) and the permission granted
///   (`SmsPermissionFailure(status)`, which drives the revoked or denied
///   banner). A precondition failure reads nothing.
/// - Allow-list: the parser's recognized senders minus the muted senders,
///   canonical. An empty allow-list reads nothing.
/// - Cursor reset: an explicit scan always starts at `now - window`, not
///   at the stored cursor, and keeps its own page cursor. Each fully
///   ingested page advances the STORED cursor (`advanceCursor`), which the
///   repository never moves backwards; a cancelled page never advances it.
/// - Pages of [pageSize] until a short page. Before every page it stops
///   when the token is cancelled, the app is no longer resumed (FR-008a)
///   or the feature was turned off (so `DisableSmsImport` stops it); the
///   summary is then `cancelled = true` and every item already created is
///   kept (FR-007).
/// - Defensive sender re-check: a row whose sender is not on the
///   allow-list is dropped unread by the pipeline.
/// - Sets `lastScanAt` (best effort: a failed write never hides the scan's
///   result). Bypasses the catch-up debounce.
///
/// It never creates a transaction: the only writes are pending rows (via
/// [SmsIngestionService]), the cursor, the counters and `lastScanAt`.
@injectable
class RunInboxScan {
  RunInboxScan(
    this._capability,
    this._permission,
    this._settings,
    this._parser,
    this._gateway,
    this._ingestion,
    this._coordinator,
    this._lifecycle,
    this._clock,
  );

  final GetSmsCapability _capability;
  final GetSmsPermissionStatus _permission;
  final SmsImportSettingsRepository _settings;
  final SmsMessageParser _parser;
  final SmsInboxGateway _gateway;
  final SmsIngestionService _ingestion;
  final ScanCoordinator _coordinator;
  final AppLifecycleStateSource _lifecycle;
  final AppClock _clock;

  /// Rows per `queryInbox` page (the platform maximum).
  static const int pageSize = 200;

  Future<Either<Failure, ScanSummary>> call({
    required ScanWindow window,
    required ScanCancellationToken token,
    void Function(ScanProgress)? onProgress,
  }) async {
    final result = await _coordinator.runExclusive(
      ScanKind.explicit,
      token,
      () => _scan(window, token, onProgress),
    );
    return result ?? Right(ScanSummary(cancelled: true));
  }

  Future<Either<Failure, ScanSummary>> _scan(
    ScanWindow window,
    ScanCancellationToken token,
    void Function(ScanProgress)? onProgress,
  ) async {
    final capability = await _capability();
    if (!capability.available) {
      return const Left(SmsCapabilityUnavailableFailure());
    }
    final enabled = await _isEnabled();
    if (enabled case Left(:final value)) return Left(value);
    if (!enabled.getOrElse((_) => false)) {
      return const Left(ScanNotAllowedFailure(ScanBlockReason.disabled));
    }
    final status = await _permission();
    if (status case Left(:final value)) return Left(value);
    final permission = status.getOrElse((_) => SmsPermissionStatus.denied);
    if (permission != SmsPermissionStatus.granted) {
      return Left(SmsPermissionFailure(permission));
    }

    final mutes = await _settings.watchMutedSenders().first;
    if (mutes case Left(:final value)) return Left(value);
    final muted = mutes.getOrElse((_) => const {}).map(canonicalSmsSenderId);
    final allowed = {
      for (final sender in _parser.allowedSenders) canonicalSmsSenderId(sender),
    }..removeAll(muted);
    final senders = allowed.toList()..sort();

    final now = _clock.now();
    var afterDate = DateTime(
      now.year,
      now.month,
      now.day - window.days,
      now.hour,
      now.minute,
      now.second,
      now.millisecond,
    );
    int? afterId;
    var total = ScanSummary();
    var processed = 0;
    var cancelled = false;

    if (senders.isNotEmpty) {
      for (var page = 0; ; page++) {
        if (token.isCancelled || !_lifecycle.isResumed) {
          cancelled = true;
          break;
        }
        if (page > 0) {
          final stillEnabled = await _isEnabled();
          if (stillEnabled case Left(:final value)) return Left(value);
          if (!stillEnabled.getOrElse((_) => false)) {
            cancelled = true;
            break;
          }
        }

        final rows = await _gateway.queryInbox(
          senders: senders,
          afterDate: afterDate,
          afterId: afterId,
          limit: pageSize,
        );
        if (rows case Left(:final value)) return Left(value);
        final messages = rows.getOrElse((_) => const []);

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
        final offset = processed;
        final ingested = await _ingestion.ingest(
          messages: kept,
          source: SmsSource.inboxScan,
          token: token,
          advanceCursor: true,
          onProgress: onProgress == null
              ? null
              : (p) =>
                    onProgress(ScanProgress(processed: offset + p.processed)),
        );
        if (ingested case Left(:final value)) return Left(value);
        final summary = ingested.getOrElse((_) => ScanSummary());
        total = _merge(total, summary);
        processed += summary.scanned;

        if (summary.cancelled) {
          cancelled = true;
          break;
        }
        if (messages.length < pageSize) break;
        afterDate = messages.last.date;
        afterId = messages.last.id;
      }
    }

    // Best effort: the scan's result matters more than its timestamp.
    await _settings.recordScan(at: _clock.now(), catchUp: false);
    return Right(
      cancelled ? _merge(total, ScanSummary(cancelled: true)) : total,
    );
  }

  Future<Either<Failure, bool>> _isEnabled() async =>
      (await _settings.getSettings()).map((s) => s.isEnabled);

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
