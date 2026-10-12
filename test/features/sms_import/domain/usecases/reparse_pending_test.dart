import 'dart:convert';
import 'dart:typed_data';

import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/finance/data/repositories/category_repository_impl.dart';
import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/rule_based_sms_parser.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:daftary/features/sms_import/domain/usecases/load_parser_options.dart';
import 'package:daftary/features/sms_import/domain/usecases/parse_messages.dart';
import 'package:daftary/features/sms_import/domain/usecases/reparse_pending.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../helpers/test_daos.dart';
import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';
import '../../helpers/pipeline_harness.dart';
import '../../helpers/review_harness.dart';

class _FixedOptions extends Fake implements LoadParserOptions {
  int calls = 0;

  @override
  Future<Either<Failure, ParserOptions>> call() async {
    calls++;
    return const Right(ParserOptions(countCashWithdrawals: true));
  }
}

/// A parse of the re-read text by the "new" nbe@2 rules.
ParsedTransaction _parsed({
  String bankId = 'nbe',
  Money? amount = const Money.egp(12550),
  List<int> candidates = const [],
  String merchant = 'Example Cafe Updated',
  String? cardLast4 = '4821',
}) => ParsedTransaction(
  bankId: bankId,
  parserId: bankId,
  ruleVersion: '$bankId@2',
  kind: SmsKind.cardPurchase,
  direction: SmsDirection.debit,
  suggestedType: SuggestedRecordType.expense,
  confidence: highConfidence(),
  amount: amount,
  amountCandidatesMinor: candidates,
  merchant: merchant,
  merchantKey: 'example cafe updated',
  cardLast4: cardLast4,
  referenceId: '998877',
  occurredOn: DateTime(2026, 3, 4),
  suggestedCategoryKeyOrId: 'seed_rent',
);

