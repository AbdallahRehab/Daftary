import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/remote/sync_remote_data_source.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_models.dart';

/// 021 T055: an in-memory [SyncRemoteDataSource] that reproduces the
/// server semantics of `sync_push` and `sync_pull` (contracts/sync-rpc.md
/// §2–§3, as implemented in supabase/migrations/…_021_offline_sync.sql):
///
/// - a per-owner revision counter, incremented on every write;
/// - the `op_id` ledger: a replayed `applied`/`already_applied` returns
///   `already_applied`; a replayed `conflict`/`superseded`/`rejected`
///   returns the same result (with the current server row);
/// - the `idempotency_key` check for financial creates (3a) and the
///   equal-fields check for a create that hits an existing row (3b);
/// - `conflict` for stale financial updates, last-write-wins otherwise,
///   `superseded` for a stale delete, category delete → archive, person
///   delete with transactions → `rejected person_has_transactions`;
/// - `rejected missing_parent` for a foreign-key miss, **not** ledgered;
/// - money comes back as JSON numbers, like `jsonb` renders a `bigint`.
///
/// Tests script failures with [failNextCalls], [failOnCall] and
/// [dropResponseAfterCommit], and seed server data with [seedServerRow].
class FakeSyncRemote implements SyncRemoteDataSource {
  static const ownerId = '00000000-0000-4000-8000-000000000001';

  /// The account the calls act as (`auth.uid()`). Each account has its own
  /// rows, ledger and revision counter, like row-level security gives it.
  String owner = ownerId;
  final Map<String, _OwnerData> _owners = {};

  _OwnerData get _data => _owners.putIfAbsent(owner, _OwnerData.new);
  Map<SyncEntityType, Map<String, Map<String, Object?>>> get _tables =>
      _data.tables;
  Map<String, _LedgerEntry> get _ledger => _data.ledger;
  int get _lastRevision => _data.lastRevision;
  set _lastRevision(int value) => _data.lastRevision = value;

  /// Every `sync_push` call that reached the fake, including failed ones.
  int pushCalls = 0;
  int pullCalls = 0;

  /// The operations of every call that was processed (committed).
  final List<List<OutboxOp>> committedBatches = [];
  DeviceInfo? lastDevice;

  final List<SyncRemoteException> _scriptedFailures = [];
  final List<SyncRemoteException> _scriptedPullFailures = [];
  final Map<int, SyncRemoteException> _failOnCall = {};
  bool _dropNextResponse = false;
  int? _dropOnCall;

  // ---------------------------------------------------------------------------
  // Scripting
  // ---------------------------------------------------------------------------

  /// The next [n] push calls fail before touching the server state.
  void failNextCalls(
    int n, [
    Failure failure = const NetworkFailure('scripted'),
    bool transient = true,
  ]) {
    for (var i = 0; i < n; i++) {
      _scriptedFailures.add(_exception(failure, transient));
    }
  }

  /// The next [n] pull calls fail.
  void failNextPulls(
    int n, [
    Failure failure = const NetworkFailure('scripted'),
    bool transient = true,
  ]) {
    for (var i = 0; i < n; i++) {
      _scriptedPullFailures.add(_exception(failure, transient));
    }
  }

  /// The [callNumber]-th push call (1-based, counting every call) fails
  /// before touching the server state.
  void failOnCall(
    int callNumber, [
    Failure failure = const NetworkFailure('scripted'),
  ]) => _failOnCall[callNumber] = _exception(failure, true);

  /// The next push call commits on the server, then its response is lost
  /// (it throws a transient network error).
  void dropResponseAfterCommit() => _dropNextResponse = true;

  /// The [callNumber]-th push call (1-based) commits, then its response is
  /// lost.
  void dropResponseOnCall(int callNumber) => _dropOnCall = callNumber;

  /// Writes [row] as if another device had pushed it; returns its revision.
  int seedServerRow(
    SyncEntityType type,
    Map<String, Object?> row, {
    bool deleted = false,
  }) {
    final id = row['id']! as String;
    final revision = ++_lastRevision;
    _tables[type]![id] = {
      ..._normalize(row),
      'owner_id': owner,
      'revision': revision,
      'deleted_at': deleted ? '2026-01-01T00:00:00.000Z' : row['deleted_at'],
    };
    return revision;
  }

  // ---------------------------------------------------------------------------
  // Inspection
  // ---------------------------------------------------------------------------

