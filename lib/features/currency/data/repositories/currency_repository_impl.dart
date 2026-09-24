import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/money/currency.dart';
import '../../domain/entities/currency_failures.dart';
import '../../domain/entities/exchange_rate.dart';
import '../../domain/entities/primary_currency_setting.dart';
import '../../domain/repositories/currency_repository.dart';
import '../datasources/currency_dao.dart';
import '../models/currency_mappers.dart';

/// Local-only [CurrencyRepository] (contracts/currency_converter.md): the
/// bundled `Currency.catalog` plus the two 018 drift tables. No network
/// call anywhere (FR-014).
@LazySingleton(as: CurrencyRepository)
class CurrencyRepositoryImpl implements CurrencyRepository {
  CurrencyRepositoryImpl(this._dao, this._clock);

  final CurrencyDao _dao;
  final AppClock _clock;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, List<Currency>>> getSupportedCurrencies() async =>
      const Right(Currency.catalog);

  @override
  Future<Either<Failure, PrimaryCurrencySetting>> getPrimaryCurrency() async {
    try {
      final row = await _dao.getPrimary();
      return Right(row?.toDomain() ?? PrimaryCurrencySetting.defaultSetting);
    } catch (e) {
      return Left(CacheFailure('Failed to load primary currency: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> setPrimaryCurrency(String currencyCode) async {
    if (Currency.tryFromCode(currencyCode) == null) {
      return Left(CurrencyNotFoundFailure(currencyCode));
    }
    try {
      await _dao.upsertPrimary(
        currencyCode: currencyCode,
        updatedAtMillis: _clock.now().millisecondsSinceEpoch,
      );
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to save primary currency: $e'));
    }
  }

  @override
  Future<Either<Failure, List<ExchangeRate>>> getExchangeRates() async {
    try {
      final rows = await _dao.getRates();
      return Right([for (final row in rows) row.toDomain()]);
    } catch (e) {
      return Left(CacheFailure('Failed to load exchange rates: $e'));
    }
  }

  @override
  Future<Either<Failure, ExchangeRate>> setExchangeRate({
    required String currencyCode,
    required String relativeToCurrencyCode,
    required double rate,
  }) async {
    if (!rate.isFinite || ExchangeRate.toMicros(rate) <= 0) {
      return const Left(InvalidExchangeRateFailure());
    }
    for (final code in [currencyCode, relativeToCurrencyCode]) {
      if (Currency.tryFromCode(code) == null) {
        return Left(CurrencyNotFoundFailure(code));
      }
    }
    try {
      final row = await _dao.upsertRate(
        newId: _uuid.v4(),
        currencyCode: currencyCode,
        relativeToCurrencyCode: relativeToCurrencyCode,
        rateMicros: ExchangeRate.toMicros(rate),
        lastUpdatedAtMillis: _clock.now().millisecondsSinceEpoch,
      );
      return Right(row.toDomain());
    } catch (e) {
      return Left(CacheFailure('Failed to save exchange rate: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> removeExchangeRate(String currencyCode) async {
    try {
      await _dao.deleteRatesFrom(currencyCode);
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure('Failed to remove exchange rate: $e'));
    }
  }
}
