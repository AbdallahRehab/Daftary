import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/finance_category_seed.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `finance_categories` ⇄ the `finance_category` wire payload. The
/// local `icon` is the cloud `icon_key`.
@lazySingleton
class FinanceCategorySyncMapper extends SyncMapper<FinanceCategory> {
  const FinanceCategorySyncMapper();

  static const types = {'income', 'expense'};

  @override
  SyncEntityType get type => SyncEntityType.financeCategory;

  @override
  Map<String, Object?> toWire(FinanceCategory row) => {
    'id': row.id,
    'name': row.name,
    'normalized_name': row.normalizedName,
    'type': row.type,
    'icon_key': row.icon,
    'is_default': row.isDefault,
    'is_archived': row.isArchived,
    'client_created_at': SyncWire.instant(row.createdAt),
    'client_updated_at': SyncWire.instant(row.updatedAt),
    // Categories are hard-deleted locally; a delete op carries the tombstone.
    'deleted_at': null,
  };

  @override
  FinanceCategoriesCompanion fromWire(
    Map<String, Object?> json, {
    FinanceCategory? existingLocal,
  }) => FinanceCategoriesCompanion.insert(
    id: SyncWire.string(json, 'id'),
    name: SyncWire.string(json, 'name'),
    normalizedName: SyncWire.string(json, 'normalized_name'),
    type: SyncWire.oneOf(json, 'type', types),
    icon: SyncWire.string(json, 'icon_key'),
    isDefault: Value(SyncWire.boolean(json, 'is_default')),
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

/// Whether [category] is a seeded starter category the user has not touched
/// (research.md Decision 10): its id is `seed_<key>` and its name, icon and
/// archived flag still equal the seed definition. Pristine seeds are never
/// uploaded as changes, so a fresh device cannot overwrite a rename made on
/// another device.
bool isPristineSeed(FinanceCategory category) {
  const prefix = 'seed_';
  if (!category.id.startsWith(prefix)) return false;
  final key = category.id.substring(prefix.length);
  for (final seed in defaultFinanceCategorySeeds) {
    if (seed.key != key) continue;
    return category.name == seed.name &&
        category.icon == seed.key &&
        !category.isArchived;
  }
  return false;
}
