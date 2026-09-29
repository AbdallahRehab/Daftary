import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/currency_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../savings/domain/entities/savings_overview.dart';

/// Home's Upcoming section once real items exist (012 FR-010, 011 FR-031):
/// the savings goals `WatchUpcomingSavingsGoals` returned, soonest target
/// date first. Purely presentational — every figure is 011's own, in the
/// goal's currency, and nothing is shown that was not handed in.
///
/// Only used with a non-empty [goals]; with none, Home shows
/// `UpcomingPlaceholderCard` instead.
class UpcomingSavingsGoalsCard extends StatelessWidget {
  const UpcomingSavingsGoalsCard({
    required this.goals,
    required this.onOpenGoal,
    super.key,
  });

  final List<GoalOverviewLine> goals;

  /// Opens one goal's detail page (`/savings/:goalId`).
  final ValueChanged<String> onOpenGoal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.homeUpcomingTitle,
                    style: AppTypography.title.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final line in goals)
            _UpcomingGoalRow(line: line, onTap: () => onOpenGoal(line.goal.id)),
        ],
      ),
    );
  }
}

class _UpcomingGoalRow extends StatelessWidget {
  const _UpcomingGoalRow({required this.line, required this.onTap});

  final GoalOverviewLine line;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final progress = line.progress;
    final money = CurrencyFormatter(
      currency: progress.currency,
      locale: locale,
    );
    String format(Money amount) => money.formatWithSymbol(amount);
    final targetDate = line.goal.targetDate!;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    line.goal.name,
                    style: AppTypography.body.copyWith(
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.homeSavingsUpcomingTargetDate(
                      AppDateFormatter(locale: locale).format(targetDate),
                    ),
                    style: AppTypography.bodyMuted.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  // Display only; the figures beside it are the source.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: progress.percentageProgress / 100,
                      minHeight: 6,
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.homeSavingsUpcomingProgress(
                      format(progress.currentAmount),
                      format(progress.targetAmount),
                    ),
                    style: AppTypography.bodyMuted.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
