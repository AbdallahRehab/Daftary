import 'dart:convert';

import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/savings/domain/entities/savings_contribution_audit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/stream_recorder.dart';
import '../../helpers/savings_harness.dart';

/// 022 T058 (C3): a contribution's edit/delete history is readable, live,
/// and ordered by `changedAt` — the savings mirror of T056.
void main() {
  late SavingsHarness h;

  setUp(() async => h = await SavingsHarness.open());
  tearDown(() => h.close());

  test('edit (1,000 -> 800) then delete give two entries in order; the '
      'edit keeps the previous amount', () async {
    final goal = await h.createGoal(target: 500000);
    final entry = await h.contribute(goal.id, 100000);
    final history = StreamRecorder(
      h.repository.watchContributionAuditHistory(entry.id),
    );
    addTearDown(history.cancel);
    await history.waitFor((r) => rightOf(r).isEmpty);

    await h.repository.editContribution(
      contributionId: entry.id,
      amount: const Money.egp(80000),
      date: h.today,
    );
    await history.waitFor((r) => rightOf(r).length == 1);
    // The fixed test clock would stamp both audits identically; advance it
    // so `changedAt` alone orders them, whatever the time zone or the ids.
    h.clock.current = h.clock.current.add(const Duration(minutes: 1));
    await h.repository.deleteContribution(entry.id);
    final entries = rightOf(
      await history.waitFor((r) => rightOf(r).length == 2),
    );

    expect(entries.map((e) => e.changeType), [
      ContributionAuditChange.edited,
      ContributionAuditChange.deleted,
    ]);
    final times = entries.map((e) => e.changedAt).toList();
    expect([...times]..sort(), times);
    final previous =
        jsonDecode(entries.first.previousValuesJson) as Map<String, dynamic>;
    expect(previous['amountMinorUnits'], 100000);
  });

  test('another contribution\'s audits are not returned', () async {
    final goal = await h.createGoal(target: 500000);
    final a = await h.contribute(goal.id, 100);
    final b = await h.contribute(goal.id, 200);
    await h.repository.editContribution(
      contributionId: b.id,
      amount: const Money.egp(300),
      date: h.today,
    );

    final entries = rightOf(
      await h.repository.watchContributionAuditHistory(a.id).first,
    );

    expect(entries, isEmpty);
  });
}
