import 'package:daftary/core/database/app_database.dart' hide isNotNull, isNull;
import 'package:daftary/features/ai_assistant/domain/usecases/purge_ai_assistant_credentials.dart';
import 'package:daftary/features/app_lock/data/datasources/secure_app_lock_storage.dart';
import 'package:daftary/features/app_lock/data/repositories/app_lock_repository_impl.dart';
import 'package:daftary/features/app_lock/data/services/app_lock_secure_storage_wiper.dart';
import 'package:daftary/features/app_lock/domain/services/lockout_policy.dart';
import 'package:daftary/features/app_lock/domain/services/pin_hasher.dart';
import 'package:daftary/features/data_privacy/data/repositories/data_wipe_repository_impl.dart';
import 'package:daftary/features/data_privacy/domain/usecases/delete_all_user_data.dart';
import 'package:daftary/features/onboarding/data/datasources/onboarding_dao.dart';
import 'package:daftary/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_cloud_copy_eraser.dart';
import '../../ai_assistant/helpers/ai_assistant_harness.dart';

/// The real canonical wipe (`DeleteAllUserData` over a real in-memory
/// drift database, the real `DataWipeRepositoryImpl` and the real
/// `AppLockSecureStorageWiper`) around a given [SecureAppLockStorage] —
/// only the keychains themselves are in-memory.
class WipeHarness {
  WipeHarness._(this.ai, this.storage, this.appLock, this.deleteAllUserData);

  static WipeHarness open(SecureAppLockStorage storage) {
    final ai = AIAssistantHarness.open();
    return WipeHarness._(
      ai,
      storage,
      AppLockRepositoryImpl(
        storage,
        Pbkdf2PinHasher(iterations: 5),
        const EscalatingLockoutPolicy(),
        runPinWork: runPinWorkInline,
      ),
      DeleteAllUserData(
        DataWipeRepositoryImpl(ai.db),
        PurgeAIAssistantCredentials(ai.repository),
        AppLockSecureStorageWiper(storage),
        FakeCloudCopyEraser(),
      ),
    );
  }

  final AIAssistantHarness ai;
  final SecureAppLockStorage storage;
  final AppLockRepositoryImpl appLock;
  final DeleteAllUserData deleteAllUserData;

  AppDatabase get db => ai.db;

  Future<void> close() => ai.close();

  /// App Lock fully configured: PIN set, enabled, biometric on, and a
  /// running lockout — so all three `app_lock.*` keys hold a value.
  Future<void> configureAppLock() async {
    await appLock.setPin('1357');
    await appLock.enableAppLock();
    await appLock.setBiometricEnabled(true);
    for (var i = 0; i < 6; i++) {
      await appLock.recordFailedPinAttempt();
    }
    expect(await storage.readConfig(), isNotNull);
    expect(await storage.readPinCredential(), isNotNull);
    expect(await storage.readLockoutState(), isNotNull);
  }

  /// User data across several features, onboarding marked complete.
  Future<void> populate() async {
    const t = 1760000000000;
    await db
        .into(db.people)
        .insert(
          PeopleCompanion.insert(
            id: 'p1',
            name: 'Ahmed',
            normalizedName: 'ahmed',
            createdAt: t,
            updatedAt: t,
          ),
        );
    await db
        .into(db.moneyTransactions)
        .insert(
          MoneyTransactionsCompanion.insert(
            id: 'm1',
            idempotencyKey: 'mk1',
            personId: 'p1',
            amountMinorUnits: 10000,
            direction: 'given',
            kind: 'initialExchange',
            date: t,
            createdAt: t,
          ),
        );
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: 'singleton',
            languageCode: 'ar',
            updatedAt: t,
          ),
        );
    await db
        .into(db.onboardingStatus)
        .insert(
          OnboardingStatusCompanion.insert(
            id: 'singleton',
            isComplete: const Value(true),
          ),
        );
    await db
        .into(db.aiConversations)
        .insert(
          AiConversationsCompanion.insert(
            id: 'conv1',
            createdAt: t,
            lastActivityAt: t,
          ),
        );
  }

  /// Full row contents of every table, so "untouched" means identical.
  Future<Map<String, List<Map<String, Object?>>>> snapshotContents() async => {
    for (final table in db.allTables)
      table.actualTableName: [
        for (final row
            in await db
                .customSelect(
                  'SELECT * FROM ${table.actualTableName} ORDER BY rowid',
                )
                .get())
          row.data,
      ],
  };

  /// Every table empty except the re-seeded starter categories, and the
  /// onboarding-seen flag gone — the app's first-launch state.
  Future<void> expectFreshInstall() async {
    for (final table in db.allTables) {
      if (table.actualTableName == db.financeCategories.actualTableName) {
        continue;
      }
      final count = await db
          .customSelect('SELECT COUNT(*) AS c FROM ${table.actualTableName}')
          .getSingle();
      expect(
        count.read<int>('c'),
        0,
        reason: '${table.actualTableName} still has rows',
      );
    }
    final onboarding = OnboardingRepositoryImpl(OnboardingDao(db));
    expect(
      (await onboarding.isOnboardingComplete()).getOrElse((_) => true),
      isFalse,
    );
  }

  /// Makes the table wipe fail inside SQLite after several tables have
  /// already been emptied by the transaction (same technique as 013's
  /// `data_wipe_test.dart`).
  Future<void> forceMidWipeDatabaseFailure() => db.customStatement('''
    CREATE TRIGGER force_wipe_failure BEFORE DELETE ON people
    BEGIN SELECT RAISE(ABORT, 'forced mid-wipe failure'); END;
  ''');
}
