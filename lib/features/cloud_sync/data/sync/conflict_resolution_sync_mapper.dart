import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `conflict_resolutions` ⇄ the `conflict_resolution` wire payload
/// (research.md Decision 8). Append-only. `discarded_values` is a JSON
/// object on the wire, text locally.
@lazySingleton
class ConflictResolutionSyncMapper extends SyncMapper<ConflictResolutionRow> {
  const ConflictResolutionSyncMapper();

  static const entityTypes = {'money_transaction', 'finance_entry'};
  static const sides = {'local', 'server'};

  @override
  SyncEntityType get type => SyncEntityType.conflictResolution;

  @override
  Map<String, Object?> toWire(ConflictResolutionRow row) => {
    'id': row.id,
    'entity_type': row.entityType,
    'entity_id': row.entityId,
    'chosen_side': row.chosenSide,
    'discarded_values': jsonDecode(row.discardedValuesJson),
    'resolved_at': SyncWire.instant(row.resolvedAt),
    'client_created_at': SyncWire.instant(row.resolvedAt),
    'client_updated_at': SyncWire.instant(row.resolvedAt),
    'deleted_at': null,
  };

  @override
  ConflictResolutionsCompanion fromWire(
    Map<String, Object?> json, {
    ConflictResolutionRow? existingLocal,
  }) {
    final discarded = json['discarded_values'];
    if (discarded is! Map) {
      throw const FormatException('Invalid wire value for "discarded_values"');
    }
    return ConflictResolutionsCompanion.insert(
      id: SyncWire.string(json, 'id'),
      entityType: SyncWire.oneOf(json, 'entity_type', entityTypes),
      entityId: SyncWire.string(json, 'entity_id'),
      chosenSide: SyncWire.oneOf(json, 'chosen_side', sides),
      discardedValuesJson: jsonEncode(discarded),
      resolvedAt: SyncWire.parseInstant(json['resolved_at'], 'resolved_at'),
    );
  }
}
