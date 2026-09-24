import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/date/app_clock.dart';
import '../entities/composed_notification.dart';
import '../entities/notification_source_type.dart';
import '../ports/budget_insights_source.dart';
import '../ports/savings_insights_source.dart';

/// Where a tapped notification should take the user (FR-014). The router
/// maps each case onto a concrete route.
sealed class NotificationTapDestination extends Equatable {
  const NotificationTapDestination();
}

/// 010's budget-category detail for [categoryId] within [month]
/// (`'YYYY-MM'`).
class BudgetCategoryDestination extends NotificationTapDestination {
  const BudgetCategoryDestination({
    required this.categoryId,
    required this.month,
  });

  final String categoryId;
  final String month;

  @override
  List<Object?> get props => [categoryId, month];
}

/// 011's goal detail for [goalId].
class SavingsGoalDestination extends NotificationTapDestination {
  const SavingsGoalDestination({required this.goalId});

  final String goalId;

  @override
  List<Object?> get props => [goalId];
}

/// The budget/category or goal the notification was about has since been
/// deleted — the caller shows a graceful "no longer exists" state rather
/// than a broken screen (FR-014, spec Edge Cases).
class SourceNoLongerExists extends NotificationTapDestination {
  const SourceNoLongerExists(this.sourceType);

  final NotificationSourceType sourceType;

  @override
  List<Object?> get props => [sourceType];
}

/// Resolves a [NotificationDeepLinkTarget] into a
/// [NotificationTapDestination], confirming read-only through 010/011's
/// ports that the source still exists.
@injectable
class HandleNotificationTap {
  const HandleNotificationTap(this._budgets, this._savings, this._clock);

  final BudgetInsightsSource _budgets;
  final SavingsInsightsSource _savings;
  final AppClock _clock;

  Future<NotificationTapDestination> call(
    NotificationDeepLinkTarget target,
  ) async {
    try {
      switch (target.type) {
        case NotificationSourceType.budgetCategory:
          // Every payload this feature writes carries its month; an older
          // or hand-built one without it falls back to the current month.
          final month = target.applicablePeriod ?? _currentMonth();
          return await _budgets.categoryBudgetExists(target.id, month)
              ? BudgetCategoryDestination(categoryId: target.id, month: month)
              : SourceNoLongerExists(target.type);
        case NotificationSourceType.savingsGoal:
          return await _savings.goalExists(target.id)
              ? SavingsGoalDestination(goalId: target.id)
              : SourceNoLongerExists(target.type);
      }
    } catch (_) {
      // A source that cannot be confirmed is treated as gone, never as a
      // crash on tap.
      return SourceNoLongerExists(target.type);
    }
  }

  String _currentMonth() {
    final now = _clock.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}';
  }
}
