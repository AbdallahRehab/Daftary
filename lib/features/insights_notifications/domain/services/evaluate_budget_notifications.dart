import 'package:injectable/injectable.dart';

import '../entities/notification_candidate.dart';
import '../entities/notification_history_entry.dart';
import '../ports/budget_insights_source.dart';

/// Pure band classification over already-fetched 010 budget data
/// (contracts/notification_engine.md). No repository, no I/O (research.md
/// Decision 2).
abstract class EvaluateBudgetNotifications {
  /// One candidate per category in [categories], in the same order. The
  /// band is read off 010's own [BudgetCategoryStatus] — never recomputed
  /// from the percentages, so 010's near-full threshold is the only one
  /// that exists (FR-003).
  List<BudgetNotificationCandidate> evaluate(
    List<BudgetCategorySnapshot> categories,
  );
}

@LazySingleton(as: EvaluateBudgetNotifications)
class EvaluateBudgetNotificationsImpl implements EvaluateBudgetNotifications {
  const EvaluateBudgetNotificationsImpl();

  @override
  List<BudgetNotificationCandidate> evaluate(
    List<BudgetCategorySnapshot> categories,
  ) {
    return [
      for (final category in categories)
        BudgetNotificationCandidate(
          categoryId: category.categoryId,
          categoryName: category.categoryName,
          applicablePeriod: category.month,
          band: _bandFor(category.status),
          percentageUsed: category.percentageUsed,
          actualMinorUnits: category.actualMinorUnits,
          plannedMinorUnits: category.plannedMinorUnits,
        ),
    ];
  }

  static ThresholdBand _bandFor(BudgetCategoryStatus status) =>
      switch (status) {
        BudgetCategoryStatus.onTrack => ThresholdBand.belowWarning,
        BudgetCategoryStatus.nearFull => ThresholdBand.nearLimit,
        BudgetCategoryStatus.overBudget => ThresholdBand.exceeded,
      };
}
