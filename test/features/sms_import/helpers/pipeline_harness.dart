import 'dart:async';

import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_duplicate_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/registry_bank_reference_policy.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_scan_coordinator.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/repositories/sms_import_repository.dart';
import 'package:daftary/features/sms_import/domain/services/bank_reference_policy.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/usecases/add_imported_transaction.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:daftary/features/sms_import/domain/usecases/close_as_duplicate.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_shared_text.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:daftary/features/sms_import/domain/services/shared_text_source.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_daos.dart';
import 'fakes.dart';
import 'review_harness.dart';

/// The whole bank-message pipeline on ONE real in-memory database: the
/// real parser (shipped registry), frozen fingerprint normalizer, HMAC
/// hasher, AES-GCM vault, staging repository, duplicate DAO,
/// `CheckDuplicates`, `AddImportedTransaction`, `CloseAsDuplicate`, and
/// the real transaction and finance repositories. Only the platform edges
/// (inbox gateway, permission, lifecycle, lock, shared-text source) and
/// the settings store are fakes. Used by the US5 scenario suites (T099,
/// T170). Every value is synthetic.
class PipelineHarness {
  PipelineHarness({
    DateTime? now,
    BankReferencePolicy? policy,
    SmsParserRegistry? registry,
    db.AppDatabase? database,
    FakeSmsKeyStore? keys,
  }) : database =
           database ?? db.AppDatabase.forTesting(NativeDatabase.memory()),
       clock = FixedClock(now ?? DateTime(2026, 3, 6, 12)),
       keys = keys ?? FakeSmsKeyStore(),
       policy = policy ?? RegistryBankReferencePolicy() {
    settings = FakeSmsImportSettingsRepository(
      settings: const SmsImportSettings(isEnabled: true),
    );
    finance = FinanceRepositoryImpl(testFinanceDao(this.database));
    transactions = TransactionsRepositoryImpl(
      testTransactionsDao(this.database),
      this.database,
    );
    repository = SmsImportRepositoryImpl(
      SmsImportDao(this.database),
      SmsImportSettingsDao(this.database),
      AesGcmRawTextVault(this.keys),
      const SmsMaskerImpl(),
      this.policy,
      clock,
      transactions,
      finance,
    );
    parser = RuleBasedSmsParser(clock: clock, registry: registry);
    ingestion = SmsIngestionService(
      ParseMessages(parser),
      LoadParserOptions(
        settings,
        CategoryRepositoryImpl(testFinanceDao(this.database)),
        FakePeopleRepository(const []),
      ),
      const FingerprintNormalizerV1(),
      HmacFingerprintHasher(this.keys),
      const SmsMaskerImpl(),
      this.policy,
      repository,
      settings,
      clock,
    );
    paste = ImportPastedText(SmsMessageSplitterImpl(), ingestion);
    shareSource = FakeSharedTextSource();
    lock = FakeLockStatus();
    share = ImportSharedText(shareSource, lock, paste);
    lookup = SmsDuplicateDao(this.database);
    checkDuplicates = CheckDuplicates(lookup, this.policy);
    add = AddImportedTransaction(repository, checkDuplicates);
    closeAsDuplicate = CloseAsDuplicate(repository);
  }

  final db.AppDatabase database;
  final FixedClock clock;
  final FakeSmsKeyStore keys;
  final BankReferencePolicy policy;

  late final FakeSmsImportSettingsRepository settings;
  late final FinanceRepository finance;
  late final TransactionsRepository transactions;
  late final SmsImportRepositoryImpl repository;
  late final RuleBasedSmsParser parser;
  late final SmsIngestionService ingestion;
  late final ImportPastedText paste;
  late final FakeSharedTextSource shareSource;
  late final FakeLockStatus lock;
  late final ImportSharedText share;
  late final SmsDuplicateDao lookup;
  late final CheckDuplicates checkDuplicates;
  late final AddImportedTransaction add;
  late final CloseAsDuplicate closeAsDuplicate;
  final InMemoryScanCoordinator coordinator = InMemoryScanCoordinator();

