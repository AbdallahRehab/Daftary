import 'dart:convert';

import 'package:daftary/core/database/app_database.dart'
    show SavingsGoalsCompanion, Value;
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_mapper_registry.dart';
import 'package:daftary/features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart';
import 'package:daftary/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/sync/fakes/fake_sync_remote.dart';
import '../../../core/sync/fakes/sync_harness.dart';
import '../../../helpers/stream_recorder.dart';

/// 022 T045 (A3): a savings contribution edited on two devices shows up in
/// the conflict list, and both versions survive the resolution.
void main() {
  late SyncHarness h;
  late CloudSyncRepositoryImpl repository;

  const contribution = SyncEntityType.savingsContribution;

  setUp(() async {
    h = SyncHarness();
    // Migration 025 gives this version the financial policy.
    h.remote.appVersionOverride = FakeSyncRemote.savingsConflictMinVersion;
    repository = h.cloudSync();
    await h.createGoal('g1');
    await h.createContribution('c1', goalId: 'g1', amount: 50000);
    await h.engine.runCycle();
  });

  tearDown(() => h.close());

  /// The other phone changed it to 1,200.00 first; this one edits to
  /// 1,000.00 against the stale revision.
  Future<void> conflictOnC1() async {
    h.remote.seedServerRow(contribution, {
      ...h.remote.rowOf(contribution, 'c1')!,
      'amount_minor_units': 120000,
      'entered_amount_minor_units': 120000,
      'note': 'from the other phone',
    });
    await h.editContribution('c1', amount: 100000);
    await h.engine.runCycle();
  }

  test(
    'watchConflicts emits the savings contribution with both versions',
    () async {
      final conflicts = StreamRecorder(WatchSyncConflicts(repository).call());
      addTearDown(conflicts.cancel);
      await conflicts.waitFor((items) => items.isEmpty);

      await conflictOnC1();
      final item = (await conflicts.waitFor((i) => i.isNotEmpty)).single;
      expect(item.entityType, ConflictEntityType.savingsContribution);
      expect(item.entityId, 'c1');
      expect(item.localSummary.direction, ConflictDirection.contribution);
      expect(item.localSummary.amount, const Money.egp(100000));
      expect(item.serverSummary.amount, const Money.egp(120000));
      expect(item.serverSummary.note, 'from the other phone');
      expect(item.localSummary.isDeleted, isFalse);
    },
  );

  test('keep theirs applies the server value and keeps the local payload '
      'in conflict_resolutions', () async {
    await conflictOnC1();
    final result = await repository.resolveConflict(
      'savings_contribution',
      'c1',
      ConflictChoice.keepTheirs,
    );
    expect(result.isRight(), isTrue);
    expect((await h.contribution('c1')).amountMinorUnits, 120000);
    final resolution = (await h.resolutions()).single;
    expect(resolution.chosenSide, 'server');
    expect(
      jsonDecode(resolution.discardedValuesJson)['amount_minor_units'],
      '100000',
    );
  });

  test('both versions carry the goal-currency amount, and the item says '
      'when it must be shown', () async {
    // Same typed amount, different derived (goal-currency) amount.
    h.remote.seedServerRow(contribution, {
      ...h.remote.rowOf(contribution, 'c1')!,
      'amount_minor_units': 70000,
    });
    await h.editContribution('c1', amount: 50000);
    await h.engine.runCycle();

    final item = (await repository.watchConflicts().first).single;
    expect(item.localSummary.amount, item.serverSummary.amount);
    expect(item.localSummary.goalAmount, const Money.egp(50000));
    expect(item.serverSummary.goalAmount, const Money.egp(70000));
    expect(item.showsGoalAmount, isTrue);
  });

  test('why migration 025 filters sync_pull: a v1.0.1 client cannot read a '
      'savings resolution row', () {
    // v1.0.1's ConflictResolutionSyncMapper accepted only these two types.
    const legacyTypes = {'money_transaction', 'finance_entry'};
    final row = {
      'id': 'r1',
      'entity_type': 'savings_contribution',
      'entity_id': 'c1',
      'chosen_side': 'local',
      'discarded_values': <String, Object?>{},
      'resolved_at': '2026-10-05T00:00:00.000Z',
    };
    expect(
      () => SyncWire.oneOf(row, 'entity_type', legacyTypes),
      throwsFormatException,
    );
    // The current client reads it.
    expect(
      const ConflictResolutionSyncMapper().fromWire(row).entityType.value,
      'savings_contribution',
    );
  });

  test('no goal amount is shown when the goal is not on this device', () async {
    h.remote.seedServerRow(contribution, {
      ...h.remote.rowOf(contribution, 'c1')!,
      'amount_minor_units': 70000,
    });
    await h.editContribution('c1', amount: 50000);
    await h.engine.runCycle();
    await h.db.customStatement('PRAGMA foreign_keys = OFF');
    await h.db.delete(h.db.savingsGoals).go();

    final item = (await repository.watchConflicts().first).single;
    expect(item.localSummary.goalAmount, isNull);
    expect(item.serverSummary.goalAmount, isNull);
    expect(item.showsGoalAmount, isFalse);
  });

  test('each version uses the currency of its own goal_id', () async {
    await h.db
        .into(h.db.savingsGoals)
        .insert(
          SavingsGoalsCompanion.insert(
            id: 'g2',
            idempotencyKey: 'key-g2',
            name: 'Dollars',
            currencyCode: const Value('USD'),
            targetAmountMinorUnits: 1000000,
            createdAt: 1000,
            updatedAt: 1000,
          ),
        );
    h.remote.seedServerRow(contribution, {
      ...h.remote.rowOf(contribution, 'c1')!,
      'goal_id': 'g2',
      'amount_minor_units': 70000,
    });
    await h.editContribution('c1', amount: 50000);
    await h.engine.runCycle();

    final item = (await repository.watchConflicts().first).single;
    expect(item.localSummary.goalAmount?.currency.code, 'EGP');
    expect(item.serverSummary.goalAmount?.currency.code, 'USD');
  });
}
