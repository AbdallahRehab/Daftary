import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:daftary/features/transactions/domain/entities/person_balance.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T006) — repayment catalogue. The direction of a repayment is
/// inferred by `TransactionsRepositoryImpl._repaymentDirection`: they owe you
/// => you receive; otherwise you give. A1 (direction locked on edit) and B2
/// (unknown direction => RatesMissingFailure) are fixed in US6.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  group('CHK023 they owe you 1,000.00', () {
    test('a 1,000.00 repayment is saved as "received" / repayment and the '
        'status is settled', () async {
      await env.give('ahmed', 100000);

      final repayment = unwrapOrThrow(await env.repay('ahmed', 100000));

      expect(repayment.direction, TransactionDirection.received);
      expect(repayment.kind, TransactionKind.repayment);
      expect(repayment.amount, const Money.egp(100000));
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('ahmed'),
      );
      expect(balance.net, const Money.egp(0));
      expect(balance.status, RelationshipStatus.settled);
    });
  });

  group('CHK024 you owe them 700.00', () {
    test('a 700.00 repayment is saved as "given" / repayment and the status '
        'is settled', () async {
      await env.receive('mona', 70000);

      final repayment = unwrapOrThrow(await env.repay('mona', 70000));

      expect(repayment.direction, TransactionDirection.given);
      expect(repayment.kind, TransactionKind.repayment);
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('mona'),
      );
      expect(balance.net, const Money.egp(0));
      expect(balance.status, RelationshipStatus.settled);
    });
  });

  group('CHK026 balance outcome of an over-repayment', () {
    test(
      'they owe 1,000.00, repay 1,500.00 => you owe 500.00 (-50000); '
      'today it saves without a confirmation (A2, out of this phase)',
      () async {
        await env.give('ahmed', 100000);

        final repayment = unwrapOrThrow(await env.repay('ahmed', 150000));

        expect(repayment.direction, TransactionDirection.received);
        expect(await env.net('ahmed'), -50000);
      },
    );
  });

  group('CHK091 A1: editing a repayment must not flip it', () {
    test(
      'owes 1,000.00, repaid 400.00 (balance 60000); editing the repayment to '
      '"given" is rejected with ValidationFailure and the balance stays 60000',
      () async {
        await env.give('ahmed', 100000);
        final repayment = unwrapOrThrow(await env.repay('ahmed', 40000));
        expect(await env.net('ahmed'), 60000);

        final result = await env.transactions.editTransaction(
          transactionId: repayment.id,
          amount: repayment.amount,
          direction: TransactionDirection.given,
          date: repayment.date,
        );

        expect(result.getLeft().toNullable(), isA<ValidationFailure>());
        expect(await env.net('ahmed'), 60000);
        final history = unwrapOrThrow(
          await env.transactions.getPersonHistory('ahmed'),
        );
        expect(
          history.firstWhere((t) => t.id == repayment.id).direction,
          TransactionDirection.received,
        );
      },
    );
  });

  group('B2: repayments against a blocked balance', () {
    test(
      'USD with no rate against an EGP balance has an unknown direction: a '
      'GBP repayment (no GBP net) returns RatesMissingFailure and inserts nothing',
      () async {
        await env.give('sara', 10000, currency: Currency.usd);
        await env.receive('sara', 100000);
        final before = unwrapOrThrow(
          await env.transactions.getPersonHistory('sara'),
        );

        final result = await env.repay('sara', 5000, currency: Currency.gbp);

        expect(result.getLeft().toNullable(), isA<RatesMissingFailure>());
        final after = unwrapOrThrow(
          await env.transactions.getPersonHistory('sara'),
        );
        expect(after, hasLength(before.length));
      },
    );

    test('opposite-direction blocked balance (Sara: USD given, EGP received): '
        'an EUR repayment (no EUR net) returns RatesMissingFailure and '
        'inserts nothing', () async {
      await env.give('sara', 10000, currency: Currency.usd);
      await env.receive('sara', 100000);
      final before = unwrapOrThrow(
        await env.transactions.getPersonHistory('sara'),
      );

      final result = await env.repay('sara', 2500, currency: Currency.eur);

      expect(result.getLeft().toNullable(), isA<RatesMissingFailure>());
      final after = unwrapOrThrow(
        await env.transactions.getPersonHistory('sara'),
      );
      expect(after, hasLength(before.length));
    });
  });

  const cap = 99999999999999;

  group('TS-REPAY-12 SC-004 near-cap repayment', () {
    test('Ahmed owes 999,999,999,999.99; repaying the same amount settles '
        'to exactly 0', () async {
      await env.give('ahmed', cap);

      final repayment = unwrapOrThrow(await env.repay('ahmed', cap));

      expect(repayment.direction, TransactionDirection.received);
      expect(repayment.amount, const Money.egp(cap));
      final balance = unwrapOrThrow(
        await env.transactions.getPersonBalance('ahmed'),
      );
      expect(balance.net, const Money.egp(0));
      expect(balance.status, RelationshipStatus.settled);
    });

    test('repaying one unit less leaves exactly +1', () async {
      await env.give('ahmed', cap);

      unwrapOrThrow(await env.repay('ahmed', cap - 1));

      expect(await env.net('ahmed'), 1);
    });

    test('you owe the cap; repayment is "given" and settles', () async {
      await env.receive('mona', cap);

      final repayment = unwrapOrThrow(await env.repay('mona', cap));

      expect(repayment.direction, TransactionDirection.given);
      expect(await env.net('mona'), 0);
    });
  });

  group('CHK027 a repayment stays a repayment after an edit', () {
    test('editing the amount keeps kind = repayment and direction; the '
        'balance follows the new amount', () async {
      await env.give('ahmed', 100000);
      final repayment = unwrapOrThrow(await env.repay('ahmed', 40000));

      final edited = unwrapOrThrow(
        await env.transactions.editTransaction(
          transactionId: repayment.id,
          amount: const Money.egp(25000),
          direction: repayment.direction,
          date: repayment.date,
        ),
      );

      expect(edited.kind, TransactionKind.repayment);
      expect(edited.direction, TransactionDirection.received);
      expect(await env.net('ahmed'), 75000);
      final history = unwrapOrThrow(
        await env.transactions.getPersonHistory('ahmed'),
      );
      expect(
        history.firstWhere((t) => t.id == repayment.id).kind,
        TransactionKind.repayment,
      );
    });
  });
}
