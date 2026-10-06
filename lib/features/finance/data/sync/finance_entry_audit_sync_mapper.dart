import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 022 D2: `finance_entry_audits` ⇄ the `finance_entry_audit` wire payload.
/// Append-only, like `transaction_audit`. `change_type` is carried
/// unchanged; `previous_values` is a JSON object on the wire (a `jsonb`
/// column) and null for `created`, text locally.
@lazySingleton
class FinanceEntryAuditSyncMapper extends SyncMapper<FinanceEntryAudit> {
  const FinanceEntryAuditSyncMapper();

  static const changeTypes = {'created', 'edited', 'deleted', 'restored'};

  @override
  SyncEntityType get type => SyncEntityType.financeEntryAudit;

  @override
  Map<String, Object?> toWire(FinanceEntryAudit row) => {
    'id': row.id,
    'finance_entry_id': row.financeEntryId,
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
  FinanceEntryAuditsCompanion fromWire(
    Map<String, Object?> json, {
    FinanceEntryAudit? existingLocal,
  }) {
    final previous = json['previous_values'];
    if (previous != null && previous is! Map) {
      throw const FormatException('Invalid wire value for "previous_values"');
    }
    return FinanceEntryAuditsCompanion.insert(
      id: SyncWire.string(json, 'id'),
      financeEntryId: SyncWire.string(json, 'finance_entry_id'),
      changeType: SyncWire.oneOf(json, 'change_type', changeTypes),
      previousValuesJson: Value(previous == null ? null : jsonEncode(previous)),
      changedAt: SyncWire.parseInstant(json['changed_at'], 'changed_at'),
    );
  }
}
