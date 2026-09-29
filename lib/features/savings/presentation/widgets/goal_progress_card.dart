import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/goal_progress.dart';
import '../../domain/entities/savings_goal.dart';
import 'achieved_goal_badge.dart';
import 'savings_format.dart';

/// A goal's figures (FR-004/FR-010-FR-012/FR-017): saved, remaining and
/// target, a progress bar, and the plan read out in words — the estimated
/// completion, the monthly amount a target date needs, and FR-012's honest
/// shortfall line when the two disagree. A goal with no plan gets the
/// US1 AS-6 prompt instead; an achieved one the celebratory badge.
///
/// Renders a [progress] computed elsewhere (by `SavingsCalculator`); it
/// does no arithmetic of its own. Used by the goal page and, with a
/// transient goal, by the goal form's live preview.
class GoalProgressCard extends StatelessWidget {
  const GoalProgressCard({
    required this.goal,
    required this.progress,
    super.key,
    this.title,
  });

  /// Supplies the plan the sentences name: its monthly contribution and
  /// target date.
  final SavingsGoal goal;
  final GoalProgress progress;

  /// Optional heading, e.g. the form preview's "Your plan".
  final String? title;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final theme = Theme.of(context);
    final colors = context.financeColors;
    final percent = format.percent(progress.percentageProgress);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Text(title!, style: AppTypography.title),
            const SizedBox(height: AppSpacing.md),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Figure(
                  key: const ValueKey('savingsSavedFigure'),
                  label: l10n.savingsProgressSavedLabel,
                  value: format.money(progress.currentAmount),
                ),
              ),
              Expanded(
                child: _Figure(
                  key: const ValueKey('savingsRemainingFigure'),
                  label: l10n.savingsProgressRemainingLabel,
                  value: format.money(progress.remainingAmount),
                ),
              ),
              Expanded(
                child: _Figure(
                  label: l10n.savingsProgressTargetLabel,
                  value: format.money(progress.targetAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.savingsProgressPercent(percent),
            style: AppTypography.bodyMuted.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._plan(context, format),
        ],
      ),
    );
  }

  List<Widget> _plan(BuildContext context, SavingsFormat format) {
    final l10n = format.l10n;
    if (progress.isAchieved) return const [AchievedGoalBadge()];

    final estimate = progress.estimatedCompletion;
    if (estimate == null) {
      return [
        _PlanLine(
          key: const ValueKey('savingsNoEstimatePrompt'),
          icon: Icons.lightbulb_outline,
          text: l10n.savingsNoEstimatePrompt,
        ),
      ];
    }

    final monthly = goal.monthlyContribution;
    final months = estimate.estimatedMonths;
    final targetDate = goal.targetDate;
    final required = estimate.requiredMonthlyContributionMinorUnits;
    final shortfall = estimate.shortfallMonths;
    return [
      if (monthly != null && months != null)
        _PlanLine(
          key: const ValueKey('savingsEstimateLine'),
          icon: Icons.event_available_outlined,
          text: estimate.estimatedDate == null
              ? l10n.savingsEstimateByContributionUndated(
                  format.money(monthly),
                  format.duration(months),
                )
              : l10n.savingsEstimateByContribution(
                  format.money(monthly),
                  format.duration(months),
                  format.date(estimate.estimatedDate!),
                ),
        ),
      if (targetDate != null && required != null)
        _PlanLine(
          key: const ValueKey('savingsRequiredLine'),
          icon: Icons.flag_outlined,
          text: l10n.savingsEstimateRequired(
            format.date(targetDate),
            format.money(Money.fromMinorUnits(required, goal.currency)),
          ),
        ),
      // FR-012: both figures stay visible; the mismatch is stated, never
      // silently resolved in favour of either.
      if (shortfall != null)
        _PlanLine(
          key: const ValueKey('savingsShortfallLine'),
          icon: Icons.schedule_outlined,
          color: context.financeColors.warning,
          text: l10n.savingsEstimateShortfall(format.duration(shortfall)),
        ),
    ];
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: muted)),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: AppTypography.figure),
      ],
    );
  }
}

class _PlanLine extends StatelessWidget {
  const _PlanLine({
    required this.icon,
    required this.text,
    super.key,
    this.color,
  });

  final IconData icon;
  final String text;

  /// Tints the icon and text; the words carry the meaning either way.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final muted = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.md + AppSpacing.xs, color: muted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: AppTypography.body.copyWith(color: color)),
          ),
        ],
      ),
    );
  }
}
