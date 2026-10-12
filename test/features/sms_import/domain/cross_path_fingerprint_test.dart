import 'package:daftary/features/sms_import/data/crypto/hmac_fingerprint_hasher.dart';
import 'package:daftary/features/sms_import/data/parsing/bank_profile.dart';
import 'package:daftary/features/sms_import/data/parsing/fingerprint_normalizer.dart';
import 'package:daftary/features/sms_import/data/parsing/sms_parser_registry.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pipeline_harness.dart';
import '../helpers/sms_fixture_loader.dart';

// A synthetic NBE purchase (NBE profile phrasing; no real card number).
const _nbe =
    'NBE: Your card ending 4821 was charged EGP 250.00 at Example Market on '
    '05/03/2026 at 14:30. Available balance EGP 3,200.00';

/// The shipped registry with every profile's rule version bumped by one: a
/// parser/rule update that leaves the frozen fingerprint untouched (FR-023).
SmsParserRegistry _bumpedRegistry() {
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

/// The `_paste/envelopes/` cases: the envelope text as copied or shared,
/// and the bodies as the inbox stores them.
List<SmsFixture> _envelopes() => [
  for (final fixture in loadSmsFixtures())
    if (fixture.path.startsWith('_paste/envelopes/')) fixture,
];

List<String> _inboxBodies(SmsFixture fixture) =>
    (fixture.meta['inboxBodies'] as List).cast<String>();

/// T170 — one message, one pending item, one fingerprint, whatever the
/// path (scan, catch-up, paste, share) and whatever envelope the messaging
/// app added (FR-017a, FR-023, SC-006); and a parser version bump never
/// resurfaces a message on re-scan.
void main() {
  late PipelineHarness h;

  setUp(() async {
    h = PipelineHarness();
    await h.open();
  });
  tearDown(() => h.close());

  /// The fingerprint the frozen normalizer gives [body] under this
  /// harness's key.
  Future<String> expectedFingerprint(String body) => HmacFingerprintHasher(
    h.keys,
  ).fingerprint(const FingerprintNormalizerV1().normalize(body));

  Future<String> expectedFeeFingerprint(String body) => HmacFingerprintHasher(
    h.keys,
  ).feeFingerprint(const FingerprintNormalizerV1().normalize(body));

  group('the same message through every path', () {
    test(
      'scan -> catch-up -> paste -> share: one item, one fingerprint',
      () async {
        final scanned = await h.scan([inboxRow(7, _nbe)]);
        expect(scanned.createdPending, 1);
        expect((await h.catchUp([inboxRow(8, _nbe)])).createdPending, 0);
        expect((await h.pasteText(_nbe)).newIds, isEmpty);
        expect((await h.shareText(_nbe)).newIds, isEmpty);

        final rows = await h.rows();
        expect(rows, hasLength(1));
        expect(rows.single.origin, SmsSource.inboxScan.dbValue);
        expect(rows.single.fingerprint, await expectedFingerprint(_nbe));
        expect(await h.savedRecords(), 0);
      },
    );

    test(
      'share -> paste -> catch-up -> scan: one item, one fingerprint',
      () async {
        expect((await h.shareText(_nbe)).newIds, hasLength(1));
        expect((await h.pasteText(_nbe)).newIds, isEmpty);
        expect((await h.catchUp([inboxRow(8, _nbe)])).createdPending, 0);
        final scanned = await h.scan([inboxRow(9, _nbe)]);
        expect(scanned.createdPending, 0);
        expect(scanned.alreadyKnown, 1);

        final rows = await h.rows();
        expect(rows, hasLength(1));
        expect(rows.single.origin, SmsSource.share.dbValue);
        expect(rows.single.fingerprint, await expectedFingerprint(_nbe));
      },
    );

    test('sender and receipt time are not fingerprint inputs', () async {
      await h.scan([
        inboxRow(1, _nbe, date: DateTime(2026, 3, 5, 14, 31)),
        inboxRow(2, _nbe, address: 'NBEGYPT', date: DateTime(2026, 3, 6, 8)),
      ]);
      await h.catchUp([
        inboxRow(3, _nbe, address: 'nbe', date: DateTime(2026, 3, 6, 9)),
      ]);
      expect(await h.rows(), hasLength(1));
    });

    test('whitespace, bidi marks and Arabic-Indic digits added by a '
        'messaging app do not change the fingerprint', () async {
      await h.scan([inboxRow(1, _nbe)]);
      final variants = [
        '‏$_nbe‏',
        '  $_nbe  \r\n',
        _nbe.replaceAll(' ', '  '),
        _nbe.replaceAll('250.00', '٢٥٠.٠٠'),
      ];
      for (final variant in variants) {
        expect(
          (await h.pasteText(variant)).newIds,
          isEmpty,
          reason: variant.length.toString(),
        );
      }
      expect(await h.rows(), hasLength(1));
    });
  });

  group('every _paste/envelopes/ format', () {
    final fixtures = _envelopes();

    test('the corpus is present', () {
      expect(fixtures.length, greaterThanOrEqualTo(13));
      for (final fixture in fixtures) {
        expect(fixture.meta['synthetic'], isTrue, reason: fixture.path);
        expect(_inboxBodies(fixture), isNotEmpty, reason: fixture.path);
      }
    });

    for (final fixture in fixtures) {
      test(
        '${fixture.path}: inbox first, then paste and share add nothing',
        () async {
          final bodies = _inboxBodies(fixture);
          final scanned = await h.ingestInbox(bodies);
          final created = scanned.createdPending;
          expect(created, greaterThanOrEqualTo(1));
          final before = {for (final r in await h.rows()) r.fingerprint};

          final pasted = await h.pasteText(fixture.text);
          expect(pasted.newIds, isEmpty, reason: 'paste');
          final shared = await h.shareText(fixture.text);
          expect(shared.newIds, isEmpty, reason: 'share');
          final caughtUp = await h.ingestInbox(
            bodies,
            source: SmsSource.catchUpScan,
          );
          expect(caughtUp.createdPending, 0, reason: 'catch-up');

          final after = {for (final r in await h.rows()) r.fingerprint};
          expect(after, before);
          expect(await h.rows(), hasLength(created));
          // Every stored fingerprint is the frozen one of an inbox body (or
          // the fee fingerprint derived from it, FR-030a).
          final allowed = <String>{
            for (final body in bodies) ...[
              await expectedFingerprint(body),
              await expectedFeeFingerprint(body),
            ],
          };
          expect(allowed.containsAll(after), isTrue);
        },
      );

      test(
        '${fixture.path}: paste first, then the inbox adds nothing',
        () async {
          final pasted = await h.pasteText(fixture.text);
          final created = pasted.newIds.length;
          expect(created, greaterThanOrEqualTo(1));
          final before = {for (final r in await h.rows()) r.fingerprint};

          final scanned = await h.ingestInbox(_inboxBodies(fixture));
          expect(scanned.createdPending, 0);
          expect({for (final r in await h.rows()) r.fingerprint}, before);
          expect(await h.rows(), hasLength(created));
        },
      );
    }
  });

  group('a parser version bump followed by a re-scan resurfaces nothing', () {
    late PipelineHarness bumped;

    Future<PipelineHarness> openBumped() async {
      bumped = PipelineHarness(
        database: h.database,
        keys: h.keys,
        registry: _bumpedRegistry(),
        now: h.clock.now(),
      );
      return bumped;
    }

    tearDown(() async {
      await bumped.lock.close();
    });

    test('the bumped registry really is a new rule version', () async {
      await openBumped();
      await h.scan([inboxRow(1, _nbe)]);
      expect((await h.rows()).single.ruleVersion, 'nbe@1');
      final reparsed = bumped.parser.registry.profiles.firstWhere(
        (p) => p.id == 'nbe',
      );
      expect(reparsed.ruleVersion, 'nbe@2');
    });

    test('a pending item stays one item', () async {
      await h.scan([inboxRow(1, _nbe)]);
      await openBumped();
      final rescan = await bumped.scan([inboxRow(1, _nbe)]);
      expect(rescan.createdPending, 0);
      expect(rescan.alreadyKnown, 1);
      expect(await h.rows(), hasLength(1));
    });

    test(
      'an added item does not come back, and no second record is made',
      () async {
        await h.scan([inboxRow(1, _nbe)]);
        final item = (await h.pending()).single;
        final added = await h.add(
          pendingId: item.id,
          draft: _expenseDraft(item.amount!.minorUnits, item.occurredOn!),
        );
        expect(added.isRight(), isTrue);
        await openBumped();
        final rescan = await bumped.scan([inboxRow(1, _nbe)]);
        expect(rescan.createdPending, 0);
        expect((await bumped.pasteText(_nbe)).newIds, isEmpty);
        expect(await bumped.pending(), isEmpty);
        expect(await h.savedRecords(), 1);
      },
    );

    test('an item closed as a duplicate does not come back', () async {
      await h.scan([inboxRow(1, _nbe)]);
      final item = (await h.pending()).single;
      await h.closeAsDuplicate(item.id);
      await openBumped();
      expect((await bumped.scan([inboxRow(1, _nbe)])).createdPending, 0);
      expect(await bumped.pending(), isEmpty);
    });

    test(
      '...even after the decided row was purged (the tombstone stays)',
      () async {
        await h.scan([inboxRow(1, _nbe)]);
        final item = (await h.pending()).single;
        await h.closeAsDuplicate(item.id);
        // Past the 30-day row retention, before the tombstone's purge date.
        final later = h.clock.now().add(const Duration(days: 31));
        final purged = await h.repository.purgeDecided(later);
        expect(purged.getOrElse((f) => fail('$f')).rows, 1);
        expect(await h.rows(), isEmpty);
        expect(
          await h.database.select(h.database.smsImportTombstones).get(),
          hasLength(1),
        );
        await openBumped();
        final rescan = await bumped.ingestInbox([_nbe], sender: 'NBE');
        expect(rescan.createdPending, 0);
        expect(await h.rows(), isEmpty);
      },
    );
  });
}

ReviewDraft _expenseDraft(int minor, DateTime date) => ReviewDraft(
  type: SuggestedRecordType.expense,
  amountMinorUnits: minor,
  currencyCode: 'EGP',
  date: date,
  categoryId: 'seed_groceries',
);
