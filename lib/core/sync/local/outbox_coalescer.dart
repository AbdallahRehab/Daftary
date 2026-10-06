import '../sync_entity_type.dart';

/// 021: outbox operation kinds, as stored in `sync_outbox.op_type`.
enum OutboxOpType {
  upsert('upsert'),
  delete('delete');

  const OutboxOpType(this.wire);

  final String wire;

  static OutboxOpType fromWire(String value) => switch (value) {
    'upsert' => upsert,
    'delete' => delete,
    _ => throw ArgumentError.value(value, 'value', 'Unknown outbox op type'),
  };
}

/// 021: outbox row statuses, as stored in `sync_outbox.status`.
abstract final class OutboxStatus {
  static const pending = 'pending';
  static const inFlight = 'in_flight';
  static const failed = 'failed';
  static const blockedConflict = 'blocked_conflict';
}

/// The open outbox operation already queued for an entity — the fields the
/// coalescing rules look at.
class ExistingOutboxOp {
  const ExistingOutboxOp({
    required this.opId,
    required this.opType,
    required this.baseRevision,
    required this.status,
  });

  final String opId;
  final OutboxOpType opType;

  /// Null = the record has never been synced.
  final int? baseRevision;
  final String status;
}

/// What the outbox must do with a new operation.
sealed class CoalesceDecision {
  const CoalesceDecision();
}

/// Queue the new operation as its own row.
final class InsertNewOp extends CoalesceDecision {
  const InsertNewOp();

  @override
  bool operator ==(Object other) => other is InsertNewOp;

  @override
  int get hashCode => (InsertNewOp).hashCode;
}

/// Fold the new operation into the existing row [opId]: replace its payload
/// and set its type to [opType], keeping its `op_id` and `base_revision`.
final class MergeIntoOp extends CoalesceDecision {
  const MergeIntoOp(this.opId, this.opType);

  final String opId;
  final OutboxOpType opType;

  @override
  bool operator ==(Object other) =>
      other is MergeIntoOp && other.opId == opId && other.opType == opType;

  @override
  int get hashCode => Object.hash(opId, opType);
}

/// Delete the existing row [opId] and queue nothing: the server never saw
/// the record, so the create and the delete cancel out.
final class DropBothOps extends CoalesceDecision {
  const DropBothOps(this.opId);

  final String opId;

  @override
  bool operator ==(Object other) => other is DropBothOps && other.opId == opId;

  @override
  int get hashCode => opId.hashCode;
}

/// Types whose delete is a hard local delete with a cloud tombstone, so a
/// never-synced create followed by a delete can be dropped entirely.
const _droppableOnDelete = {
  SyncEntityType.person,
  SyncEntityType.financeCategory,
  SyncEntityType.exchangeRate,
};

/// Append-only types: every insert is its own operation.
const _neverCoalesced = {
  SyncEntityType.transactionAudit,
  SyncEntityType.conflictResolution,
  SyncEntityType.savingsContributionAudit,
  SyncEntityType.financeEntryAudit,
};

/// The coalescing rules of data-model.md §5 (FR-025), as a pure function.
///
/// Only a `pending` operation is ever merged into — never one that is
/// `in_flight` (it may already be applied on the server), `failed` or
/// `blocked_conflict`.
CoalesceDecision coalesce(
  ExistingOutboxOp? existing, {
  required SyncEntityType type,
  required OutboxOpType newOpType,
}) {
  if (_neverCoalesced.contains(type)) return const InsertNewOp();
  if (existing == null || existing.status != OutboxStatus.pending) {
    return const InsertNewOp();
  }

  if (existing.opType == OutboxOpType.upsert &&
      newOpType == OutboxOpType.delete &&
      existing.baseRevision == null &&
      _droppableOnDelete.contains(type)) {
    return DropBothOps(existing.opId);
  }

  // upsert + upsert → replace the payload (this also covers a financial
  // soft delete, which is an upsert with `deleted_at` set); upsert + delete
  // of a synced record → a delete that keeps the base revision; a pending
  // delete followed by a re-create → an upsert against the same base.
  return MergeIntoOp(existing.opId, newOpType);
}
