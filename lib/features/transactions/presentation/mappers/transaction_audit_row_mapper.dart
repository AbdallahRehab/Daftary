import 'dart:convert';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/change_history/change_history_diff.dart';
import '../../../../core/design_system/change_history/change_history_row.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/entities/transaction_audit_entry.dart';

/// Maps a transaction's audit entries to feature-neutral
/// [ChangeHistoryRow]s (022 C3). An audit entry stores the values *before*
/// its change, so the "after" of entry i is the before-image of the next
/// entry that has one — or the live [MoneyTransaction] for the last. Edit
/// rows show only the fields that changed (old → new); a created row shows
/// the initial values and a delete row the values at deletion. Pure — built
/// once per emission, never inside `build()`.
class TransactionAuditRowMapper {
  TransactionAuditRowMapper({required this.l10n, required String locale})
    : _locale = locale;

  final AppLocalizations l10n;
  final String _locale;

  List<ChangeHistoryRow> rows(
    List<TransactionAuditEntry> entries,
    MoneyTransaction current,
  ) {
    final images = [for (final e in entries) _parse(e.previousValuesJson)];
    final currentSnap = _fromTransaction(current);

    // The values right after entry [i]: the next readable before-image.
    List<ChangeHistoryField> after(int i) {
      for (var j = i + 1; j < entries.length; j++) {
        final image = images[j];
        if (image != null) return image;
      }
      return currentSnap;
    }

    return [
      for (var i = 0; i < entries.length; i++)
        ChangeHistoryRow(
          label: switch (entries[i].changeType) {
            AuditChangeType.created => l10n.changeHistoryCreated,
            AuditChangeType.edited => l10n.changeHistoryEdited,
            AuditChangeType.deleted => l10n.changeHistoryDeleted,
          },
          timestamp: entries[i].changedAt,
          fields: switch (entries[i].changeType) {
            AuditChangeType.created => ChangeHistoryDiff.all(after(i)),
            AuditChangeType.edited =>
              images[i] == null
                  ? const []
                  : ChangeHistoryDiff.changed(
                      images[i]!,
                      after(i),
                      l10n.changeHistoryChange,
                      empty: l10n.changeHistoryNoValue,
                    ),
            AuditChangeType.deleted =>
              images[i] == null
                  ? const []
                  : ChangeHistoryDiff.all(
                      images[i]!,
                      l10n.changeHistoryValueAtDeletion,
                    ),
          },
        ),
    ];
  }

  List<ChangeHistoryField> _fromTransaction(MoneyTransaction t) => _snapshot(
    amount: _money(t.amount.minorUnits, t.amount.currency.code),
    direction: t.direction,
    date: t.date,
    note: t.note,
  );

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
    final direction = decoded['direction'];
    final date = decoded['date'];
    final note = decoded['note'];
    return _snapshot(
      amount: minor is int && code is String ? _money(minor, code) : null,
      direction: switch (direction) {
        'given' => TransactionDirection.given,
        'received' => TransactionDirection.received,
        _ => null,
      },
      date: date is int ? DateTime.fromMillisecondsSinceEpoch(date) : null,
      note: note is String ? note : null,
    );
  }

  List<ChangeHistoryField> _snapshot({
    required String? amount,
    required TransactionDirection? direction,
    required DateTime? date,
    required String? note,
  }) => [
    if (amount != null)
      ChangeHistoryField(label: l10n.amountLabel, value: amount),
    if (direction != null)
      ChangeHistoryField(
        label: l10n.changeHistoryDirectionField,
        value: direction == TransactionDirection.given
            ? l10n.directionGiven
            : l10n.directionReceived,
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
