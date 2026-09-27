import 'package:equatable/equatable.dart';

import 'local/outbox_coalescer.dart';
import 'sync_entity_type.dart';

/// 021: one queued outbox operation, as the engine sees it
/// (data-model.md §2 `sync_outbox`).
class OutboxOp extends Equatable {
  const OutboxOp({
    required this.opId,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payload,
    required this.baseRevision,
    this.attemptCount = 0,
    this.createdAt = 0,
  });

  final String opId;
  final SyncEntityType entityType;
  final String entityId;
  final OutboxOpType opType;

  /// The full record snapshot in the wire shape (contracts/sync-rpc.md §1).
  final Map<String, Object?> payload;

  /// The server revision the change was made against; null = never synced.
  final int? baseRevision;
  final int attemptCount;
  final int createdAt;

  /// One element of `sync_push`'s `p_ops` (contracts/sync-rpc.md §2).
  Map<String, Object?> toWire() => {
    'op_id': opId,
    'entity_type': entityType.wire,
    'op_type': opType.wire,
    'entity_id': entityId,
    'base_revision': baseRevision,
    'payload': payload,
  };

  @override
  List<Object?> get props => [
    opId,
    entityType,
    entityId,
    opType,
    payload,
    baseRevision,
    attemptCount,
    createdAt,
  ];
}

/// The device fields `sync_push` records in `devices` (FR-064).
class DeviceInfo extends Equatable {
  const DeviceInfo({
    required this.deviceId,
    required this.platform,
    required this.appVersion,
  });

  final String deviceId;

  /// `android` | `ios` (the server's `devices.platform` check).
  final String platform;
  final String appVersion;

  @override
  List<Object?> get props => [deviceId, platform, appVersion];
}

/// The `sync_push` result for one operation (contracts/sync-rpc.md §2).
sealed class PushResult extends Equatable {
  const PushResult(this.opId);

  final String opId;
}

/// `applied` or `already_applied`: the server holds the change at
/// [revision]. [serverRow] is set when the server wrote something other
/// than what was sent (a category archived instead of deleted).
final class PushApplied extends PushResult {
  const PushApplied(
    super.opId, {
    required this.revision,
    this.alreadyApplied = false,
    this.serverRow,
  });

  /// Null only for a delete of a row the server never had.
  final int? revision;
  final bool alreadyApplied;
  final Map<String, Object?>? serverRow;

  @override
  List<Object?> get props => [opId, revision, alreadyApplied, serverRow];
}

/// `conflict`: a financial record changed on the server since
/// `base_revision`; nothing was written.
final class PushConflict extends PushResult {
  const PushConflict(
    super.opId, {
    required this.revision,
    required this.serverRow,
  });

  final int revision;
  final Map<String, Object?> serverRow;

  @override
  List<Object?> get props => [opId, revision, serverRow];
}

/// `superseded`: a delete lost to a concurrent edit; nothing was written.
final class PushSuperseded extends PushResult {
  const PushSuperseded(
    super.opId, {
    required this.revision,
    required this.serverRow,
  });

  final int revision;
  final Map<String, Object?> serverRow;

  @override
  List<Object?> get props => [opId, revision, serverRow];
}

/// `rejected`: the server refused the operation by rule. [reason] is a code
/// (`person_has_transactions`, `category_type_mismatch`, `missing_parent`,
/// `validation`, `unknown_entity`).
final class PushRejected extends PushResult {
  const PushRejected(
    super.opId, {
    required this.reason,
    this.serverRow,
    this.revision,
  });

  final String reason;

  /// Set for `person_has_transactions`: the current person row.
  final Map<String, Object?>? serverRow;
  final int? revision;

  /// `missing_parent` is transient: the parent is uploaded in an earlier
  /// rank or a later batch (contracts/sync-rpc.md §5).
  bool get isTransient => reason == PushRejectReason.missingParent;

  @override
  List<Object?> get props => [opId, reason, serverRow, revision];
}

/// The `rejected` reasons the server returns.
abstract final class PushRejectReason {
  static const personHasTransactions = 'person_has_transactions';
  static const categoryTypeMismatch = 'category_type_mismatch';
  static const missingParent = 'missing_parent';
  static const validation = 'validation';
  static const unknownEntity = 'unknown_entity';
}

/// One changed row from `sync_pull` (contracts/sync-rpc.md §3).
class PulledChange extends Equatable {
  const PulledChange({
    required this.entityType,
    required this.revision,
    required this.row,
  });

  final SyncEntityType entityType;
  final int revision;
  final Map<String, Object?> row;

  @override
  List<Object?> get props => [entityType, revision, row];
}

/// One `sync_pull` page.
class PullPage extends Equatable {
  const PullPage({
    required this.changes,
    required this.maxRevision,
    required this.hasMore,
  });

  final List<PulledChange> changes;

  /// The highest revision in the page (== `since` when empty).
  final int maxRevision;
  final bool hasMore;

  @override
  List<Object?> get props => [changes, maxRevision, hasMore];
}

/// The status counts behind the Settings sync page, from
/// `sync_record_meta`.
class SyncCounts extends Equatable {
  const SyncCounts({
    required this.pending,
    required this.failed,
    required this.conflicts,
  });

  static const zero = SyncCounts(pending: 0, failed: 0, conflicts: 0);

  final int pending;
  final int failed;
  final int conflicts;

  @override
  List<Object?> get props => [pending, failed, conflicts];
}
