import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/goal_progress.dart';
import '../../domain/entities/savings_goal.dart';
import '../../domain/entities/what_if_mode.dart';
import '../../domain/entities/what_if_result.dart';
import 'savings_format.dart';

/// A what-if answer (FR-013/FR-014) read out in words: the hypothetical
/// plan, how it compares with the goal's real plan, and exactly what
/// applying it would change (FR-015).
///
/// Renders a [result] computed elsewhere (by `SavingsCalculator`, via the
/// `CalculateWhatIf*` use cases); the only arithmetic here is the
/// difference between two already-computed figures for the comparison line.
class WhatIfResultCard extends StatelessWidget {
  const WhatIfResultCard({
    required this.goal,
    required this.progress,
    required this.result,
    required this.mode,
    super.key,
  });

  /// The real goal and its real progress — the comparison baseline.
  final SavingsGoal goal;
  final GoalProgress progress;
  final WhatIfResult result;

  /// The direction [result] was explored in.
  final WhatIfMode mode;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final monthly = result.hypotheticalMonthlyContributionMinorUnits;
    final date = result.hypotheticalTargetDate;
    final months = result.estimatedMonths;
    final monthlyText = monthly == null ? null : format.money(_money(monthly));

    final String headline;
    final String? explain;
    switch (mode) {
      case WhatIfMode.monthlyContribution:
        headline = date == null
            ? l10n.savingsWhatIfResultByMonthlyUndated(
                monthlyText ?? '',
                format.duration(months ?? 0),
              )
            : l10n.savingsWhatIfResultByMonthly(
                monthlyText ?? '',
                format.duration(months ?? 0),
                format.date(date),
              );
        explain = monthlyText == null
            ? null
            : l10n.savingsWhatIfApplyExplainMonthly(monthlyText);
      case WhatIfMode.targetDate:
        final dateText = date == null ? '' : format.date(date);
        headline = l10n.savingsWhatIfResultByDate(dateText, monthlyText ?? '');
        explain = monthlyText == null
            ? null
            : l10n.savingsWhatIfApplyExplainDate(dateText, monthlyText);
    }
    final comparison = _comparison(format);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.savingsWhatIfResultTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.md),
          _Line(
            key: const ValueKey('savingsWhatIfResultLine'),
            icon: mode == WhatIfMode.monthlyContribution
                ? Icons.event_available_outlined
                : Icons.flag_outlined,
            text: headline,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (comparison != null)
            _Line(
              key: const ValueKey('savingsWhatIfCompareLine'),
              icon: Icons.compare_arrows,
              text: comparison,
            ),
          if (explain != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _Line(
              key: const ValueKey('savingsWhatIfApplyExplain'),
              icon: Icons.info_outline,
              text: explain,
              muted: true,
            ),
          ],
        ],
      ),
    );
  }

  /// How the hypothetical differs from the real plan, or `null` when the
  /// goal has no comparable real figure (or the two are equal in the
  /// target-date direction).
  String? _comparison(SavingsFormat format) {
    final l10n = format.l10n;
    switch (mode) {
      case WhatIfMode.monthlyContribution:
        // Only a real monthly contribution yields a real month count.
        final current = goal.monthlyContributionMinorUnits == null
            ? null
            : progress.estimatedCompletion?.estimatedMonths;
        final hypothetical = result.estimatedMonths;
        if (current == null || hypothetical == null) return null;
        final diff = current - hypothetical;
        if (diff > 0) {
          return l10n.savingsWhatIfCompareSooner(format.duration(diff));
        }
        if (diff < 0) {
          return l10n.savingsWhatIfCompareLater(format.duration(-diff));
        }
        return l10n.savingsWhatIfCompareSame;
      case WhatIfMode.targetDate:
        final current = goal.monthlyContributionMinorUnits;
        final required = result.hypotheticalMonthlyContributionMinorUnits;
        if (current == null || required == null || current == required) {
          return null;
        }
        final diff = required - current;
        return diff > 0
            ? l10n.savingsWhatIfCompareMore(format.money(_money(diff)))
            : l10n.savingsWhatIfCompareLess(format.money(_money(-diff)));
    }
  }

  Money _money(int minorUnits) =>
      Money.fromMinorUnits(minorUnits, goal.currency);
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.text,
    super.key,
    this.style,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final TextStyle? style;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final mutedColor = Theme.of(context).colorScheme.onSurfaceVariant;
    final base = style ?? AppTypography.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSpacing.md + AppSpacing.xs, color: mutedColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: muted ? base.copyWith(color: mutedColor) : base,
            ),
          ),
        ],
      ),
    );
  }
}
