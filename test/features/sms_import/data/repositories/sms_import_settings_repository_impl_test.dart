import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/models/pending_import_mapper.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T059 — settings, mutes, mappings and counters against a real in-memory
/// database. Every value is synthetic.
void main() {
  late db.AppDatabase database;
  late SmsImportSettingsRepositoryImpl repository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    repository = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(database),
      FixedClock(DateTime(2026, 3, 4, 12)),
    );
  });
  tearDown(() => database.close());

  Future<SmsImportSettings> settings() async =>
      (await repository.getSettings()).getOrElse((f) => fail('$f'));

  test('a read returns the defaults and creates no row', () async {
    expect(await settings(), const SmsImportSettings());
    expect(await database.select(database.smsImportSettings).get(), isEmpty);
  });

  test('the first write creates the singleton', () async {
    await repository.setEnabled(true);
    await repository.dismissOnboarding();
    await repository.setCountCashWithdrawals(true);
    await repository.markPermissionRequested();
    await repository.setScanWindow(ScanWindow.days90);
    await repository.recordScan(at: DateTime(2026, 3, 4, 9), catchUp: false);
    await repository.recordScan(at: DateTime(2026, 3, 4, 10), catchUp: true);
    await repository.setRulesSeen({'generic': 1});
    final read = await settings();
    expect(read.isEnabled, isTrue);
    expect(read.onboardingDismissed, isTrue);
    expect(read.countCashWithdrawals, isTrue);
    expect(read.permissionRequested, isTrue);
    expect(read.scanWindow, ScanWindow.days90);
    expect(read.lastScanAt, DateTime(2026, 3, 4, 9));
    expect(read.lastCatchUpAt, DateTime(2026, 3, 4, 10));
    expect(read.rulesSeen, {'generic': 1});
    expect(
      await database.select(database.smsImportSettings).get(),
      hasLength(1),
    );
  });

  test('the scan window is checked in code, not SQL', () async {
    await (database.into(database.smsImportSettings)).insert(
      const db.SmsImportSettingsCompanion(
        id: db.Value('singleton'),
        scanWindowDays: db.Value(45),
      ),
    );
    expect((await settings()).scanWindow, ScanWindow.days30);
  });

  test('the cursor only moves forward', () async {
    await repository.advanceCursor(date: DateTime(2026, 3, 4, 10), id: 5);
    await repository.advanceCursor(date: DateTime(2026, 3, 4, 9), id: 99);
    await repository.advanceCursor(date: DateTime(2026, 3, 4, 10), id: 4);
    var read = await settings();
    expect(read.cursorDate, DateTime(2026, 3, 4, 10));
    expect(read.cursorId, 5);
    await repository.advanceCursor(date: DateTime(2026, 3, 4, 10), id: 6);
    read = await settings();
    expect(read.cursorId, 6);
  });

  test('counters are monotonic and never lose an increment', () async {
    await Future.wait([
      for (var i = 0; i < 10; i++)
        repository.addCounts(scanned: 2, recognized: 1),
    ]);
    await repository.addCounts(added: 1, ignored: 3);
    final read = await settings();
    expect(read.scannedCount, 20);
    expect(read.recognizedCount, 10);
    expect(read.addedCount, 1);
    expect(read.ignoredCount, 3);
    final negative = await repository.addCounts(scanned: -1);
    expect(negative.getLeft().toNullable(), isA<ValidationFailure>());
    expect((await settings()).scannedCount, 20);
  });

  test(
    'muting deletes that sender\'s pending rows only, no tombstone',
    () async {
      Future<void> seed(String id, String fingerprint, String? sender) =>
          database
              .into(database.pendingSmsImports)
              .insert(
                pendingImportToCompanion(
                  buildPendingImport(
                    id: id,
                    fingerprint: fingerprint,
                    senderId: sender,
                    hasRawText: false,
                  ),
                ),
              );
      await seed('a', 'fa', 'BANKX');
      await seed('b', 'fb', 'BANKX');
      await seed('c', 'fc', 'OTHER');
      await seed('d', 'fd', null);

      final deleted = await repository.muteSender(' bank x ');
      expect(deleted.getOrElse((_) => -1), 2);
      final left = await database.select(database.pendingSmsImports).get();
      expect(left.map((r) => r.id), unorderedEquals(['c', 'd']));
      expect(
        await database.select(database.smsImportTombstones).get(),
        isEmpty,
      );
      expect(
        (await repository.watchMutedSenders().first).getOrElse((_) => {}),
        {'BANKX'},
      );

      await repository.unmuteSender('bankx');
      expect(
        (await repository.watchMutedSenders().first).getOrElse((_) => {'x'}),
        isEmpty,
      );
    },
  );

  test('learned mappings: map, remove one, clear all', () async {
    Future<void> map(String key, String type, String category) => database
        .into(database.smsMerchantCategoryMappings)
        .insert(
          db.SmsMerchantCategoryMappingsCompanion.insert(
            merchantKey: key,
            entryType: type,
            categoryId: category,
            updatedAt: 0,
          ),
        );
    await map('example cafe', 'expense', 'cat-1');
    await map('example co', 'income', 'cat-2');

    expect((await repository.getMappingMap()).getOrElse((_) => {}), {
      ('example cafe', 'expense'): 'cat-1',
      ('example co', 'income'): 'cat-2',
    });
    final listed = (await repository.watchMappings().first).getOrElse(
      (_) => [],
    );
    expect(listed.map((m) => m.entryType), [
      FinanceEntryType.expense,
      FinanceEntryType.income,
    ]);

    await repository.removeMapping('example cafe', 'expense');
    expect((await repository.getMappingMap()).getOrElse((_) => {}).keys, [
      ('example co', 'income'),
    ]);
    await repository.clearMappings();
    final cleared = await repository.getMappingMap();
    expect(cleared.isRight(), isTrue);
    expect(cleared.getOrElse((_) => {('x', 'y'): 'z'}), isEmpty);
  });
}
