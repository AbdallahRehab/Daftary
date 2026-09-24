import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// Shown while the feature is on but the OS has denied (or revoked)
/// notification permission (FR-012): states plainly that nothing can be
/// delivered and offers a direct path to the device's app-notification
/// settings. Colors come from the `ColorScheme` only, so it follows the
/// active theme.
class PermissionDeniedBanner extends StatelessWidget {
  const PermissionDeniedBanner({required this.onOpenSettings, super.key});

  /// Stable key so tests can assert presence without the localized copy.
  static const Key rootKey = Key('notification_permission_denied_banner');

  /// Opens the device's notification settings for this app.
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onErrorContainer;
    return Container(
      key: rootKey,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.notifications_off_outlined,
                size: 20,
                color: foreground,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notificationPermissionDeniedTitle,
                      style: AppTypography.body.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.notificationPermissionDeniedMessage,
                      style: AppTypography.bodyMuted.copyWith(
                        color: foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: const Key('notification_open_device_settings'),
              style: TextButton.styleFrom(foregroundColor: foreground),
              onPressed: onOpenSettings,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.notificationPermissionDeniedAction),
            ),
          ),
        ],
      ),
    );
  }
}
