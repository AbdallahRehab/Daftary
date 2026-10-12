import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/finance/domain/entities/category.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/finance/domain/repositories/category_repository.dart';
import 'package:daftary/features/finance/domain/repositories/finance_repository.dart';
import 'package:daftary/features/people/domain/repositories/people_repository.dart';
import 'package:daftary/features/sms_import/data/crypto/aes_gcm_raw_text_vault.dart';
import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_dao.dart';
import 'package:daftary/features/sms_import/data/datasources/sms_import_settings_dao.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_masker_impl.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_message_splitter.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_repository_impl.dart';
import 'package:daftary/features/sms_import/data/repositories/sms_import_settings_repository_impl.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_confidence.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_ingestion_service.dart';
import 'package:daftary/features/sms_import/domain/usecases/import_pasted_text.dart';
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

class _StrictTransactions extends Mock implements TransactionsRepository {}

class _StrictFinance extends Mock implements FinanceRepository {}

class _MockIngestion extends Mock implements SmsIngestionService {}

// Synthetic messages (paste-fixture phrasing; no real card numbers).
const _purchase =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with card ****0000.';
const _purchase2 =
    'Purchase of EGP 80.00 at Example Bakery on 05/03/2026 09:00 with card ****0000.';
const _otp = 'Your OTP is 482913. Do not share it.';
const _noise = 'Hello, see you tomorrow at the cafe';

