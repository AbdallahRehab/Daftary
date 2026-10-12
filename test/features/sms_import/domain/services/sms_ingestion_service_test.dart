import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/di/injection.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/people/domain/entities/person.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/services/sms_key_store.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/transactions/domain/repositories/transactions_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';

class _MockCategories extends Mock implements CategoryRepository {}

class _MockPeople extends Mock implements PeopleRepository {}

/// Strict: every call is recorded and any unstubbed call fails the test.
class _StrictTransactions extends Mock implements TransactionsRepository {}

class _StrictFinance extends Mock implements FinanceRepository {}

/// A parser that throws for one hostile text (FR-098 isolation).
class _ThrowingParser implements SmsMessageParser {
  _ThrowingParser(this._inner, this._hostile);

  final SmsMessageParser _inner;
  final String _hostile;

  @override
  Map<String, int> get currentVersions => _inner.currentVersions;

  @override
  Set<String> get allowedSenders => _inner.allowedSenders;

  @override
  ParseResult parse(
    SmsParseInput input, {
    ParserOptions options = const ParserOptions(),
  }) {
    if (input.rawText == _hostile) throw StateError('boom');
    return _inner.parse(input, options: options);
  }
}

// Synthetic messages (the paste fixtures' phrasing).
const _purchase =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with card ****0000.';
const _purchaseWithFee =
    'Purchase of USD 20.00 at Example Online Store. Foreign transaction fee USD 0.50';
const _otp = 'Your OTP is 482913. Do not share it.';
const _noise = 'Hello, see you tomorrow at the cafe';
const _hostile = 'Purchase of EGP 1.00 at Hostile Shop on 04/03/2026';

