import 'dart:convert';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/change_history/change_history_diff.dart';
import '../../../../core/design_system/change_history/change_history_row.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_audit.dart';
import '../../domain/entities/finance_entry_type.dart';

/// Maps an income or expense entry's audit rows to feature-neutral
/// [ChangeHistoryRow]s (022 D2), the finance twin of
/// `TransactionAuditRowMapper`. An `edited` row stores the values *before*
/// the edit, so the "after" of row i is the before-image of the next row
/// that has one, or the live [FinanceEntry] for the last. Edit rows show only
/// the fields that changed (old → new), including the type and category, so
/// a switch between income and expense is visible (RF-08). `created` shows
/// the initial values; `deleted` and `restored` carry no values. Pure.
class FinanceEntryAuditRowMapper {
  FinanceEntryAuditRowMapper({
    required this.l10n,
    required String locale,
    required this.categoryNames,
  }) : _locale = locale;

  final AppLocalizations l10n;
  final String _locale;

  /// Display name by category id, resolved by the screen. An id that is
  /// missing falls back to the generic "Other" label.
  final Map<String, String> categoryNames;

  List<ChangeHistoryRow> rows(
    List<FinanceEntryAudit> audits,
    FinanceEntry current,
  ) {
    final images = [for (final a in audits) _parse(a.previousValuesJson)];
    final currentSnap = _snapshot(
      amount: _money(current.amount.minorUnits, current.amount.currency.code),
      type: current.type.dbValue,
      categoryId: current.categoryId,
      date: current.date,
      note: current.note,
    );

    // The values right after row [i]: the next readable before-image.
    List<ChangeHistoryField> after(int i) {
      for (var j = i + 1; j < audits.length; j++) {
        final image = images[j];
        if (image != null) return image;
      }
      return currentSnap;
    }

    return [
      for (var i = 0; i < audits.length; i++)
        ChangeHistoryRow(
          label: switch (audits[i].changeType) {
            FinanceAuditChange.created => l10n.changeHistoryCreated,
            FinanceAuditChange.edited => l10n.changeHistoryEdited,
            FinanceAuditChange.deleted => l10n.changeHistoryDeleted,
            FinanceAuditChange.restored => l10n.changeHistoryRestored,
          },
          timestamp: audits[i].changedAt,
          fields: switch (audits[i].changeType) {
            FinanceAuditChange.created => ChangeHistoryDiff.all(after(i)),
            FinanceAuditChange.edited =>
              images[i] == null
                  ? const []
                  : ChangeHistoryDiff.changed(
                      images[i]!,
                      after(i),
                      l10n.changeHistoryChange,
                      empty: l10n.changeHistoryNoValue,
                    ),
            FinanceAuditChange.deleted ||
            FinanceAuditChange.restored => const [],
          },
        ),
    ];
  }

  List<ChangeHistoryField>? _parse(String? json) {
    if (json == null) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(json);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final minor = decoded['amountMinorUnits'];
    final code = decoded['currencyCode'];
    final type = decoded['type'];
    final categoryId = decoded['categoryId'];
    final date = decoded['date'];
    final note = decoded['note'];
    return _snapshot(
      amount: minor is int && code is String ? _money(minor, code) : null,
      type: type is String ? type : null,
      categoryId: categoryId is String ? categoryId : null,
      date: _parseDate(date),
      note: note is String ? note : null,
    );
  }

  /// The stored previous date: a `yyyy-MM-dd` calendar day (read as that day
  /// in the local zone), or, for rows written before the day format, epoch
  /// milliseconds.
  static DateTime? _parseDate(Object? value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
      if (m == null) return null;
      return DateTime(
        int.parse(m.group(1)!),
        int.parse(m.group(2)!),
        int.parse(m.group(3)!),
      );
    }
    return null;
  }

  List<ChangeHistoryField> _snapshot({
    required String? amount,
    required String? type,
    required String? categoryId,
    required DateTime? date,
    required String? note,
  }) => [
    if (amount != null)
      ChangeHistoryField(label: l10n.amountLabel, value: amount),
    if (type != null)
      ChangeHistoryField(
        label: l10n.changeHistoryTypeField,
        value: type == FinanceEntryType.income.dbValue
            ? l10n.financeTypeIncome
            : l10n.financeTypeExpense,
      ),
    if (categoryId != null)
      ChangeHistoryField(
        label: l10n.financeCategoryLabel,
        value: categoryNames[categoryId] ?? l10n.financeCategoryOther,
      ),
    if (date != null)
      ChangeHistoryField(
        label: l10n.dateLabel,
        value: AppDateFormatter(locale: _locale).format(date),
      ),
    if (note != null && note.isNotEmpty)
      ChangeHistoryField(label: l10n.changeHistoryNoteField, value: note),
  ];

  /// An unknown (corrupted) currency code falls back to the raw minor units
  /// and code rather than failing the whole sheet.
  String _money(int minorUnits, String code) {
    final currency = Currency.tryFromCode(code);
    if (currency == null) return '$minorUnits $code';
    return CurrencyFormatter(
      currency: currency,
      locale: _locale,
    ).formatWithSymbol(Money.fromMinorUnits(minorUnits, currency));
  }
}
