import 'dart:io';

import 'package:daftary/core/database/app_database.dart' show AppDatabase;
import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/finance/data/repositories/finance_repository_impl.dart';
import 'package:daftary/features/finance/data/datasources/finance_dao.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_audit_sync_mapper.dart';
import 'package:daftary/features/finance/data/sync/finance_entry_sync_mapper.dart';
import 'package:daftary/core/sync/local/sync_outbox.dart';
import 'package:daftary/features/people/data/datasources/people_dao.dart';
import 'package:daftary/features/people/data/repositories/people_repository_impl.dart';
import 'package:daftary/features/people/data/sync/person_sync_mapper.dart';
import 'package:daftary/features/people/domain/usecases/find_possible_duplicate_person.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/crypto/secure_storage_sms_key_store.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/registry_bank_reference_policy.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/platform/in_memory_scan_coordinator.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_capability.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_sender_mute.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/app_lifecycle_state_source.dart';
import 'package:daftary/features/sms_import/domain/services/sms_inbox_gateway.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_permission_service.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_capability.dart';
import 'package:daftary/features/sms_import/domain/usecases/get_sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/run_inbox_scan.dart';
import 'package:daftary/features/transactions/data/datasources/transactions_dao.dart';
import 'package:daftary/features/transactions/data/repositories/transactions_repository_impl.dart';
import 'package:daftary/features/transactions/data/sync/money_transaction_sync_mapper.dart';
import 'package:daftary/features/transactions/data/sync/transaction_audit_sync_mapper.dart';
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';

