import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

/// 021: the sync lifecycle events (plan §24). [logName] is the name that
/// appears in the log output.
enum SyncEvent {
  syncStarted('SYNC_STARTED'),
  uploadStarted('SYNC_UPLOAD_STARTED'),
  uploadSuccess('SYNC_UPLOAD_SUCCESS'),
  uploadFailed('SYNC_UPLOAD_FAILED', level: 1000),
  downloadStarted('SYNC_DOWNLOAD_STARTED'),
  downloadSuccess('SYNC_DOWNLOAD_SUCCESS'),
  conflict('SYNC_CONFLICT', level: 900),
  retryScheduled('SYNC_RETRY'),
  syncCompleted('SYNC_COMPLETED'),
  syncAborted('SYNC_ABORTED', level: 1000),
  migrationEnqueued('SYNC_MIGRATION_ENQUEUED'),
  cursorAdvanced('SYNC_CURSOR_ADVANCED'),

  /// S0: a pulled row of a record type this app version does not know was
  /// skipped. Logs the type name only.
  unknownEntitySkipped('SYNC_UNKNOWN_ENTITY_SKIPPED');

  const SyncEvent(this.logName, {this.level = 800});

  final String logName;

  /// A `dart:developer` log level: 800 info, 900 warning, 1000 error.
  final int level;

  /// Release builds log only warnings and errors (research.md Decision 18).
  bool get loggedInRelease => level >= 900;
}

/// The only field keys a sync log line may carry (research.md Decision 18).
/// Amounts, names, notes, phone numbers, emails and tokens cannot be logged
/// because there is no key for them.
enum SyncLogField {
  entityType,
  count,
  durationMs,
  errorCode,
  delayMs,
  revision,
  opId,
}

/// Structured, allow-listed logging for the sync engine.
abstract class SyncLogger {
  void event(SyncEvent e, {Map<SyncLogField, Object> fields = const {}});
}

/// Formats one event as `SYNC_X key=value key=value`, with the keys in
/// [SyncLogField] declaration order so the output is deterministic.
String formatSyncLogLine(SyncEvent e, Map<SyncLogField, Object> fields) {
  final buffer = StringBuffer(e.logName);
  for (final field in SyncLogField.values) {
    final value = fields[field];
    if (value == null) continue;
    buffer.write(' ${field.name}=$value');
  }
  return buffer.toString();
}

/// Signature of the underlying sink, matching the parts of
/// `dart:developer`'s `log` that are used.
typedef SyncLogSink = void Function(String message, {int level, String name});

void _developerSink(String message, {int level = 800, String name = ''}) =>
    developer.log(message, level: level, name: name);

@LazySingleton(as: SyncLogger)
class DeveloperSyncLogger implements SyncLogger {
  DeveloperSyncLogger() : _sink = _developerSink, _releaseMode = kReleaseMode;

  @visibleForTesting
  DeveloperSyncLogger.withSink(this._sink, {required bool releaseMode})
    : _releaseMode = releaseMode;

  final SyncLogSink _sink;
  final bool _releaseMode;

  @override
  void event(SyncEvent e, {Map<SyncLogField, Object> fields = const {}}) {
    if (_releaseMode && !e.loggedInRelease) return;
    _sink(formatSyncLogLine(e, fields), level: e.level, name: 'daftary.sync');
  }
}
