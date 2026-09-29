import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 023: `savings_goals` ⇄ the `savings_goal` wire payload. Last-write-wins;
/// a delete (only ever of a goal with no history, 011 FR-021) travels as
/// `deleted_at` on an upsert, never as a delete op.
@lazySingleton
class SavingsGoalSyncMapper extends SyncMapper<SavingsGoal> {
  const SavingsGoalSyncMapper();

  @override
  SyncEntityType get type => SyncEntityType.savingsGoal;

  @override
  Map<String, Object?> toWire(SavingsGoal row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'name': row.name,
    'type': row.type,
    'currency_code': row.currencyCode,
    'target_amount_minor_units': SyncWire.money(row.targetAmountMinorUnits),
    'monthly_contribution_minor_units':
        row.monthlyContributionMinorUnits == null
        ? null
        : SyncWire.money(row.monthlyContributionMinorUnits!),
    // Date-only in the app: the local midnight, as an instant.
    'target_date': SyncWire.instantOrNull(row.targetDate),
    'is_archived': row.isArchived,
    'deleted_at': SyncWire.instantOrNull(row.deletedAt),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(
      SyncWire.latest([row.createdAt, row.updatedAt, row.deletedAt]),
    ),
  };

  @override
  SavingsGoalsCompanion fromWire(
    Map<String, Object?> json, {
    SavingsGoal? existingLocal,
  }) {
    final monthly = json['monthly_contribution_minor_units'];
    return SavingsGoalsCompanion.insert(
      id: SyncWire.string(json, 'id'),
      idempotencyKey: SyncWire.string(json, 'idempotency_key'),
      name: SyncWire.string(json, 'name'),
      type: Value(SyncWire.stringOrNull(json, 'type')),
      currencyCode: Value(SyncWire.string(json, 'currency_code')),
      targetAmountMinorUnits: SyncWire.parseMoney(
        json['target_amount_minor_units'],
        'target_amount_minor_units',
      ),
      monthlyContributionMinorUnits: Value(
        monthly == null
            ? null
            : SyncWire.parseMoney(monthly, 'monthly_contribution_minor_units'),
      ),
      targetDate: Value(
        SyncWire.parseInstantOrNull(json['target_date'], 'target_date'),
      ),
      isArchived: Value(SyncWire.boolean(json, 'is_archived')),
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
