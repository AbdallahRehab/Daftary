import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';

/// A named target the user is saving toward (FR-001).
///
/// Stores the plan only. The saved amount, remaining amount, progress and
/// estimated completion are always derived from the goal's
/// [SavingsContribution] history (`GoalProgress`), never stored here, so no
/// figure the user plans around can drift from the entries behind it
/// (research.md Decision 2).
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.id,
    required this.idempotencyKey,
    required this.name,
    required this.currency,
    required this.targetAmountMinorUnits,
    required this.createdAt,
    required this.updatedAt,
    this.type,
    this.monthlyContributionMinorUnits,
    this.targetDate,
    this.isArchived = false,
    this.deletedAt,
  });

  final String id;

  /// Client-generated once per creation save action; a retried insert with
  /// the same key is a no-op that returns the existing row (FR-022).
  final String idempotencyKey;

  /// Non-empty after trim. Not unique (Assumptions).
  final String name;

  /// A standard `SavingsGoalType` value, or `null` for a plain custom-named
  /// goal. Cosmetic only.
  final String? type;

  /// Every amount on the goal is in this currency. Set at creation and
  /// never edited (FR-027).
  final Currency currency;

  /// `> 0` (FR-002).
  final int targetAmountMinorUnits;

  /// `> 0` when present (FR-002); absent means no contribution plan.
  final int? monthlyContributionMinorUnits;

  /// Date-only. Strictly after "today" when set (FR-003) — checked at write
  /// time only, so a target date that has since passed makes the goal
  /// overdue, never invalid.
  final DateTime? targetDate;

  /// Hidden from the active list and overview, still editable (FR-020).
  final bool isArchived;
  final DateTime createdAt;

  /// Bumped by every edit, archive and restore.
  final DateTime updatedAt;

  /// Tombstone of a goal deleted with no history (FR-021), kept so the
  /// delete syncs; `null` means not deleted.
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  Money get targetAmount =>
      Money.fromMinorUnits(targetAmountMinorUnits, currency);

  Money? get monthlyContribution => monthlyContributionMinorUnits == null
      ? null
      : Money.fromMinorUnits(monthlyContributionMinorUnits!, currency);

  @override
  List<Object?> get props => [
    id,
    idempotencyKey,
    name,
    type,
    currency,
    targetAmountMinorUnits,
    monthlyContributionMinorUnits,
    targetDate,
    isArchived,
    createdAt,
    updatedAt,
    deletedAt,
  ];
}
