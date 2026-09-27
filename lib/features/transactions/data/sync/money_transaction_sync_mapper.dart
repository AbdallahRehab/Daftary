import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `money_transactions` ⇄ the `money_transaction` wire payload
/// (contracts/sync-rpc.md §1). A soft delete travels as `deleted_at`.
@lazySingleton
class MoneyTransactionSyncMapper extends SyncMapper<MoneyTransaction> {
  const MoneyTransactionSyncMapper();

  static const directions = {'given', 'received'};
  static const kinds = {'initialExchange', 'repayment'};

  @override
  SyncEntityType get type => SyncEntityType.moneyTransaction;

  @override
  Map<String, Object?> toWire(MoneyTransaction row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'person_id': row.personId,
    'amount_minor': SyncWire.money(row.amountMinorUnits),
    'currency_code': row.currencyCode,
    'direction': row.direction,
    'kind': row.kind,
    ...SyncWire.occurrence(row.date),
    'note': row.note,
    'edited_at': SyncWire.instantOrNull(row.editedAt),
    'deleted_at': SyncWire.instantOrNull(row.deletedAt),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(
      SyncWire.latest([row.createdAt, row.editedAt, row.deletedAt]),
    ),
  };

  @override
  MoneyTransactionsCompanion fromWire(
    Map<String, Object?> json, {
    MoneyTransaction? existingLocal,
  }) => MoneyTransactionsCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    personId: SyncWire.string(json, 'person_id'),
    amountMinorUnits: SyncWire.parseMoney(json['amount_minor'], 'amount_minor'),
    currencyCode: Value(SyncWire.string(json, 'currency_code')),
    direction: SyncWire.oneOf(json, 'direction', directions),
    kind: SyncWire.oneOf(json, 'kind', kinds),
    date: SyncWire.parseInstant(json['occurred_at'], 'occurred_at'),
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
