import 'package:daftary/core/database/app_database.dart' hide ExchangeRate;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/data/repositories/currency_repository_impl.dart';
import 'package:daftary/features/currency/domain/usecases/get_conversion_context.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../../../helpers/test_daos.dart';

/// 021 T030: history, balances and the overview are live — a write (or a
/// rate change) shows up with no reload.
void main() {
  late AppDatabase db;
  late CurrencyRepositoryImpl currency;
  late TransactionsRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    currency = CurrencyRepositoryImpl(
      testCurrencyDao(db),
      const SystemAppClock(),
    );
    repository = TransactionsRepositoryImpl(
      testTransactionsDao(db),
      db,
      getConversionContext: GetConversionContext(currency),
    );
    await testPeopleDao(
      db,
    ).insertPerson(id: 'p1', name: 'Ahmed', createdAt: DateTime(2026));
  });

  tearDown(() => db.close());

  Future<void> give(Money amount, String key) => repository.addTransaction(
    idempotencyKey: key,
    personId: 'p1',
    amount: amount,
    direction: TransactionDirection.given,
    date: DateTime(2026, 1, 1),
  );

  test('addTransaction re-emits history and balance', () async {
    final history = StreamRecorder(repository.watchPersonHistory('p1'));
    final balance = StreamRecorder(repository.watchPersonBalance('p1'));
    addTearDown(history.cancel);
    addTearDown(balance.cancel);
    await history.waitFor((r) => rightOf(r).isEmpty);

    await give(const Money.egp(50000), 'k1');

    final rows = rightOf(await history.waitFor((r) => rightOf(r).isNotEmpty));
    expect(rows.single.amount, const Money.egp(50000));
    await balance.waitFor((r) => rightOf(r).net == const Money.egp(50000));
  });

  test('a repeated idempotency key adds no duplicate row', () async {
    final history = StreamRecorder(repository.watchPersonHistory('p1'));
    addTearDown(history.cancel);

    await give(const Money.egp(50000), 'k1');
    await give(const Money.egp(50000), 'k1');
    await StreamRecorder.settle();

    expect(rightOf(history.last), hasLength(1));
  });

  test('changing an exchange rate re-emits the converted balance, '
      'balances and overview', () async {
    await currency.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    await give(const Money.fromMinorUnits(100, Currency.usd), 'k1');

    final balance = StreamRecorder(repository.watchPersonBalance('p1'));
    final balances = StreamRecorder(repository.watchPersonBalances(['p1']));
    final overview = StreamRecorder(repository.watchOverview());
    addTearDown(balance.cancel);
    addTearDown(balances.cancel);
    addTearDown(overview.cancel);
    await balance.waitFor((r) => rightOf(r).net == const Money.egp(5000));

    await currency.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 60,
    );

    await balance.waitFor((r) => rightOf(r).net == const Money.egp(6000));
    await balances.waitFor(
      (r) => rightOf(r)['p1']!.net == const Money.egp(6000),
    );
    await overview.waitFor(
      (r) => rightOf(r).totalOwedToUser == const Money.egp(6000),
    );
  });

  test('removing the rate blocks the balance', () async {
    await currency.setExchangeRate(
      currencyCode: 'USD',
      relativeToCurrencyCode: 'EGP',
      rate: 50,
    );
    await give(const Money.fromMinorUnits(100, Currency.usd), 'k1');
    final balance = StreamRecorder(repository.watchPersonBalance('p1'));
    addTearDown(balance.cancel);
    await balance.waitFor((r) => !rightOf(r).isBlocked);

    await currency.removeExchangeRate('USD');

    await balance.waitFor((r) => rightOf(r).isBlocked);
  });

  test('the overview updates after a transaction is added elsewhere', () async {
    final overview = StreamRecorder(repository.watchOverview());
    addTearDown(overview.cancel);
    await overview.waitFor(
      (r) => rightOf(r).totalOwedToUser == const Money.egp(0),
    );

    await give(const Money.egp(1200), 'k1');

    await overview.waitFor(
      (r) => rightOf(r).totalOwedToUser == const Money.egp(1200),
    );
  });
}
