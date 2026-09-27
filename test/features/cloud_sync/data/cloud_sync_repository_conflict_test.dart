import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_conflict_item.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/resolve_sync_conflict.dart';
import 'package:daftary/features/cloud_sync/domain/usecases/watch_sync_conflicts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/sync/fakes/sync_harness.dart';
import '../../../helpers/stream_recorder.dart';

/// 021 T073: the conflict part of [CloudSyncRepositoryImpl].
void main() {
  late SyncHarness h;
  late CloudSyncRepositoryImpl repository;

  setUp(() {
    h = SyncHarness();
    repository = CloudSyncRepositoryImpl(h.db, h.resolver);
  });

  tearDown(() => h.close());

  const txn = SyncEntityType.moneyTransaction;

  Future<void> conflictOnT1() async {
    await h.createPerson('p1');
    await h.createTransaction('t1', personId: 'p1', amount: 1500);
    await h.engine.runCycle();
    h.remote.seedServerRow(txn, {
      ...h.remote.rowOf(txn, 't1')!,
      'amount_minor': 9999,
      'note': 'from the other phone',
    });
    await h.editTransaction('t1', amount: 1234);
    await h.engine.runCycle();
  }

  test('watchConflicts lists both versions: amount, date, direction and '
      'note, unformatted', () async {
    final conflicts = StreamRecorder(WatchSyncConflicts(repository).call());
    addTearDown(conflicts.cancel);
    await conflicts.waitFor((items) => items.isEmpty);

    await conflictOnT1();
    final item = (await conflicts.waitFor((i) => i.isNotEmpty)).single;
    expect(item.entityType, ConflictEntityType.moneyTransaction);
    expect(item.entityId, 't1');
    expect(item.localSummary.amount, const Money.egp(1234));
    expect(item.serverSummary.amount, const Money.egp(9999));
    expect(item.serverSummary.note, 'from the other phone');
    expect(item.localSummary.direction, ConflictDirection.given);
    expect(item.localSummary.date, DateTime.fromMillisecondsSinceEpoch(1000));
    expect(item.localSummary.isDeleted, isFalse);
  });

  test('watchHasConflict follows the conflict, and resolveConflict closes '
      'it', () async {
    final badge = StreamRecorder(
      repository.watchHasConflict('money_transaction', 't1'),
    );
    addTearDown(badge.cancel);
    await badge.waitFor((v) => !v);

    await conflictOnT1();
    await badge.waitFor((v) => v);

    final result = await ResolveSyncConflict(repository).call(
      ConflictEntityType.moneyTransaction,
      't1',
      ConflictChoice.keepTheirs,
    );
    expect(result, const Right<Failure, Unit>(unit));
    await badge.waitForNext((v) => !v);
    expect((await h.transaction('t1')).amountMinorUnits, 9999);
    expect(await h.resolutions(), hasLength(1));
  });

  test('keep mine is routed to the resolver', () async {
    await conflictOnT1();
    final result = await repository.resolveConflict(
      'money_transaction',
      't1',
      ConflictChoice.keepMine,
    );
    expect(result.isRight(), isTrue);
    expect((await h.resolutions()).single.chosenSide, 'local');
  });

  test('no open conflict → NotFoundFailure; a non-financial type → '
      'ValidationFailure', () async {
    expect(
      (await repository.resolveConflict(
        'money_transaction',
        'nope',
        ConflictChoice.keepMine,
      )).getLeft().toNullable(),
      isA<NotFoundFailure>(),
    );
    expect(
      (await repository.resolveConflict(
        'person',
        'p1',
        ConflictChoice.keepMine,
      )).getLeft().toNullable(),
      isA<ValidationFailure>(),
    );
  });

  test('the T076 methods are not implemented yet', () async {
    expect(
      (await repository.syncNow()).getLeft().toNullable(),
      isA<UnknownFailure>(),
    );
    expect(
      (await repository.setEnabled(true)).getLeft().toNullable(),
      isA<UnknownFailure>(),
    );
  });
}
