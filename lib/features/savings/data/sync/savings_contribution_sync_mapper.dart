import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';
import '../../domain/entities/savings_contribution.dart' show ContributionType;

/// 023: `savings_contributions` ⇄ the `savings_contribution` wire payload.
/// Conflict policy (migration 025): `financial` (a stale edit becomes a
/// manual conflict) for app 1.1.0 and later, last-write-wins for older
/// apps; a soft delete travels as `deleted_at` on an upsert,
/// never as a delete op. Both the goal-currency amount and what the user
/// entered travel, so no device ever re-converts (011 research.md
/// Decision 9).
@lazySingleton
class SavingsContributionSyncMapper extends SyncMapper<SavingsContribution> {
  const SavingsContributionSyncMapper();

  static final Set<String> types = {
    for (final type in ContributionType.values) type.value,
  };

  @override
  SyncEntityType get type => SyncEntityType.savingsContribution;

  @override
  Map<String, Object?> toWire(SavingsContribution row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'goal_id': row.goalId,
    'type': row.type,
    'amount_minor_units': SyncWire.money(row.amountMinorUnits),
    'entered_amount_minor_units': SyncWire.money(row.enteredAmountMinorUnits),
    'entered_currency_code': row.enteredCurrencyCode,
    // Date-only in the app: the local midnight, as an instant.
    'date': SyncWire.instant(row.date),
    'note': row.note,
    'edited_at': SyncWire.instantOrNull(row.editedAt),
    'deleted_at': SyncWire.instantOrNull(row.deletedAt),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(
      SyncWire.latest([row.createdAt, row.editedAt, row.deletedAt]),
    ),
  };

  @override
  SavingsContributionsCompanion fromWire(
    Map<String, Object?> json, {
    SavingsContribution? existingLocal,
  }) => SavingsContributionsCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    goalId: SyncWire.string(json, 'goal_id'),
    type: SyncWire.oneOf(json, 'type', types),
    amountMinorUnits: SyncWire.parseMoney(
      json['amount_minor_units'],
      'amount_minor_units',
    ),
    enteredAmountMinorUnits: SyncWire.parseMoney(
      json['entered_amount_minor_units'],
      'entered_amount_minor_units',
    ),
    enteredCurrencyCode: SyncWire.string(json, 'entered_currency_code'),
    date: SyncWire.parseInstant(json['date'], 'date'),
    note: Value(SyncWire.stringOrNull(json, 'note')),
    createdAt: SyncWire.parseFirstInstant(json, const [
      'client_created_at',
      'server_created_at',
    ]),
    editedAt: Value(
      SyncWire.parseInstantOrNull(json['edited_at'], 'edited_at'),
    ),
    deletedAt: Value(
      SyncWire.parseInstantOrNull(json['deleted_at'], 'deleted_at'),
    ),
  );
}
