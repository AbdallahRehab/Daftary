import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/acknowledge_expired_notice.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_expired_notice.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T077 — expiry, purge and the expired notice, against a real database.
void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late SmsImportRepositoryImpl repository;
  late ExpirePendingImports expire;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    repository = SmsImportRepositoryImpl(
      SmsImportDao(database),
      SmsImportSettingsDao(database),
      AesGcmRawTextVault(FakeSmsKeyStore()),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      clock,
      TransactionsRepositoryImpl(testTransactionsDao(database), database),
      FinanceRepositoryImpl(testFinanceDao(database)),
    );
    expire = ExpirePendingImports(repository, clock);
  });
  tearDown(() => database.close());

  Future<void> stage(String id, DateTime createdAt) async {
    await repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(
          id: id,
          fingerprint: 'fp-$id',
          createdAt: createdAt,
          refHash: 'rh-$id',
        ),
        rawMasked: 'Purchase EGP 125.50 at Example Cafe',
      ),
    );
  }

  Future<db.PendingSmsImportRow> row(String id) => (database.select(
    database.pendingSmsImports,
  )..where((p) => p.id.equals(id))).getSingle();

  test('expires only items past 30 days, with tombstone and scrub', () async {
    await stage('old', DateTime(2026, 2, 1));
    await stage('fresh', DateTime(2026, 3, 1));
    final expired = await expire();
    expect(expired.getOrElse((f) => fail('$f')), 1);

    final shell = await row('old');
    expect(shell.status, 'expired');
    expect(shell.decidedAt, clock.now().millisecondsSinceEpoch);
    expect(shell.rawBlob, isNull);
    // The six Undo-list fields are kept.
    expect(shell.amountMinorUnits, 12550);
    expect(shell.currencyCode, 'EGP');
    expect(shell.occurredOn, isNotNull);
    expect(shell.merchant, 'Example Cafe');
    expect(shell.bankId, 'nbe');
    expect(shell.kind, 'card_purchase');
    // Everything else is cleared.
    expect(shell.cardLast4, isNull);
    expect(shell.timeMinutes, isNull);
    expect(shell.merchantKey, isNull);
    expect(shell.senderId, isNull);
    expect(shell.suggestedAction, 'unset');
    expect(shell.confidenceJson, '{}');
    expect(shell.warningsJson, '{}');

    final tomb = await database
        .select(database.smsImportTombstones)
        .getSingle();
    expect(tomb.fingerprint, 'fp-old');
    expect(tomb.outcome, 'expired');
    expect(tomb.refHash, 'rh-old');

    expect((await row('fresh')).status, 'pending');
    expect((await row('fresh')).rawBlob, isNotNull);
  });

  test('idempotent: a second run expires nothing more', () async {
    await stage('old', DateTime(2026, 2, 1));
    await expire();
    final before = await row('old');
    expect((await expire()).getOrElse((f) => fail('$f')), 0);
    expect(await row('old'), before);
    expect(
      await database.select(database.smsImportTombstones).get(),
      hasLength(1),
    );
  });

  test(
    'purges decided rows after 30 days and tombstones past purge_after',
    () async {
      await stage('old', DateTime(2026, 1, 1));
      await expire(now: DateTime(2026, 2, 1));
      // 29 days later the row stays.
      await expire(now: DateTime(2026, 3, 2));
      expect(
        await database.select(database.pendingSmsImports).get(),
        hasLength(1),
      );
      // 30 days later it is purged; the tombstone stays (97 days).
      final purged = await repository.purgeDecided(DateTime(2026, 3, 3, 1));
      expect(purged.getOrElse((f) => fail('$f')).rows, 1);
      expect(await database.select(database.pendingSmsImports).get(), isEmpty);
      expect(
        await database.select(database.smsImportTombstones).get(),
        hasLength(1),
      );
      final late = await repository.purgeDecided(DateTime(2026, 5, 10));
      expect(late.getOrElse((f) => fail('$f')).tombstones, 1);
      expect(
        await database.select(database.smsImportTombstones).get(),
        isEmpty,
      );
    },
  );

  test('pending rows are never purged', () async {
    await stage('fresh', DateTime(2026, 3, 1));
    final result = await repository.purgeDecided(DateTime(2026, 3, 4));
    expect(result.getOrElse((f) => fail('$f')).rows, 0);
    expect((await row('fresh')).status, 'pending');
  });

  test('the notice counts expiries since expired_notice_seen_at', () async {
    final notice = GetExpiredNotice(repository);
    await stage('a', DateTime(2026, 2, 1));
    await stage('b', DateTime(2026, 2, 2));
    await expire();
    expect((await notice()).getOrElse((f) => fail('$f')), 2);

    clock.current = DateTime(2026, 3, 4, 13);
    await AcknowledgeExpiredNotice(repository)();
    expect((await notice()).getOrElse((f) => fail('$f')), 0);

    await stage('c', DateTime(2026, 2, 5));
    clock.current = DateTime(2026, 3, 8);
    await expire();
    expect((await notice()).getOrElse((f) => fail('$f')), 1);
  });
}