  /// Seeds the first-launch categories (runs `beforeOpen`).
  Future<void> open() async {
    await database.select(database.financeCategories).get();
  }

  Future<void> close() async {
    unawaited(shareSource.close());
    await lock.close();
    await database.close();
  }

  // ------------------------------------------------------------- entry paths

  /// A user-initiated inbox scan through `RunInboxScan` over [rows].
  Future<ScanSummary> scan(List<InboxSmsMessage> rows) async {
    final gateway = FakeSmsInboxGateway(rows: rows);
    final capability = GetSmsCapability(gateway);
    final result = await RunInboxScan(
      capability,
      GetSmsPermissionStatus(
        capability,
        FakeSmsPermissionService(status: SmsPermissionStatus.granted),
      ),
      settings,
      parser,
      gateway,
      ingestion,
      coordinator,
      FakeLifecycle(),
      clock,
    )(window: ScanWindow.days30, token: ScanCancellationToken());
    return result.getOrElse((f) => fail('scan failed: $f'));
  }

  /// An automatic catch-up page: the same ingestion the catch-up path
  /// runs, with the catch-up source and the stored cursor advanced.
  Future<ScanSummary> catchUp(List<InboxSmsMessage> rows) async {
    final result = await ingestion.ingest(
      messages: [
        for (final row in rows)
          RawIncoming(
            text: row.body,
            sender: row.address,
            receivedAt: row.date,
            providerId: row.id,
          ),
      ],
      source: SmsSource.catchUpScan,
      token: ScanCancellationToken(),
      advanceCursor: true,
    );
    return result.getOrElse((f) => fail('catch-up failed: $f'));
  }

  /// A raw ingestion with a sender (an inbox read without the allow-list,
  /// for the generic phrasing that no shipped sender sends).
  Future<ScanSummary> ingestInbox(
    List<String> bodies, {
    String sender = 'BANKX',
    SmsSource source = SmsSource.inboxScan,
  }) async {
    final at = clock.now().subtract(const Duration(hours: 1));
    final result = await ingestion.ingest(
      messages: [
        for (final body in bodies)
          RawIncoming(text: body, sender: sender, receivedAt: at),
      ],
      source: source,
      token: ScanCancellationToken(),
    );
    return result.getOrElse((f) => fail('ingest failed: $f'));
  }

  /// A paste; a not-recognized paste is returned as an empty result.
  Future<PasteImportResult> pasteText(String text) async {
    final result = await paste(text: text, source: SmsSource.paste);
    return result.getOrElse((f) => fail('paste failed: $f'));
  }

  /// A share through `ImportSharedText` (the cubit's path).
  Future<PasteImportResult> shareText(String text) async {
    final result = await share(SharedText(text: text));
    return result.getOrElse((f) => fail('share failed: $f'));
  }

  // ------------------------------------------------------------------ reads

  Future<List<db.PendingSmsImportRow>> rows() =>
      database.select(database.pendingSmsImports).get();

  Future<List<PendingSmsImport>> pending() async =>
      (await repository.watchPending().first).getOrElse(
        (f) => fail('pending failed: $f'),
      );

  Future<PendingSmsImport> item(String id) async =>
      (await repository.getById(id)).getOrElse((f) => fail('get failed: $f'));

  Future<int> savedRecords() async =>
      (await database.select(database.financeEntries).get()).length +
      (await database.select(database.moneyTransactions).get()).length;

  /// Stages [item] directly (for values no shipped template extracts).
  Future<void> stage(PendingSmsImport item, {String? raw}) async {
    final result = await repository.insertPending(
      NewPendingImport(item: item, rawMasked: raw),
    );
    expect(
      result.getOrElse((Failure f) => fail('stage failed: $f')),
      InsertOutcome.inserted,
    );
  }
}

/// A synthetic inbox row.
InboxSmsMessage inboxRow(
  int id,
  String body, {
  String address = 'NBE',
  DateTime? date,
}) => InboxSmsMessage(
  id: id,
  address: address,
  date: date ?? DateTime(2026, 3, 5, 9).add(Duration(minutes: id)),
  body: body,
);
