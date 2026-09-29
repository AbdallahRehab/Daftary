import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/savings_contribution_audit.dart' as domain;

/// Maps `savings_contribution_audits` rows to the domain
/// [domain.SavingsContributionAudit].
extension SavingsContributionAuditMapper on db.SavingsContributionAudit {
  domain.SavingsContributionAudit toDomain() => domain.SavingsContributionAudit(
    id: id,
    contributionId: contributionId,
    changeType: domain.ContributionAuditChange.fromValue(changeType),
    previousValuesJson: previousValuesJson,
    changedAt: DateTime.fromMillisecondsSinceEpoch(changedAt),
  );
}
