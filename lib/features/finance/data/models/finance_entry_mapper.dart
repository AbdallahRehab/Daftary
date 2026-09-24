import '../../../../core/database/app_database.dart' as db;
import '../../../../core/money/money.dart';
import '../../domain/entities/finance_entry.dart' as domain;
import '../../domain/entities/finance_entry_type.dart';

/// Maps `finance_entries` rows to the domain [domain.FinanceEntry].
extension FinanceEntryMapper on db.FinanceEntry {
  domain.FinanceEntry toDomain() => domain.FinanceEntry(
    id: id,
    idempotencyKey: idempotencyKey,
    categoryId: categoryId,
    type: financeEntryTypeFromDb(type),
    amount: Money.fromMinorUnits(
      amountMinorUnits,
      Currency.fromCode(currencyCode),
    ),
    date: DateTime.fromMillisecondsSinceEpoch(date),
    note: note,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
    editedAt: editedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(editedAt!),
    deletedAt: deletedAt == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(deletedAt!),
  );
}

/// Strips a [DateTime] to its date at local midnight, in millis — entries
/// are day-granular (data-model.md), so a time component would make two
/// entries on the same day sort and filter inconsistently.
int dateOnlyMillis(DateTime date) =>
    DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