  int get lastRevision => _lastRevision;

  Map<String, Object?>? rowOf(SyncEntityType type, String id) =>
      _tables[type]![id];

  List<Map<String, Object?>> rowsOf(SyncEntityType type) =>
      _tables[type]!.values.toList();

  int rowCount(SyncEntityType type) => _tables[type]!.length;

  /// Rows sharing an `idempotency_key` with another row of [type].
  int duplicateIdempotencyKeys(SyncEntityType type) {
    final keys = [
      for (final row in _tables[type]!.values) row['idempotency_key'],
    ];
    return keys.length - keys.toSet().length;
  }

  bool ledgerHas(String opId) => _ledger.containsKey(opId);

  // ---------------------------------------------------------------------------
  // SyncRemoteDataSource
  // ---------------------------------------------------------------------------

  @override
  Future<List<PushResult>> push(List<OutboxOp> ops, DeviceInfo device) async {
    pushCalls++;
    if (_scriptedFailures.isNotEmpty) throw _scriptedFailures.removeAt(0);
    final scripted = _failOnCall.remove(pushCalls);
    if (scripted != null) throw scripted;
    if (ops.length > 100) {
      throw _exception(const ServerFailure('too_many_operations'), false);
    }

    final results = [for (final op in ops) _apply(op)];
    committedBatches.add(List.of(ops));
    lastDevice = device;

    if (_dropNextResponse || _dropOnCall == pushCalls) {
      _dropNextResponse = false;
      _dropOnCall = null;
      throw _exception(const NetworkFailure('response lost'), true);
    }
    return results;
  }

  @override
  Future<PullPage> pull({required int since, int limit = 500}) async {
    pullCalls++;
    if (_scriptedPullFailures.isNotEmpty) {
      throw _scriptedPullFailures.removeAt(0);
    }
    final all = <PulledChange>[
      for (final MapEntry(key: type, value: rows) in _tables.entries)
        for (final row in rows.values)
          if ((row['revision']! as int) > since)
            PulledChange(
              entityType: type,
              revision: row['revision']! as int,
              row: Map.of(row),
            ),
    ]..sort((a, b) => a.revision.compareTo(b.revision));
    final page = all.take(limit).toList();
    return PullPage(
      changes: page,
      maxRevision: page.isEmpty ? since : page.last.revision,
      hasMore: all.length > limit,
    );
  }

  // ---------------------------------------------------------------------------
  // sync_push, one operation
  // ---------------------------------------------------------------------------

  PushResult _apply(OutboxOp op) {
    final replay = _ledger[op.opId];
    if (replay != null) return _replay(op, replay);

    final spec = _specs[op.entityType]!;
    final PushResult result;
    if (op.opType == OutboxOpType.delete && !spec.deletable) {
      result = PushRejected(op.opId, reason: PushRejectReason.validation);
    } else {
      result = _applyValid(op, spec);
    }

    final transient = result is PushRejected && result.isTransient;
    if (!transient) {
      _ledger[op.opId] = switch (result) {
        PushApplied(:final revision, :final alreadyApplied) => _LedgerEntry(
          alreadyApplied ? 'already_applied' : 'applied',
          revision,
          null,
        ),
        PushConflict(:final revision) => _LedgerEntry(
          'conflict',
          revision,
          null,
        ),
        PushSuperseded(:final revision) => _LedgerEntry(
          'superseded',
          revision,
          null,
        ),
        PushRejected(:final reason, :final revision) => _LedgerEntry(
          'rejected',
          revision,
          reason,
        ),
      };
    }
    return result;
  }

  PushResult _replay(OutboxOp op, _LedgerEntry entry) {
    final current = _tables[op.entityType]![op.entityId];
    return switch (entry.result) {
      'applied' || 'already_applied' => PushApplied(
        op.opId,
        revision: entry.revision,
        alreadyApplied: true,
      ),
      'conflict' => PushConflict(
        op.opId,
        revision: entry.revision!,
        serverRow: Map.of(current!),
      ),
      'superseded' => PushSuperseded(
        op.opId,
        revision: entry.revision!,
        serverRow: Map.of(current!),
      ),
      _ => PushRejected(
        op.opId,
        reason: entry.reason!,
        revision: entry.revision,
        serverRow:
            entry.reason == PushRejectReason.personHasTransactions &&
                current != null
            ? Map.of(current)
            : null,
      ),
    };
  }

