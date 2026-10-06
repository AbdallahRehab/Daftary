import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_detail.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_summary.dart';
import 'package:daftary/features/occasions/domain/entities/occasion_type.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/catalogue_fixtures.dart';

/// 022 Phase 2 (T007) — occasion catalogue. Occasion totals come only from
/// the occasion's own rows; condolence money does not count toward a
/// person's balance; deleting an occasion soft-deletes its contributions.
/// Every figure is an exact integer count of minor units.
void main() {
  late CatalogueEnv env;

  setUp(() async => env = await CatalogueEnv.open());
  tearDown(() => env.close());

  Future<OccasionDetail> detail(String occasionId) async =>
      unwrapOrThrow(await env.occasions.getOccasionDetail(occasionId));

  group('CHK068 Wedding: 500 + 300 received, 200 given', () {
    test(
      'received 80000, given 20000, 60000 more received, 3 participants',
      () async {
        final wedding = await env.seedChk068();

        final summary = (await detail(wedding.id)).summary;

        expect(summary.totalReceived, const Money.egp(80000));
        expect(summary.totalGiven, const Money.egp(20000));
        expect(summary.net, const Money.egp(60000));
        expect(summary.settlementStatus, SettlementStatus.moreReceived);
        expect(summary.outstanding, const Money.egp(60000));
        expect(summary.participantCount, 3);
      },
    );
  });

  group('CHK069 a contribution is one row shared by both screens', () {
    test(
      'Ahmed history holds it once; editing it to 450.00 from the '
      'occasion changes both views and the received total to 75000',
      () async {
        final wedding = await env.seedChk068();
        final history = unwrapOrThrow(
          await env.transactions.getPersonHistory('ahmed'),
        );
        expect(history, hasLength(1));
        expect(history.single.amount, const Money.egp(50000));

        unwrapOrThrow(
          await env.occasions.editParticipantContribution(
            transactionId: history.single.id,
            amount: const Money.egp(45000),
            direction: TransactionDirection.received,
            date: history.single.date,
          ),
        );

        final afterHistory = unwrapOrThrow(
          await env.transactions.getPersonHistory('ahmed'),
        );
        expect(afterHistory.single.amount, const Money.egp(45000));
        expect(
          (await detail(wedding.id)).summary.totalReceived,
          const Money.egp(75000),
        );
      },
    );

    test(
      'editing it to 450.00 from the person page gives the same totals',
      () async {
        final wedding = await env.seedChk068();
        final row = unwrapOrThrow(
          await env.transactions.getPersonHistory('ahmed'),
        ).single;

        unwrapOrThrow(
          await env.transactions.editTransaction(
            transactionId: row.id,
            amount: const Money.egp(45000),
            direction: row.direction,
            date: row.date,
          ),
        );

        final participants = (await detail(wedding.id)).participants;
        final ahmed = participants.singleWhere((p) => p.personId == 'ahmed');
        expect(ahmed.amount, const Money.egp(45000));
        expect(
          (await detail(wedding.id)).summary.totalReceived,
          const Money.egp(75000),
        );
      },
    );
  });

  group('CHK070 wedding money counts toward the balance by default', () {
    test('Ahmed received 500.00 at the wedding => you owe him 500.00 '
        '(-50000)', () async {
      await env.seedChk068();

      // ⏸ Q1: today's behavior, final only once the owner decides.
      expect(await env.net('ahmed'), -50000);
      expect(await env.net('mona'), -30000);
      expect(await env.net('karim'), 20000);
    });
  });

  group('CHK071 condolence money does not count toward a balance', () {
    test(
      '1,000.00 received from Sara at a condolence: occasion received 100000, '
      "Sara's balance is 0",
      () async {
        final condolence = await env.occasion(
          name: 'Condolence',
          type: OccasionType.condolence,
        );
        final row = await env.contribution(
          condolence.id,
          'sara',
          100000,
          TransactionDirection.received,
        );

        expect(row.countsTowardBalance, isFalse);
        expect(
          (await detail(condolence.id)).summary.totalReceived,
          const Money.egp(100000),
        );
        expect(await env.net('sara'), 0);
      },
    );
  });

  group('CHK072 changing the occasion type moves no balance', () {
    test(
      'Wedding to Condolence leaves every person balance unchanged',
      () async {
        final wedding = await env.seedChk068();
        final before = {
          for (final id in ['ahmed', 'mona', 'karim']) id: await env.net(id),
        };

        unwrapOrThrow(
          await env.occasions.editOccasion(
            occasionId: wedding.id,
            name: wedding.name,
            date: wedding.date,
            type: OccasionType.condolence,
          ),
        );

        expect({
          for (final id in ['ahmed', 'mona', 'karim']) id: await env.net(id),
        }, before);
        expect(before, {'ahmed': -50000, 'mona': -30000, 'karim': 20000});
      },
    );
  });

  group('CHK073 deleting an occasion removes its contributions', () {
    test('Ahmed +100000 before the wedding, +50000 with it, +100000 again '
        'after the occasion is deleted; Mona and Karim return to 0', () async {
      await env.give('ahmed', 150000); // gave 1,500.00, received 500.00
      await env.receive('ahmed', 50000); // +100000
      final wedding = await env.seedChk068();
      expect(await env.net('ahmed'), 50000);

      unwrapOrThrow(await env.occasions.deleteOccasion(wedding.id));

      expect(await env.net('ahmed'), 100000);
      expect(await env.net('mona'), 0);
      expect(await env.net('karim'), 0);
      for (final id in ['ahmed', 'mona', 'karim']) {
        final rows = unwrapOrThrow(await env.transactions.getPersonHistory(id));
        expect(rows.where((t) => t.occasionId == wedding.id), isEmpty);
      }
      final contributions = unwrapOrThrow(
        await env.transactions.getContributionsForOccasion(wedding.id),
      );
      expect(contributions, isEmpty);
    });
  });

  group('CHK083 occasion totals equal the sum of participant rows', () {
    test(
      'received 80000 and given 20000 equal the per-direction sums',
      () async {
        final wedding = await env.seedChk068();
        final result = await detail(wedding.id);

        int sumOf(TransactionDirection direction) => result.participants
            .where((p) => p.direction == direction)
            .fold(0, (sum, p) => sum + p.amount.minorUnits);

        expect(
          result.summary.totalReceived.minorUnits,
          sumOf(TransactionDirection.received),
        );
        expect(
          result.summary.totalGiven.minorUnits,
          sumOf(TransactionDirection.given),
        );
        expect(sumOf(TransactionDirection.received), 80000);
        expect(sumOf(TransactionDirection.given), 20000);
      },
    );
  });

  const cap = 99999999999999;

  group('TS-OCCASION-08 SC-004 one minor unit', () {
    test(
      'received 0.01 from Ahmed only: received 1, given 0, more received',
      () async {
        final wedding = await env.occasion();
        await env.contribution(
          wedding.id,
          'ahmed',
          1,
          TransactionDirection.received,
        );

        final summary = (await detail(wedding.id)).summary;

        expect(summary.totalReceived, const Money.egp(1));
        expect(summary.totalGiven, const Money.egp(0));
        expect(summary.net, const Money.egp(1));
        expect(summary.settlementStatus, SettlementStatus.moreReceived);
      },
    );
  });

  group('TS-OCCASION-09 SC-004 near the 12-digit cap', () {
    test('received cap and gave cap: net 0, settled', () async {
      final wedding = await env.occasion();
      await env.contribution(
        wedding.id,
        'ahmed',
        cap,
        TransactionDirection.received,
      );
      await env.contribution(
        wedding.id,
        'karim',
        cap,
        TransactionDirection.given,
      );

      final summary = (await detail(wedding.id)).summary;

      expect(summary.totalReceived, const Money.egp(cap));
      expect(summary.totalGiven, const Money.egp(cap));
      expect(summary.net, const Money.egp(0));
      expect(summary.settlementStatus, SettlementStatus.settled);
    });

    test('two near-cap received rows sum to 199999999999998 exactly', () async {
      final wedding = await env.occasion();
      await env.contribution(
        wedding.id,
        'ahmed',
        cap,
        TransactionDirection.received,
      );
      await env.contribution(
        wedding.id,
        'mona',
        cap,
        TransactionDirection.received,
      );

      final summary = (await detail(wedding.id)).summary;

      expect(summary.totalReceived, const Money.egp(199999999999998));
      expect(summary.net, const Money.egp(199999999999998));
    });
  });

  group('TS-OCCASION SC-004 edit and remove effects', () {
    test('a near-cap contribution edited to 0.01, then removed', () async {
      final wedding = await env.occasion();
      final row = await env.contribution(
        wedding.id,
        'ahmed',
        cap,
        TransactionDirection.received,
      );

      unwrapOrThrow(
        await env.occasions.editParticipantContribution(
          transactionId: row.id,
          amount: const Money.egp(1),
          direction: row.direction,
          date: row.date,
        ),
      );
      expect(
        (await detail(wedding.id)).summary.totalReceived,
        const Money.egp(1),
      );
      expect(await env.net('ahmed'), -1);

      unwrapOrThrow(await env.occasions.removeParticipantContribution(row.id));
      final summary = (await detail(wedding.id)).summary;
      expect(summary.totalReceived, const Money.egp(0));
      expect(summary.settlementStatus, SettlementStatus.settled);
      expect(await env.net('ahmed'), 0);
    });
  });
}
