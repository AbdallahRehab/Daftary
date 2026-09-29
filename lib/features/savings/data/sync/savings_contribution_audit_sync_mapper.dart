import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';
import '../../domain/entities/savings_contribution_audit.dart'
    show ContributionAuditChange;

/// 023: `savings_contribution_audits` ⇄ the `savings_contribution_audit`
/// wire payload. Append-only, like `transaction_audit`: `previous_values`
/// is a JSON object on the wire (a `jsonb` column), text locally, and is
/// always present.
@lazySingleton
class SavingsContributionAuditSyncMapper
    extends SyncMapper<SavingsContributionAudit> {
  const SavingsContributionAuditSyncMapper();

  static final Set<String> changeTypes = {
    for (final change in ContributionAuditChange.values) change.value,
  };

  @override
  SyncEntityType get type => SyncEntityType.savingsContributionAudit;

  @override
  Map<String, Object?> toWire(SavingsContributionAudit row) => {
    'id': row.id,
    'contribution_id': row.contributionId,
    'change_type': row.changeType,
    'previous_values': jsonDecode(row.previousValuesJson),
    'changed_at': SyncWire.instant(row.changedAt),
    'client_created_at': SyncWire.instant(row.changedAt),
    'client_updated_at': SyncWire.instant(row.changedAt),
    'deleted_at': null,
  };

  @override
  SavingsContributionAuditsCompanion fromWire(
    Map<String, Object?> json, {
    SavingsContributionAudit? existingLocal,
  }) {
    final previous = json['previous_values'];
    if (previous is! Map) {
      throw const FormatException('Invalid wire value for "previous_values"');
    }
    return SavingsContributionAuditsCompanion.insert(
      id: SyncWire.string(json, 'id'),
      contributionId: SyncWire.string(json, 'contribution_id'),
      changeType: SyncWire.oneOf(json, 'change_type', changeTypes),
      previousValuesJson: jsonEncode(previous),
      changedAt: SyncWire.parseInstant(json['changed_at'], 'changed_at'),
    );
  }
}
