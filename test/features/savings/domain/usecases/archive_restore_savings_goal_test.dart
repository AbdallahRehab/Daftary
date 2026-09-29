import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/archive_savings_goal.dart';
import 'package:daftary/features/savings/domain/usecases/delete_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/edit_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/get_savings_overview.dart';
import 'package:daftary/features/savings/domain/usecases/log_contribution.dart';
import 'package:daftary/features/savings/domain/usecases/log_withdrawal.dart';
import 'package:daftary/features/savings/domain/usecases/restore_savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T056 — `ArchiveSavingsGoal`/`RestoreSavingsGoal` (FR-020, US4 AS-2).
void main() {
  late SavingsHarness h;
  late ArchiveSavingsGoal archive;
  late RestoreSavingsGoal restore;

  setUp(() async {
    h = await SavingsHarness.open();
    archive = ArchiveSavingsGoal(h.repository);
    restore = RestoreSavingsGoal(h.repository);
  });

  tearDown(() => h.close());

  Future<List<String>> activeIds() async => [
    for (final line in (await GetSavingsOverview(
      h.repository,
    )()).getOrElse((f) => throw StateError(f.message)).goals)
      line.goal.id,
  ];

  test('archive hides the goal from the active list; its history and '
      'figures are untouched; restore brings it back', () async {
    final goal = await h.createGoal(
      target: 100000,
      starting: 20000,
      monthly: 10000,
    );
    await h.contribute(goal.id, 5000);
    final before = await h.detail(goal.id);
    h.clock.current = h.clock.current.add(const Duration(hours: 1));

    expect((await archive(goal.id)).isRight(), isTrue);

    expect(await activeIds(), isEmpty);
    final archived = await h.detail(goal.id);
    expect(archived.goal.isArchived, isTrue);
    expect(archived.goal.updatedAt, h.clock.current);
    expect(archived.history, before.history);
    expect(archived.progress, before.progress);

    expect((await restore(goal.id)).isRight(), isTrue);

    expect(await activeIds(), [goal.id]);
    final restored = await h.detail(goal.id);
    expect(restored.goal.isArchived, isFalse);
    expect(restored.history, before.history);
  });

  test('archive and restore each queue the goal for sync as an upsert '
      'carrying the flag', () async {
    final goal = await h.createGoal();

    await archive(goal.id);
    expect((await h.lastOutboxPayload(goal.id))['is_archived'], isTrue);

    await restore(goal.id);
    expect((await h.lastOutboxPayload(goal.id))['is_archived'], isFalse);
    expect(await h.outboxOpTypes(SyncEntityType.savingsGoal), {'upsert'});
  });

  test('archiving an archived goal (and restoring an active one) is a '
      'no-op success', () async {
    final goal = await h.createGoal();
    await archive(goal.id);
    final updatedAt = (await h.goalRows()).single.updatedAt;
    h.clock.current = h.clock.current.add(const Duration(hours: 1));

    expect((await archive(goal.id)).isRight(), isTrue);
    expect((await h.goalRows()).single.updatedAt, updatedAt);

    await restore(goal.id);
    expect((await restore(goal.id)).isRight(), isTrue);
  });

  test('FR-020: an archived goal rejects new entries but accepts edits and '
      'deletes of existing ones; after restore it accepts new ones', () async {
    final goal = await h.createGoal(target: 100000);
    final a = await h.contribute(goal.id, 1000);
    final b = await h.contribute(goal.id, 2000);
    await archive(goal.id);

    final logged = await LogContribution(h.repository)(
      idempotencyKey: 'new',
      goalId: goal.id,
      amount: Money.egp(10),
      date: h.today,
    );
    final withdrawn = await LogWithdrawal(h.repository)(
      idempotencyKey: 'new-w',
      goalId: goal.id,
      amount: Money.egp(10),
      date: h.today,
    );
    expect(logged.getLeft().toNullable(), isA<GoalArchivedFailure>());
    expect(withdrawn.getLeft().toNullable(), isA<GoalArchivedFailure>());

    final edited = await EditContribution(h.repository)(
      contributionId: a.id,
      amount: Money.egp(1500),
      date: h.today,
    );
    final deleted = await DeleteContribution(h.repository)(b.id);
    expect(edited.isRight(), isTrue);
    expect(deleted.isRight(), isTrue);
    expect((await h.detail(goal.id)).progress.currentAmountMinorUnits, 1500);

    await restore(goal.id);
    final afterRestore = await LogContribution(h.repository)(
      idempotencyKey: 'after',
      goalId: goal.id,
      amount: Money.egp(10),
      date: h.today,
    );
    expect(afterRestore.isRight(), isTrue);
  });

  test('an unknown or deleted goal is GoalNotFoundFailure', () async {
    final goal = await h.createGoal();
    await h.repository.deleteSavingsGoal(goal.id);

    expect(
      (await archive('missing')).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
    expect(
      (await archive(goal.id)).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
    expect(
      (await restore(goal.id)).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
  });
}
