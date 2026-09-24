import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/data/datasources/currency_dao.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/entities/currency_failures.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/usecases/get_exchange_rates.dart';
import 'package:daftary/features/currency/domain/usecases/set_exchange_rate.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeClock implements AppClock {
  DateTime current = DateTime(2026, 9, 1, 9);

  @override
  DateTime now() => current;
}

/// T044 — `SetExchangeRate`/`GetExchangeRates` over the real repository
/// and an in-memory database.
void main() {
  late db.AppDatabase database;
  late _FakeClock clock;
  late SetExchangeRate setRate;
  late GetExchangeRates getRates;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    clock = _FakeClock();
    final repository = CurrencyRepositoryImpl(CurrencyDao(database), clock);
    setRate = SetExchangeRate(repository);
    getRates = GetExchangeRates(repository);
  });

  Future<List<ExchangeRate>> rates() async =>
      (await getRates()).getOrElse((f) => fail('unexpected $f'));

  test('rejects zero, negative, NaN and infinite rates (FR-006)', () async {
    for (final bad in [
      0.0,
      -0.5,
      -100.0,
      double.nan,
      double.infinity,
      double.negativeInfinity,
    ]) {
      final result = await setRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: bad,
      );
      expect(
        result.getLeft().toNullable(),
        isA<InvalidExchangeRateFailure>(),
        reason: '$bad',
      );
    }
    expect(await rates(), isEmpty);
  });

  test('rejects an unknown currency and a same-currency pair', () async {
    final unknown = await setRate(
      currencyCode: 'XYZ',
      relativeToCurrencyCode: 'EGP',
      rate: 2,
    );
    expect(unknown.getLeft().toNullable(), isA<CurrencyNotFoundFailure>());

    final same = await setRate(
      currencyCode: 'EGP',
      relativeToCurrencyCode: 'EGP',
      rate: 1,
    );
    expect(same.getLeft().toNullable(), isA<InvalidExchangeRateFailure>());
    expect(await rates(), isEmpty);
  });

  test('upserts by pair: editing never duplicates', () async {
    await setRate(currencyCode: 'USD', relativeToCurrencyCode: 'EGP', rate: 50);
    await setRate(currencyCode: 'USD', relativeToCurrencyCode: 'EGP', rate: 49);
    await setRate(currencyCode: 'USD', relativeToCurrencyCode: 'EGP', rate: 49);

    final all = await rates();
    expect(all, hasLength(1));
    expect(all.single.rateMicros, 49000000);
  });

  test('lastUpdatedAt is refreshed on every edit (FR-007)', () async {
    await setRate(currencyCode: 'EUR', relativeToCurrencyCode: 'EGP', rate: 55);
    expect((await rates()).single.lastUpdatedAt, DateTime(2026, 9, 1, 9));

    clock.current = DateTime(2026, 9, 20, 18, 30);
    await setRate(
      currencyCode: 'EUR',
      relativeToCurrencyCode: 'EGP',
      rate: 56.1,
    );

    final rate = (await rates()).single;
    expect(rate.lastUpdatedAt, DateTime(2026, 9, 20, 18, 30));
    expect(rate.rate, 56.1);
    expect(rate.currency, Currency.eur);
  });
}
