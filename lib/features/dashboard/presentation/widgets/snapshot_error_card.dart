import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// An inline, per-section failure state for Home's Financial Snapshot
/// (012): shown in place of one card whose source failed to load, while the
/// rest of the dashboard keeps rendering. Always offers a retry.
class SnapshotErrorCard extends StatelessWidget {
  const SnapshotErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  /// Already-localized explanation, e.g. `l10n.homeFinanceLoadError`.
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: colorScheme.onSurface),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
        ],
      ),
    );
  }
}
