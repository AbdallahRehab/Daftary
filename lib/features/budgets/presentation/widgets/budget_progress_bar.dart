import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../domain/entities/budget_category_line.dart';
import 'over_budget_warning_badge.dart';

/// The whole-number percentage shown next to a progress bar. Floored rather
/// than rounded, so a category at 99.6% never reads "100%" while it still
/// has money left — "100%" appears only once the plan is fully used
/// (US3 scenario 1).
int budgetPercentLabel(double percentage) => percentage.floor();

/// A planned-vs-actual bar colored by [status]. Clamped at full: an
/// over-budget line shows a full bar plus its badge and overage text,
/// rather than a bar that overflows its track.
///
/// Decorative for screen readers — the same information is always given as
/// text beside it.
class BudgetProgressBar extends StatelessWidget {
  const BudgetProgressBar({
    required this.plannedMinorUnits,
    required this.actualMinorUnits,
    required this.status,
    super.key,
    this.height = 8,
  });

  final int plannedMinorUnits;
  final int actualMinorUnits;
  final BudgetCategoryStatus status;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double fraction;
    if (plannedMinorUnits <= 0) {
      fraction = actualMinorUnits > 0 ? 1 : 0;
    } else {
      fraction = (actualMinorUnits / plannedMinorUnits).clamp(0, 1).toDouble();
    }
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: height,
          color: OverBudgetWarningBadge.colorFor(context, status),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
