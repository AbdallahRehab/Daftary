import 'dart:async';

import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/sync_scheduler.dart';
import 'package:daftary/core/sync/sync_trigger.dart';
import 'package:daftary/features/cloud_sync/data/repositories/cloud_sync_repository_impl.dart';
import 'package:daftary/features/cloud_sync/domain/email_mask.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_failed_item.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_runtime_status.dart';
import 'package:daftary/features/cloud_sync/domain/entities/sync_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../../core/sync/fakes/sync_harness.dart';
import '../../../core/sync/fakes/sync_test_doubles.dart';
import '../../../helpers/stream_recorder.dart';

class _MockScheduler extends Mock implements SyncScheduler {}

/// An auth source whose email steps can fail.
class _FailingAuth extends FakeCloudAuth {
  SyncRemoteException? failure;
  final calls = <String>[];

  @override
  Future<void> requestEmailLinkCode(String email) async {
    calls.add('link');
    if (failure != null) throw failure!;
  }

  @override
  Future<void> requestSignInCode(String email) async {
    calls.add('signIn');
    if (failure != null) throw failure!;
  }

  @override
  Future<void> confirmEmailLink(String email, String code) async {
    calls.add('confirmLink');
    this.email = email;
  }

  @override
  Future<String> confirmSignIn(String email, String code) async {
    calls.add('confirmSignIn');
    this.email = email;
    uid = 'other-account';
    return uid;
  }
}

