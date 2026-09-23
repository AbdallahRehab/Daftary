import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/budget.dart' as domain;

/// Maps `budgets` rows to the domain [domain.Budget]. Timestamps are stored
/// as epoch millis, so this is the single place that conversion happens.
extension BudgetMapper on db.Budget {
  domain.Budget toDomain() => domain.Budget(
    id: id,
    idempotencyKey: idempotencyKey,
    month: month,
    expectedIncomeMinorUnits: expectedIncomeMinorUnits,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}
