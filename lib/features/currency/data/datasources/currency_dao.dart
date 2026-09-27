import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/database/watch_tables.dart';
import '../../../../core/sync/local/sync_outbox.dart';
import '../../../../core/sync/sync_entity_type.dart';
import '../sync/exchange_rate_sync_mapper.dart';
import '../sync/primary_currency_sync_mapper.dart';

/// Direct `drift` access to `primary_currency_settings` and `exchange_rates`
/// (018). Touches no other table and makes no network call (FR-014).
///
/// 021: every write records its change to the [SyncOutbox] inside the same
/// `_db.transaction` (plan.md §7); the upload itself happens elsewhere.
@injectable
class CurrencyDao {
  CurrencyDao(this._db, this._outbox, this._rateMapper, this._primaryMapper);

  final db.AppDatabase _db;
  final SyncOutbox _outbox;
  final ExchangeRateSyncMapper _rateMapper;
  final PrimaryCurrencySyncMapper _primaryMapper;

  /// The fixed id of the single primary-currency row (data-model.md).
  static const primaryRowId = 'singleton';

  // ---------------------------------------------------------- change signals

  /// 021: fires now and after every burst of writes to
  /// `primary_currency_settings`.
  Stream<void> primaryChanged() => _db.changesOf({_db.primaryCurrencySettings});

  /// 021: fires now and after every burst of writes to `exchange_rates`.
  Stream<void> ratesChanged() => _db.changesOf({_db.exchangeRates});

  // ------------------------------------------------------- primary currency

  Future<db.PrimaryCurrencySetting?> getPrimary() => (_db.select(
    _db.primaryCurrencySettings,
  )..where((t) => t.id.equals(primaryRowId))).getSingleOrNull();

  Future<void> upsertPrimary({
    required String currencyCode,
    required int updatedAtMillis,
  }) {
    return _db.transaction(() async {
      await _db
          .into(_db.primaryCurrencySettings)
          .insertOnConflictUpdate(
            db.PrimaryCurrencySettingsCompanion.insert(
              id: primaryRowId,
              currencyCode: db.Value(currencyCode),
              updatedAt: updatedAtMillis,
            ),
          );
      final row = (await getPrimary())!;
      await _outbox.recordUpsert(
        SyncEntityType.primaryCurrency,
        primaryRowId,
        _primaryMapper.toWire(row),
      );
    });
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
  /// UNIQUE index backs that up). Either way the resulting row is queued
  /// as an `exchange_rate` upsert in the same transaction.
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
        await _recordRateUpsert(row);
        return row;
      }
      final updated = existing.copyWith(
        rateMicros: rateMicros,
        lastUpdatedAt: lastUpdatedAtMillis,
      );
      await _db.update(_db.exchangeRates).replace(updated);
      await _recordRateUpsert(updated);
      return updated;
    });
  }

  Future<void> _recordRateUpsert(db.ExchangeRate row) => _outbox.recordUpsert(
    SyncEntityType.exchangeRate,
    row.id,
    _rateMapper.toWire(row),
  );

  /// Deletes every rate converting FROM [currencyCode]; returns the count.
  /// The matching rows are read first, in the same transaction, so each
  /// one is queued as its own `exchange_rate` delete.
  Future<int> deleteRatesFrom(String currencyCode) {
    return _db.transaction(() async {
      final rows = await (_db.select(
        _db.exchangeRates,
      )..where((t) => t.currencyCode.equals(currencyCode))).get();
      final deleted = await (_db.delete(
        _db.exchangeRates,
      )..where((t) => t.currencyCode.equals(currencyCode))).go();
      for (final row in rows) {
        await _outbox.recordDelete(
          SyncEntityType.exchangeRate,
          row.id,
          _rateMapper.toWire(row),
        );
      }
      return deleted;
    });
  }
}