/// 023 T166 — the SC-005 device benchmark. **Device only, owner-run**: not
/// part of CI. Run in profile mode on the reference device (4 GB RAM or
/// less, released 2022 or later):
///
/// ```sh
/// fvm flutter drive --profile -d DEVICE_ID \
///   --driver=test_driver/screenshot_driver.dart \
///   --target=integration_test/sms_ingest_device_benchmark_test.dart
/// ```
///
/// (`screenshot_driver.dart` is a plain `integrationDriver()` host.) A
/// debug-mode `fvm flutter test` run of this file is only a smoke run: its
/// timing does not count.
/// Record the device, the Android version and the reported time in
/// `specs/023-bank-sms-import/quickstart.md`.
///
/// 500 synthetic inbox messages from allow-listed senders (recognized
/// transactions from every shipped profile, bank noise, and wording no
/// template reads) plus 150 from unknown senders, served by an in-memory
/// gateway. Everything else is real: the shipped parser registry, the
/// frozen fingerprint normalizer, HMAC hashing and AES-GCM sealing with
/// keys in the device's secure storage, and a file-backed SQLite database
/// in the app's documents directory. Asserts ≤ 5 s (SC-005); a miss moves
/// the parse to `compute` per the T154 decision.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late AppDatabase db;
  late SecureStorageSmsKeyStore keys;

  setUp(() async {
    final docs = await getApplicationDocumentsDirectory();
    dir = Directory('${docs.path}/sms_benchmark')..createSync(recursive: true);
    db = AppDatabase.forTesting(NativeDatabase(File('${dir.path}/bench.db')));
    await db.select(db.financeCategories).get();
    keys = SecureStorageSmsKeyStore(storage: const FlutterSecureStorage());
  });

  tearDown(() async {
    await db.close();
    await keys.purge();
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  testWidgets('SC-005: a 500-message scan completes within 5 s', (_) async {
    const clock = SystemAppClock();
    final outbox = DriftSyncOutbox(db, clock);
    final financeDao = FinanceDao(
      db,
      outbox,
      const FinanceCategorySyncMapper(),
      const FinanceEntrySyncMapper(),
      const FinanceEntryAuditSyncMapper(),
    );
    final transactions = TransactionsRepositoryImpl(
      TransactionsDao(
        db,
        outbox,
        const MoneyTransactionSyncMapper(),
        const TransactionAuditSyncMapper(),
      ),
      db,
    );
    final policy = RegistryBankReferencePolicy();
    final settings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(db),
      clock,
    );
    expect((await settings.setEnabled(true)).isRight(), isTrue);
    final repository = SmsImportRepositoryImpl(
      SmsImportDao(db),
      SmsImportSettingsDao(db),
      AesGcmRawTextVault(keys),
      const SmsMaskerImpl(),
      policy,
      clock,
      transactions,
      FinanceRepositoryImpl(financeDao),
    );
    final parser = RuleBasedSmsParser(clock: clock);
    final ingestion = SmsIngestionService(
      ParseMessages(parser),
      LoadParserOptions(
        settings,
        CategoryRepositoryImpl(financeDao),
        PeopleRepositoryImpl(
          PeopleDao(db, outbox, const PersonSyncMapper()),
          const FindPossibleDuplicatePerson(),
          db,
        ),
      ),
      const FingerprintNormalizerV1(),
      HmacFingerprintHasher(keys),
      const SmsMaskerImpl(),
      policy,
      repository,
      settings,
      clock,
    );
    final gateway = _BenchGateway(_inbox(clock.now()));
    final capability = GetSmsCapability(gateway);
    final scan = RunInboxScan(
      capability,
      GetSmsPermissionStatus(capability, _GrantedPermission()),
      settings,
      parser,
      gateway,
      ingestion,
      InMemoryScanCoordinator(),
      _Resumed(),
      clock,
    );

    // Warm the keys (first-use key generation is not part of a scan).
    await keys.encKey();
    await keys.macKey();

    final stopwatch = Stopwatch()..start();
    final result = await scan(
      window: ScanWindow.days30,
      token: ScanCancellationToken(),
    );
    stopwatch.stop();

    final summary = result.getOrElse((f) => fail('scan failed: $f'));
    expect(summary.scanned, 500);
    expect(summary.cancelled, isFalse);
    expect(summary.createdPending, greaterThan(250));
    // ignore: avoid_print
    print(
      'SC-005 device benchmark: 500 messages in '
      '${stopwatch.elapsedMilliseconds} ms '
      '(${summary.createdPending} staged, ${summary.nonTransactional} noise, '
      '${summary.unreadable} unreadable)',
    );
    expect(stopwatch.elapsed, lessThanOrEqualTo(const Duration(seconds: 5)));
  });
}

// ---------------------------------------------------------------------------
// Synthetic inbox (modeled on the synthetic corpus; invented names, no real
// card numbers, phone numbers or references).
// ---------------------------------------------------------------------------

const List<(String, String)> _templates = [
  (
    'NBE',
    'NBE: Your card ending 4821 was charged EGP {amt} at Example Market on '
        '{date} at 14:30. Available balance EGP 3,200.00',
  ),
  (
    'NBE',
    'NBE: Bill payment of EGP {amt} to Example Electricity was debited from '
        'your account ****4821 on {date}.',
  ),
  (
    'NBE',
    'NBE: Transfer of EGP {amt} to Ahmed Example from your account ****4821 '
        'on {date}.',
  ),
  (
    'CIB',
    'CIB: Purchase transaction of EGP {amt} on your credit card ending 2290 '
        'at Example Restaurant on {date} 21:40.',
  ),
  (
    'CIB',
    'CIB: Incoming transfer of EGP {amt} to account ****2290 from Tarek '
        'Example on {date}.',
  ),
  (
    'QNB',
    'QNB ALAHLI: Card XXXX5521 purchase EGP {amt} at Example Coffee on {date} '
        '08:15. Avl bal EGP 1,020.00',
  ),
  (
    'AAIB',
    'AAIB: Debit card purchase EGP {amt} card ending 3318 at Example Market '
        'on {date} 11:45.',
  ),
  (
    'BDC',
    'Banque du Caire: EGP {amt} purchase made with your card ****6650 at '
        'Example Grocery on {date} 18:25.',
  ),
  (
    'BANQUEMISR',
    'Banque Misr: Your salary of EGP {amt} has been credited to your account '
        '**7310 on {date}.',
  ),
  (
    'INSTAPAY',
    'InstaPay: You have received EGP {amt} from Mona Example on {date} at '
        '12:10.',
  ),
];

