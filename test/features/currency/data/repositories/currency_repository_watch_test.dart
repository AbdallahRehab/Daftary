import 'package:daftary/core/database/app_database.dart' hide ExchangeRate;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/currency.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/watch_conversion_context.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';

/// 021 T032: the primary currency and the rate list are live.
void main() {
  late AppDatabase db;
  late CurrencyRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
  });

  tearDown(() => db.close());

  test('watchExchangeRates emits after a rate is set and removed', () async {
    final rates = StreamRecorder(repository.watchExchangeRates());
    addTearDown(rates.cancel);
    await rates.waitFor((r) => rightOf(r).isEmpty);

    await repository.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    await rates.waitFor((r) => rightOf(r).length == 1);

    await repository.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 51,
    );
    await rates.waitFor(
      (r) => rightOf(r).any((rate) => rate.rateMicros == 51000000),
    );

    await repository.removeExchangeRate('USD');
    await rates.waitForNext((r) => rightOf(r).isEmpty);
  });

  test(
    'watchPrimaryCurrency starts on the default and emits a change',
    () async {
      final primary = StreamRecorder(repository.watchPrimaryCurrency());
      addTearDown(primary.cancel);
      await primary.waitFor((r) => rightOf(r).currency == Currency.egp);

      await repository.setPrimaryCurrency('USD');

      await primary.waitFor((r) => rightOf(r).currency == Currency.usd);
    },
  );

  test('WatchConversionContext combines both', () async {
    final context = StreamRecorder(WatchConversionContext(repository)());
    addTearDown(context.cancel);
    await context.waitFor((r) => rightOf(r).primary == Currency.egp);

    await repository.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    await context.waitFor((r) => rightOf(r).rates.length == 1);

    await repository.setPrimaryCurrency('USD');
    await context.waitFor(
      (r) => rightOf(r).primary == Currency.usd && rightOf(r).rates.length == 1,
    );
  });
}
