import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_contribution.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T032 — `EditContribution`/`DeleteContribution` through the real
/// repository: recalculation, balance re-validation, re-conversion, and
/// exactly one audit row per change (FR-030, SC-008).
void main() {
  late SavingsHarness h;
  late EditContribution edit;
  late DeleteContribution delete;

  setUp(() async {
    h = await SavingsHarness.open();
    edit = EditContribution(h.repository);
    delete = DeleteContribution(h.repository);
  });

  tearDown(() => h.close());

  test('US2 AS-7: an edit recalculates every figure and keeps the prior '
      'values in one audit row', () async {
    final goal = await h.createGoal(target: 100000, monthly: 10000);
    final c = await h.contribute(goal.id, 20000, date: DateTime(2026, 9, 1));

    final result = await edit(
      contributionId: c.id,
      amount: Money.egp(30000),
      date: DateTime(2026, 9, 2, 18),
      note: 'corrected',
    );

    final edited = result.toNullable()!;
    expect(edited.amountMinorUnits, 30000);
    expect(edited.date, DateTime(2026, 9, 2), reason: 'date-only');
    expect(edited.note, 'corrected');
    expect(edited.isEdited, isTrue);
    expect(edited.type, c.type, reason: 'the type is immutable');

    final progress = (await h.detail(goal.id)).progress;
    expect(progress.currentAmountMinorUnits, 30000);
    expect(progress.remainingMinorUnits, 70000);
    expect(progress.estimatedCompletion!.estimatedMonths, 7);

    final audits = await h.auditValuesFor(c.id);
    expect(audits, hasLength(1));
    expect(audits.single, {
      'amountMinorUnits': 20000,
      'enteredAmountMinorUnits': 20000,
      'enteredCurrencyCode': 'EGP',
      'date': DateTime(2026, 9, 1).millisecondsSinceEpoch,
      'note': null,
    });
    expect((await h.auditRows()).single.changeType, 'edited');
  });

  test('a delete recalculates and audits the prior values', () async {
    final goal = await h.createGoal(target: 100000);
    final keep = await h.contribute(goal.id, 20000);
    final gone = await h.contribute(goal.id, 5000);

    final result = await delete(gone.id);

    expect(result.isRight(), isTrue);
    final detail = await h.detail(goal.id);
    expect(detail.history.map((e) => e.id), [keep.id]);
    expect(detail.progress.currentAmountMinorUnits, 20000);
    final audit = (await h.auditRows()).single;
    expect(audit.contributionId, gone.id);
    expect(audit.changeType, 'deleted');
    expect((await h.auditValuesFor(gone.id)).single['amountMinorUnits'], 5000);
  });

  test('an edited withdrawal is re-validated against the balance excluding '
      'its own prior value', () async {
    final goal = await h.createGoal(target: 100000, starting: 10000);
    final w = await h.withdraw(goal.id, 4000);

    // Balance without the withdrawal is 10,000: raising it to exactly that
    // is fine (it would be rejected if checked against 6,000).
    final ok = await edit(
      contributionId: w.id,
      amount: Money.egp(10000),
      date: h.today,
    );
    expect(ok.isRight(), isTrue);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 0);

    final tooMuch = await edit(
      contributionId: w.id,
      amount: Money.egp(10001),
      date: h.today,
    );
    final failure = tooMuch.getLeft().toNullable();
    expect(failure, isA<WithdrawalExceedsBalanceFailure>());
    expect(
      (failure! as WithdrawalExceedsBalanceFailure).availableMinorUnits,
      10000,
    );
    expect(await h.auditRows(), hasLength(1), reason: 'only the good edit');
  });

  test('lowering a contribution below what was since withdrawn is '
      'rejected — the balance never goes negative', () async {
    final goal = await h.createGoal(target: 100000);
    final c = await h.contribute(goal.id, 10000);
    await h.withdraw(goal.id, 8000);

    final result = await edit(
      contributionId: c.id,
      amount: Money.egp(7999),
      date: h.today,
    );

    expect(
      result.getLeft().toNullable(),
      isA<WithdrawalExceedsBalanceFailure>(),
    );
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 2000);
  });

  test('deleting a contribution that would leave the balance negative is '
      'rejected; deleting the withdrawal first then works', () async {
    final goal = await h.createGoal(target: 100000);
    final c = await h.contribute(goal.id, 10000);
    final w = await h.withdraw(goal.id, 6000);

    final blocked = await delete(c.id);
    expect(
      blocked.getLeft().toNullable(),
      isA<WithdrawalExceedsBalanceFailure>(),
    );
    expect(await h.auditRows(), isEmpty);

    expect((await delete(w.id)).isRight(), isTrue);
    expect((await delete(c.id)).isRight(), isTrue);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 0);
    expect(await h.auditRows(), hasLength(2));
  });

  test('a foreign-currency edit re-converts at the current rate; the audit '
      'keeps the prior entered and converted figures', () async {
    await h.setRate(Currency.usd, 50);
    final goal = await h.createGoal(target: 10000000);
    final c = await h.contribute(goal.id, 10000, currency: Currency.usd);
    expect(c.amountMinorUnits, 500000);

    await h.setRate(Currency.usd, 52);
    final edited = (await edit(
      contributionId: c.id,
      amount: Money.fromMinorUnits(10000, Currency.usd),
      date: h.today,
    )).toNullable()!;

    expect(edited.amountMinorUnits, 520000);
    expect(edited.enteredCurrency, Currency.usd);
    final audit = (await h.auditValuesFor(c.id)).single;
    expect(audit['amountMinorUnits'], 500000);
    expect(audit['enteredAmountMinorUnits'], 10000);
    expect(audit['enteredCurrencyCode'], 'USD');
  });

  test('an edit may switch an entry into the goal currency; one needing a '
      'missing rate is refused and nothing changes', () async {
    final goal = await h.createGoal(target: 10000000);
    final c = await h.contribute(goal.id, 10000);

    final blocked = await edit(
      contributionId: c.id,
      amount: Money.fromMinorUnits(10000, Currency.eur),
      date: h.today,
    );

    expect(blocked.getLeft().toNullable(), isA<RatesMissingFailure>());
    expect((await h.contributionRows()).single.amountMinorUnits, 10000);
    expect(await h.auditRows(), isEmpty);
  });

  test('FR-020: editing and deleting existing entries stay allowed on an '
      'archived goal', () async {
    final goal = await h.createGoal(target: 100000);
    final a = await h.contribute(goal.id, 1000);
    final b = await h.contribute(goal.id, 2000);
    await ArchiveSavingsGoal(h.repository)(goal.id);

    final edited = await edit(
      contributionId: a.id,
      amount: Money.egp(1500),
      date: h.today,
    );
    final deleted = await delete(b.id);

    expect(edited.isRight(), isTrue);
    expect(deleted.isRight(), isTrue);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 1500);
  });

  test('SC-008: every edit and delete leaves exactly one audit row', () async {
    final goal = await h.createGoal(target: 100000);
    final c = await h.contribute(goal.id, 1000);
    for (var i = 1; i <= 3; i++) {
      await edit(
        contributionId: c.id,
        amount: Money.egp(1000 + i),
        date: h.today,
      );
    }
    await delete(c.id);

    final audits = await h.auditValuesFor(c.id);
    expect(audits.map((a) => a['amountMinorUnits']), [1000, 1001, 1002, 1003]);
  });

  test('unknown or already-deleted entries are GoalNotFoundFailure; a zero '
      'amount is a ValidationFailure', () async {
    final goal = await h.createGoal(target: 100000);
    final c = await h.contribute(goal.id, 1000);
    await delete(c.id);

    expect(
      (await delete(c.id)).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
    expect(
      (await edit(
        contributionId: 'missing',
        amount: Money.egp(1),
        date: h.today,
      )).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
    expect(
      (await edit(
        contributionId: c.id,
        amount: Money.egp(0),
        date: h.today,
      )).getLeft().toNullable(),
      isA<ValidationFailure>(),
    );
  });
}