const List<(String, String)> _noise = [
  (
    'NBE',
    'NBE: Your OTP for the purchase of EGP 250.00 at Example Store is '
        '482913. Do not share it with anyone.',
  ),
  (
    'NBE',
    'NBE: Enjoy 20% cashback at Example Store until the end of the month. '
        'Visit www.example.com for details',
  ),
  ('CIB', 'CIB: Dear customer, your e-statement is now available.'),
];

String _two(int v) => v.toString().padLeft(2, '0');

List<InboxSmsMessage> _inbox(DateTime now) {
  final rows = <InboxSmsMessage>[];
  for (var i = 0; i < 500; i++) {
    final at = now.subtract(Duration(days: 1 + i % 25, minutes: i));
    final date = '${_two(at.day)}/${_two(at.month)}/${at.year}';
    final (sender, body) = i % 8 == 7
        ? _noise[i % _noise.length]
        : _templates[i % _templates.length];
    final amount =
        '${1 + i % 900},${(i * 7 % 1000).toString().padLeft(3, '0')}'
        '.${_two(i % 100)}';
    rows.add(
      InboxSmsMessage(
        id: i + 1,
        address: sender,
        date: at,
        body:
            '${body.replaceFirst('{amt}', amount).replaceFirst('{date}', date)}'
            '${i % 8 == 7 ? ' #$i' : ''}',
      ),
    );
  }
  for (var i = 0; i < 150; i++) {
    rows.add(
      InboxSmsMessage(
        id: 1000 + i,
        address: i.isEven ? 'EXAMPLESHOP' : 'Vodafone',
        date: now.subtract(Duration(days: 1 + i % 25, minutes: i, seconds: 30)),
        body: 'Your order of EGP ${100 + i}.00 has shipped.',
      ),
    );
  }
  return rows;
}

/// Serves [rows] the way the platform query does: allow-listed senders,
/// strictly after the `(date, id)` cursor, ascending, at most `limit`.
class _BenchGateway implements SmsInboxGateway {
  _BenchGateway(this.rows);

  final List<InboxSmsMessage> rows;

  @override
  Future<SmsCapability> getCapability() async =>
      const SmsCapability(readSmsDeclared: true, isAndroid: true);

  @override
  Future<Either<Failure, List<InboxSmsMessage>>> queryInbox({
    required List<String> senders,
    required DateTime afterDate,
    int? afterId,
    int limit = 200,
  }) async {
    final allowed = senders.map(canonicalSmsSenderId).toSet();
    final page =
        rows
            .where((m) => allowed.contains(canonicalSmsSenderId(m.address)))
            .where((m) {
              final cmp = m.date.compareTo(afterDate);
              if (cmp != 0) return cmp > 0;
              return afterId != null && m.id > afterId;
            })
            .toList()
          ..sort((a, b) {
            final byDate = a.date.compareTo(b.date);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    return Right(page.take(limit).toList());
  }
}

class _GrantedPermission implements SmsPermissionService {
  @override
  Future<Either<Failure, SmsPermissionStatus>> getStatus() async =>
      const Right(SmsPermissionStatus.granted);

  @override
  Future<Either<Failure, SmsPermissionStatus>> request({
    required bool previouslyRequested,
  }) async => const Right(SmsPermissionStatus.granted);

  @override
  Future<Either<Failure, Unit>> openAppInfo() async => const Right(unit);
}

class _Resumed implements AppLifecycleStateSource {
  @override
  bool get isResumed => true;
}
