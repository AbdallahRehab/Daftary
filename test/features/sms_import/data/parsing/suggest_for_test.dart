import 'package:daftary/features/sms_import/data/parsing/suggest_for.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/services/sms_message_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// 023 T051: the mapping table of parser-contract §8, row by row.
void main() {
  const seeds = {
    'other': 'cat-other',
    'other_income': 'cat-other-income',
    'salary': 'cat-salary',
    'restaurants': 'cat-restaurants',
    'electricity': 'cat-electricity',
  };
  const options = ParserOptions(activeCategoryIdsBySeedKey: seeds);

  SmsSuggestion suggest(
    SmsKind kind, {
    SmsDirection direction = SmsDirection.debit,
    ParserOptions opts = options,
    String? merchantKey,
    String? counterparty,
    String matchText = '',
  }) => suggestFor(
    kind: kind,
    direction: direction,
    source: SmsSource.inboxScan,
    options: opts,
    merchantKey: merchantKey,
    counterparty: counterparty,
    matchText: matchText,
  );

  test('cardPurchase: expense; learned, then keyword, then other', () {
    expect(
      suggest(SmsKind.cardPurchase, merchantKey: 'example cafe'),
      SmsSuggestion(
        type: SuggestedRecordType.expense,
        categoryId: 'cat-restaurants',
      ),
    );
    expect(
      suggest(SmsKind.cardPurchase, merchantKey: 'example store').categoryId,
      'cat-other',
    );
    const learned = ParserOptions(
      activeCategoryIdsBySeedKey: seeds,
      activeCategoryIds: {'cat-custom'},
      learnedCategoryIds: {('example cafe', 'expense'): 'cat-custom'},
    );
    expect(
      suggest(
        SmsKind.cardPurchase,
        merchantKey: 'example cafe',
        opts: learned,
      ).categoryId,
      'cat-custom',
    );
  });

  test('an archived learned mapping is skipped', () {
    const archived = ParserOptions(
      activeCategoryIdsBySeedKey: seeds,
      learnedCategoryIds: {('example cafe', 'expense'): 'cat-archived'},
    );
    expect(
      suggest(
        SmsKind.cardPurchase,
        merchantKey: 'example cafe',
        opts: archived,
      ).categoryId,
      'cat-restaurants',
    );
  });

  test('a missing seed category is never suggested', () {
    expect(
      suggest(SmsKind.cardPurchase, opts: const ParserOptions()).categoryId,
      isNull,
    );
  });

  test('atmWithdrawal: ignore by default; expense when counted', () {
    expect(
      suggest(SmsKind.atmWithdrawal),
      SmsSuggestion(
        type: SuggestedRecordType.ignore,
        warnings: const {SmsWarning.atmIgnoredByDefault},
      ),
    );
    expect(
      suggest(
        SmsKind.atmWithdrawal,
        opts: const ParserOptions(
          countCashWithdrawals: true,
          activeCategoryIdsBySeedKey: seeds,
        ),
      ),
      SmsSuggestion(type: SuggestedRecordType.expense, categoryId: 'cat-other'),
    );
  });

  test('cardOrLoanSettlement: ignore', () {
    expect(suggest(SmsKind.cardOrLoanSettlement).warnings, {
      SmsWarning.cardSettlementSuggestedIgnore,
    });
    expect(
      suggest(SmsKind.cardOrLoanSettlement).type,
      SuggestedRecordType.ignore,
    );
  });

  test('billPayment: expense with a bill keyword seed', () {
    expect(
      suggest(
        SmsKind.billPayment,
        matchText: 'electricity bill payment',
      ).categoryId,
      'cat-electricity',
    );
    expect(suggest(SmsKind.billPayment).categoryId, 'cat-other');
  });

  test('fee: expense, other, feeSeparateItem', () {
    expect(
      suggest(SmsKind.fee),
      SmsSuggestion(
        type: SuggestedRecordType.expense,
        categoryId: 'cat-other',
        warnings: const {SmsWarning.feeSeparateItem},
      ),
    );
  });

  test('salary: income with the salary seed', () {
    expect(
      suggest(SmsKind.salary, direction: SmsDirection.credit),
      SmsSuggestion(type: SuggestedRecordType.income, categoryId: 'cat-salary'),
    );
  });

  test('otherDeposit: unset', () {
    expect(
      suggest(SmsKind.otherDeposit, direction: SmsDirection.credit).type,
      SuggestedRecordType.unset,
    );
  });

  group('transfers and people (FR-051a, FR-054, US7-1)', () {
    const people = ParserOptions(
      activeCategoryIdsBySeedKey: seeds,
      peopleNames: [
        PersonNameRef(id: 'p1', normalizedName: 'ahmed'),
        PersonNameRef(id: 'p2', normalizedName: 'sara'),
        PersonNameRef(id: 'p3', normalizedName: 'sara'),
      ],
    );

    test('incoming transfer with a name match: Income default plus the '
        'one-tap Received person', () {
      expect(
        suggest(
          SmsKind.transferIn,
          direction: SmsDirection.credit,
          opts: people,
          counterparty: 'Ahmed',
        ),
        SmsSuggestion(
          type: SuggestedRecordType.income,
          categoryId: 'cat-other-income',
          personId: 'p1',
        ),
      );
    });

    test('incoming transfer with no match or several matches: Income, no '
        'person', () {
      for (final name in ['Mona', 'Sara', null, '   ']) {
        expect(
          suggest(
            SmsKind.transferIn,
            direction: SmsDirection.credit,
            opts: people,
            counterparty: name,
          ),
          SmsSuggestion(
            type: SuggestedRecordType.income,
            categoryId: 'cat-other-income',
          ),
          reason: '$name',
        );
      }
    });

    test('outgoing transfer with a name match: Expense default plus the '
        'one-tap Given person', () {
      expect(
        suggest(SmsKind.transferOut, opts: people, counterparty: ' Ahmed '),
        SmsSuggestion(
          type: SuggestedRecordType.expense,
          categoryId: 'cat-other',
          personId: 'p1',
        ),
      );
    });

    test('outgoing transfer with no match or several matches: Expense, no '
        'person', () {
      for (final name in ['Mona', 'Sara', null]) {
        expect(
          suggest(SmsKind.transferOut, opts: people, counterparty: name),
          SmsSuggestion(
            type: SuggestedRecordType.expense,
            categoryId: 'cat-other',
          ),
        );
      }
    });

    test('a person is never suggested for anything but a named transfer', () {
      for (final kind in SmsKind.values) {
        if (kind == SmsKind.transferIn || kind == SmsKind.transferOut) {
          continue;
        }
        expect(
          suggest(kind, opts: people, counterparty: 'Ahmed').personId,
          isNull,
          reason: kind.name,
        );
      }
    });

    test('own-account transfer: Ignore, even with a name match', () {
      expect(
        suggest(
          SmsKind.ownAccountTransfer,
          opts: people,
          counterparty: 'Ahmed',
        ),
        SmsSuggestion(
          type: SuggestedRecordType.ignore,
          warnings: {SmsWarning.ownAccountSuggestedIgnore},
        ),
      );
    });

    test('a learned transfer category wins over the seed', () {
      const learned = ParserOptions(
        activeCategoryIdsBySeedKey: seeds,
        activeCategoryIds: {'cat-family'},
        learnedCategoryIds: {('ahmed', 'expense'): 'cat-family'},
        peopleNames: [PersonNameRef(id: 'p1', normalizedName: 'ahmed')],
      );
      expect(
        suggest(
          SmsKind.transferOut,
          opts: learned,
          merchantKey: 'ahmed',
          counterparty: 'Ahmed',
        ),
        SmsSuggestion(
          type: SuggestedRecordType.expense,
          categoryId: 'cat-family',
          personId: 'p1',
        ),
      );
    });
  });

  test('refund, reversal and own-account: ignore with their hint', () {
    final cases = {
      SmsKind.refund: SmsWarning.refundHint,
      SmsKind.authorizationReversal: SmsWarning.reversalHint,
      SmsKind.ownAccountTransfer: SmsWarning.ownAccountSuggestedIgnore,
    };
    cases.forEach((kind, warning) {
      expect(
        suggest(kind, direction: SmsDirection.credit),
        SmsSuggestion(type: SuggestedRecordType.ignore, warnings: {warning}),
        reason: kind.name,
      );
    });
  });

  test('unknown: unset when direction is unknown, expense when debit', () {
    expect(
      suggest(SmsKind.unknown, direction: SmsDirection.unknown).type,
      SuggestedRecordType.unset,
    );
    expect(
      suggest(SmsKind.unknown),
      SmsSuggestion(type: SuggestedRecordType.expense, categoryId: 'cat-other'),
    );
  });

  test('never sets possibleOwnTransfer', () {
    for (final kind in SmsKind.values) {
      for (final direction in SmsDirection.values) {
        expect(
          suggest(kind, direction: direction).warnings,
          isNot(contains(SmsWarning.possibleOwnTransfer)),
        );
      }
    }
  });
}
