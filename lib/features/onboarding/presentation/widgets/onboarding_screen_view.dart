import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../onboarding_content.dart';

/// Renders one onboarding topic's icon, title, and description using
/// `core/design_system` tokens only — no hardcoded colors/spacing.
/// Scrollable so very small screens or large system text sizes wrap
/// instead of overflowing (Edge Cases: "very small screens", FR-014).
class OnboardingScreenView extends StatelessWidget {
  const OnboardingScreenView({required this.content, super.key});

  final OnboardingContent content;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(content.icon, size: 96, color: colorScheme.primary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            content.title,
            style: AppTypography.headline,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            content.description,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