/// T088 — `ImportPastedText`: splitter bounds, ingestion with no sender and
/// no receipt time (capped at Medium), not recognized stores nothing.
void main() {
  setUpAll(() {
    registerFallbackValue(SmsSource.paste);
    registerFallbackValue(ScanCancellationToken());
  });

  group('through the real pipeline', () {
    late db.AppDatabase database;
    late SmsImportRepositoryImpl repository;
    late ImportPastedText importPasted;
    var ids = 0;

    setUp(() {
      ids = 0;
      database = db.AppDatabase.forTesting(NativeDatabase.memory());
      final clock = FixedClock(DateTime(2026, 3, 6, 12));
      final keys = FakeSmsKeyStore();
      final categories = _MockCategories();
      final people = _MockPeople();
      when(() => categories.getCategories(type: any(named: 'type'))).thenAnswer(
        (invocation) async => Right([
          Category(
            id: 'seed_other',
            name: 'Other',
            type: invocation.namedArguments[#type] as FinanceEntryType,
            icon: 'other',
            createdAt: DateTime(2026),
            updatedAt: DateTime(2026),
          ),
        ]),
      );
      when(
        () => people.searchActivePeople(),
      ).thenAnswer((_) async => const Right([]));
      final settings = SmsImportSettingsRepositoryImpl(
        SmsImportSettingsDao(database),
        clock,
      );
      repository = SmsImportRepositoryImpl(
        SmsImportDao(database),
        SmsImportSettingsDao(database),
        AesGcmRawTextVault(keys),
        const SmsMaskerImpl(),
        FakeBankReferencePolicy(),
        clock,
        _StrictTransactions(),
        _StrictFinance(),
      );
      final ingestion = SmsIngestionService(
        ParseMessages(RuleBasedSmsParser(clock: clock)),
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
      importPasted = ImportPastedText(SmsMessageSplitterImpl(), ingestion);
    });
    tearDown(() => database.close());

    setUpAll(() => registerFallbackValue(FinanceEntryType.expense));

    Future<List<db.PendingSmsImportRow>> rows() =>
        database.select(database.pendingSmsImports).get();

    test('stages a paste with no sender and no receipt time, at most '
        'Medium', () async {
      final result = await importPasted(
        text: _purchase,
        source: SmsSource.paste,
      );
      final value = result.getOrElse((f) => fail('unexpected $f'));
      expect(value.notRecognized, isFalse);
      expect(value.summary.recognized, 1);
      expect(value.newIds, hasLength(1));

      final row = (await rows()).single;
      expect(row.id, value.newIds.single);
      expect(row.origin, 'paste');
      expect(row.senderId, isNull);
      expect(row.receivedAt, isNull);

      final item = (await repository.getById(
        value.newIds.single,
      )).getOrElse((f) => fail('unexpected $f'));
      expect(item.source, SmsSource.paste);
      expect(item.confidence.overall, isNot(OverallConfidence.high));
    });

    test('a share is staged with the share origin', () async {
      final result = await importPasted(
        text: _purchase,
        source: SmsSource.share,
      );
      expect(result.isRight(), isTrue);
      final row = (await rows()).single;
      expect(row.origin, 'share');
      expect(row.senderId, isNull);
      expect(row.receivedAt, isNull);
    });

    test('an inbox source is treated as a paste (never a trusted '
        'sender)', () async {
      await importPasted(text: _purchase, source: SmsSource.inboxScan);
      expect((await rows()).single.origin, 'paste');
    });

    test('several messages: each recognized one is staged and the summary '
        'counts recognized and skipped', () async {
      final result = await importPasted(
        text: '$_purchase\n\n$_otp\n\n$_purchase2',
        source: SmsSource.paste,
      );
      final value = result.getOrElse((f) => fail('unexpected $f'));
      expect(value.summary.scanned, 3);
      expect(value.summary.recognized, 2);
      expect(value.newIds, hasLength(2));
      expect((await rows()).map((r) => r.id).toSet(), value.newIds.toSet());
    });

    test('not recognized: NotRecognizedFailure and nothing stored', () async {
      final result = await importPasted(
        text: '$_noise\n\n$_otp',
        source: SmsSource.paste,
      );
      expect(
        result,
        const Left<Failure, PasteImportResult>(NotRecognizedFailure()),
      );
      expect(await rows(), isEmpty);
    });

    test('blank text is not recognized and stores nothing', () async {
      final result = await importPasted(
        text: '  \n\n ',
        source: SmsSource.paste,
      );
      expect(
        result,
        const Left<Failure, PasteImportResult>(NotRecognizedFailure()),
      );
      expect(await rows(), isEmpty);
    });

    test('over 10,000 characters: too large, nothing stored', () async {
      final result = await importPasted(
        text: 'a' * 10001,
        source: SmsSource.paste,
      );
      expect(
        result,
        const Left<Failure, PasteImportResult>(
          InputTooLargeFailure(InputLimit.characters),
        ),
      );
      expect(await rows(), isEmpty);
    });

    test('over 50 messages: too large, nothing stored', () async {
      final text = List.filled(51, _purchase).join('\n\n');
      final result = await importPasted(text: text, source: SmsSource.paste);
      expect(
        result,
        const Left<Failure, PasteImportResult>(
          InputTooLargeFailure(InputLimit.messages),
        ),
      );
      expect(await rows(), isEmpty);
    });

    test('pasting the same message twice creates one item', () async {
      await importPasted(text: _purchase, source: SmsSource.paste);
      final again = await importPasted(
        text: _purchase,
        source: SmsSource.share,
      );
      final value = again.getOrElse((f) => fail('unexpected $f'));
      expect(value.newIds, isEmpty);
      expect(value.summary.alreadyKnown, 1);
      expect(await rows(), hasLength(1));
    });
  });

  group('result mapping', () {
    late _MockIngestion ingestion;
    late ImportPastedText importPasted;

    setUp(() {
      ingestion = _MockIngestion();
      importPasted = ImportPastedText(FakeSmsMessageSplitter(), ingestion);
    });

    void stub(ScanSummary summary, {List<String> created = const []}) {
      when(
        () => ingestion.ingest(
          messages: any(named: 'messages'),
          source: any(named: 'source'),
          token: any(named: 'token'),
          onCreated: any(named: 'onCreated'),
        ),
      ).thenAnswer((invocation) async {
        final onCreated =
            invocation.namedArguments[#onCreated]
                as void Function(List<String>)?;
        onCreated?.call(created);
        return Right(summary);
      });
    }

    test('passes every message with no sender and no receipt time', () async {
      stub(ScanSummary(scanned: 2, recognized: 2, createdPending: 2));
      await importPasted(text: 'one\n\ntwo', source: SmsSource.share);
      final captured = verify(
        () => ingestion.ingest(
          messages: captureAny(named: 'messages'),
          source: captureAny(named: 'source'),
          token: any(named: 'token'),
          onCreated: any(named: 'onCreated'),
        ),
      ).captured;
      final messages = captured[0] as List<RawIncoming>;
      expect(messages.map((m) => m.text), ['one', 'two']);
      expect(messages.every((m) => m.sender == null), isTrue);
      expect(messages.every((m) => m.receivedAt == null), isTrue);
      expect(messages.every((m) => m.providerId == null), isTrue);
      expect(captured[1], SmsSource.share);
    });

    test('unreadable only is Right with no new item', () async {
      stub(ScanSummary(scanned: 1, unreadable: 1));
      final result = await importPasted(text: 'x', source: SmsSource.paste);
      final value = result.getOrElse((f) => fail('unexpected $f'));
      expect(value.newIds, isEmpty);
      expect(value.summary.recognized, 0);
    });

    test('the created ids are returned', () async {
      stub(
        ScanSummary(scanned: 1, recognized: 1, createdPending: 1),
        created: ['a'],
      );
      final result = await importPasted(text: 'x', source: SmsSource.paste);
      expect(result.getOrElse((f) => fail('$f')).newIds, ['a']);
    });

    test('a storage failure is passed through', () async {
      when(
        () => ingestion.ingest(
          messages: any(named: 'messages'),
          source: any(named: 'source'),
          token: any(named: 'token'),
          onCreated: any(named: 'onCreated'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('x')));
      final result = await importPasted(text: 'x', source: SmsSource.paste);
      expect(result, const Left<Failure, PasteImportResult>(CacheFailure('x')));
    });

    test('a bound exceeded never reaches ingestion', () async {
      final result = await importPasted(
        text: 'a' * 10001,
        source: SmsSource.paste,
      );
      expect(result.isLeft(), isTrue);
      verifyNever(
        () => ingestion.ingest(
          messages: any(named: 'messages'),
          source: any(named: 'source'),
          token: any(named: 'token'),
          onCreated: any(named: 'onCreated'),
        ),
      );
    });
  });
}
