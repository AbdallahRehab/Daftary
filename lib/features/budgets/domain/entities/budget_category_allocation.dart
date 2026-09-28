import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// One expense category's planned amount within a [Budget] (FR-001/FR-002).
///
/// References 007's `Category` by id only — never a name snapshot — so a
/// rename in category management shows up here immediately, and an
/// archived category keeps resolving (FR-021).
class BudgetCategoryAllocation extends Equatable {
  const BudgetCategoryAllocation({
    required this.id,
    required this.idempotencyKey,
    required this.budgetId,
    required this.categoryId,
    required this.plannedAmountMinorUnits,
    required this.createdAt,
    required this.updatedAt,
    this.currency = Currency.egp,
  });

  final String id;

  /// Client-generated per "add allocation" save; a retry with the same key
  /// returns this row instead of being rejected as a duplicate (FR-017).
  final String idempotencyKey;
  final String budgetId;

  /// An expense-type 007 `Category` id. Unique within [budgetId].
  final String categoryId;

  /// `>= 0`. Zero is a valid plan ("spend nothing here"), not a missing one
  /// (FR-002).
  final int plannedAmountMinorUnits;

  /// 018: its budget's currency — an allocation has none of its own.
  final Currency currency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Money get plannedAmount =>
      Money.fromMinorUnits(plannedAmountMinorUnits, currency);

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    budgetId,
    categoryId,
    plannedAmountMinorUnits,
    currency,
    createdAt,
    updatedAt,
  ];
}