  PushResult _applyValid(OutboxOp op, _EntitySpec spec) {
    final table = _tables[op.entityType]!;
    final current = table[op.entityId];
    final payload = _normalize(op.payload);

    if (op.opType == OutboxOpType.delete) {
      return _delete(op, current);
    }

    final invalid = _validate(op.entityType, payload);
    if (invalid != null) return PushRejected(op.opId, reason: invalid);

    if (current == null) {
      // 3a
      if (spec.policy == _Policy.financial) {
        final key = payload['idempotency_key'];
        for (final row in table.values) {
          if (row['idempotency_key'] == key) {
            return PushApplied(
              op.opId,
              revision: row['revision']! as int,
              alreadyApplied: true,
            );
          }
        }
      }
      final parentMiss = _missingParent(op.entityType, payload);
      if (parentMiss) {
        return PushRejected(op.opId, reason: PushRejectReason.missingParent);
      }
      return PushApplied(op.opId, revision: _write(op, payload, null));
    }

    final currentRevision = current['revision']! as int;
    switch (spec.policy) {
      case _Policy.append:
        return PushApplied(
          op.opId,
          revision: currentRevision,
          alreadyApplied: true,
        );
      case _Policy.financial
          when op.baseRevision == null || op.baseRevision != currentRevision:
        final equal =
            op.baseRevision == null &&
            spec.business.every(
              (c) => !payload.containsKey(c) || payload[c] == current[c],
            );
        if (equal) {
          return PushApplied(
            op.opId,
            revision: currentRevision,
            alreadyApplied: true,
          );
        }
        return PushConflict(
          op.opId,
          revision: currentRevision,
          serverRow: Map.of(current),
        );
      case _Policy.financial || _Policy.lww:
        if (_missingParent(op.entityType, payload)) {
          return PushRejected(op.opId, reason: PushRejectReason.missingParent);
        }
        return PushApplied(op.opId, revision: _write(op, payload, current));
    }
  }

  PushResult _delete(OutboxOp op, Map<String, Object?>? current) {
    if (current == null || current['deleted_at'] != null) {
      return PushApplied(
        op.opId,
        revision: current?['revision'] as int?,
        alreadyApplied: true,
      );
    }
    final currentRevision = current['revision']! as int;
    if (op.baseRevision != null && op.baseRevision != currentRevision) {
      return PushSuperseded(
        op.opId,
        revision: currentRevision,
        serverRow: Map.of(current),
      );
    }
    if (op.entityType == SyncEntityType.financeCategory &&
        _tables[SyncEntityType.financeEntry]!.values.any(
          (e) => e['category_id'] == op.entityId,
        )) {
      final revision = ++_lastRevision;
      current
        ..['is_archived'] = true
        ..['revision'] = revision;
      return PushApplied(
        op.opId,
        revision: revision,
        serverRow: Map.of(current),
      );
    }
    if (op.entityType == SyncEntityType.person &&
        _tables[SyncEntityType.moneyTransaction]!.values.any(
          (t) => t['person_id'] == op.entityId,
        )) {
      return PushRejected(
        op.opId,
        reason: PushRejectReason.personHasTransactions,
        revision: currentRevision,
        serverRow: Map.of(current),
      );
    }
    final revision = ++_lastRevision;
    current
      ..['deleted_at'] = '2026-09-27T00:00:00.000Z'
      ..['revision'] = revision;
    return PushApplied(op.opId, revision: revision);
  }

  int _write(
    OutboxOp op,
    Map<String, Object?> payload,
    Map<String, Object?>? current,
  ) {
    final revision = ++_lastRevision;
    final spec = _specs[op.entityType]!;
    _tables[op.entityType]![op.entityId] = {
      ...?current,
      ...payload,
      // Step 4: an LWW upsert always restates deleted_at (undelete).
      if (spec.policy == _Policy.lww && !payload.containsKey('deleted_at'))
        'deleted_at': null,
      'id': op.entityId,
      'owner_id': owner,
      'revision': revision,
    };
    return revision;
  }

