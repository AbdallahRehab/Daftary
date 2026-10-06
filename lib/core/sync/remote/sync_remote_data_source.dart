import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../sync_entity_type.dart';
import '../sync_logger.dart';
import '../sync_models.dart';
import 'supabase_initializer.dart';
import 'sync_error_mapper.dart';

/// 021: the only class that touches the Supabase client for data
/// (contracts/dart-interfaces.md §1). Every call has a 20 s timeout and
/// throws [SyncRemoteException] on failure.
abstract class SyncRemoteDataSource {
  /// Sends up to 100 operations through `sync_push` and returns one result
  /// per operation, in order (contracts/sync-rpc.md §2).
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device);

  /// One `sync_pull` page of changes with `revision > since`, in revision
  /// order (contracts/sync-rpc.md §3).
  Future<PullPage> pull({required int since, int limit = 500});
}

/// Calls one Postgres function and returns its decoded JSON result.
typedef RpcCall =
    Future<Object?> Function(String function, Map<String, Object?> params);

@LazySingleton(as: SyncRemoteDataSource)
class SupabaseSyncRemoteDataSource implements SyncRemoteDataSource {
  SupabaseSyncRemoteDataSource(SupabaseInitializer supabase, SyncLogger logger)
    : this.withRpc((function, params) async {
        // `rpc` returns a builder that is itself a Future; awaiting it here
        // lets `timeout` apply to the whole request.
        final Object? result = await supabase.client.rpc<dynamic>(
          function,
          params: params,
        );
        return result;
      }, logger: logger);

  @visibleForTesting
  SupabaseSyncRemoteDataSource.withRpc(
    this._rpc, {
    this.timeout = const Duration(seconds: 20),
    SyncLogger? logger,
  }) : _logger = logger;

  final RpcCall _rpc;
  final SyncLogger? _logger;

  /// research.md Decision 19.
  final Duration timeout;

  @override
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device) async {
    try {
      final response = await _rpc('sync_push', {
        'p_device_id': device.deviceId,
        'p_app_version': device.appVersion,
        'p_platform': device.platform,
        'p_ops': [for (final op in ops) op.toWire()],
      }).timeout(timeout);
      return parsePushResponse(response);
    } catch (error) {
      throw SyncErrorMapper.map(error);
    }
  }

  /// 022 D2 (migration 026): the pull this release calls. `sync_pull_v2`
  /// also returns `finance_entry_audit`; the original `sync_pull` never
  /// does, so v1.0.1 and R1 keep calling it unharmed. Both walk the same
  /// revision cursor.
  static const pullFunction = 'sync_pull_v2';

  @override
  Future<PullPage> pull({required int since, int limit = 500}) async {
    try {
      final response = await _rpc(pullFunction, {
        'p_since': since,
        'p_limit': limit,
      }).timeout(timeout);
      return parsePullResponse(
        response,
        since: since,
        onUnknownType: (type) => _logger?.event(
          SyncEvent.unknownEntitySkipped,
          fields: {SyncLogField.entityType: type},
        ),
      );
    } catch (error) {
      throw SyncErrorMapper.map(error);
    }
  }
}

/// Parses a `sync_pull` response body (contracts/sync-rpc.md §3). Money and
/// revisions arrive as JSON numbers (`to_jsonb` of a `bigint`). Throws
/// [FormatException] when it does not have the contracted shape.
///
/// S0: a change whose `entity_type` this app does not know is skipped, so a
/// newer server can add record types without failing the page. [onUnknownType]
/// receives the type name only, never the row. The cursor still moves past
/// the skipped row: `maxRevision` falls back to the raw page's last revision.
@visibleForTesting
PullPage parsePullResponse(
  Object? response, {
  required int since,
  void Function(String entityType)? onUnknownType,
}) {
  if (response is! Map) throw const FormatException('pull: not an object');
  final changes = response['changes'];
  if (changes is! List) throw const FormatException('pull: no changes');
  final parsed = <PulledChange>[];
  var rawHighest = since;
  for (final item in changes) {
    final change = _parseChange(item, onUnknownType);
    final revision = _rawRevision(item);
    if (revision > rawHighest) rawHighest = revision;
    if (change != null) parsed.add(change);
  }
  final hasMore = response['has_more'];
  if (hasMore is! bool) throw const FormatException('pull: bad has_more');
  final maxRevision = _intOrNull(response['max_revision']) ?? rawHighest;
  return PullPage(changes: parsed, maxRevision: maxRevision, hasMore: hasMore);
}

/// The revision of a raw change, known to be a map by the caller.
int _rawRevision(Object? item) =>
    _required(_intOrNull((item! as Map)['revision']), 'revision');

/// Null for an unknown `entity_type` (S0).
PulledChange? _parseChange(
  Object? item,
  void Function(String entityType)? onUnknownType,
) {
  if (item is! Map) throw const FormatException('pull: bad change');
  final type = item['entity_type'];
  if (type is! String) throw const FormatException('pull: bad entity_type');
  final SyncEntityType entityType;
  try {
    entityType = SyncEntityType.fromWire(type);
  } on ArgumentError {
    onUnknownType?.call(type);
    return null;
  }
  final row = _rowOrNull(item['row']);
  if (row == null) throw const FormatException('pull: no row');
  return PulledChange(
    entityType: entityType,
    revision: _required(_intOrNull(item['revision']), 'revision'),
    row: row,
  );
}

/// Parses a `sync_push` response body (contracts/sync-rpc.md §2). Throws
/// [FormatException] when it does not have the contracted shape.
@visibleForTesting
List<PushResult> parsePushResponse(Object? response) {
  if (response is! Map) throw const FormatException('push: not an object');
  final results = response['results'];
  if (results is! List) throw const FormatException('push: no results');
  return [for (final item in results) _parseResult(item)];
}

PushResult _parseResult(Object? item) {
  if (item is! Map) throw const FormatException('push: bad result');
  final opId = item['op_id'];
  if (opId is! String) throw const FormatException('push: bad op_id');
  final revision = _intOrNull(item['revision']);
  final serverRow = _rowOrNull(item['server_row']);
  switch (item['result']) {
    case 'applied':
    case 'already_applied':
      return PushApplied(
        opId,
        revision: revision,
        alreadyApplied: item['result'] == 'already_applied',
        serverRow: serverRow,
      );
    case 'conflict':
      return PushConflict(
        opId,
        revision: _required(revision, 'revision'),
        serverRow: _required(serverRow, 'server_row'),
      );
    case 'superseded':
      return PushSuperseded(
        opId,
        revision: _required(revision, 'revision'),
        serverRow: _required(serverRow, 'server_row'),
      );
    case 'rejected':
      final reason = item['reason'];
      if (reason is! String) throw const FormatException('push: no reason');
      return PushRejected(
        opId,
        reason: reason,
        serverRow: serverRow,
        revision: revision,
      );
    default:
      throw const FormatException('push: unknown result');
  }
}

int? _intOrNull(Object? value) => switch (value) {
  null => null,
  final int i => i,
  final num n when n == n.truncate() => n.toInt(),
  final String s => int.tryParse(s) ?? _bad('revision'),
  _ => _bad('revision'),
};

Map<String, Object?>? _rowOrNull(Object? value) => switch (value) {
  null => null,
  final Map<dynamic, dynamic> m => {
    for (final e in m.entries) e.key as String: e.value,
  },
  _ => _bad('server_row'),
};

T _required<T>(T? value, String field) => value ?? _bad(field);

Never _bad(String field) => throw FormatException('push: bad $field');
