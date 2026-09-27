import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../sync_entity_type.dart';
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
  SupabaseSyncRemoteDataSource(SupabaseInitializer supabase)
    : this.withRpc((function, params) async {
        // `rpc` returns a builder that is itself a Future; awaiting it here
        // lets `timeout` apply to the whole request.
        final Object? result = await supabase.client.rpc<dynamic>(
          function,
          params: params,
        );
        return result;
      });

  @visibleForTesting
  SupabaseSyncRemoteDataSource.withRpc(
    this._rpc, {
    this.timeout = const Duration(seconds: 20),
  });

  final RpcCall _rpc;

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

  @override
  Future<PullPage> pull({required int since, int limit = 500}) async {
    try {
      final response = await _rpc('sync_pull', {
        'p_since': since,
        'p_limit': limit,
      }).timeout(timeout);
      return parsePullResponse(response, since: since);
    } catch (error) {
      throw SyncErrorMapper.map(error);
    }
  }
}

/// Parses a `sync_pull` response body (contracts/sync-rpc.md §3). Money and
/// revisions arrive as JSON numbers (`to_jsonb` of a `bigint`). Throws
/// [FormatException] when it does not have the contracted shape.
@visibleForTesting
PullPage parsePullResponse(Object? response, {required int since}) {
  if (response is! Map) throw const FormatException('pull: not an object');
  final changes = response['changes'];
  if (changes is! List) throw const FormatException('pull: no changes');
  final parsed = [for (final item in changes) _parseChange(item)];
  final hasMore = response['has_more'];
  if (hasMore is! bool) throw const FormatException('pull: bad has_more');
  final maxRevision =
      _intOrNull(response['max_revision']) ??
      (parsed.isEmpty ? since : parsed.last.revision);
  return PullPage(changes: parsed, maxRevision: maxRevision, hasMore: hasMore);
}

PulledChange _parseChange(Object? item) {
  if (item is! Map) throw const FormatException('pull: bad change');
  final type = item['entity_type'];
  if (type is! String) throw const FormatException('pull: bad entity_type');
  final SyncEntityType entityType;
  try {
    entityType = SyncEntityType.fromWire(type);
  } on ArgumentError {
    throw const FormatException('pull: unknown entity_type');
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
