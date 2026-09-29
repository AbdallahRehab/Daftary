import 'dart:math';

import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T019 (US1) and T034 (US2) — `SavingsRepositoryImpl` against a real
/// in-memory database: idempotency, same-transaction writes, outbox rows,
/// the balance aggregate, audit rows, and SC-002.
void main() {
  late SavingsHarness h;

  setUp(() async => h = await SavingsHarness.open());
  tearDown(() => h.close());

  group('US1 (T019)', () {
    test('createSavingsGoal: the idempotency key is unique — a retry is a '
        'no-op returning the stored goal', () async {
      Future<String> createWithKey(String key, String name) async =>
          (await h.repository.createSavingsGoal(
            idempotencyKey: key,
            name: name,
            currency: Currency.egp,
            targetAmountMinorUnits: 100,
          )).toNullable()!.id;

      final a = await createWithKey('k1', 'A');
      final again = await createWithKey('k1', 'A again');
      final b = await createWithKey('k2', 'B');

      expect(again, a);
      expect(b, isNot(a));
      expect((await h.goalRows()).map((g) => g.name), ['A', 'B']);
    });

    test('the goal and its starting-amount entry are written, and queued, '
        'together — one outbox upsert per record', () async {
      final goal = await h.createGoal(target: 1000, starting: 250);
      final entry = (await h.contributionRows()).single;

      expect(entry.goalId, goal.id);
      expect(entry.amountMinorUnits, 250);
      expect(
        await h.outboxCount(SyncEntityType.savingsGoal, entityId: goal.id),
        1,
      );
      expect(
        await h.outboxCount(
          SyncEntityType.savingsContribution,
          entityId: entry.id,
        ),
        1,
      );
    });

    test('a goal without a starting amount queues only the goal', () async {
      await h.createGoal(target: 1000);

      expect(await h.outboxCount(SyncEntityType.savingsGoal), 1);
      expect(await h.outboxCount(SyncEntityType.savingsContribution), 0);
    });

    test('editSavingsGoal updates the row and queues it (coalesced into the '
        'goal\'s single pending upsert)', () async {
      final goal = await h.createGoal(target: 1000);

      await h.repository.editSavingsGoal(
        goalId: goal.id,
        name: 'Edited',
        targetAmountMinorUnits: 2000,
      );

      expect((await h.goalRows()).single.name, 'Edited');
      expect(
        await h.outboxCount(SyncEntityType.savingsGoal, entityId: goal.id),
        1,
      );
      expect(await h.outboxOpTypes(SyncEntityType.savingsGoal), {'upsert'});
    });

    test('a retried create queues nothing new', () async {
      await h.repository.createSavingsGoal(
        idempotencyKey: 'k',
        name: 'A',
        currency: Currency.egp,
        targetAmountMinorUnits: 100,
        startingAmountMinorUnits: 10,
      );
      await h.repository.createSavingsGoal(
        idempotencyKey: 'k',
        name: 'A',
        currency: Currency.egp,
        targetAmountMinorUnits: 100,
        startingAmountMinorUnits: 10,
      );

      expect(await h.outboxCount(SyncEntityType.savingsGoal), 1);
      expect(await h.outboxCount(SyncEntityType.savingsContribution), 1);
    });
  });

  group('US2 (T034)', () {
    test('log/withdraw write one row and one outbox upsert each; the '
        'balance is the SQL aggregate', () async {
      final goal = await h.createGoal(target: 100000);
      final c = await h.contribute(goal.id, 5000);
      final w = await h.withdraw(goal.id, 2000);

      expect(c.type, ContributionType.contribution);
      expect(w.type, ContributionType.withdrawal);
      expect(w.amountMinorUnits, 2000, reason: 'always positive (FR-007)');
      expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 3000);
      for (final id in [c.id, w.id]) {
        expect(
          await h.outboxCount(SyncEntityType.savingsContribution, entityId: id),
          1,
        );
      }
    });

    test('the withdrawal-balance query refuses an over-withdrawal and '
        'writes nothing', () async {
      final goal = await h.createGoal(target: 100000, starting: 1000);

      final result = await h.repository.logWithdrawal(
        idempotencyKey: 'w',
        goalId: goal.id,
        amount: Money.egp(1001),
        date: h.today,
      );

      final failure = result.getLeft().toNullable();
      expect(failure, isA<WithdrawalExceedsBalanceFailure>());
      expect(
        (failure! as WithdrawalExceedsBalanceFailure).availableMinorUnits,
        1000,
      );
      expect(await h.contributionRows(), hasLength(1));
      expect(await h.outboxCount(SyncEntityType.savingsContribution), 1);
    });

    test('an edit writes the change, its audit row and both outbox upserts '
        'in one transaction', () async {
      final goal = await h.createGoal(target: 100000);
      final c = await h.contribute(goal.id, 5000);

      await h.repository.editContribution(
        contributionId: c.id,
        amount: Money.egp(7000),
        date: h.today,
        note: 'fixed',
      );

      final row = (await h.contributionRows()).single;
      expect(row.amountMinorUnits, 7000);
      expect(row.note, 'fixed');
      expect(row.editedAt, h.clock.current.millisecondsSinceEpoch);
      final audit = (await h.auditRows()).single;
      expect(audit.contributionId, c.id);
      expect(audit.changeType, 'edited');
      expect(await h.outboxCount(SyncEntityType.savingsContributionAudit), 1);
      expect(await h.outboxOpTypes(SyncEntityType.savingsContributionAudit), {
        'upsert',
      });
    });

    test('a delete is a soft delete, audited and queued as an upsert — '
        'never a delete op', () async {
      final goal = await h.createGoal(target: 100000);
      final c = await h.contribute(goal.id, 5000);

      await h.repository.deleteContribution(c.id);

      final row = (await h.contributionRows()).single;
      expect(row.deletedAt, h.clock.current.millisecondsSinceEpoch);
      expect((await h.auditRows()).single.changeType, 'deleted');
      expect(await h.outboxOpTypes(SyncEntityType.savingsContribution), {
        'upsert',
      });
      expect((await h.detail(goal.id)).history, isEmpty);
    });

    test('a rejected edit rolls back: no change, no audit row', () async {
      final goal = await h.createGoal(target: 100000);
      await h.contribute(goal.id, 1000);
      final w = await h.withdraw(goal.id, 500);

      final result = await h.repository.editContribution(
        contributionId: w.id,
        amount: Money.egp(1001),
        date: h.today,
      );

      expect(
        result.getLeft().toNullable(),
        isA<WithdrawalExceedsBalanceFailure>(),
      );
      expect(
        (await h.contributionRows())
            .firstWhere((r) => r.id == w.id)
            .amountMinorUnits,
        500,
      );
      expect(await h.auditRows(), isEmpty);
    });

    test('SC-002: across 60 entries — contributions, withdrawals, edits, '
        'deletes and a converted foreign-currency entry — current always '
        'equals Σ contributions − Σ withdrawals exactly', () async {
      await h.setRate(Currency.usd, 48.35);
      final goal = await h.createGoal(target: 500000000, starting: 100000);
      final random = Random(11);

      /// The expected ledger, kept independently of the repository.
      final expected = <String, int>{};
      final starting = (await h.detail(goal.id)).history.single;
      expect(starting.isStartingAmount, isTrue);
      expected[starting.id] = starting.amountMinorUnits;

      Future<void> assertExact() async {
        final detail = await h.detail(goal.id);
        final fromHistory = detail.history.fold<int>(
          0,
          (sum, e) => sum + e.signedAmountMinorUnits,
        );
        final fromExpected = expected.values.fold<int>(0, (a, b) => a + b);
        expect(detail.progress.currentAmountMinorUnits, fromExpected);
        expect(detail.progress.currentAmountMinorUnits, fromHistory);
        expect(detail.history.map((e) => e.id).toSet(), expected.keys.toSet());
      }

      // One converted entry: 100.00 USD at 48.35 → 4,835.00 EGP.
      final usd = await h.contribute(goal.id, 10000, currency: Currency.usd);
      expect(usd.amountMinorUnits, 483500);
      expect(usd.enteredAmountMinorUnits, 10000);
      expect(usd.enteredCurrency, Currency.usd);
      expected[usd.id] = usd.amountMinorUnits;
      await assertExact();

      var logged = 2;
      var edits = 0;
      var deletes = 0;
      for (var i = 0; logged < 60; i++) {
        final day = h.today.subtract(Duration(days: random.nextInt(90)));
        final roll = random.nextInt(10);
        final balance = expected.values.fold<int>(0, (a, b) => a + b);
        if (roll < 6 || balance < 100) {
          final c = await h.contribute(
            goal.id,
            1 + random.nextInt(250000),
            date: day,
          );
          expected[c.id] = c.amountMinorUnits;
        } else if (roll < 8) {
          final w = await h.withdraw(
            goal.id,
            1 + random.nextInt(balance ~/ 2),
            date: day,
          );
          expected[w.id] = -w.amountMinorUnits;
        } else if (roll == 8) {
          // Edit a random earlier contribution upward (always valid).
          final candidates = [
            for (final e in expected.entries)
              if (e.value > 0 && e.key != usd.id) e.key,
          ];
          final id = candidates[random.nextInt(candidates.length)];
          final newAmount = expected[id]! + 1 + random.nextInt(1000);
          final result = await h.repository.editContribution(
            contributionId: id,
            amount: Money.egp(newAmount),
            date: day,
          );
          expect(result.isRight(), isTrue);
          expected[id] = newAmount;
          edits++;
        } else {
          // Delete the most recent withdrawal, if any (always valid).
          final withdrawals = expected.entries.where((e) => e.value < 0);
          if (withdrawals.isEmpty) continue;
          final id = withdrawals.last.key;
          expect((await h.repository.deleteContribution(id)).isRight(), isTrue);
          expected.remove(id);
          deletes++;
        }
        logged++;
        await assertExact();
      }

      expect(edits, greaterThan(0));
      expect(deletes, greaterThan(0));
      expect(
        (await h.contributionRows()).where((r) => r.type == 'withdrawal'),
        isNotEmpty,
      );

      // A later rate change never reinterprets the converted entry.
      await h.setRate(Currency.usd, 60);
      await assertExact();

      // Every edit and delete left exactly one audit row (SC-008).
      final audits = await h.auditRows();
      expect(audits, hasLength(edits + deletes));
      expect(
        audits.where((a) => a.changeType == 'deleted').length,
        (await h.contributionRows()).where((r) => r.deletedAt != null).length,
      );
    });
  });
}