/// 021 T076: status, switch, notice, retry and email in
/// [CloudSyncRepositoryImpl].
void main() {
  late SyncHarness h;
  late _MockScheduler scheduler;
  late StreamController<SchedulerState> runtime;
  late _FailingAuth auth;
  late CloudSyncRepositoryImpl repository;

  setUpAll(() => registerFallbackValue(SyncTrigger.manual));

  setUp(() {
    h = SyncHarness();
    scheduler = _MockScheduler();
    runtime = StreamController<SchedulerState>.broadcast();
    when(() => scheduler.status).thenAnswer((_) async* {
      yield SchedulerState.idle;
      yield* runtime.stream;
    });
    when(() => scheduler.request(any())).thenReturn(null);
    when(() => scheduler.setEnabled(any())).thenAnswer((i) async {
      final enabled = i.positionalArguments.first as bool;
      await h.store.writeState((s) => s.copyWith(enabled: enabled));
    });
    auth = _FailingAuth();
    repository = CloudSyncRepositoryImpl(
      h.db,
      h.resolver,
      scheduler,
      h.store,
      auth,
      h.supabase,
    );
  });

  tearDown(() async {
    await runtime.close();
    await h.close();
  });

  Future<void> failOp(String personId, String code) async {
    await h.createPerson(personId);
    await (h.db.update(
      h.db.syncOutboxEntries,
    )..where((o) => o.entityId.equals(personId))).write(
      SyncOutboxEntriesCompanion(
        status: const Value(OutboxStatus.failed),
        errorCode: Value(code),
        nextAttemptAt: const Value(5),
      ),
    );
    await (h.db.update(
      h.db.syncRecordMeta,
    )..where((m) => m.entityId.equals(personId))).write(
      const SyncRecordMetaCompanion(state: Value(SyncRecordState.failed)),
    );
  }

  group('watchStatus', () {
    test('combines the scheduler state, the counts and sync_state', () async {
      final status = StreamRecorder(repository.watchStatus());
      addTearDown(status.cancel);
      final first = await status.waitFor((_) => true);
      expect(first.runtime, SyncRuntimeStatus.idle);
      expect(first.enabled, isTrue);
      expect(first.noticeShown, isFalse);
      expect(first.available, isTrue);
      expect(first.isAnonymous, isTrue);
      expect(first.lastSuccessAt, isNull);

      await h.createPerson('p1');
      await status.waitFor((s) => s.pending == 1);

      runtime.add(SchedulerState.syncing);
      await status.waitFor((s) => s.runtime == SyncRuntimeStatus.syncing);
      for (final (core, domain) in [
        (SchedulerState.offline, SyncRuntimeStatus.offline),
        (SchedulerState.backingOff, SyncRuntimeStatus.backingOff),
        (SchedulerState.authRequired, SyncRuntimeStatus.authRequired),
        (SchedulerState.disabled, SyncRuntimeStatus.disabled),
      ]) {
        runtime.add(core);
        await status.waitFor((s) => s.runtime == domain);
      }

      await h.store.writeState(
        (s) => s.copyWith(lastSuccessAt: const Value(1000)),
      );
      final synced = await status.waitFor((s) => s.lastSuccessAt != null);
      expect(synced.lastSuccessAt, DateTime.fromMillisecondsSinceEpoch(1000));
    });

    test('an unreadable downloaded row is reported as a problem', () async {
      final status = StreamRecorder(repository.watchStatus());
      addTearDown(status.cancel);
      await h.store.writeState(
        (s) => s.copyWith(
          lastErrorCode: const Value(SyncErrorCode.downloadUnreadableRow),
        ),
      );
      await status.waitFor((s) => s.problem == SyncProblem.unreadableCloudData);
      await h.store.writeState(
        (s) => s.copyWith(lastErrorCode: const Value(SyncErrorCode.network)),
      );
      await status.waitFor((s) => s.problem == null);
    });

    test('a linked account shows only the masked email', () async {
      await h.supabase.ensureInitialized();
      auth.email = 'ahmed@gmail.com';
      final s = await repository.watchStatus().first;
      expect(s.isAnonymous, isFalse);
      expect(s.linkedEmailMasked, 'a***@g***.com');
      expect(s.props.join(), isNot(contains('ahmed')));
    });

    test('an unconfigured build is not available', () async {
      h.supabase.configured = false;
      expect((await repository.watchStatus().first).available, isFalse);
    });
  });

  test('syncNow requests a manual cycle', () async {
    expect(await repository.syncNow(), const Right<Failure, Unit>(unit));
    verify(() => scheduler.request(SyncTrigger.manual)).called(1);
  });

  test('setEnabled goes through the scheduler and is persisted', () async {
    expect(
      await repository.setEnabled(false),
      const Right<Failure, Unit>(unit),
    );
    verify(() => scheduler.setEnabled(false)).called(1);
    expect((await h.state()).enabled, isFalse);
  });

  test('setEnabled returns a failure instead of throwing', () async {
    when(() => scheduler.setEnabled(any())).thenThrow(StateError('db'));
    expect((await repository.setEnabled(true)).isLeft(), isTrue);
  });

  test('markNoticeShown persists the flag', () async {
    await repository.markNoticeShown();
    expect((await h.state()).noticeShown, isTrue);
  });

  test('watchFailedItems lists refused changes with a reason', () async {
    await failOp('p1', 'person_has_transactions');
    await failOp('p2', 'validation');
    final items = await repository.watchFailedItems().first;
    expect(items, [
      const SyncFailedItem(
        kind: SyncItemKind.person,
        entityId: 'p1',
        reason: SyncFailedReason.personHasTransactions,
      ),
      const SyncFailedItem(
        kind: SyncItemKind.person,
        entityId: 'p2',
        reason: SyncFailedReason.invalid,
      ),
    ]);
  });

  test('retryFailed puts failed items back to pending, clears their retry '
      'time and requests a cycle', () async {
    await failOp('p1', 'validation');
    expect(await repository.retryFailed(), const Right<Failure, Unit>(unit));
    final op = (await h.opFor('p1'))!;
    expect(op.status, OutboxStatus.pending);
    expect(op.nextAttemptAt, isNull);
    expect((await h.metaFor('p1'))!.state, SyncRecordState.pending);
    expect(await repository.watchFailedItems().first, isEmpty);
    verify(() => scheduler.request(SyncTrigger.manual)).called(1);
  });

  group('email', () {
    test('link and sign-in go to the matching auth step', () async {
      await repository.requestEmailCode('a@b.co', linkCurrent: true);
      await repository.requestEmailCode('a@b.co', linkCurrent: false);
      expect(auth.calls, ['link', 'signIn']);
      expect(h.supabase.initializeCalls, greaterThan(0));
    });

    test('confirming a sign-in switches the account and requests a cycle '
        '(the engine re-owns the data)', () async {
      final result = await repository.confirmEmailCode(
        'a@b.co',
        '123456',
        linkCurrent: false,
      );
      expect(result.isRight(), isTrue);
      expect(auth.calls, ['confirmSignIn']);
      expect(auth.uid, 'other-account');
      verify(() => scheduler.request(SyncTrigger.manual)).called(1);
    });

    test('a refused step comes back as its failure', () async {
      auth.failure = const SyncRemoteException(
        EmailAuthFailure(EmailAuthErrorReason.rateLimited),
        transient: false,
        errorCode: 'email_rateLimited',
      );
      final result = await repository.requestEmailCode(
        'a@b.co',
        linkCurrent: true,
      );
      expect(
        result.getLeft().toNullable(),
        const EmailAuthFailure(EmailAuthErrorReason.rateLimited),
      );
    });

    test('nothing is sent while sync is off', () async {
      await h.store.writeState((s) => s.copyWith(enabled: false));
      final result = await repository.requestEmailCode(
        'a@b.co',
        linkCurrent: true,
      );
      expect(result.getLeft().toNullable(), isA<ValidationFailure>());
      expect(auth.calls, isEmpty);
      expect(h.supabase.initializeCalls, 0);
    });
  });

  test('maskEmail keeps one letter of the name and the domain', () {
    expect(maskEmail('ahmed@gmail.com'), 'a***@g***.com');
    expect(maskEmail('x@mail.co.uk'), 'x***@m***.uk');
    expect(maskEmail('broken'), '***');
  });
}
