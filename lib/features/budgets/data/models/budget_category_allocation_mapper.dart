import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/currency.dart';
import '../../domain/entities/budget_category_allocation.dart' as domain;

/// Maps `budget_category_allocations` rows to the domain
/// [domain.BudgetCategoryAllocation]. An allocation row has no currency of
/// its own, so the caller passes its budget's (018).
extension BudgetCategoryAllocationMapper on db.BudgetCategoryAllocation {
  domain.BudgetCategoryAllocation toDomain(Currency currency) =>
      domain.BudgetCategoryAllocation(
        id: id,
        idempotencyKey: idempotencyKey,
        budgetId: budgetId,
        categoryId: categoryId,
        plannedAmountMinorUnits: plannedAmountMinorUnits,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
        currency: currency,
      );
}
