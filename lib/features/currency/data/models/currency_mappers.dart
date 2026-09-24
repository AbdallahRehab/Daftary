import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/currency.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/entities/primary_currency_setting.dart';

extension ExchangeRateRowMapper on db.ExchangeRate {
  ExchangeRate toDomain() => ExchangeRate(
    currency: Currency.fromCode(currencyCode),
    relativeTo: Currency.fromCode(relativeToCurrencyCode),
    rateMicros: rateMicros,
    lastUpdatedAt: DateTime.fromMillisecondsSinceEpoch(lastUpdatedAt),
  );
}

extension PrimaryCurrencyRowMapper on db.PrimaryCurrencySetting {
  PrimaryCurrencySetting toDomain() => PrimaryCurrencySetting(
    currency: Currency.fromCode(currencyCode),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
  );
}
