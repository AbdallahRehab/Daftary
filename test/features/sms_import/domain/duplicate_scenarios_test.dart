import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/test_daos.dart';
import '../helpers/builders.dart';
import '../helpers/fakes.dart';
import '../helpers/pipeline_harness.dart';

// Synthetic messages (generic and NBE/CIB profile phrasing; no real card
// numbers, phone numbers or references).
const _purchase =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with card '
    '****0000.';
const _purchaseOtherWording =
    'Your card was charged EGP 125.50 at Example Cafe on 04/03/2026.';
const _purchaseRefA =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 10:15 with card '
    '****0000. Ref: AA1111';
const _purchaseRefB =
    'Purchase of EGP 125.50 at Example Cafe on 04/03/2026 18:40 with card '
    '****0000. Ref: BB2222';
const _transferWithRef =
    'Your account was debited with EGP 500.00 for a transfer to Mona Example '
    'on 05/03/2026. Ref: TRX12345';
const _feeSameRef =
    'A fee of EGP 5.00 was debited from your account on 05/03/2026. '
    'Ref: TRX12345';
const _atmWithFee =
    'Cash withdrawal of EGP 2,000.00 from ATM Example Branch on 05/03/2026. '
    'Fees EGP 15.00';
const _hotel =
    'Purchase of EGP 450.00 at Example Hotel on 05/03/2026 with card ****0000.';
const _reversal =
    'Authorization reversed: the hold of EGP 450.00 at Example Hotel on '
    '05/03/2026 has been released.';

String _nbeTransfer(String date, {String amount = '1,500.00'}) =>
    'NBE: Transfer of EGP $amount to Ahmed Example from your account ****4821 '
    'on $date. Ref 7731902';
String _nbeCredit(String date) =>
    'NBE: Your account ****4821 was credited with EGP 1,500.00 from Mona '
    'Example on $date.';
String _cibIncoming(String date) =>
    'CIB: Incoming transfer of EGP 1,500.00 to account ****2290 from Abdo '
    'Example on $date.';

const _groceries = 'seed_groceries';
const _salary = 'seed_salary';

