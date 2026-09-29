import 'package:equatable/equatable.dart';

import '../../../../core/money/money.dart';
import 'goal_progress.dart';
import 'savings_goal.dart';

/// One goal in the savings overview (FR-019): its progress in its own
/// currency, plus its current amount converted into the primary currency
/// for the combined total.
///
/// 018 FR-009: [isBlocked] when that conversion needs a missing exchange
/// rate — the goal is still listed with its own-currency progress, but is
/// left out of the total.
class GoalOverviewLine extends Equatable {
  const GoalOverviewLine({
    required this.goal,
    required this.progress,
    required this.primaryCurrencyAmountMinorUnits,
    this.missingRatesFor = const [],
  });

  final SavingsGoal goal;
  final GoalProgress progress;

  /// The current amount in the primary currency, converted at read time;
  /// `null` when a rate is missing.
  final int? primaryCurrencyAmountMinorUnits;

  /// The currencies a rate is needed for; empty unless [isBlocked].
  final List<Currency> missingRatesFor;

  bool get isBlocked => primaryCurrencyAmountMinorUnits == null;

  @override
  List<Object?> get props => [
    goal,
    progress,
    primaryCurrencyAmountMinorUnits,
    missingRatesFor,
  ];
}

/// Every active (or, on request, archived) goal with a combined total saved
/// in the primary currency (FR-019). Derived on every read.
///
/// The total is a getter over [goals], so it can never disagree with the
/// lines beneath it; blocked lines are excluded and flagged through
/// [isIncomplete] rather than silently converted 1:1.
class SavingsOverview extends Equatable {
  const SavingsOverview({required this.goals, required this.primaryCurrency});

  final List<GoalOverviewLine> goals;

  /// From 018's conversion context.
  final Currency primaryCurrency;

  /// Σ of the non-blocked lines' converted current amounts.
  int get totalSavedMinorUnits => goals.fold(
    0,
    (sum, line) => sum + (line.primaryCurrencyAmountMinorUnits ?? 0),
  );

  Money get totalSaved =>
      Money.fromMinorUnits(totalSavedMinorUnits, primaryCurrency);

  /// Some goal needed a missing rate, so [totalSavedMinorUnits] leaves it out.
  bool get isIncomplete => goals.any((line) => line.isBlocked);

  /// Every currency a rate is needed for, each once, in first-seen order.
  List<Currency> get missingRatesFor => [
    ...{for (final line in goals) ...line.missingRatesFor},
  ];

  bool get isEmpty => goals.isEmpty;

  @override
  List<Object?> get props => [goals, primaryCurrency];
}
