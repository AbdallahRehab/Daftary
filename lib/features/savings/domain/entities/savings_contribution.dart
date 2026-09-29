import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// Which way a [SavingsContribution] moves the goal's balance. The amount is
/// always positive; direction is carried here, never by sign (FR-007).
/// Fixed at creation — reclassifying means delete and re-create.
enum ContributionType {
  contribution('contribution'),
  withdrawal('withdrawal');

  const ContributionType(this.value);

  /// The stored and wire value.
  final String value;

  /// Parses a stored [value]. Throws [ArgumentError] on an unknown value.
  static ContributionType fromValue(String value) {
    for (final type in values) {
      if (type.value == value) return type;
    }
    throw ArgumentError.value(value, 'value', 'Unknown contribution type');
  }
}

/// One logged deposit or withdrawal against a `SavingsGoal` (FR-005/FR-006).
///
/// 018: [amountMinorUnits] is in the goal's currency and is the only figure
/// progress sums. What the user typed is kept as [enteredAmountMinorUnits]
/// in [enteredCurrency]; when that differs from the goal's currency the
/// amount was converted once, at log (or edit) time (research.md
/// Decision 9), so a later rate change never moves a goal's progress.
class SavingsContribution extends Equatable {
  const SavingsContribution({
    required this.id,
    required this.idempotencyKey,
    required this.goalId,
    required this.type,
    required this.amountMinorUnits,
    required this.enteredAmountMinorUnits,
    required this.enteredCurrency,
    required this.date,
    required this.createdAt,
    this.note,
    this.editedAt,
    this.deletedAt,
  });

  /// The note stored on the entry created alongside a new goal with a
  /// starting amount (research.md Decision 3). A stored marker, not display
  /// copy: the UI shows its own localized label for an entry carrying it.
  static const String startingAmountNote = 'Starting amount';

  final String id;

  /// Per FR-022: a retried log with the same key returns this row.
  final String idempotencyKey;
  final String goalId;
  final ContributionType type;

  /// `> 0`, in the goal's currency.
  final int amountMinorUnits;

  /// `> 0`, in [enteredCurrency]; equals [amountMinorUnits] when that is the
  /// goal's currency.
  final int enteredAmountMinorUnits;
  final Currency enteredCurrency;

  /// Date-only; defaults to today, user-editable.
  final DateTime date;

  /// Optional; "Starting amount" for the row created alongside a new goal
  /// (research.md Decision 3).
  final String? note;
  final DateTime createdAt;

  /// Set by any edit (FR-009); `null` means never edited.
  final DateTime? editedAt;

  /// Soft-delete tombstone; `null` means active.
  final DateTime? deletedAt;

  bool get isWithdrawal => type == ContributionType.withdrawal;

  /// The system-created "starting amount" entry of a new goal.
  bool get isStartingAmount => note == startingAmountNote;
  bool get isEdited => editedAt != null;
  bool get isDeleted => deletedAt != null;

  /// This entry's effect on the balance: positive for a contribution,
  /// negative for a withdrawal.
  int get signedAmountMinorUnits =>
      isWithdrawal ? -amountMinorUnits : amountMinorUnits;

  Money get enteredAmount =>
      Money.fromMinorUnits(enteredAmountMinorUnits, enteredCurrency);

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    goalId,
    type,
    amountMinorUnits,
    enteredAmountMinorUnits,
    enteredCurrency,
    date,
    note,
    createdAt,
    editedAt,
    deletedAt,
  ];
}
