import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/currency.dart';
import '../../domain/entities/savings_contribution.dart' as domain;

/// Maps `savings_contributions` rows to the domain
/// [domain.SavingsContribution].
extension SavingsContributionMapper on db.SavingsContribution {
  domain.SavingsContribution toDomain() => domain.SavingsContribution(
    id: id,
    idempotencyKey: idempotencyKey,
    goalId: goalId,
    type: domain.ContributionType.fromValue(type),
    amountMinorUnits: amountMinorUnits,
    enteredAmountMinorUnits: enteredAmountMinorUnits,
    enteredCurrency: Currency.fromCode(enteredCurrencyCode),
    date: DateTime.fromMillisecondsSinceEpoch(date),
    note: note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    editedAt: editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(editedAt!),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}
