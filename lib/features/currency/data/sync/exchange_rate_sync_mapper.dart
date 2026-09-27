import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../../../../core/sync/sync_mapper_registry.dart';

/// 021: `exchange_rates` ⇄ the `exchange_rate` wire payload. The id is
/// derived from the currency pair, `rate_<CUR>_<REL>` (research.md Decision
/// 9), so two devices that create the same pair converge on one record.
@lazySingleton
class ExchangeRateSyncMapper extends SyncMapper<ExchangeRate> {
  const ExchangeRateSyncMapper();

  /// The deterministic id of the rate "1 [currencyCode] = x
  /// [relativeToCurrencyCode]".
  static String idFor(String currencyCode, String relativeToCurrencyCode) =>
      'rate_${currencyCode}_$relativeToCurrencyCode';

  @override
  SyncEntityType get type => SyncEntityType.exchangeRate;

  @override
  Map<String, Object?> toWire(ExchangeRate row) => {
    'id': idFor(row.currencyCode, row.relativeToCurrencyCode),
    'currency_code': row.currencyCode,
    'relative_to_currency_code': row.relativeToCurrencyCode,
    'rate_micros': SyncWire.money(row.rateMicros),
    'client_created_at': SyncWire.instant(row.lastUpdatedAt),
    'client_updated_at': SyncWire.instant(row.lastUpdatedAt),
    // Rates are hard-deleted locally; a delete op carries the tombstone.
    'deleted_at': null,
  };

  @override
  ExchangeRatesCompanion fromWire(
    Map<String, Object?> json, {
    ExchangeRate? existingLocal,
  }) {
    final currency = SyncWire.string(json, 'currency_code');
    final relative = SyncWire.string(json, 'relative_to_currency_code');
    return ExchangeRatesCompanion.insert(
      id: idFor(currency, relative),
      currencyCode: currency,
      relativeToCurrencyCode: relative,
      rateMicros: SyncWire.parseMoney(json['rate_micros'], 'rate_micros'),
      lastUpdatedAt: SyncWire.parseFirstInstant(json, const [
        'client_updated_at',
        'server_updated_at',
      ]),
    );
  }
}
