import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 022: `budgets` ⇄ the `budget` wire payload. Last-write-wins; a soft
/// delete travels as `deleted_at` on an upsert. New budgets are keyed
/// `budget_<YYYY-MM>` (`BudgetIds`), so two devices planning the same month
/// offline converge on one row.
@lazySingleton
class BudgetSyncMapper extends SyncMapper<Budget> {
  const BudgetSyncMapper();

  @override
  SyncEntityType get type => SyncEntityType.budget;

  @override
  Map<String, Object?> toWire(Budget row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'month': row.month,
    'expected_income_minor': row.expectedIncomeMinorUnits == null
        ? null
        : SyncWire.money(row.expectedIncomeMinorUnits!),
    'currency_code': row.currencyCode,
    'deleted_at': SyncWire.instantOrNull(row.deletedAt),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(
      SyncWire.latest([row.createdAt, row.updatedAt, row.deletedAt]),
    ),
  };

  @override
  BudgetsCompanion fromWire(
    Map<String, Object?> json, {
    Budget? existingLocal,
  }) {
    final income = json['expected_income_minor'];
    return BudgetsCompanion.insert(
      id: SyncWire.string(json, 'id'),
      idempotencyKey: SyncWire.string(json, 'idempotency_key'),
      month: SyncWire.string(json, 'month'),
      expectedIncomeMinorUnits: Value(
        income == null
            ? null
            : SyncWire.parseMoney(income, 'expected_income_minor'),
      ),
      currencyCode: Value(SyncWire.string(json, 'currency_code')),
      createdAt: SyncWire.parseFirstInstant(json, const [
        'client_created_at',
        'server_created_at',
      ]),
      updatedAt: SyncWire.parseFirstInstant(json, const [
        'client_updated_at',
        'server_updated_at',
      ]),
      deletedAt: Value(
        SyncWire.parseInstantOrNull(json['deleted_at'], 'deleted_at'),
      ),
    );
  }
}

/// 022: `budget_category_allocations` ⇄ the `budget_allocation` wire
/// payload. Hard-deleted in the app, so a removal travels as a delete op and
/// arrives as a tombstone that removes the row. Keyed
/// `alloc_<budget>_<category>` (`BudgetIds`), so the same category planned on
/// two devices converges on one row.
@lazySingleton
class BudgetAllocationSyncMapper extends SyncMapper<BudgetCategoryAllocation> {
  const BudgetAllocationSyncMapper();

  @override
  SyncEntityType get type => SyncEntityType.budgetAllocation;

  @override
  Map<String, Object?> toWire(BudgetCategoryAllocation row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'budget_id': row.budgetId,
    'category_id': row.categoryId,
    'planned_minor': SyncWire.money(row.plannedAmountMinorUnits),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(row.updatedAt),
    'deleted_at': null,
  };

  @override
  BudgetCategoryAllocationsCompanion fromWire(
    Map<String, Object?> json, {
    BudgetCategoryAllocation? existingLocal,
  }) => BudgetCategoryAllocationsCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    budgetId: SyncWire.string(json, 'budget_id'),
    categoryId: SyncWire.string(json, 'category_id'),
    plannedAmountMinorUnits: SyncWire.parseMoney(
      json['planned_minor'],
      'planned_minor',
    ),
    createdAt: SyncWire.parseFirstInstant(json, const [
      'client_created_at',
      'server_created_at',
    ]),
    updatedAt: SyncWire.parseFirstInstant(json, const [
      'client_updated_at',
      'server_updated_at',
    ]),
  );
}
