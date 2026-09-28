import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// A user's spending plan for one calendar month (FR-001).
///
/// Holds planned figures only. Everything "actual" — spend, remaining,
/// percentage used — is derived on read from 007's expense entries and
/// never stored here, so a plan can never drift out of sync with the
/// spending it is compared against (data-model.md).
class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.idempotencyKey,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.expectedIncomeMinorUnits,
    this.currency = Currency.egp,
    this.deletedAt,
  });

  final String id;

  /// Client-generated once per creation save action; a retried insert with
  /// the same key is a no-op that returns the existing row (FR-017).
  final String idempotencyKey;

  /// `'YYYY-MM'` (see `BudgetMonth`). At most one active budget per month.
  final String month;

  /// Optional reference figure (FR-003), `>= 0` when present. Never
  /// aggregated from income entries and never part of any planned/actual
  /// computation — it only feeds the "planned exceeds income" hint
  /// (FR-004).
  final int? expectedIncomeMinorUnits;

  /// 018: the currency every planned figure of this budget is in.
  final Currency currency;
  final DateTime createdAt;

  /// Bumped by every edit, including allocation add/edit/remove.
  final DateTime updatedAt;

  /// Soft-delete tombstone; `null` means active (FR-011).
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Money? get expectedIncome => expectedIncomeMinorUnits == null
      ? null
      : Money.fromMinorUnits(expectedIncomeMinorUnits!, currency);

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    month,
    expectedIncomeMinorUnits,
    currency,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
