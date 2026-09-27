import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `people` ⇄ the `person` wire payload.
///
/// `avatarPath` is a device file path: it is never uploaded, and a
/// downloaded person keeps the local value if there is one (data-model.md
/// §1).
@lazySingleton
class PersonSyncMapper extends SyncMapper<PeopleData> {
  const PersonSyncMapper();

  @override
  SyncEntityType get type => SyncEntityType.person;

  @override
  Map<String, Object?> toWire(PeopleData row) => {
    'id': row.id,
    'name': row.name,
    'normalized_name': row.normalizedName,
    'phone_number': row.phoneNumber,
    'relationship_tag': row.relationshipTag,
    'notes': row.notes,
    'is_archived': row.isArchived,
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(row.updatedAt),
    // People are hard-deleted locally; a delete op carries the tombstone.
    'deleted_at': null,
  };

  @override
  PeopleCompanion fromWire(
    Map<String, Object?> json, {
    PeopleData? existingLocal,
  }) => PeopleCompanion.insert(
    id: SyncWire.string(json, 'id'),
    name: SyncWire.string(json, 'name'),
    normalizedName: SyncWire.string(json, 'normalized_name'),
    phoneNumber: Value(SyncWire.stringOrNull(json, 'phone_number')),
    avatarPath: Value(existingLocal?.avatarPath),
    relationshipTag: Value(SyncWire.stringOrNull(json, 'relationship_tag')),
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
  );
}
