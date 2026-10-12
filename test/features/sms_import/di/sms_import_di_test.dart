import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/crypto/secure_storage_sms_key_store.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/platform/sms_platform_module.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_shared_text_source.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/data/platform/unavailable_sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_duplicate_lookup.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_settings_repository.dart';
import 'package:daftary/features/sms_import/domain/services/app_lifecycle_state_source.dart';
import 'package:daftary/features/sms_import/domain/services/bank_reference_policy.dart';
import 'package:daftary/features/sms_import/domain/services/clipboard_reader.dart';
import 'package:daftary/features/sms_import/domain/services/external_activity_runner.dart';
import 'package:daftary/features/sms_import/domain/services/fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/domain/services/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/domain/services/lock_status.dart';
import 'package:daftary/features/sms_import/domain/services/raw_text_vault.dart';
import 'package:daftary/features/sms_import/domain/services/review_lease_registry.dart';
import 'package:daftary/features/sms_import/domain/services/scan_coordinator.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_key_store.dart';
import 'package:daftary/features/sms_import/domain/services/sms_masker.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/domain/services/sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_text_normalizer.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/add_imported_transaction.dart';
import 'package:daftary/features/sms_import/domain/usecases/expire_pending_imports.dart';
import 'package:daftary/features/sms_import/domain/usecases/show_original_message.dart';
import 'package:daftary/features/sms_import/presentation/cubit/bank_messages_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/import_review_cubit.dart';
import 'package:daftary/features/sms_import/presentation/cubit/paste_cubit.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_inbox.dart';
import 'package:daftary/features/sms_import/presentation/shared_text_router.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/read_clipboard_text.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T069 — the generated DI graph resolves every Phase 2 implementation.
/// Construction only: the database is in memory, and nothing touches the
/// keychain or a platform channel (both are used only on a call).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;

  setUp(() async {
    await configureDependencies();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    getIt
      ..unregister<AppDatabase>()
      ..registerSingleton<AppDatabase>(db);
  });

  tearDown(() async {
    await getIt.reset();
    await db.close();
  });

  test('resolves the US1 review graph (T076-T079)', () async {
    expect(getIt<AddImportedTransaction>(), isNotNull);
    expect(getIt<ExpirePendingImports>(), isNotNull);
    expect(getIt<ShowOriginalMessage>(), isNotNull);
    final review = getIt<ImportReviewCubit>();
    final list = getIt<BankMessagesCubit>();
    await review.close();
    await list.close();
  });

  test('resolves the US4 paste and share graph (T088-T098)', () async {
    expect(getIt<ImportPastedText>(), isNotNull);
    expect(getIt<ImportSharedText>(), isNotNull);
    expect(getIt<ReadClipboardText>(), isNotNull);
    expect(getIt<GetSmsCapability>(), isNotNull);
    expect(getIt<SharedTextRouter>(), same(getIt<SharedTextRouter>()));
    expect(getIt<SharedTextInbox>(), same(getIt<SharedTextInbox>()));
    // The host is never Android, so no share target exists here.
    expect(getIt<SharedTextSource>(), isA<UnavailableSharedTextSource>());
    final paste = getIt<PasteCubit>();
    await paste.close();
  });

  test('resolves the bank-message import graph', () {
    expect(getIt<SmsKeyStore>(), isA<SecureStorageSmsKeyStore>());
    expect(getIt<RawTextVault>(), isA<AesGcmRawTextVault>());
    expect(getIt<FingerprintHasher>(), isA<HmacFingerprintHasher>());
    expect(getIt<FingerprintNormalizer>(), isA<FingerprintNormalizerV1>());
    expect(getIt<SmsMessageParser>(), isA<RuleBasedSmsParser>());
    expect(getIt<SmsTextNormalizer>(), isNotNull);
    expect(getIt<SmsMasker>(), isNotNull);
    expect(getIt<SmsMessageSplitter>(), isNotNull);
    expect(getIt<BankReferencePolicy>(), isNotNull);
    expect(getIt<SmsImportRepository>(), isNotNull);
    expect(getIt<SmsImportSettingsRepository>(), isNotNull);
    expect(getIt<SmsDuplicateLookup>(), isNotNull);
    expect(getIt<CheckDuplicates>(), isNotNull);
    expect(getIt<ParseMessages>(), isNotNull);
    expect(getIt<LoadParserOptions>(), isNotNull);
    expect(getIt<SmsIngestionService>(), isNotNull);
    expect(getIt<ClipboardReader>(), isNotNull);
    expect(getIt<ReviewLeaseRegistry>(), isNotNull);
    expect(getIt<LockStatus>(), isNotNull);
    expect(getIt<ExternalActivityRunner>(), isNotNull);
    expect(getIt<AppLifecycleStateSource>(), isNotNull);
    expect(getIt<ScanCoordinator>(), isNotNull);
  });

  test('the host platform gets the Unavailable adapters', () {
    expect(getIt<SmsInboxGateway>(), isA<UnavailableSmsInboxGateway>());
    expect(
      getIt<SmsPermissionService>(),
      isA<UnavailableSmsPermissionService>(),
    );
    expect(getIt<SharedTextSource>(), isA<UnavailableSharedTextSource>());
  });

  test('selectForPlatform picks by the flag only', () {
    expect(
      selectForPlatform(isAndroid: true, android: () => 'a', other: () => 'o'),
      'a',
    );
    expect(
      selectForPlatform(isAndroid: false, android: () => 'a', other: () => 'o'),
      'o',
    );
  });
}
