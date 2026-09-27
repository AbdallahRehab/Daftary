import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/entities/currency_failures.dart';
import 'package:daftary/features/currency/domain/entities/exchange_rate.dart';
import 'package:daftary/features/currency/domain/entities/primary_currency_setting.dart';
import 'package:drift/native.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_daos.dart';

class _FakeClock implements AppClock {
  DateTime current = DateTime(2026, 9, 1, 10);

  @override
  DateTime now() => current;
}

/// T013 — `CurrencyRepositoryImpl` against a real in-memory drift database.
void main() {
  late db.AppDatabase database;
  late _FakeClock clock;
  late CurrencyRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);
    clock = _FakeClock();
    repository = CurrencyRepositoryImpl(testCurrencyDao(database), clock);
  });

  T right<T>(Either<Failure, T> either) =>
      either.getOrElse((f) => fail('unexpected $f'));

  test(
    'getSupportedCurrencies returns the bundled catalog, EGP first',
    () async {
      final currencies = right<List<Currency>>(
        await repository.getSupportedCurrencies(),
      );
      expect(currencies, Currency.catalog);
      expect(currencies.first, Currency.egp);
    },
  );

  group('primary currency', () {
    test('defaults to EGP with no stored row (FR-005)', () async {
      final setting = right<PrimaryCurrencySetting>(
        await repository.getPrimaryCurrency(),
      );
      expect(setting, PrimaryCurrencySetting.defaultSetting);
      expect(setting.currency, Currency.egp);
      expect(
        await database.select(database.primaryCurrencySettings).get(),
        isEmpty,
      );
    });

    test('set then get round-trips, keeping a single row', () async {
      expect((await repository.setPrimaryCurrency('USD')).isRight(), isTrue);
      clock.current = DateTime(2026, 9, 2);
      expect((await repository.setPrimaryCurrency('SAR')).isRight(), isTrue);

      final setting = right<PrimaryCurrencySetting>(
        await repository.getPrimaryCurrency(),
      );
      expect(setting.currency, Currency.sar);
      expect(setting.updatedAt, DateTime(2026, 9, 2));
      expect(
        await database.select(database.primaryCurrencySettings).get(),
        hasLength(1),
      );
    });

    test('rejects an unknown code', () async {
      final result = await repository.setPrimaryCurrency('XXX');
      expect(result.getLeft().toNullable(), isA<CurrencyNotFoundFailure>());
    });
  });

  group('exchange rates', () {
    test('setExchangeRate inserts a rate stored as micros', () async {
      final rate = right<ExchangeRate>(
        await repository.setExchangeRate(
          currencyCode: 'USD',
          relativeToCurrencyCode: 'EGP',
          rate: 50.25,
        ),
      );
      expect(rate.currency, Currency.usd);
      expect(rate.relativeTo, Currency.egp);
      expect(rate.rateMicros, 50250000);
      expect(rate.lastUpdatedAt, DateTime(2026, 9, 1, 10));

      final rows = await database.select(database.exchangeRates).get();
      expect(rows.single.rateMicros, 50250000);
    });

    test(
      'upserts by pair: same id, new rate, refreshed lastUpdatedAt',
      () async {
        await repository.setExchangeRate(
          currencyCode: 'USD',
          relativeToCurrencyCode: 'EGP',
          rate: 50,
        );
        final firstId =
            (await database.select(database.exchangeRates).get()).single.id;
        // 021: the id is the pair, so devices converge on one cloud row.
        expect(firstId, 'rate_USD_EGP');

        clock.current = DateTime(2026, 9, 5, 8);
        final updated = right<ExchangeRate>(
          await repository.setExchangeRate(
            currencyCode: 'USD',
            relativeToCurrencyCode: 'EGP',
            rate: 51.5,
          ),
        );

        final rows = await database.select(database.exchangeRates).get();
        expect(rows, hasLength(1));
        expect(rows.single.id, firstId);
        expect(rows.single.rateMicros, 51500000);
        expect(updated.lastUpdatedAt, DateTime(2026, 9, 5, 8));
      },
    );

    test('different pairs are distinct rows', () async {
      await repository.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 50,
      );
      await repository.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'SAR',
        rate: 3.75,
      );
      await repository.setExchangeRate(
        currencyCode: 'EUR',
        relativeToCurrencyCode: 'EGP',
        rate: 55,
      );
      final rates = right<List<ExchangeRate>>(
        await repository.getExchangeRates(),
      );
      expect(rates, hasLength(3));
    });

    test(
      'rejects zero, negative and non-finite rates without writing',
      () async {
        for (final bad in [0.0, -1.0, double.nan, double.infinity, 0.0000001]) {
          final result = await repository.setExchangeRate(
            currencyCode: 'USD',
            relativeToCurrencyCode: 'EGP',
            rate: bad,
          );
          expect(
            result.getLeft().toNullable(),
            isA<InvalidExchangeRateFailure>(),
            reason: 'rate $bad',
          );
        }
        expect(await database.select(database.exchangeRates).get(), isEmpty);
      },
    );

    test('removeExchangeRate deletes every rate FROM that code only', () async {
      await repository.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'EGP',
        rate: 50,
      );
      await repository.setExchangeRate(
        currencyCode: 'USD',
        relativeToCurrencyCode: 'SAR',
        rate: 3.75,
      );
      await repository.setExchangeRate(
        currencyCode: 'EUR',
        relativeToCurrencyCode: 'USD',
        rate: 1.1,
      );

      expect((await repository.removeExchangeRate('USD')).isRight(), isTrue);

      final rates = right<List<ExchangeRate>>(
        await repository.getExchangeRates(),
      );
      expect(rates.single.currency, Currency.eur);
      expect(rates.single.relativeTo, Currency.usd);
    });

    test('a database error surfaces as CacheFailure', () async {
      await repository.getExchangeRates(); // open, then close under it
      await database.close();
      final result = await repository.getExchangeRates();
      expect(result.getLeft().toNullable(), isA<CacheFailure>());
    });
  });
}
