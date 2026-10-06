import 'dart:async';
import 'dart:io';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/sync/local/outbox_coalescer.dart';
import 'package:daftary/core/sync/remote/supabase_initializer.dart';
import 'package:daftary/core/sync/remote/sync_error_mapper.dart';
import 'package:daftary/core/sync/remote/sync_remote_data_source.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:daftary/core/sync/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fakes/sync_test_doubles.dart';

class _MockClient extends Mock implements SupabaseClient {}

/// A `PostgrestFilterBuilder` stand-in: only awaiting it is used.
class _FakeBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  _FakeBuilder(this._future);

  final Future<dynamic> _future;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(dynamic value) onValue, {
    Function? onError,
  }) => _future.then(onValue, onError: onError);
}

class _Initializer extends Fake implements SupabaseInitializer {
  _Initializer(this.client);

  @override
  final SupabaseClient client;
}

/// 021 T054: `push` calls `sync_push` with a 20 s timeout and parses every
/// result kind.
void main() {
  const device = DeviceInfo(
    deviceId: '11111111-1111-4111-8111-111111111111',
    platform: 'android',
    appVersion: '1.0.0',
  );
  const op = OutboxOp(
    opId: 'op-1',
    entityType: SyncEntityType.moneyTransaction,
    entityId: 't1',
    opType: OutboxOpType.upsert,
    payload: {'id': 't1', 'amount_minor': '150000'},
    baseRevision: 42,
  );

  test('calls rpc(sync_push) through the SupabaseClient with the contract '
      'params', () async {
    final client = _MockClient();
    Map<String, dynamic>? sent;
    when(
      () => client.rpc<dynamic>('sync_push', params: any(named: 'params')),
    ).thenAnswer((inv) {
      sent = inv.namedArguments[#params] as Map<String, dynamic>;
      return _FakeBuilder(
        Future.value({
          'results': [
            {'op_id': 'op-1', 'result': 'applied', 'revision': 57},
          ],
          'server_time': '2026-09-27T09:13:00Z',
        }),
      );
    });
    final source = SupabaseSyncRemoteDataSource(
      _Initializer(client),
      RecordingSyncLogger(),
    );

    final results = await source.push([op], device);
    expect(results, [const PushApplied('op-1', revision: 57)]);
    expect(sent!['p_device_id'], device.deviceId);
    expect(sent!['p_platform'], 'android');
    expect(sent!['p_app_version'], '1.0.0');
    expect(sent!['p_ops'], [
      {
        'op_id': 'op-1',
        'entity_type': 'money_transaction',
        'op_type': 'upsert',
        'entity_id': 't1',
        'base_revision': 42,
        'payload': {'id': 't1', 'amount_minor': '150000'},
      },
    ]);
  });

  test('parses all five result kinds', () {
    final results = parsePushResponse({
      'results': [
        {'op_id': 'a', 'result': 'applied', 'revision': 57},
        {'op_id': 'b', 'result': 'already_applied', 'revision': 57.0},
        {
          'op_id': 'c',
          'result': 'conflict',
          'revision': 55,
          'server_row': {'id': 't1', 'amount_minor': 150000},
        },
        {
          'op_id': 'd',
          'result': 'superseded',
          'revision': 56,
          'server_row': {'id': 'p1'},
        },
        {
          'op_id': 'e',
          'result': 'rejected',
          'reason': 'person_has_transactions',
          'revision': 9,
          'server_row': {'id': 'p1'},
        },
        {'op_id': 'f', 'result': 'rejected', 'reason': 'missing_parent'},
        {'op_id': 'g', 'result': 'already_applied'},
        {
          'op_id': 'h',
          'result': 'applied',
          'revision': 60,
          'server_row': {'id': 'c1', 'is_archived': true},
        },
      ],
    });
    expect(results, [
      const PushApplied('a', revision: 57),
      const PushApplied('b', revision: 57, alreadyApplied: true),
      const PushConflict(
        'c',
        revision: 55,
        serverRow: {'id': 't1', 'amount_minor': 150000},
      ),
      const PushSuperseded('d', revision: 56, serverRow: {'id': 'p1'}),
      const PushRejected(
        'e',
        reason: 'person_has_transactions',
        revision: 9,
        serverRow: {'id': 'p1'},
      ),
      const PushRejected('f', reason: 'missing_parent'),
      // A delete of a row the server never had: no revision.
      const PushApplied('g', revision: null, alreadyApplied: true),
      const PushApplied(
        'h',
        revision: 60,
        serverRow: {'id': 'c1', 'is_archived': true},
      ),
    ]);
    expect((results[5] as PushRejected).isTransient, isTrue);
    expect((results[4] as PushRejected).isTransient, isFalse);
  });

  test('a malformed response is a permanent bad_response failure', () async {
    for (final body in <Object?>[
      null,
      'nope',
      {'results': 'x'},
      {
        'results': [
          {'op_id': 'a', 'result': 'teleported'},
        ],
      },
      {
        'results': [
          {'op_id': 'a', 'result': 'conflict', 'revision': 1},
        ],
      },
    ]) {
      final source = SupabaseSyncRemoteDataSource.withRpc((_, _) async => body);
      await expectLater(
        source.push([op], device),
        throwsA(
          isA<SyncRemoteException>()
              .having((e) => e.errorCode, 'code', 'bad_response')
              .having((e) => e.transient, 'transient', isFalse),
        ),
        reason: '$body',
      );
    }
  });

  test('error paths are mapped', () async {
    Future<SyncRemoteException> failWith(Object error) async {
      final source = SupabaseSyncRemoteDataSource.withRpc(
        (_, _) async => throw error,
      );
      try {
        await source.push([op], device);
      } on SyncRemoteException catch (e) {
        return e;
      }
      fail('expected a SyncRemoteException');
    }

    expect(
      (await failWith(const SocketException('x'))).failure,
      isA<NetworkFailure>(),
    );
    expect(
      (await failWith(
        const PostgrestException(message: 'm', code: '42501'),
      )).failure,
      isA<ForbiddenFailure>(),
    );
    expect(
      (await failWith(
        const PostgrestException(message: 'm', code: 'PGRST301'),
      )).failure,
      isA<UnauthorizedFailure>(),
    );
    expect(
      (await failWith(
        const PostgrestException(message: 'm', code: '503'),
      )).failure,
      isA<ServerFailure>(),
    );
  });

  test(
    'the timeout is 20 s, and a timeout is a transient TimeoutFailure',
    () async {
      expect(
        SupabaseSyncRemoteDataSource.withRpc((_, _) async => null).timeout,
        const Duration(seconds: 20),
      );
      final never = Completer<Object?>();
      final source = SupabaseSyncRemoteDataSource.withRpc(
        (_, _) => never.future,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        source.push([op], device),
        throwsA(
          isA<SyncRemoteException>()
              .having((e) => e.failure, 'failure', isA<TimeoutFailure>())
              .having((e) => e.transient, 'transient', isTrue),
        ),
      );
    },
  );

  group('pull (T067)', () {
    test(
      'calls rpc(sync_pull_v2) with the cursor and the page size (022 D2: '
      'R2 receives finance_entry_audit rows; v1.0.1 and R1 keep sync_pull)',
      () async {
        String? function;
        Map<String, Object?>? params;
        final source = SupabaseSyncRemoteDataSource.withRpc((f, p) async {
          function = f;
          params = p;
          return {'changes': <Object?>[], 'max_revision': 7, 'has_more': false};
        });
        final page = await source.pull(since: 7, limit: 50);
        expect(function, 'sync_pull_v2');
        expect(params, {'p_since': 7, 'p_limit': 50});
        expect(
          page,
          const PullPage(changes: [], maxRevision: 7, hasMore: false),
        );
      },
    );

    test('a finance_entry_audit change is parsed, not skipped as unknown '
        '(022 D2)', () {
      final page = parsePullResponse({
        'changes': [
          {
            'entity_type': 'finance_entry_audit',
            'revision': 9,
            'row': {'id': 'a1', 'revision': 9},
          },
        ],
        'max_revision': 9,
        'has_more': false,
      }, since: 0);
      expect(page.changes.single.entityType, SyncEntityType.financeEntryAudit);
    });

    test('parses changes in order, with money and revisions as numbers', () {
      final page = parsePullResponse({
        'changes': [
          {
            'entity_type': 'person',
            'revision': 43,
            'row': {'id': 'p1', 'owner_id': 'u', 'deleted_at': null},
          },
          {
            'entity_type': 'money_transaction',
            'revision': 44.0,
            'row': {'id': 't1', 'amount_minor': 150000, 'revision': 44},
          },
        ],
        'max_revision': 44,
        'has_more': true,
      }, since: 42);
      expect(page.hasMore, isTrue);
      expect(page.maxRevision, 44);
      expect(page.changes, [
        const PulledChange(
          entityType: SyncEntityType.person,
          revision: 43,
          row: {'id': 'p1', 'owner_id': 'u', 'deleted_at': null},
        ),
        const PulledChange(
          entityType: SyncEntityType.moneyTransaction,
          revision: 44,
          row: {'id': 't1', 'amount_minor': 150000, 'revision': 44},
        ),
      ]);
    });

    test('S0: an unknown entity_type is skipped, the rest applies and the '
        'cursor uses the raw page', () {
      final skipped = <String>[];
      final page = parsePullResponse(
        {
          'changes': [
            {
              'entity_type': 'person',
              'revision': 43,
              'row': {'id': 'p1'},
            },
            {
              'entity_type': 'future_type',
              'revision': 44,
              'row': {'id': 'f1', 'secret': 'amount 123'},
            },
            {
              'entity_type': 'money_transaction',
              'revision': 45,
              'row': {'id': 't1'},
            },
          ],
          'has_more': false,
        },
        since: 42,
        onUnknownType: skipped.add,
      );
      expect(page.changes.map((c) => c.revision), [43, 45]);
      expect(page.maxRevision, 45);
      expect(skipped, ['future_type']);
    });

    test('S0: a page of only unknown types still advances the cursor', () {
      final page = parsePullResponse({
        'changes': [
          {
            'entity_type': 'future_type',
            'revision': 50,
            'row': {'id': 'f'},
          },
          {
            'entity_type': 'other_type',
            'revision': 51,
            'row': {'id': 'g'},
          },
        ],
        'has_more': false,
      }, since: 42);
      expect(page.changes, isEmpty);
      expect(page.maxRevision, 51);
    });

    test('S0: pull logs the skipped type name only', () async {
      final logger = RecordingSyncLogger();
      final source = SupabaseSyncRemoteDataSource.withRpc(
        (_, _) async => {
          'changes': [
            {
              'entity_type': 'future_type',
              'revision': 9,
              'row': {'id': 'f1', 'amount': 'private'},
            },
          ],
          'max_revision': 9,
          'has_more': false,
        },
        logger: logger,
      );
      final page = await source.pull(since: 5);
      expect(page.changes, isEmpty);
      expect(page.maxRevision, 9);
      expect(logger.names, [SyncEvent.unknownEntitySkipped]);
      expect(logger.events.single.$2, {SyncLogField.entityType: 'future_type'});
    });

    test('an empty page keeps the cursor', () {
      final page = parsePullResponse({
        'changes': <Object?>[],
        'has_more': false,
      }, since: 12);
      expect(page.maxRevision, 12);
    });

    test('a malformed page is a permanent bad_response failure', () async {
      for (final body in <Object?>[
        null,
        {'changes': 'x', 'has_more': false},
        {'changes': <Object?>[]},
        {
          'changes': [
            {'entity_type': 'person', 'revision': 1},
          ],
          'has_more': false,
        },
      ]) {
        final source = SupabaseSyncRemoteDataSource.withRpc(
          (_, _) async => body,
        );
        await expectLater(
          source.pull(since: 0),
          throwsA(
            isA<SyncRemoteException>()
                .having((e) => e.errorCode, 'code', 'bad_response')
                .having((e) => e.transient, 'transient', isFalse),
          ),
          reason: '$body',
        );
      }
    });

    test('errors and timeouts are mapped', () async {
      final failing = SupabaseSyncRemoteDataSource.withRpc(
        (_, _) async => throw const SocketException('x'),
      );
      await expectLater(
        failing.pull(since: 0),
        throwsA(
          isA<SyncRemoteException>().having(
            (e) => e.failure,
            'failure',
            isA<NetworkFailure>(),
          ),
        ),
      );
      final never = Completer<Object?>();
      final slow = SupabaseSyncRemoteDataSource.withRpc(
        (_, _) => never.future,
        timeout: const Duration(milliseconds: 20),
      );
      await expectLater(
        slow.pull(since: 0),
        throwsA(
          isA<SyncRemoteException>().having(
            (e) => e.failure,
            'failure',
            isA<TimeoutFailure>(),
          ),
        ),
      );
    });
  });
}
