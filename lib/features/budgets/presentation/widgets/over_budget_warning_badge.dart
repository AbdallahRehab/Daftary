import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/budget_category_line.dart';

/// The on-track / near-limit / over-budget marker for one budgeted category
/// or for the budget overall (FR-008/FR-009).
///
/// Every state pairs a distinct icon and a text label with its color, and
/// exposes the label to screen readers — the state is never conveyed by
/// color alone (constitution Accessibility standard, FR-020). Colors come
/// from `context.financeColors`, so both themes stay legible.
class OverBudgetWarningBadge extends StatelessWidget {
  const OverBudgetWarningBadge({
    required this.status,
    super.key,
    this.dense = false,
  });

  final BudgetCategoryStatus status;

  /// A smaller pill for use inside a list row.
  final bool dense;

  /// The icon for [status] — distinct per state, so the three remain
  /// distinguishable in grayscale and for color-blind users.
  static IconData iconFor(BudgetCategoryStatus status) => switch (status) {
    BudgetCategoryStatus.onTrack => Icons.check_circle_outline,
    BudgetCategoryStatus.nearFull => Icons.warning_amber_rounded,
    BudgetCategoryStatus.overBudget => Icons.error_outline,
  };

  /// The accent color for [status] — also used by progress bars so a row's
  /// bar and its badge always agree.
  static Color colorFor(BuildContext context, BudgetCategoryStatus status) {
    final colors = context.financeColors;
    return switch (status) {
      BudgetCategoryStatus.onTrack => colors.success,
      BudgetCategoryStatus.nearFull => colors.warning,
      BudgetCategoryStatus.overBudget => colors.negative,
    };
  }

  static Color surfaceColorFor(
    BuildContext context,
    BudgetCategoryStatus status,
  ) {
    final colors = context.financeColors;
    return switch (status) {
      BudgetCategoryStatus.onTrack => colors.successSurface,
      BudgetCategoryStatus.nearFull => colors.warningSurface,
      BudgetCategoryStatus.overBudget => colors.negativeSurface,
    };
  }

  static String labelFor(AppLocalizations l10n, BudgetCategoryStatus status) =>
      switch (status) {
        BudgetCategoryStatus.onTrack => l10n.budgetStatusOnTrack,
        BudgetCategoryStatus.nearFull => l10n.budgetStatusNearFull,
        BudgetCategoryStatus.overBudget => l10n.budgetStatusOverBudget,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final foreground = colorFor(context, status);
    final label = labelFor(l10n, status);

    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.md,
          vertical: dense ? AppSpacing.xs / 2 : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: surfaceColorFor(context, status),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconFor(status), size: dense ? 14 : 16, color: foreground),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
