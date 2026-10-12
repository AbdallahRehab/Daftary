import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'sms_import_enums.dart';

/// A field the review screen can flag as missing or invalid (FR-043a).
/// Codes only: a failure or state that carries these never carries a value.
enum ReviewField { type, amount, currency, date, category, person, note }

/// The user's edits on the review screen: cubit-local state, never
/// persisted (FR-047, data-model §2.9).
///
/// [validate] is the pure domain rule that mirrors the manual-entry limits
/// (FR-043a, FR-044), so the cubit and `AddImportedTransaction` never
/// duplicate it.
class ReviewDraft extends Equatable {
  const ReviewDraft({
    this.type,
    this.amountMinorUnits,
    this.currencyCode,
    this.date,
    this.categoryId,
    this.personId,
    this.note,
  });

  /// Largest whole-unit amount: 12 digits, as `CurrencyFormatter.parse`.
  static const int maxWholeUnits = 999999999999;

  /// The manual forms' note cap (`maxLength: 500`).
  static const int maxNoteLength = 500;

  /// The chosen record type. Only [SuggestedRecordType.isSavable] values
  /// can be added; `ignore`, `unset` and `null` are reported as
  /// [ReviewField.type].
  final SuggestedRecordType? type;

  /// The amount in minor units of [currencyCode].
  final int? amountMinorUnits;

  /// ISO 4217 code; must be in the catalog (EGP, USD, EUR, SAR, AED, GBP).
  final String? currencyCode;

  /// Date-only.
  final DateTime? date;

  /// Required for expense and income.
  final String? categoryId;

  /// Required for given and received.
  final String? personId;

  /// Optional; never prefilled with message text (FR-049).
  final String? note;

  /// The catalog currency, or `null` when absent or outside the catalog.
  Currency? get currency {
    final code = currencyCode;
    return code == null ? null : Currency.tryFromCode(code);
  }

  /// The amount as [Money] when both parts are present and the currency is
  /// in the catalog.
  Money? get money {
    final minor = amountMinorUnits;
    final catalogCurrency = currency;
    if (minor == null || catalogCurrency == null) return null;
    return Money.fromMinorUnits(minor, catalogCurrency);
  }

  /// Every field that blocks Add. Empty means the draft can be added.
  ///
  /// - type: one of expense, income, given, received;
  /// - amount: present, > 0 and at most 12 whole digits;
  /// - currency: present and in the catalog;
  /// - date: present;
  /// - category (expense/income) or person (given/received): non-blank;
  /// - note: at most 500 characters (counted as Unicode code points).
  Set<ReviewField> validate() {
    final missing = <ReviewField>{};
    final chosenType = type;
    if (chosenType == null || !chosenType.isSavable) {
      missing.add(ReviewField.type);
    }

    final catalogCurrency = currency;
    if (catalogCurrency == null) missing.add(ReviewField.currency);

    final minor = amountMinorUnits;
    final perMajor = catalogCurrency?.minorUnitsPerMajor ?? 100;
    if (minor == null || minor <= 0 || minor ~/ perMajor > maxWholeUnits) {
      missing.add(ReviewField.amount);
    }

    if (date == null) missing.add(ReviewField.date);

    if (chosenType != null && chosenType.isFinanceEntry && _blank(categoryId)) {
      missing.add(ReviewField.category);
    }
    if (chosenType != null &&
        chosenType.isPersonTransaction &&
        _blank(personId)) {
      missing.add(ReviewField.person);
    }

    final text = note;
    if (text != null && text.runes.length > maxNoteLength) {
      missing.add(ReviewField.note);
    }
    return missing;
  }

  static bool _blank(String? value) => value == null || value.trim().isEmpty;

  ReviewDraft copyWith({
    SuggestedRecordType? type,
    bool clearType = false,
    int? amountMinorUnits,
    bool clearAmount = false,
    String? currencyCode,
    bool clearCurrency = false,
    DateTime? date,
    bool clearDate = false,
    String? categoryId,
    bool clearCategory = false,
    String? personId,
    bool clearPerson = false,
    String? note,
    bool clearNote = false,
  }) {
    return ReviewDraft(
      type: clearType ? null : (type ?? this.type),
      amountMinorUnits: clearAmount
          ? null
          : (amountMinorUnits ?? this.amountMinorUnits),
      currencyCode: clearCurrency ? null : (currencyCode ?? this.currencyCode),
      date: clearDate ? null : (date ?? this.date),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      personId: clearPerson ? null : (personId ?? this.personId),
      note: clearNote ? null : (note ?? this.note),
    );
  }

  @override
  List<Object?> get props => [
    type,
    amountMinorUnits,
    currencyCode,
    date,
    categoryId,
    personId,
    note,
  ];

  /// Redacted: never prints the amount, the note or an id (FR-097).
  @override
  String toString() =>
      'ReviewDraft(type: ${type?.name}, '
      'missing: ${validate().map((f) => f.name).join(',')})';
}
