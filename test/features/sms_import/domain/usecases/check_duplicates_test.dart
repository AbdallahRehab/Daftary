import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/sms_import/domain/usecases/check_duplicates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/builders.dart';
import '../../helpers/fakes.dart';

/// T061 — written before `CheckDuplicates`. The FR-059b order on the
/// draft's current values; every value is synthetic.
void main() {
  late FakeSmsDuplicateLookup lookup;
  late FakeBankReferencePolicy policy;
  late CheckDuplicates check;

  final day = DateTime(2026, 3, 4);
  const amount = Money.egp(12550);

  setUp(() {
    lookup = FakeSmsDuplicateLookup();
    policy = FakeBankReferencePolicy({'uniquebank'});
    check = CheckDuplicates(lookup, policy);
  });

  ReviewDraft draftFor(
    PendingSmsImport item, {
    SuggestedRecordType? type,
    int? minor,
    String? currency,
    DateTime? date,
  }) => ReviewDraft(
    type: type ?? item.suggestedType,
    amountMinorUnits: minor ?? item.amount?.minorUnits,
    currencyCode: currency ?? item.amount?.currency.code,
    date: date ?? item.occurredOn,
    categoryId: 'cat-1',
  );

  DuplicateRecordRef saved({
    String id = 'rec-1',
    SuggestedRecordType type = SuggestedRecordType.expense,
    Money money = amount,
    DateTime? date,
    ImportProvenance? provenance,
    String? note,
  }) => DuplicateRecordRef(
    id: id,
    recordType: type.isFinanceEntry
        ? SavedRecordType.financeEntry
        : SavedRecordType.moneyTransaction,
    type: type,
    amount: money,
    date: date ?? day,
    importProvenance: provenance,
    note: note,
  );

  Future<DuplicateFinding> run(
    PendingSmsImport item, [
    ReviewDraft? draft,
  ]) async {
    final result = await check(item: item, draft: draft ?? draftFor(item));
    return result.getOrElse((f) => fail('unexpected failure $f'));
  }

  group('tier 1: fingerprint', () {
    test('another pending row with the same fingerprint is exact', () async {
      final item = buildPendingImport();
      lookup.keyMatches = [
        const ImportKeyMatch(
          pendingId: 'pending-2',
          fingerprint: 'fp-1',
          bankId: 'nbe',
        ),
      ];
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.exact);
      expect(finding.exactBasis, ExactBasis.fingerprint);
      expect(finding.matchedPendingId, 'pending-2');
    });

    test('the item itself is never its own match', () async {
      final item = buildPendingImport();
      lookup.keyMatches = [
        const ImportKeyMatch(
          pendingId: 'pending-1',
          fingerprint: 'fp-1',
          bankId: 'nbe',
        ),
      ];
      expect((await run(item)).tier, DuplicateTier.none);
    });

    test('a matching saved record still wins over a pending-row exact match, '
        'so money already saved is never hidden (SC-007)', () async {
      final item = buildPendingImport();
      lookup
        ..keyMatches = [
          const ImportKeyMatch(
            pendingId: 'pending-2',
            fingerprint: 'fp-1',
            bankId: 'nbe',
          ),
        ]
        ..savedMatches = [saved()];
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.probable);
      expect(finding.probableBasis, ProbableBasis.savedRecord);
      expect(finding.matchedRecord?.id, 'rec-1');
    });

    test('a tombstone with the same fingerprint is exact', () async {
      final item = buildPendingImport();
      lookup.keyMatches = [
        const ImportKeyMatch(
          fingerprint: 'fp-1',
          bankId: 'nbe',
          outcome: TombstoneOutcome.ignored,
        ),
      ];
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.exact);
      expect(finding.exactBasis, ExactBasis.fingerprint);
    });
  });

  group('tier 2: bank + reference + amount + direction', () {
    test('exact for a bank with unique references, any date', () async {
      final item = buildPendingImport(
        bankId: 'uniquebank',
        refHash: 'r1',
        refAmountHash: 'ra1',
      );
      lookup.keyMatches = [
        const ImportKeyMatch(
          fingerprint: 'fp-other',
          bankId: 'uniquebank',
          refHash: 'r1',
          refAmountHash: 'ra1',
          outcome: TombstoneOutcome.added,
        ),
      ];
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.exact);
      expect(finding.exactBasis, ExactBasis.bankReferenceAmountDirection);
    });

    test('a non-unique bank also needs a date within one day', () async {
      final item = buildPendingImport(refHash: 'r1', refAmountHash: 'ra1');
      ImportKeyMatch other(DateTime date) => ImportKeyMatch(
        pendingId: 'pending-2',
        fingerprint: 'fp-other',
        bankId: 'nbe',
        refHash: 'r1',
        refAmountHash: 'ra1',
        occurredOn: date,
      );

      lookup.keyMatches = [other(DateTime(2026, 3, 5))];
      expect((await run(item)).tier, DuplicateTier.exact);

      lookup.keyMatches = [other(DateTime(2026, 3, 6))];
      expect((await run(item)).tier, isNot(DuplicateTier.exact));
    });

    test('a non-unique bank never collapses on a dateless tombstone', () async {
      final item = buildPendingImport(refHash: 'r1', refAmountHash: 'ra1');
      lookup.keyMatches = [
        const ImportKeyMatch(
          fingerprint: 'fp-other',
          bankId: 'nbe',
          refHash: 'r1',
          refAmountHash: 'ra1',
          outcome: TombstoneOutcome.added,
        ),
      ];
      expect((await run(item)).tier, isNot(DuplicateTier.exact));
    });

    test('does not apply once the draft amount is edited', () async {
      final item = buildPendingImport(
        bankId: 'uniquebank',
        refHash: 'r1',
        refAmountHash: 'ra1',
      );
      lookup.keyMatches = [
        const ImportKeyMatch(
          fingerprint: 'fp-other',
          bankId: 'uniquebank',
          refHash: 'r1',
          refAmountHash: 'ra1',
          outcome: TombstoneOutcome.added,
        ),
      ];
      final finding = await run(item, draftFor(item, minor: 99900));
      expect(finding.tier, isNot(DuplicateTier.exact));
    });
  });

  group('tier 3: both references present and different', () {
    test('an SMS-sourced record with another reference stops the check', () {
      final item = buildPendingImport(refHash: 'r1');
      lookup
        ..savedMatches = [saved(provenance: ImportProvenance.sms)]
        ..refHashBySavedRecord = {'rec-1': 'r2'};
      return run(item).then((finding) {
        expect(finding.tier, DuplicateTier.legitimatelySimilar);
        expect(finding.matchedRecord, isNull);
      });
    });

    test('the same reference on the saved record is still probable', () async {
      final item = buildPendingImport(refHash: 'r1');
      lookup
        ..savedMatches = [saved(provenance: ImportProvenance.sms)]
        ..refHashBySavedRecord = {'rec-1': 'r1'};
      expect((await run(item)).tier, DuplicateTier.probable);
    });

    test(
      'a missing reference on either side falls to the probable rule',
      () async {
        final item = buildPendingImport();
        lookup
          ..savedMatches = [saved(provenance: ImportProvenance.sms)]
          ..refHashBySavedRecord = {'rec-1': 'r2'};
        expect((await run(item)).tier, DuplicateTier.probable);
      },
    );
  });

  group('tier 4: probable', () {
    test('a manual record with the same amount and day', () async {
      final item = buildPendingImport();
      lookup.savedMatches = [saved()];
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.probable);
      expect(finding.probableBasis, ProbableBasis.savedRecord);
      expect(finding.matchedRecord?.id, 'rec-1');
    });

    test('both edges of the one-day window', () async {
      final item = buildPendingImport();
      lookup.savedMatches = [saved(date: DateTime(2026, 3, 3))];
      expect((await run(item)).tier, DuplicateTier.probable);
      lookup.savedMatches = [saved(date: DateTime(2026, 3, 5))];
      expect((await run(item)).tier, DuplicateTier.probable);
      lookup.savedMatches = [saved(date: DateTime(2026, 3, 2))];
      expect((await run(item)).tier, DuplicateTier.none);
      lookup.savedMatches = [saved(date: DateTime(2026, 3, 6))];
      expect((await run(item)).tier, DuplicateTier.none);
    });

    test('the window counts calendar days across a month edge', () async {
      final item = buildPendingImport(occurredOn: DateTime(2026, 3, 1));
      lookup.savedMatches = [saved(date: DateTime(2026, 2, 28))];
      expect((await run(item)).tier, DuplicateTier.probable);
      lookup.savedMatches = [saved(date: DateTime(2026, 2, 27))];
      expect((await run(item)).tier, DuplicateTier.none);
    });

    test('direction group: an expense matches a Given record', () async {
      final item = buildPendingImport();
      lookup.savedMatches = [saved(type: SuggestedRecordType.given)];
      expect((await run(item)).tier, DuplicateTier.probable);
      lookup.savedMatches = [saved(type: SuggestedRecordType.income)];
      expect((await run(item)).tier, DuplicateTier.none);
    });

    test(
      'a fee sharing a reference but with another amount is no match',
      () async {
        final fee = buildPendingImport(
          kind: SmsKind.fee,
          amount: const Money.egp(500),
          refHash: 'r1',
        );
        lookup.savedMatches = [saved(money: const Money.egp(200000))];
        expect((await run(fee)).tier, DuplicateTier.none);
      },
    );

    test('uses the draft values, not the parsed ones', () async {
      final item = buildPendingImport();
      final draft = draftFor(
        item,
        minor: 30000,
        currency: 'USD',
        date: DateTime(2026, 3, 10),
        type: SuggestedRecordType.given,
      );
      lookup.savedMatches = [
        saved(
          money: Money.fromMinorUnits(30000, Currency.usd),
          date: DateTime(2026, 3, 11),
          type: SuggestedRecordType.given,
        ),
      ];
      final finding = await run(item, draft);
      expect(finding.tier, DuplicateTier.probable);
      final call = lookup.savedMatchCalls.first;
      expect(call.amount, Money.fromMinorUnits(30000, Currency.usd));
      expect(call.date, DateTime(2026, 3, 10));
      expect(call.type, SuggestedRecordType.given);
    });

    test(
      'a stated original-currency amount is compared too (FR-059)',
      () async {
        final usd = Money.fromMinorUnits(2500, Currency.usd);
        final item = buildPendingImport(foreignAmount: usd);
        lookup.savedMatches = [saved(money: usd)];
        final finding = await run(item);
        expect(finding.tier, DuplicateTier.probable);
        expect(
          lookup.savedMatchCalls.map((c) => c.amount),
          containsAll(<Money>[amount, usd]),
        );
      },
    );

    test('ranks by merchant/note similarity, then by closest date', () async {
      final item = buildPendingImport(merchant: 'Example Cafe');
      lookup.savedMatches = [
        saved(id: 'far', date: DateTime(2026, 3, 5)),
        saved(id: 'near', date: day),
        saved(id: 'named', date: DateTime(2026, 3, 3), note: 'cafe example'),
      ];
      expect((await run(item)).matchedRecord?.id, 'named');

      lookup.savedMatches = [
        saved(id: 'far', date: DateTime(2026, 3, 5)),
        saved(id: 'near', date: day),
      ];
      expect((await run(item)).matchedRecord?.id, 'near');
    });

    test('the 10-minute pending pair is probable', () async {
      final item = buildPendingImport();
      lookup.pendingPair = buildPendingImport(
        id: 'pending-2',
        fingerprint: 'fp-2',
        timeMinutes: 620,
      );
      final finding = await run(item);
      expect(finding.tier, DuplicateTier.probable);
      expect(finding.probableBasis, ProbableBasis.pendingPair);
      expect(finding.matchedPendingId, 'pending-2');
    });

    test('no type, amount or date means nothing to compare', () async {
      final item = buildPendingImport(
        suggestedType: SuggestedRecordType.unset,
        direction: SmsDirection.unknown,
      );
      lookup.savedMatches = [saved()];
      final finding = await run(
        item,
        const ReviewDraft(type: SuggestedRecordType.unset),
      );
      expect(finding.tier, DuplicateTier.none);
    });
  });

  group('possible own transfer (FR-051d)', () {
    PendingSmsImport transferOut({String bankId = 'nbe'}) => buildPendingImport(
      bankId: bankId,
      kind: SmsKind.transferOut,
      merchant: null,
      merchantKey: null,
      cardLast4: null,
    );

    test('an opposite pending item from another bank is flagged', () async {
      final item = transferOut();
      lookup.pendingWithAmount = [
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          bankId: 'cib',
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
        ),
      ];
      final finding = await run(item);
      expect(finding.possibleOwnTransfer, isTrue);
      expect(finding.tier, DuplicateTier.none);
    });

    test('none within the same bank', () async {
      final item = transferOut();
      lookup.pendingWithAmount = [
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          suggestedType: SuggestedRecordType.income,
        ),
      ];
      expect((await run(item)).possibleOwnTransfer, isFalse);
    });

    test('none more than one day apart', () async {
      final item = transferOut();
      lookup.pendingWithAmount = [
        buildPendingImport(
          id: 'pending-2',
          fingerprint: 'fp-2',
          bankId: 'cib',
          kind: SmsKind.transferIn,
          direction: SmsDirection.credit,
          occurredOn: DateTime(2026, 3, 6),
        ),
      ];
      expect((await run(item)).possibleOwnTransfer, isFalse);
    });

    test('an SMS-sourced saved income from another bank is flagged', () async {
      final item = transferOut();
      lookup
        ..savedMatches = [
          saved(
            type: SuggestedRecordType.income,
            provenance: ImportProvenance.sms,
          ),
        ]
        ..bankBySavedRecord = {'rec-1': 'cib'};
      final finding = await run(item);
      expect(finding.possibleOwnTransfer, isTrue);
    });

    test('a manual saved income is not an own transfer', () async {
      final item = transferOut();
      lookup.savedMatches = [saved(type: SuggestedRecordType.income)];
      expect((await run(item)).possibleOwnTransfer, isFalse);
    });
  });

  group('authorization reversal (FR-024b)', () {
    PendingSmsImport reversal({String? refHash}) => buildPendingImport(
      kind: SmsKind.authorizationReversal,
      direction: SmsDirection.credit,
      suggestedType: SuggestedRecordType.ignore,
      refHash: refHash,
    );

    test('matches the saved expense with the same reference', () async {
      lookup.savedByRefHash = {
        'r1': [saved(id: 'purchase', date: DateTime(2026, 2, 20))],
      };
      final finding = await run(reversal(refHash: 'r1'));
      expect(finding.matchedRecord?.id, 'purchase');
      expect(finding.tier, DuplicateTier.none);
    });

    test('matches a Given record of the same amount within a day', () async {
      lookup.savedMatches = [
        saved(id: 'given', type: SuggestedRecordType.given),
      ];
      final finding = await run(reversal());
      expect(finding.matchedRecord?.id, 'given');
      expect(lookup.savedMatchCalls.single.type, SuggestedRecordType.expense);
    });

    test('an income record is never the reversed purchase', () async {
      lookup.savedMatches = [saved(type: SuggestedRecordType.income)];
      expect((await run(reversal())).matchedRecord, isNull);
    });
  });

  test('a lookup failure is returned, never swallowed', () async {
    final failing = _FailingLookup();
    final result = await CheckDuplicates(failing, policy)(
      item: buildPendingImport(),
      draft: draftFor(buildPendingImport()),
    );
    expect(result.isLeft(), isTrue);
  });
}

class _FailingLookup extends FakeSmsDuplicateLookup {
  @override
  Future<Either<Failure, List<ImportKeyMatch>>> findKeyMatches({
    required String excludeId,
    required String fingerprint,
    String? refAmountHash,
  }) async => const Left(CacheFailure('sms_duplicate_lookup_failed'));
}
