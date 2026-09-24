import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;

/// Direct `drift` access to `primary_currency_settings` and `exchange_rates`
/// (018). Touches no other table and makes no network call (FR-014).
@injectable
class CurrencyDao {
  CurrencyDao(this._db);

  final db.AppDatabase _db;

  /// The fixed id of the single primary-currency row (data-model.md).
  static const primaryRowId = 'singleton';

  // ------------------------------------------------------- primary currency

  Future<db.PrimaryCurrencySetting?> getPrimary() => (_db.select(
    _db.primaryCurrencySettings,
  )..where((t) => t.id.equals(primaryRowId))).getSingleOrNull();

  Future<void> upsertPrimary({
    required String currencyCode,
    required int updatedAtMillis,
  }) {
    return _db
        .into(_db.primaryCurrencySettings)
        .insertOnConflictUpdate(
          db.PrimaryCurrencySettingsCompanion.insert(
            id: primaryRowId,
            currencyCode: db.Value(currencyCode),
            updatedAt: updatedAtMillis,
          ),
        );
  }

  // --------------------------------------------------------- exchange rates

  Future<List<db.ExchangeRate>> getRates() =>
      (_db.select(_db.exchangeRates)..orderBy([
            (t) => db.OrderingTerm.asc(t.relativeToCurrencyCode),
            (t) => db.OrderingTerm.asc(t.currencyCode),
          ]))
          .get();

  Future<db.ExchangeRate?> findRate({
    required String currencyCode,
    required String relativeToCurrencyCode,
  }) {
    return (_db.select(_db.exchangeRates)..where(
          (t) =>
              t.currencyCode.equals(currencyCode) &
              t.relativeToCurrencyCode.equals(relativeToCurrencyCode),
        ))
        .getSingleOrNull();
  }

  /// Inserts the pair's rate, or — when the pair already has a row —
  /// overwrites its rate and timestamp while keeping its id. One
  /// transaction, so two rapid saves cannot both insert (and the pair's
  /// UNIQUE index backs that up).
  Future<db.ExchangeRate> upsertRate({
    required String newId,
    required String currencyCode,
    required String relativeToCurrencyCode,
    required int rateMicros,
    required int lastUpdatedAtMillis,
  }) {
    return _db.transaction(() async {
      final existing = await findRate(
        currencyCode: currencyCode,
        relativeToCurrencyCode: relativeToCurrencyCode,
      );
      if (existing == null) {
        final row = db.ExchangeRate(
          id: newId,
          currencyCode: currencyCode,
          relativeToCurrencyCode: relativeToCurrencyCode,
          rateMicros: rateMicros,
          lastUpdatedAt: lastUpdatedAtMillis,
        );
        await _db.into(_db.exchangeRates).insert(row);
        return row;
      }
      final updated = existing.copyWith(
        rateMicros: rateMicros,
        lastUpdatedAt: lastUpdatedAtMillis,
      );
      await _db.update(_db.exchangeRates).replace(updated);
      return updated;
    });
  }

  /// Deletes every rate converting FROM [currencyCode]; returns the count.
  Future<int> deleteRatesFrom(String currencyCode) => (_db.delete(
    _db.exchangeRates,
  )..where((t) => t.currencyCode.equals(currencyCode))).go();
}
