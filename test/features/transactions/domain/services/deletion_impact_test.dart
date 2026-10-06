import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/services/deletion_impact.dart';
import 'package:daftary/features/transactions/domain/services/person_balance_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/currency_test_doubles.dart';

void main() {
  final now = DateTime(2026, 1, 1);
  MoneyTransaction row(
    Money amount,
    TransactionDirection direction, {
    bool counts = true,
  }) => MoneyTransaction(
    id: 't',
    idempotencyKey: 'k',
    personId: 'p1',
    amount: amount,
    direction: direction,
    kind: TransactionKind.initialExchange,
    date: now,
    createdAt: now,
    countsTowardBalance: counts,
  );

  PersonBalance balance(Map<String, int> nets, ConversionContext context) =>
      const PersonBalanceCalculator().calculate(
        personId: 'p1',
        nativeNetsByCode: nets,
        context: context,
      );

  DeletionImpact impact(
    MoneyTransaction tx,
    PersonBalance b, [
    ConversionContext c = ConversionContext.egpOnly,
  ]) => DeletionImpact.of(
    transaction: tx,
    balance: b,
    context: c,
    laterRepaymentCount: 2,
  );

  test('deleting a given row removes what they owed', () {
    final result = impact(
      row(const Money.egp(100000), TransactionDirection.given),
      balance({'EGP': 60000}, ConversionContext.egpOnly),
    );

    expect(result.resultingNet, const Money.egp(-40000));
    expect(result.laterRepaymentCount, 2);
  });

  test('deleting a received row adds back what you owed', () {
    final result = impact(
      row(const Money.egp(30000), TransactionDirection.received),
      balance({'EGP': 50000}, ConversionContext.egpOnly),
    );

    expect(result.resultingNet, const Money.egp(80000));
  });

  test('a non-counting occasion row leaves the net unchanged', () {
    final result = impact(
      row(const Money.egp(30000), TransactionDirection.received, counts: false),
      balance({'EGP': 50000}, ConversionContext.egpOnly),
    );

    expect(result.resultingNet, const Money.egp(50000));
  });

  test('a foreign-currency row is re-totalled through the calculator', () {
    final context = ConversionContext(
      primary: Currency.egp,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );
    // Owed 100.00 USD + 500.00 EGP; delete the USD row.
    final b = balance({'USD': 10000, 'EGP': 50000}, context);

    final result = impact(
      row(
        Money.fromMinorUnits(10000, Currency.usd),
        TransactionDirection.given,
      ),
      b,
      context,
    );

    expect(result.resultingNet, const Money.egp(50000));
  });

  test('a blocked balance has no resulting figure', () {
    final blocked = balance({'USD': 10000}, ConversionContext.egpOnly);

    final result = impact(
      row(
        Money.fromMinorUnits(10000, Currency.usd),
        TransactionDirection.given,
      ),
      blocked,
    );

    expect(result.resultingNet, isNull);
  });
}
