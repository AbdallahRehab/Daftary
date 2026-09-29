import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/savings/domain/entities/savings_failures.dart';
import 'package:daftary/features/savings/domain/usecases/delete_savings_goal.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/savings_harness.dart';

/// T057 — `DeleteSavingsGoal` (FR-021, US4 AS-3/AS-4).
void main() {
  late SavingsHarness h;
  late DeleteSavingsGoal delete;

  setUp(() async {
    h = await SavingsHarness.open();
    delete = DeleteSavingsGoal(h.repository);
  });

  tearDown(() => h.close());

  test('US4 AS-3: a goal with logged entries is not deleted — '
      'GoalHasHistoryFailure, nothing written', () async {
    final goal = await h.createGoal(starting: 1000);
    final queued = await h.outboxCount(SyncEntityType.savingsGoal);

    final result = await delete(goal.id);

    expect(result.getLeft().toNullable(), isA<GoalHasHistoryFailure>());
    expect((await h.goalRows()).single.deletedAt, isNull);
    expect(await h.outboxCount(SyncEntityType.savingsGoal), queued);
    expect((await h.detail(goal.id)).history, hasLength(1));
  });

  test('FR-021: a soft-deleted entry still counts as history', () async {
    final goal = await h.createGoal();
    final entry = await h.contribute(goal.id, 500);
    await h.repository.deleteContribution(entry.id);
    expect((await h.detail(goal.id)).history, isEmpty);

    final result = await delete(goal.id);

    expect(result.getLeft().toNullable(), isA<GoalHasHistoryFailure>());
    expect((await h.goalRows()).single.deletedAt, isNull);
  });

  test('US4 AS-4: a zero-history goal is tombstoned and queued for sync as '
      'an upsert; to the user it is gone', () async {
    final goal = await h.createGoal();
    h.clock.current = h.clock.current.add(const Duration(hours: 2));

    final result = await delete(goal.id);

    expect(result.isRight(), isTrue);
    final row = (await h.goalRows()).single;
    expect(row.deletedAt, h.clock.current.millisecondsSinceEpoch);
    expect(row.updatedAt, h.clock.current.millisecondsSinceEpoch);
    expect((await h.lastOutboxPayload(goal.id))['deleted_at'], isNotNull);
    expect(await h.outboxOpTypes(SyncEntityType.savingsGoal), {'upsert'});
    final detail = await h.repository.getGoalDetail(goal.id);
    expect(detail.getLeft().toNullable(), isA<GoalNotFoundFailure>());
    final overview = (await h.repository.getSavingsOverview(
      includeArchived: true,
    )).toNullable()!;
    expect(overview.goals, isEmpty);
  });

  test('an archived zero-history goal can be deleted', () async {
    final goal = await h.createGoal();
    await h.repository.archiveSavingsGoal(goal.id);

    expect((await delete(goal.id)).isRight(), isTrue);
  });

  test('an unknown or already-deleted goal is GoalNotFoundFailure', () async {
    final goal = await h.createGoal();
    await delete(goal.id);

    expect(
      (await delete(goal.id)).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
    expect(
      (await delete('missing')).getLeft().toNullable(),
      isA<GoalNotFoundFailure>(),
    );
  });
}