/// T127 — `ReparsePending` (FR-026, research Decisions 7 and 8) against
/// fakes, `SmsImportRepositoryImpl.replaceParsedFields` against a real
/// database, and the whole re-parse over the real pipeline with a rule
/// version bump. Every value is synthetic.
void main() {
  group('ReparsePending (fakes)', () {
    late FixedClock clock;
    late FakeSmsImportRepository repository;
    late FakeSmsImportSettingsRepository settings;
    late FakeSmsMessageParser parser;
    late FakeReviewLeaseRegistry leases;
    late _FixedOptions options;
    late ReparsePending reparse;

    const text = 'NBE purchase EGP 125.50 at Example Cafe card ****4821';

    setUp(() {
      clock = FixedClock(DateTime(2026, 3, 4, 12));
      repository = FakeSmsImportRepository(clock: clock);
      settings = FakeSmsImportSettingsRepository(
        settings: const SmsImportSettings(rulesSeen: {'nbe': 1}),
      );
      parser = FakeSmsMessageParser(
        currentVersions: const {'nbe': 2},
        results: {text: _parsed()},
      );
      leases = FakeReviewLeaseRegistry();
      options = _FixedOptions();
      reparse = ReparsePending(
        repository,
        settings,
        parser,
        ParseMessages(parser),
        options,
        leases,
      );
    });

    void seed(PendingSmsImport item, {String? raw = text}) {
      repository.seed([item]);
      repository.blobs[item.id] = raw == null
          ? null
          : Uint8List.fromList(utf8.encode(raw));
    }

    test('does nothing when the rule versions match rulesSeen', () async {
      parser.currentVersions
        ..clear()
        ..['nbe'] = 1;
      seed(buildPendingImport());

      expect(await reparse(), const Right<Failure, int>(0));
      expect(parser.inputs, isEmpty);
      expect(repository.replacedFields, isEmpty);
      expect(options.calls, 0);
    });

    test('re-parses an out-of-date item with its own source, sender and '
        'receipt time, then updates rulesSeen', () async {
      final receivedAt = DateTime(2026, 3, 4, 9, 30);
      seed(
        buildPendingImport(
          source: SmsSource.catchUpScan,
          senderId: 'NBE',
        ).withReceivedAt(receivedAt),
      );

      expect(await reparse(), const Right<Failure, int>(1));

      final input = parser.inputs.single;
      expect(input.rawText, text);
      expect(input.source, SmsSource.catchUpScan);
      expect(input.sender, 'NBE');
      expect(input.receivedAt, receivedAt);
      expect(parser.optionsSeen.single.countCashWithdrawals, isTrue);

      final fields = repository.replacedFields['pending-1']!;
      expect(fields.ruleVersion, 'nbe@2');
      expect(fields.merchant, 'Example Cafe Updated');
      expect(fields.amount, const Money.egp(12550));
      expect(fields.suggestedCategoryId, 'seed_rent');
      expect(settings.settings.rulesSeen, {'nbe': 2});
    });

    test('skips an item open in a review and keeps rulesSeen, so it is '
        'retried once the review closes', () async {
      seed(buildPendingImport());
      final lease = leases.acquire('pending-1');

      expect(await reparse(), const Right<Failure, int>(0));
      expect(repository.replacedFields, isEmpty);
      expect(parser.inputs, isEmpty);
      expect(settings.settings.rulesSeen, {'nbe': 1});

      lease.release();
      expect(await reparse(), const Right<Failure, int>(1));
      expect(repository.replacedFields.keys, ['pending-1']);
      expect(settings.settings.rulesSeen, {'nbe': 2});
    });

    test('an item whose original cannot be opened keeps its fields', () async {
      seed(buildPendingImport(hasRawText: false), raw: null);

      expect(await reparse(), const Right<Failure, int>(0));
      expect(repository.replacedFields, isEmpty);
      expect(settings.settings.rulesSeen, {'nbe': 2});
    });

    test('a masked amount is unreadable, never a different value', () async {
      const masked = 'NBE purchase EGP •••• •••••••5678 at Example Cafe';
      parser.results[masked] = _parsed(amount: const Money.egp(567800));
      seed(buildPendingImport(), raw: masked);

      expect(await reparse(), const Right<Failure, int>(0));
      expect(repository.replacedFields, isEmpty);
    });

    test(
      'a masked card does not block a re-parse that keeps the amount',
      () async {
        const masked = 'NBE purchase EGP 125.50 card ••••••••••••4821';
        parser.results[masked] = _parsed();
        seed(buildPendingImport(), raw: masked);

        expect(await reparse(), const Right<Failure, int>(1));
      },
    );

    for (final (name, result) in <(String, ParseResult)>[
      ('unreadable', const Unreadable(UnreadableReason.noAmount)),
      ('not recognized', const NotRecognized()),
      ('non-transactional', const NonTransactional(NonTransactionalReason.otp)),
      ('without any amount', _parsed(amount: null)),
      ('from another bank', _parsed(bankId: 'cib')),
    ]) {
      test('a re-parse $name keeps the stored fields', () async {
        parser.results[text] = result;
        seed(buildPendingImport());

        expect(await reparse(), const Right<Failure, int>(0));
        expect(repository.replacedFields, isEmpty);
        expect(settings.settings.rulesSeen, {'nbe': 2});
      });
    }

    test('an amount with candidates only is still re-parsed', () async {
      parser.results[text] = _parsed(amount: null, candidates: [100, 200]);
      seed(buildPendingImport());
      expect(await reparse(), const Right<Failure, int>(1));
    });

    test('a fee item split from its parent keeps its fields', () async {
      seed(buildPendingImport(parentImportId: 'parent-1', kind: SmsKind.fee));
      expect(await reparse(), const Right<Failure, int>(0));
      expect(repository.replacedFields, isEmpty);
    });

    test('decided items are never re-parsed', () async {
      seed(
        pendingWithDecision(
          buildPendingImport(),
          status: SmsImportStatus.ignored,
          decidedAt: clock.now(),
        ),
      );
      expect(await reparse(), const Right<Failure, int>(0));
      expect(parser.inputs, isEmpty);
    });

    test(
      'a settings read failure is passed on and nothing is parsed',
      () async {
        final failing = _FailingSettings();
        final result = await ReparsePending(
          repository,
          failing,
          parser,
          ParseMessages(parser),
          options,
          leases,
        )();
        expect(result.isLeft(), isTrue);
        expect(parser.inputs, isEmpty);
      },
    );
  });

  group('replaceParsedFields (real database)', () {
    late PipelineHarness h;

    setUp(() async {
      h = PipelineHarness(now: DateTime(2026, 3, 4, 12));
      await h.open();
    });
    tearDown(() => h.close());

    ReparsedFields fields({String? cardLast4 = '4821'}) => ReparsedFields(
      parserId: 'nbe',
      ruleVersion: 'nbe@2',
      kind: SmsKind.atmWithdrawal,
      direction: SmsDirection.debit,
      suggestedType: SuggestedRecordType.expense,
      confidence: highConfidence(),
      amount: const Money.egp(99900),
      occurredOn: DateTime(2026, 3, 3),
      timeMinutes: 60,
      merchant: 'New Merchant',
      merchantKey: 'new merchant',
      cardLast4: cardLast4,
      warnings: const {SmsWarning.atmIgnoredByDefault},
    );

    test('replaces only the parsed-field columns; hashes and identity '
        'never change', () async {
      await h.stage(
        buildPendingImport(
          refHash: 'ref-1',
          refAmountHash: 'ra-1',
        ).withReceivedAt(DateTime(2026, 3, 4, 9)),
        raw: 'NBE purchase EGP 125.50 at Example Cafe',
      );
      final before = (await h.rows()).single;

      final result = await h.repository.replaceParsedFields(
        'pending-1',
        fields(),
      );
      expect(result, const Right<Failure, Unit>(unit));

      final after = (await h.rows()).single;
      // Immutable.
      expect(after.fingerprint, before.fingerprint);
      expect(after.refHash, 'ref-1');
      expect(after.refAmountHash, 'ra-1');
      expect(after.receivedAt, before.receivedAt);
      expect(after.origin, before.origin);
      expect(after.senderId, before.senderId);
      expect(after.bankId, before.bankId);
      expect(after.createdAt, before.createdAt);
      expect(after.expiresAt, before.expiresAt);
      expect(after.status, 'pending');
      expect(after.rawBlob, before.rawBlob);
      // Replaced.
      expect(after.ruleVersion, 'nbe@2');
      expect(after.kind, SmsKind.atmWithdrawal.dbValue);
      expect(after.amountMinorUnits, 99900);
      expect(after.merchant, 'New Merchant');
      expect(after.timeMinutes, 60);
      expect((await h.item('pending-1')).warnings, {
        SmsWarning.atmIgnoredByDefault,
      });
    });

    test('refuses a decided item and writes nothing', () async {
      await h.stage(buildPendingImport(), raw: 'text');
      await h.repository.ignore({'pending-1'});
      final before = (await h.rows()).single;

      final result = await h.repository.replaceParsedFields(
        'pending-1',
        fields(),
      );
      expect(
        result,
        const Left<Failure, Unit>(
          ImportAlreadyDecidedFailure(SmsImportStatus.ignored),
        ),
      );
      expect((await h.rows()).single, before);
    });

    test('refuses fields that break an entity rule, content-free', () async {
      await h.stage(buildPendingImport(), raw: 'text');
      final before = (await h.rows()).single;

      final result = await h.repository.replaceParsedFields(
        'pending-1',
        fields(cardLast4: '48210'),
      );
      final failure = result.getLeft().toNullable()!;
      expect(failure, isA<ValidationFailure>());
      expect(failure.message, isNot(matches(RegExp('[0-9]'))));
      expect((await h.rows()).single, before);
    });

    test('a missing id is content-free NotFound', () async {
      final failure = (await h.repository.replaceParsedFields(
        'missing',
        fields(),
      )).getLeft().toNullable()!;
      expect(failure, isA<NotFoundFailure>());
    });
  });

  group('the whole re-parse after a rule update (real pipeline)', () {
    late PipelineHarness h;

    setUp(() async {
      h = PipelineHarness(now: DateTime(2026, 3, 6, 12));
      await h.open();
    });
    tearDown(() => h.close());

    ReparsePending reparseWith(SmsParserRegistry registry) {
      final parser = RuleBasedSmsParser(clock: h.clock, registry: registry);
      return ReparsePending(
        h.repository,
        h.settings,
        parser,
        ParseMessages(parser),
        LoadParserOptions(
          h.settings,
          CategoryRepositoryImpl(testFinanceDao(h.database)),
          FakePeopleRepository(const []),
        ),
        FakeReviewLeaseRegistry(),
      );
    }

    test('a staged NBE item gets the new rule version; its fingerprint and '
        'hashes stay; no record is created', () async {
      const nbe =
          'NBE: Your card ending 4821 was charged EGP 250.00 at Example '
          'Market on 05/03/2026 at 14:30. Available balance EGP 3,200.00';
      await h.scan([inboxRow(1, nbe)]);
      final before = (await h.rows()).single;
      expect(before.ruleVersion, 'nbe@1');
      await h.settings.setRulesSeen(h.parser.currentVersions);

      final result = await reparseWith(_bumped())();

      expect(result, const Right<Failure, int>(1));
      final after = (await h.rows()).single;
      expect(after.ruleVersion, 'nbe@2');
      expect(after.fingerprint, before.fingerprint);
      expect(after.refHash, before.refHash);
      expect(after.refAmountHash, before.refAmountHash);
      expect(after.amountMinorUnits, before.amountMinorUnits);
      expect(after.rawBlob, isNotNull);
      expect(h.settings.settings.rulesSeen['nbe'], 2);
      expect(await h.savedRecords(), 0);
    });

    test('an amount merged into a masked run re-parses as unreadable and '
        'the stored amount is kept', () async {
      // `EGP 1500 998877665544`: the space joins the amount and a long
      // reference into one run of 16 digits, which the masker masks (research
      // Decision 7). The item was staged from the unmasked text.
      await h.stage(
        buildPendingImport(amount: const Money.egp(150000)),
        raw:
            'NBE: Your card ending 4821 was charged EGP 1500 998877665544 at '
            'Example Market on 05/03/2026.',
      );
      final original = (await h.repository.openOriginal(
        'pending-1',
      )).getOrElse((f) => fail('$f'));
      expect(original, contains('•'));
      expect(original, isNot(contains('1500')));

      final result = await reparseWith(_bumped())();

      expect(result, const Right<Failure, int>(0));
      final after = (await h.rows()).single;
      expect(after.amountMinorUnits, 150000);
      expect(after.ruleVersion, 'nbe@1');
    });

    test(
      'after key loss the item keeps its fields (FR-026, FR-074a)',
      () async {
        await h.stage(buildPendingImport(), raw: 'NBE purchase text');
        await h.keys.purge(); // the old key is gone
        final before = (await h.rows()).single;

        final result = await reparseWith(_bumped())();

        expect(result, const Right<Failure, int>(0));
        final after = (await h.rows()).single;
        expect(after.ruleVersion, before.ruleVersion);
        expect(after.merchant, before.merchant);
        expect(after.amountMinorUnits, before.amountMinorUnits);
        // The unreadable original was purged on the failed open.
        expect(after.rawBlob, isNull);
      },
    );
  });
}

