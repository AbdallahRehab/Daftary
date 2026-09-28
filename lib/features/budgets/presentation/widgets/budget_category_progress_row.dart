import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/presentation/widgets/category_display_name.dart';
import '../../../finance/presentation/widgets/category_icon_registry.dart';
import '../../domain/entities/budget_category_line.dart';
import 'budget_progress_bar.dart';
import 'budget_rate_needed_badge.dart';
import 'over_budget_warning_badge.dart';

/// One budgeted category on the month screen (FR-005/FR-008): its name and
/// warning badge, a progress bar, "spent X of Y", and what is left — or by
/// how much it is over, with the overage amount shown (US3 scenario 1).
///
/// A category with nothing spent yet renders as 0% used with the full plan
/// remaining (US2 scenario 5) — the same layout, never a blank row. A
/// zero-planned category shows "Nothing planned" instead of a percentage,
/// since a percentage of zero is undefined.
///
/// 018 FR-009: a [BudgetCategoryLine.isBlocked] line keeps its name and
/// planned amount, and swaps everything derived from the unknown actual
/// for a [BudgetRateNeededBadge], an empty track and a line naming the
/// currencies that need a rate — never a guessed figure.
class BudgetCategoryProgressRow extends StatelessWidget {
  const BudgetCategoryProgressRow({required this.line, super.key, this.onTap});

  final BudgetCategoryLine line;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final status = line.status;
    final percentage = line.percentageUsed;
    final remaining = line.remaining;
    final actual = line.actualAmount;
    final muted = AppTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final name = line.isCategoryMissing
        ? l10n.budgetCategoryMissingName
        : categoryDisplayNameFor(
            l10n,
            iconKey: line.categoryIcon,
            name: line.categoryName,
          );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  CategoryIconRegistry.iconFor(line.categoryIcon),
                  size: 20,
                  color: CategoryIconRegistry.colorFor(
                    context,
                    CategoryType.expense,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.xs,
                    children: [
                      Text(
                        name,
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Archived since it was budgeted (FR-021): still shown
                      // and counted, just labelled.
                      if (line.isCategoryArchived)
                        Text(
                          '· ${l10n.budgetCategoryArchivedTag}',
                          style: muted,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                if (status == null)
                  BudgetRateNeededBadge(
                    key: ValueKey('budgetLineRateNeeded-${line.allocationId}'),
                    dense: true,
                  )
                else
                  OverBudgetWarningBadge(status: status, dense: true),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            BudgetProgressBar(
              plannedMinorUnits: line.plannedAmountMinorUnits,
              actualMinorUnits: line.actualAmountMinorUnits,
              status: status,
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            if (actual == null || remaining == null || status == null) ...[
              Text(
                l10n.budgetPlannedAmount(
                  formatter.formatWithSymbol(line.plannedAmount),
                ),
                style: muted,
              ),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                l10n.budgetLineNeedsRate(
                  line.missingRatesFor.map((c) => c.code).join(', '),
                ),
                style: AppTypography.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.budgetSpentOfPlanned(
                        formatter.formatWithSymbol(actual),
                        formatter.formatWithSymbol(line.plannedAmount),
                      ),
                      style: muted,
                    ),
                  ),
                  Text(
                    percentage == null
                        ? l10n.budgetPercentNotApplicable
                        : l10n.budgetPercentUsed(
                            budgetPercentLabel(percentage),
                          ),
                    style: muted,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs / 2),
              Text(
                remaining.isNegative
                    ? l10n.budgetOverByAmount(
                        formatter.formatWithSymbol(remaining.abs()),
                      )
                    : l10n.budgetRemainingAmount(
                        formatter.formatWithSymbol(remaining),
                      ),
                style: AppTypography.label.copyWith(
                  color: remaining.isNegative
                      ? OverBudgetWarningBadge.colorFor(context, status)
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
