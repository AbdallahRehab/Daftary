import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Always-visible step indicator (FR-004): a row of dots plus localized
/// "Step X of N" text — progress is never conveyed by the dots' color
/// alone (constitution Accessibility standard).
class OnboardingProgressIndicator extends StatelessWidget {
  const OnboardingProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
    super.key,
  });

  /// 0-based index of the current screen.
  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < totalSteps; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs / 2,
                ),
                child: Container(
                  width: i == currentStep ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == currentStep
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.onboardingStepProgress(currentStep + 1, totalSteps),
          style: AppTypography.bodyMuted.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
