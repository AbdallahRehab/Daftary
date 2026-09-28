import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/ai_message.dart';

/// The friendly, localized explanation shown under a failed question
/// (T067, FR-017/FR-018).
///
/// One distinct variant per [AIFailureReason] — each with its own icon,
/// title, and message, so no state is conveyed by color alone — plus a
/// generic [AIFailureBanner.localStorage] variant for a non-AI failure
/// (e.g. the question couldn't be saved on this device). It takes only a
/// reason, never an exception or provider message, so raw error text can
/// never reach the screen.
///
/// Actions are explicit user choices only (no silent automatic retry):
/// an invalid key offers [onUpdateKey]; every other variant offers
/// [onRetry]. A callback left `null` hides its button.
class AIFailureBanner extends StatelessWidget {
  const AIFailureBanner({
    required AIFailureReason this.reason,
    super.key,
    this.onRetry,
    this.onUpdateKey,
  });

  /// A local (non-AI) failure, such as the question failing to save.
  const AIFailureBanner.localStorage({super.key, this.onRetry})
    : reason = null,
      onUpdateKey = null;

  /// `null` only for the [AIFailureBanner.localStorage] variant.
  final AIFailureReason? reason;
  final VoidCallback? onRetry;
  final VoidCallback? onUpdateKey;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final finance = context.financeColors;

    final (IconData icon, String title, String message) = switch (reason) {
      AIFailureReason.invalidApiKey => (
        Icons.key_off_outlined,
        l10n.aiFailureInvalidApiKeyTitle,
        l10n.aiFailureInvalidApiKeyMessage,
      ),
      AIFailureReason.rateLimited => (
        Icons.hourglass_top_outlined,
        l10n.aiFailureRateLimitedTitle,
        l10n.aiFailureRateLimitedMessage,
      ),
      AIFailureReason.network => (
        Icons.wifi_off_outlined,
        l10n.aiFailureNetworkTitle,
        l10n.aiFailureNetworkMessage,
      ),
      AIFailureReason.providerError => (
        Icons.cloud_off_outlined,
        l10n.aiFailureProviderErrorTitle,
        l10n.aiFailureProviderErrorMessage,
      ),
      AIFailureReason.unrecognizedResponse => (
        Icons.help_outline,
        l10n.aiFailureUnrecognizedTitle,
        l10n.aiFailureUnrecognizedMessage,
      ),
      null => (
        Icons.sd_card_alert_outlined,
        l10n.aiFailureLocalTitle,
        l10n.aiFailureLocalMessage,
      ),
    };

    // Surface pairs chosen for contrast: text always uses the matching
    // "on" role (or onSurface over the finance surfaces).
    final (Color background, Color foreground, Color accent) = switch (reason) {
      AIFailureReason.network => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurface,
        colorScheme.onSurfaceVariant,
      ),
      AIFailureReason.rateLimited => (
        finance.warningSurface,
        colorScheme.onSurface,
        finance.warning,
      ),
      _ => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        colorScheme.onErrorContainer,
      ),
    };

    final showUpdateKey =
        reason == AIFailureReason.invalidApiKey && onUpdateKey != null;
    final showRetry =
        reason != AIFailureReason.invalidApiKey && onRetry != null;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm + 4,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                container: true,
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 20, color: accent),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.body.copyWith(
                              fontWeight: FontWeight.w600,
                              color: foreground,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: AppTypography.bodyMuted.copyWith(
                              color: foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (showUpdateKey || showRetry)
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: foreground),
                    onPressed: showUpdateKey ? onUpdateKey : onRetry,
                    icon: Icon(
                      showUpdateKey ? Icons.vpn_key_outlined : Icons.refresh,
                      size: 18,
                    ),
                    label: Text(
                      showUpdateKey
                          ? l10n.aiFailureUpdateKeyAction
                          : l10n.aiFailureRetryAction,
                    ),
                  ),
                )
              else
                const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}