/// T099 — duplicate protection end to end (US5; FR-017a, FR-023, FR-024b,
/// FR-030a, FR-051d, FR-059, FR-059a, FR-059b, FR-060, FR-061, FR-063,
/// SC-006) on a real in-memory database: the real parser, frozen
/// fingerprint, HMAC hasher, staging repository, duplicate DAO,
/// `CheckDuplicates`, `AddImportedTransaction` and `CloseAsDuplicate`.
void main() {
  late PipelineHarness h;

  setUp(() async {
    h = PipelineHarness();
    await h.open();
  });
  tearDown(() => h.close());

  ReviewDraft draftFor(
    PendingSmsImport item, {
    SuggestedRecordType type = SuggestedRecordType.expense,
    int? minor,
    String? currency,
    DateTime? date,
    String? categoryId,
    String? personId,
  }) => ReviewDraft(
    type: type,
    amountMinorUnits: minor ?? item.amount?.minorUnits,
    currencyCode: currency ?? item.amount?.currency.code,
    date: date ?? item.occurredOn,
    categoryId: type.isFinanceEntry
        ? categoryId ??
              (type == SuggestedRecordType.income ? _salary : _groceries)
        : null,
    personId: type.isPersonTransaction ? personId ?? 'person-1' : null,
  );

  Future<DuplicateFinding> check(
    PendingSmsImport item, [
    ReviewDraft? draft,
  ]) async => (await h.checkDuplicates(
    item: item,
    draft: draft ?? draftFor(item),
  )).getOrElse((f) => fail('check failed: $f'));

  Future<PendingSmsImport> pasteOne(String text) async {
    final result = await h.pasteText(text);
    expect(result.newIds, hasLength(1), reason: 'one new item');
    return h.item(result.newIds.single);
  }

  /// Adds [item] as an expense (override: only to set the scene).
  Future<SavedRecordRef> addExpense(PendingSmsImport item) async =>
      (await h.add(
        pendingId: item.id,
        draft: draftFor(item),
        duplicateOverride: true,
      )).getOrElse((f) => fail('add failed: $f'));

  Future<String> manualExpense({
    Money amount = const Money.egp(12550),
    DateTime? date,
    FinanceEntryType type = FinanceEntryType.expense,
    String? note,
  }) async => (await h.finance.addEntry(
    idempotencyKey: 'manual-${DateTime.now().microsecondsSinceEpoch}',
    categoryId: type == FinanceEntryType.income ? _salary : _groceries,
    type: type,
    amount: amount,
    date: date ?? DateTime(2026, 3, 4),
    note: note,
  )).getOrElse((f) => fail('manual add failed: $f')).id;

  // ---------------------------------------------------------------- exact

  group('exact tier: the same message by any path collapses (FR-059, '
      'SC-006)', () {
    test('re-scan of the same inbox message adds nothing', () async {
      final row = inboxRow(1, _nbeTransfer('05/03/2026'));
      final first = await h.scan([row]);
      expect(first.createdPending, 1);
      final second = await h.scan([row]);
      expect(second.createdPending, 0);
      expect(second.alreadyKnown, 1);
      expect(await h.rows(), hasLength(1));
    });

    test('re-paste and re-share of the same message add nothing', () async {
      expect((await h.pasteText(_purchase)).newIds, hasLength(1));
      expect((await h.pasteText(_purchase)).newIds, isEmpty);
      expect((await h.shareText(_purchase)).newIds, isEmpty);
      expect((await h.shareText(_purchase)).newIds, isEmpty);
      expect(await h.rows(), hasLength(1));
    });

    test('byte-identical bodies (sent twice by the bank) give one item, in '
        'one scan page and in one paste', () async {
      final body = _nbeTransfer('05/03/2026');
      final summary = await h.scan([inboxRow(1, body), inboxRow(2, body)]);
      expect(summary.createdPending, 1);
      expect(summary.alreadyKnown, 1);
      expect(
        (await h.pasteText('$_purchase\n\n$_purchase')).newIds,
        hasLength(1),
      );
      expect(await h.rows(), hasLength(2));
    });

    test('a re-check finds no exact match against itself', () async {
      final item = await pasteOne(_purchase);
      final finding = await check(item);
      expect(finding.tier, isNot(DuplicateTier.exact));
    });

    test('after Add, the same message by any path never comes back and no '
        'second record is created', () async {
      final item = await pasteOne(_purchase);
      await addExpense(item);
      expect(await h.savedRecords(), 1);
      expect((await h.pasteText(_purchase)).newIds, isEmpty);
      expect((await h.shareText(_purchase)).newIds, isEmpty);
      expect((await h.ingestInbox([_purchase])).createdPending, 0);
      expect(await h.pending(), isEmpty);
      expect(await h.savedRecords(), 1);
    });

    test(
      'after "It\'s the same, don\'t add", the message never comes back',
      () async {
        final item = await pasteOne(_purchase);
        expect(
          await h.closeAsDuplicate(item.id),
          const Right<Failure, Unit>(unit),
        );
        expect((await h.pasteText(_purchase)).newIds, isEmpty);
        expect((await h.ingestInbox([_purchase])).createdPending, 0);
        expect(await h.pending(), isEmpty);
        expect(await h.savedRecords(), 0);
      },
    );
  });

  // ------------------------------------------------------------ references

  group('reference rules (FR-059b)', () {
    test('a fee SMS sharing the reference but with a different amount is a '
        'second item', () async {
      final summary = await h.ingestInbox([_transferWithRef, _feeSameRef]);
      expect(summary.createdPending, 2);
      final items = await h.pending();
      expect(items.map((i) => i.amount), {
        const Money.egp(50000),
        const Money.egp(500),
      });
      // Same reference hash, different reference-amount hashes.
      expect(items[0].refHash, items[1].refHash);
      expect(items[0].refAmountHash, isNot(items[1].refAmountHash));
      for (final item in items) {
        expect((await check(item)).tier, isNot(DuplicateTier.exact));
      }
    });

    test('...even for a bank whose references are unique', () async {
      await h.close();
      h = PipelineHarness(policy: FakeBankReferencePolicy({'generic'}));
      await h.open();
      final summary = await h.ingestInbox([_transferWithRef, _feeSameRef]);
      expect(summary.createdPending, 2);
    });

    test('a short reused reference on a non-unique bank does not collapse '
        'messages days apart', () async {
      expect(h.policy.refIsUnique('nbe'), isFalse);
      final summary = await h.scan([
        inboxRow(1, _nbeTransfer('01/03/2026')),
        inboxRow(2, _nbeTransfer('05/03/2026')),
      ]);
      expect(summary.createdPending, 2);
      final items = await h.pending();
      expect(items[0].refAmountHash, items[1].refAmountHash);
      for (final item in items) {
        expect((await check(item)).tier, isNot(DuplicateTier.exact));
      }
    });

    test('...but within one day the same bank, reference, amount and '
        'direction is exact (tier 2)', () async {
      final summary = await h.scan([
        inboxRow(1, _nbeTransfer('05/03/2026')),
        inboxRow(2, _nbeTransfer('06/03/2026')),
      ]);
      expect(summary.createdPending, 1);
      expect(summary.alreadyKnown, 1);
    });

    test('a non-unique bank reference is not collapsed against a decided '
        'item (a tombstone keeps no date)', () async {
      await h.scan([inboxRow(1, _nbeTransfer('05/03/2026'))]);
      final first = (await h.pending()).single;
      await addExpense(first);
      final summary = await h.scan([inboxRow(2, _nbeTransfer('06/03/2026'))]);
      expect(summary.createdPending, 1);
      // Not exact, but the saved record is still a probable duplicate:
      // the user is asked, never silently blocked.
      final second = (await h.pending()).single;
      expect((await check(second)).tier, DuplicateTier.probable);
    });

    test('a unique-reference bank collapses at any date', () async {
      await h.close();
      h = PipelineHarness(policy: FakeBankReferencePolicy({'nbe'}));
      await h.open();
      final summary = await h.scan([
        inboxRow(1, _nbeTransfer('01/03/2026')),
        inboxRow(2, _nbeTransfer('05/03/2026')),
      ]);
      expect(summary.createdPending, 1);
    });

    test('both reference hashes present and different: legitimately '
        'similar, no warning, Add is not blocked', () async {
      final first = await pasteOne(_purchaseRefA);
      await addExpense(first);
      final second = await pasteOne(_purchaseRefB);
      final finding = await check(second);
      expect(finding.tier, DuplicateTier.legitimatelySimilar);
      expect(finding.isProbable, isFalse);
      final added = await h.add(pendingId: second.id, draft: draftFor(second));
      expect(added.isRight(), isTrue);
      expect(await h.savedRecords(), 2);
    });

    test(
      'a reference missing on one side: only the probable rules apply',
      () async {
        final first = await pasteOne(_purchaseRefA);
        await addExpense(first);
        final second = await pasteOne(_purchaseOtherWording);
        expect(second.refHash, isNull);
        expect((await check(second)).tier, DuplicateTier.probable);
      },
    );
  });

  // -------------------------------------------------------------- probable

  group('probable tier: side by side, never blocking (FR-060, FR-063)', () {
    test('matches a MANUAL record; Add asks, override adds', () async {
      final manualId = await manualExpense(note: 'Example Cafe');
      final item = await pasteOne(_purchase);

      final finding = await check(item);
      expect(finding.tier, DuplicateTier.probable);
      expect(finding.probableBasis, ProbableBasis.savedRecord);
      expect(finding.matchedRecord!.id, manualId);
      expect(finding.matchedRecord!.importProvenance, isNull);

      final asked = await h.add(pendingId: item.id, draft: draftFor(item));
      expect(asked.getLeft().toNullable(), isA<ProbableDuplicateFailure>());
      expect(await h.savedRecords(), 1);
      expect((await h.item(item.id)).isPending, isTrue);

      final added = await h.add(
        pendingId: item.id,
        draft: draftFor(item),
        duplicateOverride: true,
      );
      expect(added.isRight(), isTrue);
      expect(await h.savedRecords(), 2);
    });

    test(
      'matches an OCR record (people ledger, given = expense group)',
      () async {
        await testPeopleDao(
          h.database,
        ).insertPerson(id: 'person-1', name: 'Mona', createdAt: DateTime(2026));
        final ocr = (await h.transactions.addOcrSourcedTransaction(
          idempotencyKey: 'ocr-1',
          personId: 'person-1',
          ocrScanId: 'scan-1',
          amount: const Money.egp(12550),
          direction: TransactionDirection.given,
          date: DateTime(2026, 3, 4),
        )).getOrElse((f) => fail('$f'));
        final item = await pasteOne(_purchase);

        for (final type in [
          SuggestedRecordType.expense,
          SuggestedRecordType.given,
        ]) {
          final finding = await check(item, draftFor(item, type: type));
          expect(finding.tier, DuplicateTier.probable, reason: type.name);
          expect(finding.matchedRecord!.id, ocr.id);
          expect(
            finding.matchedRecord!.recordType,
            SavedRecordType.moneyTransaction,
          );
        }
      },
    );

    test('matches an SMS-sourced record from a different message', () async {
      final first = await pasteOne(_purchase);
      final saved = await addExpense(first);
      final second = await pasteOne(_purchaseOtherWording);
      final finding = await check(second);
      expect(finding.tier, DuplicateTier.probable);
      expect(finding.matchedRecord!.id, saved.id);
      expect(finding.matchedRecord!.importProvenance, ImportProvenance.sms);
    });

    test('opposite direction group and another currency never match', () async {
      await manualExpense(type: FinanceEntryType.income);
      await manualExpense(
        amount: const Money.fromMinorUnits(12550, Currency.usd),
      );
      final item = await pasteOne(_purchase);
      expect((await check(item)).tier, DuplicateTier.none);
    });

    test('the one-day window: the day before and after match; two days do '
        'not', () async {
      final item = await pasteOne(_purchase); // dated 04/03/2026
      for (final (day, expected) in [
        (DateTime(2026, 3, 2), DuplicateTier.none),
        (DateTime(2026, 3, 3), DuplicateTier.probable),
        (DateTime(2026, 3, 5), DuplicateTier.probable),
        (DateTime(2026, 3, 6), DuplicateTier.none),
      ]) {
        final id = await manualExpense(date: day);
        expect((await check(item)).tier, expected, reason: '$day');
        await h.finance.deleteEntry(id);
      }
    });

    test('the one-day window is calendar days, across a month end', () async {
      await h.stage(
        buildPendingImport(occurredOn: DateTime(2026, 3, 1)),
        raw: 'x',
      );
      final item = await h.item('pending-1');
      final before = await manualExpense(date: DateTime(2026, 2, 28));
      expect((await check(item)).tier, DuplicateTier.probable);
      await h.finance.deleteEntry(before);
      await manualExpense(date: DateTime(2026, 2, 27));
      expect((await check(item)).tier, DuplicateTier.none);
    });

    test('the re-check on Add uses the edited amount', () async {
      await manualExpense(amount: const Money.egp(13000));
      final item = await pasteOne(_purchase);
      expect((await check(item)).tier, DuplicateTier.none);

      final edited = draftFor(item, minor: 13000);
      final result = await h.add(pendingId: item.id, draft: edited);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ProbableDuplicateFailure>());
      expect(
        (failure! as ProbableDuplicateFailure).finding.tier,
        DuplicateTier.probable,
      );
      expect(await h.savedRecords(), 1);
    });

    test('the re-check on Add uses the edited date', () async {
      await manualExpense();
      final item = await pasteOne(_purchase);
      expect((await check(item)).tier, DuplicateTier.probable);

      final moved = draftFor(item, date: DateTime(2026, 3, 1));
      final result = await h.add(pendingId: item.id, draft: moved);
      expect(result.isRight(), isTrue);
      expect(await h.savedRecords(), 2);
    });

    test('the re-check on Add uses the edited type', () async {
      await manualExpense(type: FinanceEntryType.income);
      final item = await pasteOne(_purchase);
      expect((await check(item)).tier, DuplicateTier.none);
      final asIncome = draftFor(item, type: SuggestedRecordType.income);
      final result = await h.add(pendingId: item.id, draft: asIncome);
      expect(result.getLeft().toNullable(), isA<ProbableDuplicateFailure>());
    });

    test('"It\'s the same, don\'t add" closes the item and leaves the '
        'existing record untouched', () async {
      final manualId = await manualExpense(note: 'Example Cafe');
      final before = await h.database.select(h.database.financeEntries).get();
      final item = await pasteOne(_purchase);
      expect((await check(item)).matchedRecord!.id, manualId);

      expect(
        await h.closeAsDuplicate(item.id),
        const Right<Failure, Unit>(unit),
      );
      expect(await h.database.select(h.database.financeEntries).get(), before);
      expect(await h.pending(), isEmpty);
      final closed = await h.item(item.id);
      expect(closed.status, SmsImportStatus.duplicateClosed);
      // A retried Add on the closed item is refused, nothing is written.
      final retry = await h.add(
        pendingId: item.id,
        draft: draftFor(item),
        duplicateOverride: true,
      );
      expect(retry.getLeft().toNullable(), isA<ImportAlreadyDecidedFailure>());
      expect(await h.savedRecords(), 1);
    });
  });

  // -------------------------------------------------------------- reversal

  group('authorization reversal (FR-024b)', () {
    test('after an added purchase it shows the matched record, never as a '
        'duplicate, and never touches it', () async {
      final purchase = await pasteOne(_hotel);
      final saved = await addExpense(purchase);
      final before = await h.database.select(h.database.financeEntries).get();

      final reversal = await pasteOne(_reversal);
      expect(reversal.kind, SmsKind.authorizationReversal);
      expect(reversal.suggestedType, SuggestedRecordType.ignore);
      expect(reversal.warnings, contains(SmsWarning.reversalHint));

      final finding = await check(
        reversal,
        draftFor(reversal, type: SuggestedRecordType.expense),
      );
      expect(finding.tier, DuplicateTier.none);
      expect(finding.isProbable, isFalse);
      expect(finding.matchedRecord!.id, saved.id);
      expect(await h.database.select(h.database.financeEntries).get(), before);
    });

    test('with no saved purchase there is no matched record', () async {
      final reversal = await pasteOne(_reversal);
      final finding = await check(reversal);
      expect(finding.tier, DuplicateTier.none);
      expect(finding.matchedRecord, isNull);
    });
  });

  // ------------------------------------------------------------------- fee

  group('in-message fee (FR-030a)', () {
    test('yields exactly two pending items, and re-ingesting by any path '
        'yields none', () async {
      final first = await h.pasteText(_atmWithFee);
      expect(first.newIds, hasLength(2));
      final items = await h.pending();
      final parent = items.singleWhere((i) => i.parentImportId == null);
      final fee = items.singleWhere((i) => i.parentImportId != null);
      expect(parent.amount, const Money.egp(200000));
      expect(fee.amount, const Money.egp(1500));
      expect(fee.kind, SmsKind.fee);
      expect(fee.parentImportId, parent.id);
      expect(fee.fingerprint, isNot(parent.fingerprint));

      expect((await h.pasteText(_atmWithFee)).newIds, isEmpty);
      expect((await h.shareText(_atmWithFee)).newIds, isEmpty);
      final rescan = await h.ingestInbox([_atmWithFee]);
      expect(rescan.createdPending, 0);
      expect(rescan.alreadyKnown, 2);
      expect(await h.rows(), hasLength(2));
    });

    test('the fee and its parent are never duplicates of each other', () async {
      await h.pasteText(_atmWithFee);
      for (final item in await h.pending()) {
        final finding = await check(item);
        expect(finding.tier, DuplicateTier.none);
        expect(finding.matchedPendingId, isNull);
      }
    });
  });

  // ---------------------------------------------------------- own transfer

  group('cross-bank own transfer (FR-051d)', () {
    test('a same-amount pair across banks within one day is flagged on '
        'both items, and neither is blocked', () async {
      await h.scan([
        inboxRow(1, _nbeTransfer('05/03/2026')),
        inboxRow(2, _cibIncoming('05/03/2026'), address: 'CIB'),
      ]);
      final items = await h.pending();
      expect(items.map((i) => i.bankId).toSet(), {'nbe', 'cib'});
      for (final item in items) {
        final type = item.direction == SmsDirection.credit
            ? SuggestedRecordType.income
            : SuggestedRecordType.expense;
        final finding = await check(item, draftFor(item, type: type));
        expect(finding.possibleOwnTransfer, isTrue, reason: item.bankId);
        expect(finding.isProbable, isFalse);
      }
      for (final item in items) {
        final type = item.direction == SmsDirection.credit
            ? SuggestedRecordType.income
            : SuggestedRecordType.expense;
        final added = await h.add(
          pendingId: item.id,
          draft: draftFor(item, type: type),
        );
        expect(added.isRight(), isTrue, reason: item.bankId);
      }
    });

    test('after one side is added, the other is still flagged', () async {
      await h.scan([
        inboxRow(1, _nbeTransfer('05/03/2026')),
        inboxRow(2, _cibIncoming('06/03/2026'), address: 'CIB'),
      ]);
      final nbe = (await h.pending()).singleWhere((i) => i.bankId == 'nbe');
      await addExpense(nbe);
      final cib = (await h.pending()).single;
      final finding = await check(
        cib,
        draftFor(cib, type: SuggestedRecordType.income),
      );
      expect(finding.possibleOwnTransfer, isTrue);
    });

    test('the same bank, or more than one day apart, is not flagged', () async {
      await h.scan([
        inboxRow(1, _nbeTransfer('05/03/2026')),
        inboxRow(2, _nbeCredit('05/03/2026')),
        inboxRow(3, _cibIncoming('01/03/2026'), address: 'CIB'),
      ]);
      for (final item in await h.pending()) {
        final type = item.direction == SmsDirection.credit
            ? SuggestedRecordType.income
            : SuggestedRecordType.expense;
        final finding = await check(item, draftFor(item, type: type));
        expect(finding.possibleOwnTransfer, isFalse, reason: item.bankId);
      }
    });
  });

  // ------------------------------------------------------- foreign amount

  group('stated original-currency amount (FR-059)', () {
    // No shipped bank template captures a stated original amount yet
    // (decisions/phase5-us5.md), so the item is staged with the value the
    // parser contract defines.
    PendingSmsImport billedInEgp() => buildPendingImport(
      amount: const Money.egp(100000),
      foreignAmount: const Money.fromMinorUnits(2000, Currency.usd),
      foreignAmountText: 'USD 20.00',
      warnings: const {SmsWarning.foreignCurrencyBilledAmount},
    );

    test(
      'a purchase typed in USD matches the EGP-billed SMS stating USD',
      () async {
        final typed = await manualExpense(
          amount: const Money.fromMinorUnits(2000, Currency.usd),
        );
        await h.stage(billedInEgp(), raw: 'x');
        final item = await h.item('pending-1');
        final finding = await check(item);
        expect(finding.tier, DuplicateTier.probable);
        expect(finding.matchedRecord!.id, typed);
        final asked = await h.add(pendingId: item.id, draft: draftFor(item));
        expect(asked.getLeft().toNullable(), isA<ProbableDuplicateFailure>());
      },
    );

    test('a different USD amount does not match (no conversion)', () async {
      await manualExpense(
        amount: const Money.fromMinorUnits(2500, Currency.usd),
      );
      await h.stage(billedInEgp(), raw: 'x');
      expect((await check(await h.item('pending-1'))).tier, DuplicateTier.none);
    });
  });
}
