import 'dart:convert';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/change_history/change_history_diff.dart';
import '../../../../core/design_system/change_history/change_history_row.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/savings_contribution.dart';
import '../../domain/entities/savings_contribution_audit.dart';

/// Maps a contribution's audit rows to [ChangeHistoryRow]s (022 C3), the
/// savings twin of `TransactionAuditRowMapper`. Savings writes no
/// "created" audit, so a synthetic Created row is built from
/// `createdAt`. The entry's kind (contribution or withdrawal) can never
/// change, so no direction field is shown. Pure.
class ContributionAuditRowMapper {
  ContributionAuditRowMapper({required this.l10n, required String locale})
    : _locale = locale;

  final AppLocalizations l10n;
  final String _locale;

  List<ChangeHistoryRow> rows(
    List<SavingsContributionAudit> audits,
    SavingsContribution current,
  ) {
    final images = [for (final a in audits) _parse(a.previousValuesJson)];
    final currentSnap = _snapshot(
      amount: _money(
        current.enteredAmountMinorUnits,
        current.enteredCurrency.code,
      ),
      date: current.date,
      note: current.note,
    );

    List<ChangeHistoryField> after(int i) {
      for (var j = i + 1; j < audits.length; j++) {
        final image = images[j];
        if (image != null) return image;
      }
      return currentSnap;
    }

    return [
      ChangeHistoryRow(
        label: l10n.changeHistoryCreated,
        timestamp: current.createdAt,
        fields: ChangeHistoryDiff.all(after(-1)),
      ),
      for (var i = 0; i < audits.length; i++)
        ChangeHistoryRow(
          label: audits[i].changeType == ContributionAuditChange.edited
              ? l10n.changeHistoryEdited
              : l10n.changeHistoryDeleted,
          timestamp: audits[i].changedAt,
          fields: images[i] == null
              ? const []
              : audits[i].changeType == ContributionAuditChange.edited
              ? ChangeHistoryDiff.changed(
                  images[i]!,
                  after(i),
                  l10n.changeHistoryChange,
                  empty: l10n.changeHistoryNoValue,
                )
              : ChangeHistoryDiff.all(
                  images[i]!,
                  l10n.changeHistoryValueAtDeletion,
                ),
        ),
    ];
  }

  List<ChangeHistoryField>? _parse(String json) {
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final minor = decoded['enteredAmountMinorUnits'];
    final code = decoded['enteredCurrencyCode'];
    final date = decoded['date'];
    final note = decoded['note'];
    return _snapshot(
      amount: minor is int && code is String ? _money(minor, code) : null,
      date: date is int ? DateTime.fromMillisecondsSinceEpoch(date) : null,
      note: note is String ? note : null,
    );
  }

  List<ChangeHistoryField> _snapshot({
    required String? amount,
    required DateTime? date,
    required String? note,
  }) => [
    if (amount != null)
      ChangeHistoryField(label: l10n.amountLabel, value: amount),
    if (date != null)
      ChangeHistoryField(
        label: l10n.dateLabel,
        value: AppDateFormatter(locale: _locale).format(date),
      ),
    if (note != null && note.isNotEmpty)
      ChangeHistoryField(label: l10n.changeHistoryNoteField, value: note),
  ];

  String _money(int minorUnits, String code) {
    final currency = Currency.tryFromCode(code);
    if (currency == null) return '$minorUnits $code';
    return CurrencyFormatter(
      currency: currency,
      locale: _locale,
    ).formatWithSymbol(Money.fromMinorUnits(minorUnits, currency));
  }
}
