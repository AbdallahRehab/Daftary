import 'package:daftary/core/database/app_database.dart' hide isNull, isNotNull;
import 'package:daftary/core/sync/sync_engine.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/core/sync/sync_logger.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes/fake_sync_remote.dart';
import 'fakes/server_rows.dart';
import 'fakes/sync_harness.dart';

/// 021 T083: observability review. A full run — bootstrap, a failed upload
/// with its retry, push, pull, a conflict and an unreadable pulled row —
/// against [FakeSyncRemote] with a spy logger emits every required event,
/// and no logged value carries an amount, a name, a note, a phone number,
/// an email or a token (research.md Decision 18).
void main() {
  const name = 'Amal Secretname';
  const phone = '+201001234567';
  const notes = 'private person note';
  const txnNote = 'confidential transaction note';
  const email = 'secret.user@example.com';
  const token = 'eyJhbGciOiJIUzI1NiJ9.secret-token';
  const amounts = [987654, 123456, 555555];

  late FakeSyncRemote server;
  late SyncHarness a;
  late SyncHarness b;

  setUp(() {
    server = FakeSyncRemote();
    a = SyncHarness(remote: server);
    b = SyncHarness(remote: server);
    a.auth.email = email;
    b.auth.email = email;
  });

  tearDown(() async {
    await a.close();
    await b.close();
  });

  Future<void> runEverything() async {
    // Data from before sync existed: the bootstrap queues it.
    await a.db
        .into(a.db.people)
        .insert(
          PeopleCompanion.insert(
            id: 'p1',
            name: name,
            normalizedName: name.toLowerCase(),
            phoneNumber: const Value(phone),
            notes: const Value(notes),
            createdAt: 1000,
            updatedAt: 1000,
          ),
        );
    await a.bootstrap.enqueueExistingDataIfNeeded(a.db);
    await a.createTransaction('t1', personId: 'p1', amount: amounts[0]);
    await (a.db.update(a.db.moneyTransactions)..where((t) => t.id.equals('t1')))
        .write(const MoneyTransactionsCompanion(note: Value(txnNote)));
    await a.editTransaction('t1', amount: amounts[0]);

    // A whole call fails, is retried after the backoff, then succeeds.
    server.failNextCalls(1);
    expect((await a.engine.runCycle()).result, SyncCycleResult.retryScheduled);
    a.skipBackoff();
    expect(await a.engine.runCycle(), SyncCycleOutcome.completed);

    // The second device downloads everything.
    expect(await b.engine.runCycle(), SyncCycleOutcome.completed);

    // Both edit the same transaction: a conflict on B.
    await a.editTransaction('t1', amount: amounts[1]);
    await a.engine.runCycle();
    await b.editTransaction('t1', amount: amounts[2]);
    await b.engine.runCycle();
    expect(await b.openConflict('t1'), isNotNull);

    // A pulled row this version cannot read.
    server.seedServerRow(SyncEntityType.person, {
      ...personRow('p2', name: name),
      'is_archived': 'not-a-bool',
    });
    expect((await a.engine.runCycle()).errorCode, 'download_unreadable_row');
  }

  test('every required event is emitted', () async {
    await runEverything();
    final emitted = {...a.logger.names, ...b.logger.names};
    // The unknown-type skip happens while the data source parses a raw
    // page, which the in-memory remote never produces; it is covered by
    // sync_remote_data_source_test.dart.
    expect(
      emitted,
      containsAll(
        SyncEvent.values.where((e) => e != SyncEvent.unknownEntitySkipped),
      ),
    );
  });

  test('no logged value carries an amount, a name, a note, a phone number, '
      'an email or a token', () async {
    await runEverything();
    final events = [...a.logger.events, ...b.logger.events];
    expect(events, isNotEmpty);

    final secrets = [
      name,
      'secretname',
      phone,
      '1001234567',
      notes,
      txnNote,
      'confidential',
      email,
      'example.com',
      '@',
      token,
      'eyJ',
      for (final amount in amounts) ...['$amount', (amount / 100).toString()],
    ];
    final safeText = RegExp(r'^[a-z0-9_\-]+$');

    for (final (event, fields) in events) {
      for (final MapEntry(key: field, value: value) in fields.entries) {
        final where = '${event.logName} ${field.name}=$value';
        // Only the allow-listed shapes: counts and codes, never free text.
        if (value is int) {
          expect(amounts, isNot(contains(value)), reason: where);
        } else {
          expect(value, isA<String>(), reason: where);
          expect(safeText.hasMatch(value as String), isTrue, reason: where);
        }
      }
      final line = formatSyncLogLine(event, fields).toLowerCase();
      for (final secret in secrets) {
        expect(line, isNot(contains(secret.toLowerCase())), reason: line);
      }
    }
  });
}
