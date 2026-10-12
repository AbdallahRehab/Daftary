import 'package:flutter/widgets.dart';

import '../../../../core/confidence/field_confidence.dart';
import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/parse_confidence.dart';
import '../../domain/entities/review_draft.dart';
import '../../domain/entities/sms_import_enums.dart';
import 'bidi_text.dart';

/// Shared display helpers of the bank-message screens. Formatting goes
/// through the app's formatters (Western digits in Arabic, FR-090); every
/// string comes from the ARB files.
abstract final class SmsImportLabels {
  static String _lang(BuildContext context) =>
      Localizations.localeOf(context).languageCode;

  /// "125.50 EGP", isolated as an LTR token.
  static String money(BuildContext context, Money money) => BidiIsolate.ltr(
    CurrencyFormatter(
      currency: money.currency,
      locale: _lang(context),
    ).formatWithSymbol(money),
  );

  static String date(BuildContext context, DateTime date) =>
      AppDateFormatter(locale: _lang(context)).format(date);

  /// Ids of the registered bank profiles that have a localized name.
  static const Set<String> _namedBanks = {
    'nbe',
    'banque_misr',
    'cib',
    'qnb',
    'banque_du_caire',
    'aaib',
    'instapay',
  };

  /// The bank's display name: a registered profile shows its localized
  /// name, any other id its isolated code, and the generic parser shows
  /// "Unrecognized bank".
  static String bank(AppLocalizations l10n, String bankId) =>
      bankId == 'generic' || bankId.isEmpty
      ? l10n.smsImportPendingUnknownBank
      : _namedBanks.contains(bankId)
      ? l10n.smsImportBankName(bankId)
      : BidiIsolate.ltr(bankId.toUpperCase());

  /// "•••• 1234" as an LTR token.
  static String maskedCard(String last4) => BidiIsolate.ltr('•••• $last4');

  static String kind(AppLocalizations l10n, SmsKind kind) =>
      l10n.smsImportKindLabel(kind == SmsKind.unknown ? 'other' : kind.name);

  static String warning(AppLocalizations l10n, SmsWarning warning) =>
      l10n.smsImportWarningText(warning.name);

  /// The type label, reusing the existing type strings.
  static String type(AppLocalizations l10n, SuggestedRecordType type) =>
      switch (type) {
        SuggestedRecordType.expense => l10n.financeTypeExpense,
        SuggestedRecordType.income => l10n.financeTypeIncome,
        SuggestedRecordType.given => l10n.directionGiven,
        SuggestedRecordType.received => l10n.directionReceived,
        SuggestedRecordType.ignore => l10n.smsImportPendingIgnoreSuggested,
        SuggestedRecordType.unset => l10n.smsImportPendingChooseType,
      };

  static String field(AppLocalizations l10n, ReviewField field) =>
      switch (field) {
        ReviewField.type => l10n.smsImportReviewFieldType,
        ReviewField.amount => l10n.smsImportReviewFieldAmount,
        ReviewField.currency => l10n.smsImportReviewFieldCurrency,
        ReviewField.date => l10n.smsImportReviewFieldDate,
        ReviewField.category => l10n.smsImportReviewFieldCategory,
        ReviewField.person => l10n.smsImportReviewFieldPerson,
        ReviewField.note => l10n.smsImportReviewFieldNote,
      };

  /// The missing fields in the screen-reader order of the form.
  static String missingList(AppLocalizations l10n, Set<ReviewField> fields) => [
    for (final f in ReviewField.values)
      if (fields.contains(f)) field(l10n, f),
  ].join(l10n.smsImportReviewListSeparator);

  /// The overall level rendered with the shared `ConfidenceIndicator`.
  static FieldConfidence overall(OverallConfidence level) =>
      FieldConfidence.read(switch (level) {
        OverallConfidence.low => FieldConfidenceLevel.low,
        OverallConfidence.medium => FieldConfidenceLevel.medium,
        OverallConfidence.high => FieldConfidenceLevel.high,
      });

  static String confidenceText(
    AppLocalizations l10n,
    OverallConfidence level,
  ) => switch (level) {
    OverallConfidence.low => l10n.ocrConfidenceLow,
    OverallConfidence.medium => l10n.ocrConfidenceMedium,
    OverallConfidence.high => l10n.ocrConfidenceHigh,
  };
}
