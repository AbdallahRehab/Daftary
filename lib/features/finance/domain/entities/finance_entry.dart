import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'finance_entry_type.dart';

/// A single recorded income or expense event belonging to the user — never
/// to another `Person`. Structurally parallel to, but entirely independent
/// from, `MoneyTransaction` (research.md Decision 1).
class FinanceEntry extends Equatable {
  const FinanceEntry({
    required this.id,
    required this.idempotencyKey,
    required this.categoryId,
    required this.type,
    required this.amount,
    required this.date,
    required this.createdAt,
    this.note,
    this.editedAt,
    this.deletedAt,
  });

  final String id;

  /// Client-generated once per save action; a retried insert with the same
  /// key is a no-op returning the existing row (FR-021).
  final String idempotencyKey;

  /// Required — there are no uncategorized entries (FR-003).
  final String categoryId;

  /// Always equal to the referenced category's type, enforced at the
  /// repository level rather than left to the schema alone.
  final FinanceEntryType type;

  /// Always strictly positive (FR-003). The income/expense direction lives
  /// in [type], never in the amount's sign.
  final Money amount;

  /// Date-only. Defaults to today; future dates are accepted (FR-001).
  final DateTime date;

  final String? note;
  final DateTime createdAt;

  /// `null` means never edited — drives the "edited" UI marker (FR-019).
  final DateTime? editedAt;

  /// Soft-delete tombstone; `null` means active. Set immediately on delete
  /// and un-set by a restore within the undo window (research.md
  /// Decision 8).
  final DateTime? deletedAt;

  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;
  bool get isIncome => type == FinanceEntryType.income;
  bool get isExpense => type == FinanceEntryType.expense;

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    categoryId,
    type,
    amount,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  ];
}