  /// A rule violation, as the server's check constraints and triggers
  /// report it, or null.
  String? _validate(SyncEntityType type, Map<String, Object?> payload) {
    switch (type) {
      case SyncEntityType.person:
        final name = payload['name'];
        if (name is! String || name.isEmpty) return PushRejectReason.validation;
      case SyncEntityType.moneyTransaction || SyncEntityType.financeEntry:
        final amount = payload['amount_minor'];
        if (amount is! int || amount <= 0) return PushRejectReason.validation;
        if (type == SyncEntityType.financeEntry) {
          final category =
              _tables[SyncEntityType.financeCategory]![payload['category_id']];
          if (category != null && category['type'] != payload['type']) {
            return PushRejectReason.categoryTypeMismatch;
          }
        }
      default:
        break;
    }
    return null;
  }

  bool _missingParent(SyncEntityType type, Map<String, Object?> payload) {
    final (parentType, field) = switch (type) {
      SyncEntityType.moneyTransaction => (SyncEntityType.person, 'person_id'),
      SyncEntityType.financeEntry => (
        SyncEntityType.financeCategory,
        'category_id',
      ),
      SyncEntityType.transactionAudit => (
        SyncEntityType.moneyTransaction,
        'transaction_id',
      ),
      _ => (null, null),
    };
    if (parentType == null) return false;
    // A foreign key only needs the row to exist (soft-deleted included).
    return !_tables[parentType]!.containsKey(payload[field]);
  }

  /// Money is sent as a string and stored as a number.
  static Map<String, Object?> _normalize(Map<String, Object?> payload) => {
    for (final MapEntry(:key, :value) in payload.entries)
      key: key == 'amount_minor' && value is String
          ? int.tryParse(value) ?? value
          : value,
  };

  static SyncRemoteException _exception(Failure failure, bool transient) =>
      SyncRemoteException(
        failure,
        transient: transient,
        errorCode: switch (failure) {
          NetworkFailure() => SyncErrorCode.network,
          TimeoutFailure() => SyncErrorCode.timeout,
          UnauthorizedFailure() => SyncErrorCode.unauthorized,
          ForbiddenFailure() => SyncErrorCode.forbidden,
          _ => SyncErrorCode.server,
        },
      );
}

enum _Policy { financial, append, lww }

class _EntitySpec {
  const _EntitySpec(this.policy, this.business, {this.deletable = false});

  final _Policy policy;
  final List<String> business;
  final bool deletable;
}

const _specs = {
  SyncEntityType.person: _EntitySpec(_Policy.lww, [
    'name',
    'normalized_name',
    'phone_number',
    'relationship_tag',
    'notes',
    'is_archived',
  ], deletable: true),
  SyncEntityType.moneyTransaction: _EntitySpec(_Policy.financial, [
    'person_id',
    'idempotency_key',
    'amount_minor',
    'currency_code',
    'direction',
    'kind',
    'occurred_at',
    'occurred_on',
    'tz_offset_minutes',
    'note',
    'edited_at',
    'deleted_at',
  ]),
  SyncEntityType.transactionAudit: _EntitySpec(_Policy.append, [
    'transaction_id',
    'change_type',
    'previous_values',
    'changed_at',
  ]),
  SyncEntityType.financeCategory: _EntitySpec(_Policy.lww, [
    'name',
    'normalized_name',
    'type',
    'icon_key',
    'is_default',
    'is_archived',
  ], deletable: true),
  SyncEntityType.financeEntry: _EntitySpec(_Policy.financial, [
    'category_id',
    'idempotency_key',
    'type',
    'amount_minor',
    'currency_code',
    'occurred_at',
    'occurred_on',
    'tz_offset_minutes',
    'note',
    'edited_at',
    'deleted_at',
  ]),
  SyncEntityType.exchangeRate: _EntitySpec(_Policy.lww, [
    'currency_code',
    'relative_to_currency_code',
    'rate_micros',
  ], deletable: true),
  SyncEntityType.primaryCurrency: _EntitySpec(_Policy.lww, ['currency_code']),
  SyncEntityType.conflictResolution: _EntitySpec(_Policy.append, [
    'entity_type',
    'entity_id',
    'chosen_side',
    'discarded_values',
    'resolved_at',
  ]),
};

class _OwnerData {
  final Map<SyncEntityType, Map<String, Map<String, Object?>>> tables = {
    for (final type in SyncEntityType.values) type: {},
  };
  final Map<String, _LedgerEntry> ledger = {};
  int lastRevision = 0;
}

class _LedgerEntry {
  const _LedgerEntry(this.result, this.revision, this.reason);

  final String result;
  final int? revision;
  final String? reason;
}