void main() {
  late db.AppDatabase database;
  late FixedClock clock;
  late _MockCategories categories;
  late _MockPeople people;
  late SmsImportSettingsRepositoryImpl settings;
  late SmsIngestionService service;
  late SmsMessageParser parser;
  var ids = 0;

  SmsIngestionService build(SmsMessageParser parser, SmsKeyStore keys) {
    final repository = SmsImportRepositoryImpl(
      SmsImportDao(database),
      SmsImportSettingsDao(database),
      AesGcmRawTextVault(keys),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      clock,
      // Strict mocks: ingestion must never reach the money write paths.
      _StrictTransactions(),
      _StrictFinance(),
    );
    return SmsIngestionService(
      ParseMessages(parser),
      LoadParserOptions(settings, categories, people),
      const FingerprintNormalizerV1(),
      HmacFingerprintHasher(keys),
      const SmsMaskerImpl(),
      FakeBankReferencePolicy(),
      repository,
      settings,
      clock,
      newId: () => 'id-${ids++}',
    );
  }

  setUp(() {
    ids = 0;
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    clock = FixedClock(DateTime(2026, 3, 4, 12));
    categories = _MockCategories();
    people = _MockPeople();
    when(() => categories.getCategories(type: any(named: 'type'))).thenAnswer(
      (invocation) async => Right([
        Category(
          id: invocation.namedArguments[#type] == FinanceEntryType.expense
              ? 'seed_other'
              : 'seed_other_income',
          name: 'Other',
          type: invocation.namedArguments[#type] as FinanceEntryType,
          icon: 'other',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
    );
    when(() => people.searchActivePeople()).thenAnswer(
      (_) async => Right([
        Person(
          id: 'person-1',
          name: 'Example Person',
          isArchived: false,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]),
    );
    settings = SmsImportSettingsRepositoryImpl(
      SmsImportSettingsDao(database),
      clock,
    );
    parser = RuleBasedSmsParser(clock: clock);
    service = build(parser, FakeSmsKeyStore());
  });
  tearDown(() => database.close());

  setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

  Future<ScanSummary> ingest(
    List<String> texts, {
    SmsSource source = SmsSource.paste,
    ScanCancellationToken? token,
    SmsIngestionService? using,
  }) async {
    final result = await (using ?? service).ingest(
      messages: [for (final text in texts) RawIncoming(text: text)],
      source: source,
      token: token ?? ScanCancellationToken(),
    );
    return result.getOrElse((f) => fail('unexpected $f'));
  }

  Future<List<db.PendingSmsImportRow>> rows() =>
      database.select(database.pendingSmsImports).get();

  test('stages a recognized message as one pending row', () async {
    final summary = await ingest([_purchase]);
    expect(summary.recognized, 1);
    expect(summary.createdPending, 1);
    final row = (await rows()).single;
    expect(row.status, 'pending');
    expect(row.origin, 'paste');
    expect(row.senderId, isNull);
    expect(row.amountMinorUnits, 12550);
    expect(row.rawBlob, isNotNull);
    expect(row.fingerprint, hasLength(64));
  });

  test(
    'non-transactional, not recognized and unreadable store nothing',
    () async {
      final summary = await ingest([_otp, _noise, '']);
      expect(await rows(), isEmpty);
      expect(summary.createdPending, 0);
      expect(summary.nonTransactional + summary.unreadable, greaterThan(0));
      expect(summary.skipped.every((s) => s.reason.name.isNotEmpty), isTrue);
    },
  );

  test('one hostile message never stops the batch (FR-098)', () async {
    final hostileService = build(
      _ThrowingParser(parser, _hostile),
      FakeSmsKeyStore(),
    );
    final summary = await ingest([_hostile, _purchase], using: hostileService);
    expect(summary.unreadable, 1);
    expect(summary.skipped.single.reason, SkipReason.parserError);
    expect(summary.createdPending, 1);
    expect((await rows()).single.merchant, 'Example Cafe');
  });

  test('re-ingesting is idempotent across paste, share and scan', () async {
    await ingest([_purchase]);
    final again = await ingest([_purchase], source: SmsSource.share);
    expect(again.createdPending, 0);
    expect(again.alreadyKnown, 1);
    final scan = await service.ingest(
      messages: [
        RawIncoming(
          text: _purchase,
          sender: 'BANKX',
          receivedAt: DateTime(2026, 3, 4, 10, 16),
          providerId: 7,
        ),
      ],
      source: SmsSource.inboxScan,
      token: ScanCancellationToken(),
    );
    expect(scan.getOrElse((f) => fail('$f')).alreadyKnown, 1);
    expect(await rows(), hasLength(1));
  });

  test('an in-message fee is a second item linked to its parent', () async {
    final summary = await ingest([_purchaseWithFee]);
    expect(summary.createdPending, 2);
    final all = await rows();
    final parent = all.singleWhere((r) => r.parentImportId == null);
    final fee = all.singleWhere((r) => r.parentImportId != null);
    expect(fee.parentImportId, parent.id);
    expect(fee.kind, 'fee');
    expect(fee.amountMinorUnits, 50);
    expect(fee.currencyCode, 'USD');
    expect(fee.refHash, isNull);
    expect(fee.fingerprint, isNot(parent.fingerprint));
    expect(fee.suggestedCategoryId, 'seed_other');

    final again = await ingest([_purchaseWithFee]);
    expect(again.createdPending, 0);
    expect(await rows(), hasLength(2));
  });

  test('cancel between messages keeps the items already created', () async {
    final token = ScanCancellationToken();
    var seen = 0;
    final result = await service.ingest(
      messages: const [
        RawIncoming(text: _purchase),
        RawIncoming(text: _purchaseWithFee),
      ],
      source: SmsSource.paste,
      token: token,
      onProgress: (_) {
        if (++seen == 1) token.cancel();
      },
    );
    final summary = result.getOrElse((f) => fail('$f'));
    expect(summary.cancelled, isTrue);
    expect(summary.processedBeforeInterruption, 1);
    expect(summary.createdPending, 1);
    expect(await rows(), hasLength(1));

    final resumed = await ingest([_purchase, _purchaseWithFee]);
    expect(resumed.createdPending, 2);
    expect(resumed.alreadyKnown, 1);
  });

  test('muted senders are skipped on scans', () async {
    await settings.muteSender('BANKX');
    final result = await service.ingest(
      messages: [RawIncoming(text: _purchase, sender: 'bankx')],
      source: SmsSource.inboxScan,
      token: ScanCancellationToken(),
    );
    final summary = result.getOrElse((f) => fail('$f'));
    expect(summary.mutedSkipped, 1);
    expect(await rows(), isEmpty);
  });

  test('a scan page advances the cursor and the counters', () async {
    final result = await service.ingest(
      messages: [
        RawIncoming(
          text: _purchase,
          sender: 'BANKX',
          receivedAt: DateTime(2026, 3, 4, 10, 16),
          providerId: 7,
        ),
        RawIncoming(
          text: _otp,
          sender: 'BANKX',
          receivedAt: DateTime(2026, 3, 4, 11),
          providerId: 9,
        ),
      ],
      source: SmsSource.inboxScan,
      token: ScanCancellationToken(),
      advanceCursor: true,
    );
    expect(result.isRight(), isTrue);
    final stored = (await settings.getSettings()).getOrElse((f) => fail('$f'));
    expect(stored.cursorDate, DateTime(2026, 3, 4, 11));
    expect(stored.cursorId, 9);
    expect(stored.scannedCount, 2);
    expect(stored.recognizedCount, 1);
    expect((await rows()).single.senderId, 'BANKX');
  });

  test('a lost MAC key stores nothing and says so without content', () async {
    final broken = FakeSmsKeyStore()..throwOnAccess = true;
    final result = await build(parser, broken).ingest(
      messages: const [RawIncoming(text: _purchase)],
      source: SmsSource.paste,
      token: ScanCancellationToken(),
    );
    final failure = result.getLeft().toNullable();
    expect(failure, isA<CacheFailure>());
    expect(failure!.message, isNot(contains('Example')));
    expect(await rows(), isEmpty);
  });

  test('never touches the record tables (FR-022)', () async {
    await ingest([_purchase, _purchaseWithFee]);
    expect(await database.select(database.moneyTransactions).get(), isEmpty);
    expect(await database.select(database.financeEntries).get(), isEmpty);
  });

  group('invariant 1 through the DI graph (SC-002)', () {
    late _StrictTransactions transactions;
    late _StrictFinance finance;
    late db.AppDatabase graphDb;

    setUp(() async {
      await configureDependencies();
      graphDb = db.AppDatabase.forTesting(NativeDatabase.memory());
      transactions = _StrictTransactions();
      finance = _StrictFinance();
      getIt
        ..unregister<db.AppDatabase>()
        ..registerSingleton<db.AppDatabase>(graphDb)
        ..unregister<TransactionsRepository>()
        ..registerSingleton<TransactionsRepository>(transactions)
        ..unregister<FinanceRepository>()
        ..registerSingleton<FinanceRepository>(finance)
        ..unregister<SmsKeyStore>()
        ..registerSingleton<SmsKeyStore>(FakeSmsKeyStore());
    });

    tearDown(() async {
      await getIt.reset();
      await graphDb.close();
    });

    test('ingestion makes zero calls to the record repositories', () async {
      final graphService = getIt<SmsIngestionService>();
      final result = await graphService.ingest(
        messages: const [
          RawIncoming(text: _purchase),
          RawIncoming(text: _purchaseWithFee),
          RawIncoming(text: _otp),
        ],
        source: SmsSource.paste,
        token: ScanCancellationToken(),
      );
      expect(result.getOrElse((f) => fail('$f')).createdPending, 3);
      verifyZeroInteractions(transactions);
      verifyZeroInteractions(finance);
      expect(await graphDb.select(graphDb.moneyTransactions).get(), isEmpty);
      expect(await graphDb.select(graphDb.financeEntries).get(), isEmpty);
      expect(
        await graphDb.select(graphDb.pendingSmsImports).get(),
        hasLength(3),
      );
    });
  });
}
