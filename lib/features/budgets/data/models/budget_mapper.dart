import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/currency.dart';
import '../../domain/entities/budget.dart' as domain;

/// Maps `budgets` rows to the domain [domain.Budget]. Timestamps are stored
/// as epoch millis, so this is the single place that conversion happens.
extension BudgetMapper on db.Budget {
  domain.Budget toDomain() => domain.Budget(
    id: id,
    idempotencyKey: idempotencyKey,
    month: month,
    expectedIncomeMinorUnits: expectedIncomeMinorUnits,
    currency: Currency.fromCode(currencyCode),
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}
