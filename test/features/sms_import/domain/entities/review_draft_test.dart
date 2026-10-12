import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T026: `ReviewDraft.validate()` mirrors the manual limits
/// (FR-043a, FR-044).
void main() {
  final day = DateTime(2026, 3, 4);

  ReviewDraft expense() => ReviewDraft(
    type: SuggestedRecordType.expense,
    amountMinorUnits: 12550,
    currencyCode: 'EGP',
    date: day,
    categoryId: 'cat-1',
  );

  ReviewDraft given() => ReviewDraft(
    type: SuggestedRecordType.given,
    amountMinorUnits: 5000,
    currencyCode: 'USD',
    date: day,
    personId: 'person-1',
  );

  final table = <({String name, ReviewDraft draft, Set<ReviewField> missing})>[
    // Complete drafts of each savable type.
    (name: 'complete expense', draft: expense(), missing: {}),
    (
      name: 'complete income',
      draft: expense().copyWith(type: SuggestedRecordType.income),
      missing: {},
    ),
    (name: 'complete given', draft: given(), missing: {}),
    (
      name: 'complete received',
      draft: given().copyWith(type: SuggestedRecordType.received),
      missing: {},
    ),
    // Type.
    (
      name: 'no type',
      draft: expense().copyWith(clearType: true),
      missing: {ReviewField.type},
    ),
    (
      name: 'type ignore is not savable',
      draft: expense().copyWith(type: SuggestedRecordType.ignore),
      missing: {ReviewField.type},
    ),
    (
      name: 'type unset is not savable',
      draft: expense().copyWith(type: SuggestedRecordType.unset),
      missing: {ReviewField.type},
    ),
    // Amount.
    (
      name: 'no amount',
      draft: expense().copyWith(clearAmount: true),
      missing: {ReviewField.amount},
    ),
    (
      name: 'zero amount',
      draft: expense().copyWith(amountMinorUnits: 0),
      missing: {ReviewField.amount},
    ),
    (
      name: 'negative amount',
      draft: expense().copyWith(amountMinorUnits: -1),
      missing: {ReviewField.amount},
    ),
    (
      name: 'smallest amount (one minor unit)',
      draft: expense().copyWith(amountMinorUnits: 1),
      missing: {},
    ),
    (
      name: 'exactly 12 whole digits',
      draft: expense().copyWith(amountMinorUnits: 99999999999999),
      missing: {},
    ),
    (
      name: '13 whole digits',
      draft: expense().copyWith(amountMinorUnits: 100000000000000),
      missing: {ReviewField.amount},
    ),
    // Currency.
    (
      name: 'no currency',
      draft: expense().copyWith(clearCurrency: true),
      missing: {ReviewField.currency},
    ),
    (
      name: 'currency outside the catalog',
      draft: expense().copyWith(currencyCode: 'JPY'),
      missing: {ReviewField.currency},
    ),
    (
      name: 'lower-case code is not a catalog code',
      draft: expense().copyWith(currencyCode: 'egp'),
      missing: {ReviewField.currency},
    ),
    for (final code in ['EGP', 'USD', 'EUR', 'SAR', 'AED', 'GBP'])
      (
        name: 'catalog currency $code',
        draft: expense().copyWith(currencyCode: code),
        missing: <ReviewField>{},
      ),
    // Date.
    (
      name: 'no date',
      draft: expense().copyWith(clearDate: true),
      missing: {ReviewField.date},
    ),
    // Category and person.
    (
      name: 'expense without category',
      draft: expense().copyWith(clearCategory: true),
      missing: {ReviewField.category},
    ),
    (
      name: 'expense with a blank category',
      draft: expense().copyWith(categoryId: '  '),
      missing: {ReviewField.category},
    ),
    (
      name: 'income without category',
      draft: expense().copyWith(
        type: SuggestedRecordType.income,
        clearCategory: true,
      ),
      missing: {ReviewField.category},
    ),
    (
      name: 'given without person',
      draft: given().copyWith(clearPerson: true),
      missing: {ReviewField.person},
    ),
    (
      name: 'received with a blank person',
      draft: given().copyWith(type: SuggestedRecordType.received, personId: ''),
      missing: {ReviewField.person},
    ),
    (
      name: 'switching expense -> given moves the requirement to person',
      draft: expense().copyWith(type: SuggestedRecordType.given),
      missing: {ReviewField.person},
    ),
    (
      name: 'switching given -> expense moves the requirement to category',
      draft: given().copyWith(type: SuggestedRecordType.expense),
      missing: {ReviewField.category},
    ),
    // Note.
    (
      name: 'note of exactly 500 characters',
      draft: expense().copyWith(note: 'n' * 500),
      missing: {},
    ),
    (
      name: 'note of 501 characters',
      draft: expense().copyWith(note: 'n' * 501),
      missing: {ReviewField.note},
    ),
    (
      name: 'Arabic note of 500 characters',
      draft: expense().copyWith(note: 'ب' * 500),
      missing: {},
    ),
    // Everything missing at once.
    (
      name: 'empty draft',
      draft: const ReviewDraft(),
      missing: {
        ReviewField.type,
        ReviewField.amount,
        ReviewField.currency,
        ReviewField.date,
      },
    ),
  ];

  group('validate', () {
    for (final row in table) {
      test(row.name, () {
        expect(row.draft.validate(), row.missing);
      });
    }
  });

  group('money', () {
    test('built only with a catalog currency', () {
      expect(expense().money, const Money.egp(12550));
      expect(expense().copyWith(currencyCode: 'JPY').money, isNull);
      expect(expense().copyWith(clearAmount: true).money, isNull);
    });
  });

  group('copyWith', () {
    test('keeps unchanged values and clears with flags', () {
      final draft = expense().copyWith(note: 'x');
      expect(draft.copyWith(), draft);
      expect(draft.copyWith(clearNote: true).note, isNull);
      expect(draft.copyWith(clearCategory: true).categoryId, isNull);
      expect(draft.copyWith(clearDate: true).date, isNull);
    });
  });

  test('toString never prints the amount, note or ids', () {
    final text = expense()
        .copyWith(amountMinorUnits: 987654, note: 'Sentinel note')
        .toString();
    expect(text, isNot(contains('987654')));
    expect(text, isNot(contains('Sentinel')));
    expect(text, isNot(contains('cat-1')));
  });
}
