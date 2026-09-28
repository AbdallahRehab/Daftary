import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/budget_summary.dart';
import 'budget_progress_bar.dart';
import 'over_budget_warning_badge.dart';

/// The budget's overall figures (FR-006): total planned, spent, remaining
/// (or over by), percentage used, and the overall warning badge (FR-009),
/// plus the optional expected-income reference and its non-blocking
/// "planned exceeds income" hint (FR-003/FR-004).
class BudgetOverallSummaryCard extends StatelessWidget {
  const BudgetOverallSummaryCard({
    required this.summary,
    super.key,
    this.expectedIncome,
  });

  final BudgetSummary summary;

  /// The budget's optional reference income; `null` hides the income row.
  final Money? expectedIncome;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final status = summary.overallStatus;
    final percentage = summary.overallPercentageUsed;
    final isOver = summary.isOverBudgetOverall;
    final statusColor = OverBudgetWarningBadge.colorFor(context, status);
    final muted = AppTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    final income = expectedIncome;
    final exceedsIncome =
        income != null &&
        budgetPlannedExceedsIncome(
          totalPlannedMinorUnits: summary.totalPlannedMinorUnits,
          expectedIncomeMinorUnits: income.minorUnits,
        );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.budgetOverallTitle,
                  style: AppTypography.title,
                ),
              ),
              OverBudgetWarningBadge(status: status),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  label: l10n.budgetPlannedLabel,
                  value: formatter.formatWithSymbol(summary.totalPlanned),
                ),
              ),
              Expanded(
                child: _Figure(
                  label: l10n.budgetActualLabel,
                  value: formatter.formatWithSymbol(summary.totalActual),
                ),
              ),
              Expanded(
                child: _Figure(
                  label: isOver
                      ? l10n.budgetOverByLabel
                      : l10n.budgetRemainingLabel,
                  value: formatter.formatWithSymbol(
                    summary.totalRemaining.abs(),
                  ),
                  valueColor: isOver ? statusColor : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          BudgetProgressBar(
            plannedMinorUnits: summary.totalPlannedMinorUnits,
            actualMinorUnits: summary.totalActualMinorUnits,
            status: status,
            height: 10,
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Text(
            percentage == null
                ? l10n.budgetPercentNotApplicable
                : l10n.budgetPercentUsed(budgetPercentLabel(percentage)),
            style: muted,
          ),
          if (income != null) ...[
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: theme.colorScheme.outlineVariant),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: Text(l10n.budgetExpectedIncomeDisplay, style: muted),
                ),
                Text(
                  formatter.formatWithSymbol(income),
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (exceedsIncome) ...[
              const SizedBox(height: AppSpacing.sm),
              BudgetExceedsIncomeNotice(
                excess: Money.fromMinorUnits(
                  summary.totalPlannedMinorUnits - income.minorUnits,
                  summary.currency,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// FR-004's hint — an informational notice, deliberately not styled as an
/// error: planning beyond income (e.g. drawing on savings) is valid.
class BudgetExceedsIncomeNotice extends StatelessWidget {
  const BudgetExceedsIncomeNotice({
    required this.excess,
    super.key,
    this.footnote,
  });

  final Money excess;

  /// An optional second line, e.g. "You can still save" on the form.
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.financeColors;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    return Container(
      padding: const EdgeInsetsDirectional.all(AppSpacing.sm + AppSpacing.xs),
      decoration: BoxDecoration(
        color: colors.warningSurface,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.budgetExceedsIncomeWarning(
                    formatter.formatWithSymbol(excess),
                  ),
                  style: AppTypography.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (footnote != null)
                  Text(
                    footnote!,
                    style: AppTypography.bodyMuted.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
