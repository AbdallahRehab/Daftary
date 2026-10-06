import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/finance_entry_audit.dart' as domain;

/// Maps `finance_entry_audits` rows to the domain [domain.FinanceEntryAudit].
extension FinanceEntryAuditMapper on db.FinanceEntryAudit {
  domain.FinanceEntryAudit toDomain() => domain.FinanceEntryAudit(
    id: id,
    financeEntryId: financeEntryId,
    changeType: domain.FinanceAuditChange.fromValue(changeType),
    previousValuesJson: previousValuesJson,
    changedAt: DateTime.fromMillisecondsSinceEpoch(changedAt),
  );
}