class _FailingSettings extends FakeSmsImportSettingsRepository {
  @override
  Future<Either<Failure, SmsImportSettings>> getSettings() async =>
      const Left(CacheFailure('sms_settings_store_failed'));
}

/// The shipped registry with every rule version bumped by one.
SmsParserRegistry _bumped() {
  BankProfile bump(BankProfile p) => BankProfile(
    id: p.id,
    version: p.version + 1,
    senders: p.senders,
    signatures: p.signatures,
    templates: p.templates,
    nonTransactionalRules: p.nonTransactionalRules,
    merchantKeywordRules: p.merchantKeywordRules,
    ownAccountKeywords: p.ownAccountKeywords,
    cardSettlementKeywords: p.cardSettlementKeywords,
    messageStart: p.messageStart,
    maskThreshold: p.maskThreshold,
    defaultCurrency: p.defaultCurrency,
    dateOrder: p.dateOrder,
    isGeneric: p.isGeneric,
    refIsUnique: p.refIsUnique,
    verified: p.verified,
  );
  final standard = SmsParserRegistry.standard;
  return SmsParserRegistry(
    profiles: [for (final p in standard.profiles) bump(p)],
    generic: bump(standard.generic),
  );
}

extension on PendingSmsImport {
  /// The same item with a receipt time (the builder has none).
  PendingSmsImport withReceivedAt(DateTime at) => PendingSmsImport(
    id: id,
    parentImportId: parentImportId,
    fingerprint: fingerprint,
    status: status,
    source: source,
    senderId: senderId,
    bankId: bankId,
    parserId: parserId,
    ruleVersion: ruleVersion,
    kind: kind,
    direction: direction,
    amount: amount,
    amountCandidates: amountCandidates,
    foreignAmountText: foreignAmountText,
    foreignAmount: foreignAmount,
    occurredOn: occurredOn,
    timeMinutes: timeMinutes,
    merchant: merchant,
    merchantKey: merchantKey,
    counterparty: counterparty,
    cardLast4: cardLast4,
    suggestedCategoryId: suggestedCategoryId,
    suggestedPersonId: suggestedPersonId,
    suggestedType: suggestedType,
    confidence: confidence,
    warnings: warnings,
    refHash: refHash,
    refAmountHash: refAmountHash,
    receivedAt: at,
    createdAt: createdAt,
    expiresAt: expiresAt,
    decidedAt: decidedAt,
    savedRecordId: savedRecordId,
    savedRecordType: savedRecordType,
    hasRawText: hasRawText,
  );
}
