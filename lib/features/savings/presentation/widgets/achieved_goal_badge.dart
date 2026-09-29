import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The FR-017 "goal reached" treatment: celebratory success colours and a
/// party icon — deliberately none of the warning/over-budget vocabulary the
/// app uses elsewhere. The text carries the meaning, never colour alone.
class AchievedGoalBadge extends StatelessWidget {
  const AchievedGoalBadge({super.key, this.showMessage = true});

  /// Adds the one-line congratulation under the badge.
  final bool showMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.financeColors;
    return Semantics(
      container: true,
      label: l10n.savingsGoalAchievedBadge,
      child: ExcludeSemantics(
        child: Container(
          key: const ValueKey('savingsAchievedBadge'),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.successSurface,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.celebration_outlined, color: colors.success),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.savingsGoalAchievedBadge,
                      style: AppTypography.title.copyWith(
                        color: colors.success,
                      ),
                    ),
                    if (showMessage) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.savingsGoalAchievedMessage,
                        style: AppTypography.body,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
