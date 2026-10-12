import 'dart:async';

import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

import 'builders.dart';
import 'fakes.dart';

/// 023 T034: the fakes behave like the contracts they stand in for, so
/// later tests can rely on them.
void main() {
  group('FakeSmsInboxGateway', () {
    final base = DateTime(2026, 3, 1);
    InboxSmsMessage row(int id, String address, int minutes) => InboxSmsMessage(
      id: id,
      address: address,
      date: base.add(Duration(minutes: minutes)),
      body: 'synthetic $id',
    );

    test(
      'pages allow-listed rows after the cursor and records calls',
      () async {
        final gateway = FakeSmsInboxGateway(
          rows: [
            row(3, 'nbe', 2),
            row(1, 'NBE', 0),
            row(2, 'OTHER', 1),
            row(4, 'NBE', 2),
          ],
        );
        final first = await gateway.queryInbox(
          senders: ['NBE'],
          afterDate: base.subtract(const Duration(days: 1)),
          limit: 2,
        );
        expect(first.getRight().toNullable()!.map((m) => m.id), [1, 3]);
        final second = await gateway.queryInbox(
          senders: ['NBE'],
          afterDate: base.add(const Duration(minutes: 2)),
          afterId: 3,
          limit: 2,
        );
        expect(second.getRight().toNullable()!.map((m) => m.id), [4]);
        expect(gateway.calls, hasLength(2));
        expect(gateway.calls.last.afterId, 3);
      },
    );
  });

  test('FakeLifecycle flips to paused after N checks', () {
    final lifecycle = FakeLifecycle()..pauseAfterChecks(2);
    expect(lifecycle.isResumed, isTrue);
    expect(lifecycle.isResumed, isTrue);
    expect(lifecycle.isResumed, isFalse);
  });

  test('FakeClipboardReader counts reads', () async {
    final clipboard = FakeClipboardReader('text');
    expect(clipboard.reads, 0);
    await clipboard.readText();
    expect(clipboard.reads, 1);
  });

  test('InMemorySecureStorage stores and can throw', () async {
    final storage = InMemorySecureStorage();
    await storage.write(key: 'k', value: 'v');
    expect(await storage.read(key: 'k'), 'v');
    storage.throwOnAccess = true;
    expect(() => storage.read(key: 'k'), throwsStateError);
  });

  test('FakeRawTextVault round-trips and binds the AAD', () async {
    final vault = FakeRawTextVault();
    final blob = await vault.seal('masked', aad: 'id-1');
    expect(await vault.open(blob, aad: 'id-1'), 'masked');
    expect(await vault.open(blob, aad: 'id-2'), isNull);
    vault.failOpen = true;
    expect(await vault.open(blob, aad: 'id-1'), isNull);
  });

  test('FakeFingerprintHasher is deterministic and content-free', () async {
    final hasher = FakeFingerprintHasher();
    final a = await hasher.fingerprint('Body 123');
    expect(a, await hasher.fingerprint('Body 123'));
    expect(a, isNot(await hasher.fingerprint('Body 124')));
    expect(a, isNot(contains('123')));
  });

  group('FakeScanCoordinator', () {
    test('a catch-up never runs beside another scan', () async {
      final coordinator = FakeScanCoordinator();
      final release = Completer<void>();
      final explicit = coordinator.runExclusive(
        ScanKind.explicit,
        ScanCancellationToken(),
        () => release.future.then((_) => 'explicit'),
      );
      final catchUp = await coordinator.runExclusive(
        ScanKind.catchUp,
        ScanCancellationToken(),
        () async => 'catch-up',
      );
      expect(catchUp, isNull);
      release.complete();
      expect(await explicit, 'explicit');
    });

    test('an explicit scan cancels a running catch-up and waits', () async {
      final coordinator = FakeScanCoordinator();
      final catchUpToken = ScanCancellationToken();
      final release = Completer<void>();
      final catchUp = coordinator.runExclusive(
        ScanKind.catchUp,
        catchUpToken,
        () => release.future.then((_) => 'catch-up'),
      );
      final explicit = coordinator.runExclusive(
        ScanKind.explicit,
        ScanCancellationToken(),
        () async => 'explicit',
      );
      await Future<void>.delayed(Duration.zero);
      expect(catchUpToken.isCancelled, isTrue);
      release.complete();
      expect(await catchUp, 'catch-up');
      expect(await explicit, 'explicit');
      expect(coordinator.started, [ScanKind.catchUp, ScanKind.explicit]);
    });
  });

  group('FakeSmsImportRepository', () {
    test('confirm happens once; a second confirm is already decided', () async {
      final repository = FakeSmsImportRepository()
        ..seed([buildPendingImport(id: 'p1')]);
      final confirmed = ConfirmedPersonTransaction(
        personId: 'person-1',
        direction: TransactionDirection.given,
        amount: const Money.egp(100),
        date: DateTime(2026, 3, 4),
      );
      final first = await repository.confirm(
        pendingId: 'p1',
        confirmed: confirmed,
      );
      expect(first.isRight(), isTrue);
      final second = await repository.confirm(
        pendingId: 'p1',
        confirmed: confirmed,
      );
      expect(
        second.getLeft().toNullable(),
        const ImportAlreadyDecidedFailure(SmsImportStatus.added),
      );
      expect(repository.confirmCalls, hasLength(1));
      expect(repository.rows['p1']!.hasRawText, isFalse);
      expect(repository.tombstones, hasLength(1));
    });

    test('mute deletes that sender\'s pending rows, no tombstones', () async {
      final repository = FakeSmsImportRepository()
        ..seed([
          buildPendingImport(id: 'a', fingerprint: 'fa', senderId: 'NBE'),
          buildPendingImport(id: 'b', fingerprint: 'fb', senderId: 'CIB'),
        ]);
      final settings = FakeSmsImportSettingsRepository(pending: repository);
      final deleted = await settings.muteSender('nbe');
      expect(deleted.getRight().toNullable(), 1);
      expect(repository.rows.keys, ['b']);
      expect(repository.tombstones, isEmpty);
      expect(settings.mutedSenders, {'NBE'});
    });
  });
}
