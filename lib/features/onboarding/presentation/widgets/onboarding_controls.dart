import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The Back / Next / Get Started row plus a Skip action, reachable from
/// every onboarding screen including the first and last (FR-006). Back is
/// hidden on the first screen; the primary action reads "Get Started"
/// (finish-style) rather than "Next" on the final screen (FR-007).
class OnboardingControls extends StatelessWidget {
  const OnboardingControls({
    required this.isFirstStep,
    required this.isLastStep,
    required this.onNext,
    required this.onBack,
    required this.onSkip,
    super.key,
  });

  final bool isFirstStep;
  final bool isLastStep;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (!isFirstStep)
              Expanded(
                child: AppSecondaryButton(
                  label: l10n.onboardingBackAction,
                  onPressed: onBack,
                ),
              ),
            if (!isFirstStep) const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppButton(
                label: isLastStep
                    ? l10n.onboardingGetStartedAction
                    : l10n.onboardingNextAction,
                onPressed: onNext,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(onPressed: onSkip, child: Text(l10n.onboardingSkipAction)),
      ],
    );
  }
}
