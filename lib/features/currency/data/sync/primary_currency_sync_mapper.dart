import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `primary_currency_settings` ⇄ the `primary_currency` wire payload.
/// Always the single row `'singleton'` (the cloud keys it by owner).
@lazySingleton
class PrimaryCurrencySyncMapper extends SyncMapper<PrimaryCurrencySetting> {
  const PrimaryCurrencySyncMapper();

  static const singletonId = 'singleton';

  @override
  SyncEntityType get type => SyncEntityType.primaryCurrency;

  @override
  Map<String, Object?> toWire(PrimaryCurrencySetting row) => {
    'id': singletonId,
    'currency_code': row.currencyCode,
    'client_created_at': SyncWire.instant(row.updatedAt),
    'client_updated_at': SyncWire.instant(row.updatedAt),
    'deleted_at': null,
  };

  @override
  PrimaryCurrencySettingsCompanion fromWire(
    Map<String, Object?> json, {
    PrimaryCurrencySetting? existingLocal,
  }) => PrimaryCurrencySettingsCompanion.insert(
    id: singletonId,
    currencyCode: Value(SyncWire.string(json, 'currency_code')),
    updatedAt: SyncWire.parseFirstInstant(json, const [
      'client_updated_at',
      'server_updated_at',
    ]),
  );
}
