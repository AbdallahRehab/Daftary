import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 021 T014 — one test per row of data-model.md §5.
void main() {
  ExistingOutboxOp op({
    OutboxOpType type = OutboxOpType.upsert,
    int? base,
    String status = OutboxStatus.pending,
  }) => ExistingOutboxOp(
    opId: 'op-1',
    opType: type,
    baseRevision: base,
    status: status,
  );

  test('no open operation → insert a new one', () {
    for (final t in SyncEntityType.values) {
      expect(
        coalesce(null, type: t, newOpType: OutboxOpType.upsert),
        const InsertNewOp(),
      );
    }
  });

  test('upsert + upsert → replace the payload, keeping op_id and base', () {
    for (final base in [null, 7]) {
      expect(
        coalesce(
          op(base: base),
          type: SyncEntityType.person,
          newOpType: OutboxOpType.upsert,
        ),
        const MergeIntoOp('op-1', OutboxOpType.upsert),
      );
    }
  });

  test('never-synced upsert + delete for person, category or rate → drop '
      'both', () {
    for (final t in [
      SyncEntityType.person,
      SyncEntityType.financeCategory,
      SyncEntityType.exchangeRate,
    ]) {
      expect(
        coalesce(op(), type: t, newOpType: OutboxOpType.delete),
        const DropBothOps('op-1'),
        reason: t.wire,
      );
    }
  });

  test('never-synced upsert + soft delete for a transaction or entry → an '
      'upsert (with deleted_at) that still uploads', () {
    for (final t in [
      SyncEntityType.moneyTransaction,
      SyncEntityType.financeEntry,
    ]) {
      expect(
        coalesce(op(), type: t, newOpType: OutboxOpType.upsert),
        const MergeIntoOp('op-1', OutboxOpType.upsert),
        reason: t.wire,
      );
    }
  });

  test('upsert + delete for a synced record → a delete keeping the base', () {
    for (final t in [
      SyncEntityType.person,
      SyncEntityType.financeCategory,
      SyncEntityType.exchangeRate,
    ]) {
      expect(
        coalesce(op(base: 12), type: t, newOpType: OutboxOpType.delete),
        const MergeIntoOp('op-1', OutboxOpType.delete),
        reason: t.wire,
      );
    }
  });

  test('audit and conflict-resolution inserts are never coalesced', () {
    for (final t in [
      SyncEntityType.transactionAudit,
      SyncEntityType.conflictResolution,
      SyncEntityType.savingsContributionAudit,
      SyncEntityType.financeEntryAudit,
    ]) {
      expect(
        coalesce(op(), type: t, newOpType: OutboxOpType.upsert),
        const InsertNewOp(),
        reason: t.wire,
      );
    }
  });

  test('never merges into an in_flight operation', () {
    expect(
      coalesce(
        op(status: OutboxStatus.inFlight),
        type: SyncEntityType.person,
        newOpType: OutboxOpType.upsert,
      ),
      const InsertNewOp(),
    );
    expect(
      coalesce(
        op(status: OutboxStatus.inFlight),
        type: SyncEntityType.person,
        newOpType: OutboxOpType.delete,
      ),
      const InsertNewOp(),
    );
  });

  test('never merges into a failed or conflict-blocked operation', () {
    for (final status in [OutboxStatus.failed, OutboxStatus.blockedConflict]) {
      expect(
        coalesce(
          op(status: status),
          type: SyncEntityType.moneyTransaction,
          newOpType: OutboxOpType.upsert,
        ),
        const InsertNewOp(),
        reason: status,
      );
    }
  });

  test('a pending delete followed by a re-create → an upsert on the same '
      'row', () {
    expect(
      coalesce(
        op(type: OutboxOpType.delete, base: 3),
        type: SyncEntityType.exchangeRate,
        newOpType: OutboxOpType.upsert,
      ),
      const MergeIntoOp('op-1', OutboxOpType.upsert),
    );
  });

  test('OutboxOpType round-trips its wire value', () {
    for (final t in OutboxOpType.values) {
      expect(OutboxOpType.fromWire(t.wire), t);
    }
    expect(() => OutboxOpType.fromWire('merge'), throwsArgumentError);
  });
}
