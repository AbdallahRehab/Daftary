import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import 'package:daftary/features/data_privacy/data/repositories/data_wipe_repository_impl.dart';
import 'package:daftary/features/data_privacy/domain/services/secure_storage_wiper.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/secure_storage_sms_key_store.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/usecases/purge_sms_import_keys.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_cloud_copy_eraser.dart';
import '../../../helpers/test_daos.dart';
import '../../ai_assistant/helpers/ai_assistant_harness.dart';
import '../helpers/builders.dart';
import '../helpers/fakes.dart';

class _NoopSecureStorageWiper implements SecureStorageWiper {
  @override
  Future<Either<Failure, SecureStorageRestore>> wipe() async =>
      Right(() async => const Right(unit));
}

/// T141/T144 — Delete all data removes every bank-message table row and
/// both bank-message keys (FR-076, data-model §10, SC-011), through the
/// real `DeleteAllUserData`, the real table wipe and the real
/// `SecureStorageSmsKeyStore` over an in-memory secure storage. Also the
/// key-loss behaviour (FR-074a): parsed fields stay, the original is
/// unavailable. Every value is synthetic.
void main() {
  late AIAssistantHarness ai;
  late InMemorySecureStorage storage;
  late SecureStorageSmsKeyStore keys;
  late FixedClock clock;
  late SmsImportRepositoryImpl repository;
  late SmsImportSettingsRepositoryImpl settings;
  late DeleteAllUserData deleteAll;

  const body = 'Purchase EGP 125.50 at Example Cafe card 4111111111111111';

  setUp(() async {
    ai = AIAssistantHarness.open();
    final database = ai.db;
    await database.select(database.financeCategories).get();
    storage = InMemorySecureStorage();
    keys = SecureStorageSmsKeyStore(storage: storage);
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    repository = SmsImportRepositoryImpl(
      SmsImportDao(database),
      SmsImportSettingsDao(database),
      AesGcmRawTextVault(keys),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      clock,
      TransactionsRepositoryImpl(testTransactionsDao(database), database),
      FinanceRepositoryImpl(testFinanceDao(database)),
    );
    settings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(database),
      clock,
    );
    deleteAll = DeleteAllUserData(
      DataWipeRepositoryImpl(database),
      PurgeAIAssistantCredentials(ai.repository),
      PurgeSmsImportKeys(keys),
      _NoopSecureStorageWiper(),
      FakeCloudCopyEraser(),
    );
  });
  tearDown(() => ai.close());

  /// Every bank-message table gets a row; the keys exist; one record was
  /// added from an SMS.
  Future<void> populate() async {
    await repository.insertPending(
      NewPendingImport(item: buildPendingImport(), rawMasked: body),
    );
    await repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(id: 'pending-2', fingerprint: 'fp-2'),
        rawMasked: body,
      ),
    );
    await repository.insertPending(
      NewPendingImport(
        item: buildPendingImport(id: 'pending-3', fingerprint: 'fp-3'),
        rawMasked: body,
      ),
    );
    await repository.ignore({'pending-2'});
    final added = await repository.confirm(
      pendingId: 'pending-3',
      confirmed: ConfirmedFinanceEntry(
        categoryId: 'seed_rent',
        type: FinanceEntryType.expense,
        amount: const Money.egp(12550),
        date: DateTime(2026, 3, 4),
      ),
    );
    expect(added.isRight(), isTrue, reason: '$added');
    await settings.muteSender('OTHERBANK');
    await settings.setEnabled(true);
    await settings.addCounts(scanned: 3, recognized: 3);
    // The Add above learned a merchant mapping (FR-056).
    // Ingestion would have made the MAC key; the staging above made only
    // the encryption key.
    await keys.macKey();
  }

  test('removes the five bank-message tables and both keys', () async {
    await populate();
    final db = ai.db;
    expect(await db.select(db.pendingSmsImports).get(), isNotEmpty);
    expect(await db.select(db.smsImportTombstones).get(), isNotEmpty);
    expect(await db.select(db.smsSenderMutes).get(), isNotEmpty);
    expect(await db.select(db.smsMerchantCategoryMappings).get(), isNotEmpty);
    expect(await db.select(db.smsImportSettings).get(), isNotEmpty);
    expect(storage.values.keys, {
      SecureStorageSmsKeyStore.encKeyName,
      SecureStorageSmsKeyStore.macKeyName,
    });
    storage.values['unrelated.secret'] = 'keep me';

    expect(await deleteAll(), const Right<Failure, Unit>(unit));

    expect(await db.select(db.pendingSmsImports).get(), isEmpty);
    expect(await db.select(db.smsImportTombstones).get(), isEmpty);
    expect(await db.select(db.smsSenderMutes).get(), isEmpty);
    expect(await db.select(db.smsMerchantCategoryMappings).get(), isEmpty);
    expect(await db.select(db.smsImportSettings).get(), isEmpty);
    expect(await db.select(db.financeEntries).get(), isEmpty);
    // Both keys are gone; only the two named entries were deleted.
    expect(storage.values.keys, {'unrelated.secret'});
    // A fresh state: the feature reads as off with zeroed counters.
    final fresh = (await settings.getSettings()).getOrElse((f) => fail('$f'));
    expect(fresh.isEnabled, isFalse);
    expect(fresh.scannedCount, 0);
  });

  test('a key purge failure stops before any table is wiped', () async {
    await populate();
    storage.throwOnAccess = true;

    final result = await deleteAll();

    expect(result, const Left<Failure, Unit>(PurgeSmsImportKeys.purgeFailed));
    storage.throwOnAccess = false;
    expect(await ai.db.select(ai.db.pendingSmsImports).get(), isNotEmpty);
    expect(await ai.db.select(ai.db.financeEntries).get(), hasLength(1));
  });

  group('key loss (FR-074a)', () {
    test('parsed fields stay; Show original is unavailable and the '
        'unreadable original is dropped', () async {
      await repository.insertPending(
        NewPendingImport(item: buildPendingImport(), rawMasked: body),
      );
      expect(
        (await ShowOriginalMessage(repository)('pending-1')).isRight(),
        isTrue,
      );

      // The keys are lost (a restore onto a new device, a reinstall).
      await keys.purge();

      final shown = await ShowOriginalMessage(repository)('pending-1');
      expect(
        shown,
        const Left<Failure, OriginalMessage>(OriginalUnavailableFailure()),
      );
      final item = (await repository.getById(
        'pending-1',
      )).getOrElse((f) => fail('$f'));
      expect(item.isPending, isTrue);
      expect(item.amount, const Money.egp(12550));
      expect(item.merchant, 'Example Cafe');
      expect(item.hasRawText, isFalse);
      // A second attempt stays unavailable and never throws.
      expect(
        await ShowOriginalMessage(repository)('pending-1'),
        const Left<Failure, OriginalMessage>(OriginalUnavailableFailure()),
      );
    });
  });
}
