import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `transaction_audit_entries` ⇄ the `transaction_audit` wire payload.
/// Append-only. `change_type` is carried unchanged; `previous_values` is a
/// JSON object on the wire (a `jsonb` column), text locally.
@lazySingleton
class TransactionAuditSyncMapper extends SyncMapper<TransactionAuditEntry> {
  const TransactionAuditSyncMapper();

  static const changeTypes = {'created', 'edited', 'deleted'};

  @override
  SyncEntityType get type => SyncEntityType.transactionAudit;

  @override
  Map<String, Object?> toWire(TransactionAuditEntry row) => {
    'id': row.id,
    'transaction_id': row.transactionId,
    'change_type': row.changeType,
    'previous_values': row.previousValuesJson == null
        ? null
        : jsonDecode(row.previousValuesJson!),
    'changed_at': SyncWire.instant(row.changedAt),
    'client_created_at': SyncWire.instant(row.changedAt),
    'client_updated_at': SyncWire.instant(row.changedAt),
    'deleted_at': null,
  };

  @override
  TransactionAuditEntriesCompanion fromWire(
    Map<String, Object?> json, {
    TransactionAuditEntry? existingLocal,
  }) {
    final previous = json['previous_values'];
    if (previous != null && previous is! Map) {
      throw const FormatException('Invalid wire value for "previous_values"');
    }
    return TransactionAuditEntriesCompanion.insert(
      id: SyncWire.string(json, 'id'),
      transactionId: SyncWire.string(json, 'transaction_id'),
      changeType: SyncWire.oneOf(json, 'change_type', changeTypes),
      previousValuesJson: Value(previous == null ? null : jsonEncode(previous)),
      changedAt: SyncWire.parseInstant(json['changed_at'], 'changed_at'),
    );
  }
}
