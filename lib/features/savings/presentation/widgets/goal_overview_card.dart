import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../domain/entities/savings_overview.dart';
import 'savings_format.dart';

/// One goal on the overview or the archived list: its name and type, a
/// progress bar, and saved-of-target in the goal's own currency (FR-019).
/// A goal whose conversion needs a missing rate says it is not in the
/// total (018 FR-009). Renders figures computed elsewhere; no arithmetic.
class GoalOverviewCard extends StatelessWidget {
  const GoalOverviewCard({
    required this.line,
    super.key,
    this.onTap,
    this.trailing,
    this.footer,
  });

  final GoalOverviewLine line;
  final VoidCallback? onTap;

  /// E.g. the goal's options menu.
  final Widget? trailing;

  /// E.g. the archived list's restore button.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final theme = Theme.of(context);
    final colors = context.financeColors;
    final muted = theme.colorScheme.onSurfaceVariant;
    final goal = line.goal;
    final progress = line.progress;
    final percent = format.percent(progress.percentageProgress);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: Icon(savingsGoalTypeIcon(goal.type), size: 20),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      goal.name,
                      style: AppTypography.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (goal.type != null)
                      Text(
                        savingsGoalTypeLabel(l10n, goal.type),
                        style: AppTypography.bodyMuted.copyWith(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          Semantics(
            label: l10n.savingsProgressPercent(percent),
            child: ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: LinearProgressIndicator(
                  value: progress.percentageProgress / 100,
                  minHeight: AppSpacing.sm,
                  color: progress.isAchieved
                      ? colors.success
                      : theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs + 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.savingsOverviewGoalProgress(
                    format.money(progress.currentAmount),
                    format.money(progress.targetAmount),
                  ),
                  style: AppTypography.body,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (progress.isAchieved)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.celebration_outlined,
                      size: 16,
                      color: colors.success,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      l10n.savingsGoalAchievedBadge,
                      style: AppTypography.label.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else
                Text(
                  l10n.savingsProgressPercent(percent),
                  style: AppTypography.bodyMuted.copyWith(color: muted),
                ),
            ],
          ),
          if (line.isBlocked) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              key: ValueKey('savingsOverviewBlocked-${goal.id}'),
              children: [
                Icon(Icons.currency_exchange, size: 16, color: muted),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.savingsOverviewNotInTotal(
                      line.missingRatesFor.map((c) => c.code).join(', '),
                    ),
                    style: AppTypography.bodyMuted.copyWith(color: muted),
                  ),
                ),
              ],
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.xs),
            footer!,
          ],
        ],
      ),
    );
  }
}
