import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 022: `occasions` ⇄ the `occasion` wire payload. Last-write-wins; a soft
/// delete travels as `deleted_at` on an upsert, exactly as the app records
/// it. Photo attachments never travel (008 FR-017).
@lazySingleton
class OccasionSyncMapper extends SyncMapper<Occasion> {
  const OccasionSyncMapper();

  @override
  SyncEntityType get type => SyncEntityType.occasion;

  @override
  Map<String, Object?> toWire(Occasion row) => {
    'id': row.id,
    'idempotency_key': row.idempotencyKey,
    'name': row.name,
    // Date-only in the app: the local midnight, as an instant.
    'occasion_at': SyncWire.instant(row.date),
    'type': row.type,
    'notes': row.notes,
    'is_archived': row.isArchived,
    'deleted_at': SyncWire.instantOrNull(row.deletedAt),
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(
      SyncWire.latest([row.createdAt, row.updatedAt, row.deletedAt]),
    ),
  };

  @override
  OccasionsCompanion fromWire(
    Map<String, Object?> json, {
    Occasion? existingLocal,
  }) => OccasionsCompanion.insert(
    id: SyncWire.string(json, 'id'),
    idempotencyKey: SyncWire.string(json, 'idempotency_key'),
    name: SyncWire.string(json, 'name'),
    date: SyncWire.parseInstant(json['occasion_at'], 'occasion_at'),
    type: SyncWire.string(json, 'type'),
    notes: Value(SyncWire.stringOrNull(json, 'notes')),
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
