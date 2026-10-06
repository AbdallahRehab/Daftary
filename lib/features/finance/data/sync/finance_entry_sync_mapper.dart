import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `finance_entries` ⇄ the `finance_entry` wire payload. Same money
/// and date rules as money transactions; a soft delete travels as
/// `deleted_at`.
@lazySingleton
class FinanceEntrySyncMapper extends SyncMapper<FinanceEntry> {
  const FinanceEntrySyncMapper();

  static const types = {'income', 'expense'};

  @override
  SyncEntityType get type => SyncEntityType.financeEntry;

  @override
  Map<String, Object?> toWire(FinanceEntry row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'category_id': row.categoryId,
    'type': row.type,
    'amount_minor': SyncWire.money(row.amountMinorUnits),
    'currency_code': row.currencyCode,
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
  FinanceEntriesCompanion fromWire(
    Map<String, Object?> json, {
    FinanceEntry? existingLocal,
  }) => FinanceEntriesCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    categoryId: SyncWire.string(json, 'category_id'),
    type: SyncWire.oneOf(json, 'type', types),
    amountMinorUnits: SyncWire.parseMoney(json['amount_minor'], 'amount_minor'),
    currencyCode: Value(SyncWire.string(json, 'currency_code')),
    date: SyncWire.parseLocalDay(json),
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
