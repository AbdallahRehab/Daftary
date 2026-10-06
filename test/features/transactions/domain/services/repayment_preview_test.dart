import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/currency/domain/entities/conversion_context.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:daftary/features/transactions/domain/services/person_balance_calculator.dart';
import 'package:daftary/features/transactions/domain/services/repayment_preview.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/currency_test_doubles.dart';

void main() {
  PersonBalance balanceOf(int minor) =>
      PersonBalance(personId: 'p1', net: Money.egp(minor));

  RepaymentPreview preview(
    int balanceMinor,
    Money amount, [
    ConversionContext context = ConversionContext.egpOnly,
  ]) => RepaymentPreview.of(balanceOf(balanceMinor), amount, context);

  test('owes +100000, repay 40000 EGP -> resulting +60000, no flip', () {
    final result = preview(100000, const Money.egp(40000));

    expect(result.outstanding, const Money.egp(100000));
    expect(result.resulting, const Money.egp(60000));
    expect(result.flips, isFalse);
    expect(result.blocked, isFalse);
  });

  test('repay exactly the outstanding amount -> 0, no flip', () {
    final result = preview(100000, const Money.egp(100000));

    expect(result.resulting, const Money.egp(0));
    expect(result.flips, isFalse);
  });

  test('repay 150000 against +100000 -> -50000 and flips', () {
    final result = preview(100000, const Money.egp(150000));

    expect(result.resulting, const Money.egp(-50000));
    expect(result.flips, isTrue);
  });

  test('you owe -70000, repay 70000 -> 0', () {
    final result = preview(-70000, const Money.egp(70000));

    expect(result.outstanding, const Money.egp(70000));
    expect(result.resulting, const Money.egp(0));
    expect(result.flips, isFalse);
  });

  test('you owe -70000, repay 100000 -> +30000 and flips', () {
    final result = preview(-70000, const Money.egp(100000));

    expect(result.resulting, const Money.egp(30000));
    expect(result.flips, isTrue);
  });

  test('owes +1000000, repay 100.00 USD at 48.50 -> resulting +515000', () {
    final context = ConversionContext(
      primary: Currency.egp,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );

    final result = preview(
      1000000,
      Money.fromMinorUnits(10000, Currency.usd),
      context,
    );

    expect(result.resulting, const Money.egp(515000));
    expect(result.blocked, isFalse);
    expect(result.flips, isFalse);
  });

  test('50.00 GBP with no rate is blocked and shows no number', () {
    final result = preview(1000000, Money.fromMinorUnits(5000, Currency.gbp));

    expect(result.blocked, isTrue);
    expect(result.resulting, isNull);
    expect(result.flips, isFalse);
  });

  test('a blocked balance is blocked', () {
    final blocked = PersonBalance.blocked(
      personId: 'p1',
      nativeNets: [Money.fromMinorUnits(10000, Currency.usd)],
      missingRatesFor: const [Currency.usd],
    );

    final result = RepaymentPreview.of(
      blocked,
      const Money.egp(1000),
      ConversionContext.egpOnly,
    );

    expect(result.blocked, isTrue);
    expect(result.outstanding, isNull);
    expect(result.resulting, isNull);
    expect(result.flips, isFalse);
  });

  // The preview must land on exactly the number the saved balance will show,
  // so it re-totals per-currency nets like PersonBalanceCalculator does.
  PersonBalance calculated(Map<String, int> nets, ConversionContext context) =>
      const PersonBalanceCalculator().calculate(
        personId: 'p1',
        nativeNetsByCode: nets,
        context: context,
      );

  test('rounds like the saved balance: owe 100.00 USD, repay 33.33 USD at '
      '48.50 -> 323350 (not 323349)', () {
    final context = ConversionContext(
      primary: Currency.egp,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );
    final balance = calculated({'USD': 10000}, context);

    final result = RepaymentPreview.of(
      balance,
      Money.fromMinorUnits(3333, Currency.usd),
      context,
    );

    expect(result.resulting, const Money.egp(323350));
    // What really happens after saving: the USD net drops to 66.67.
    expect(calculated({'USD': 6667}, context).net, result.resulting);
  });

  test('near zero: owe 0.02 USD, repay 0.01 USD at 48.50 -> 49 (not 48)', () {
    final context = ConversionContext(
      primary: Currency.egp,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );
    final balance = calculated({'USD': 2}, context);

    final result = RepaymentPreview.of(
      balance,
      Money.fromMinorUnits(1, Currency.usd),
      context,
    );

    expect(result.resulting, const Money.egp(49));
    expect(result.flips, isFalse);
  });

  test('settling the USD debt exactly is 0 and does not flip', () {
    final context = ConversionContext(
      primary: Currency.egp,
      rates: [rate(Currency.usd, Currency.egp, 48.5)],
    );
    final balance = calculated({'USD': 10000}, context);

    final result = RepaymentPreview.of(
      balance,
      Money.fromMinorUnits(10000, Currency.usd),
      context,
    );

    expect(result.resulting, const Money.egp(0));
    expect(result.flips, isFalse);
  });
}
