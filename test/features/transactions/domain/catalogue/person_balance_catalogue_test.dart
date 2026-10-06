import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T004) — person-balance catalogue. Every figure is an exact
/// integer count of minor units, read through the real
/// `TransactionsRepositoryImpl.getPersonBalance`. Sign rule (001 FR-008):
/// net = SUM(given) - SUM(received); positive means they owe you.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  group('CHK011 received in USD at 1 USD = 48.50 EGP', () {
    test('100.00 USD received => you owe 4,850.00 EGP (-485000)', () async {
      await env.setRate(Currency.usd, 48.5);
      await env.receive('ahmed', 10000, currency: Currency.usd);

      expect(await env.net('ahmed'), -485000);
      final history = unwrapOrThrow(
        await env.transactions.getPersonHistory('ahmed'),
      );
      expect(history, hasLength(1));
      // The row keeps its original currency and amount.
      expect(
        history.single.amount,
        const Money.fromMinorUnits(10000, Currency.usd),
      );
    });
  });

  group('CHK012 first transaction for a person with no rows', () {
    test(
      'Mona gives 50000 => net +50000 and overview rises by 50000',
      () async {
        await env.person('mona');
        final before = unwrapOrThrow(await env.transactions.getOverview());

        await env.give('mona', 50000);

        final balance = unwrapOrThrow(
          await env.transactions.getPersonBalance('mona'),
        );
        expect(balance.net, Money.egp(50000));
        expect(balance.status, RelationshipStatus.theyOweYou);
        final after = unwrapOrThrow(await env.transactions.getOverview());
        expect(
          after.totalOwedToUser!.minorUnits -
              before.totalOwedToUser!.minorUnits,
          50000,
        );
      },
    );
  });

  group('CHK013 gave 2,000.00 and received 500.00', () {
    test('Mona owes you 1,500.00 EGP (+150000)', () async {
      await env.seedChk013();

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('mona'),
      );
      expect(balance.net, const Money.egp(150000));
      expect(balance.status, RelationshipStatus.theyOweYou);
    });
  });

  group('CHK014 received 2,000.00 and gave 500.00', () {
    test('you owe Ahmed 1,500.00 EGP (-150000), not the reverse', () async {
      await env.seedChk014();

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('ahmed'),
      );
      expect(balance.net, const Money.egp(-150000));
      expect(balance.status, RelationshipStatus.youOweThem);
    });
  });

  group('CHK015 fifty mixed transactions', () {
    test('balance equals sum(given) - sum(received) exactly', () async {
      var expected = 0;
      for (var i = 1; i <= 50; i++) {
        final minor = (i * 3719) % 100000 + 1;
        final date = DateTime(2026, 9, 1).add(Duration(days: i % 28));
        if (i % 3 == 0) {
          await env.receive('ahmed', minor, date: date);
          expected -= minor;
        } else {
          await env.give('ahmed', minor, date: date);
          expected += minor;
        }
      }

      final history = unwrapOrThrow(
        await env.transactions.getPersonHistory('ahmed'),
      );
      expect(history, hasLength(50));
      expect(await env.net('ahmed'), expected);
    });
  });

  group('CHK016 gave 750.00 and received 750.00', () {
    test('settled: net is exactly 0', () async {
      await env.give('karim', 75000);
      await env.receive('karim', 75000);

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('karim'),
      );
      expect(balance.net, const Money.egp(0));
      expect(balance.status, RelationshipStatus.settled);
    });
  });

  group('CHK017 gave 750.00 and received 749.99', () {
    test('Karim owes you 0.01 EGP (+1), not settled', () async {
      await env.give('karim', 75000);
      await env.receive('karim', 74999);

      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('karim'),
      );
      expect(balance.net, const Money.egp(1));
      expect(balance.status, RelationshipStatus.theyOweYou);
    });
  });

  group('CHK029 partial repayments of 400.00, 250.00, 350.00', () {
    test('balance after each is 60000 -> 35000 -> 0, four history rows in '
        'date order', () async {
      await env.give('ahmed', 100000, date: DateTime(2026, 9, 1));

      unwrapOrThrow(
        await env.repay('ahmed', 40000, date: DateTime(2026, 9, 5)),
      );
      expect(await env.net('ahmed'), 60000);

      unwrapOrThrow(
        await env.repay('ahmed', 25000, date: DateTime(2026, 9, 10)),
      );
      expect(await env.net('ahmed'), 35000);

      unwrapOrThrow(
        await env.repay('ahmed', 35000, date: DateTime(2026, 9, 15)),
      );
      expect(await env.net('ahmed'), 0);
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('ahmed'),
      );
      expect(balance.status, RelationshipStatus.settled);

      final history = unwrapOrThrow(
        await env.transactions.getPersonHistory('ahmed'),
      );
      expect(history.map((t) => t.date).toList(), [
        DateTime(2026, 9, 1),
        DateTime(2026, 9, 5),
        DateTime(2026, 9, 10),
        DateTime(2026, 9, 15),
      ]);
      expect(history.map((t) => t.amount.minorUnits).toList(), [
        100000,
        40000,
        25000,
        35000,
      ]);
    });
  });

  group('CHK030 three repayments of 333.33 against 1,000.00', () {
    test('Ahmed owes you 0.01 EGP (+1), not settled', () async {
      await env.give('ahmed', 100000, date: DateTime(2026, 9, 1));
      for (var i = 0; i < 3; i++) {
        unwrapOrThrow(
          await env.repay('ahmed', 33333, date: DateTime(2026, 9, 2 + i)),
        );
      }

      expect(await env.net('ahmed'), 1);
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('ahmed'),
      );
      expect(balance.status, RelationshipStatus.theyOweYou);
    });
  });

  group('CHK031 repayment of 0.01 against 1,000.00', () {
    test('Ahmed owes you 999.99 EGP (+99999)', () async {
      await env.give('ahmed', 100000);
      unwrapOrThrow(await env.repay('ahmed', 1));

      expect(await env.net('ahmed'), 99999);
    });
  });

  group('CHK032 original row deleted after a repayment', () {
    test('gave 1,000.00, repaid 400.00, delete the original => you owe '
        'Ahmed 400.00 EGP (-40000): the repayment stays', () async {
      final original = await env.give('ahmed', 100000);
      final repayment = unwrapOrThrow(await env.repay('ahmed', 40000));
      expect(repayment.direction, TransactionDirection.received);
      expect(repayment.kind, TransactionKind.repayment);
      expect(await env.net('ahmed'), 60000);

      unwrapOrThrow(await env.transactions.deleteTransaction(original.id));

      expect(await env.net('ahmed'), -40000);
    });
  });
}
