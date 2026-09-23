import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/budget_category_allocation.dart' as domain;

/// Maps `budget_category_allocations` rows to the domain
/// [domain.BudgetCategoryAllocation].
extension BudgetCategoryAllocationMapper on db.BudgetCategoryAllocation {
  domain.BudgetCategoryAllocation toDomain() => domain.BudgetCategoryAllocation(
    id: id,
    idempotencyKey: idempotencyKey,
    budgetId: budgetId,
    categoryId: categoryId,
    plannedAmountMinorUnits: plannedAmountMinorUnits,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}
