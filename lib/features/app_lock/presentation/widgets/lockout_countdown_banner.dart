import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Shown while PIN entry is paused after too many wrong PINs (FR-013), with
/// the live time left. When [biometricStillAvailable] it also says that
/// biometric unlock keeps working during the cooldown (FR-008).
class LockoutCountdownBanner extends StatelessWidget {
  const LockoutCountdownBanner({
    super.key,
    required this.remaining,
    this.biometricStillAvailable = false,
  });

  final Duration remaining;
  final bool biometricStillAvailable;

  /// `m:ss` with Western digits, wrapped in a left-to-right isolate so the
  /// minutes and seconds never swap places inside an Arabic sentence.
  static String formatRemaining(Duration remaining) {
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final minutes = clamped.inMinutes;
    final seconds = clamped.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '\u2066$minutes:$seconds\u2069';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final finance = context.financeColors;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: finance.warningSurface,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.timer_outlined, color: finance.warning),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appLockLockCooldownTitle,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: finance.warning,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.appLockLockCooldownMessage(formatRemaining(remaining)),
                    style: AppTypography.body.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  if (biometricStillAvailable) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.appLockLockCooldownBiometricHint,
                      style: AppTypography.bodyMuted.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
