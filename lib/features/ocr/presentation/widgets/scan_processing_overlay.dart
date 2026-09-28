import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The in-progress state for text recognition (FR-017).
///
/// Always carries a cancel affordance: the spec's failure mode here is not
/// "slow", it is "a spinner the user cannot escape", so the cancel button
/// is part of the overlay rather than something each caller remembers to
/// add.
class ScanProcessingOverlay extends StatelessWidget {
  const ScanProcessingOverlay({required this.onCancel, super.key});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.94),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.ocrPrepProcessingTitle,
                style: AppTypography.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.ocrPrepProcessingMessage,
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              AppSecondaryButton(
                label: l10n.ocrPrepCancel,
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
