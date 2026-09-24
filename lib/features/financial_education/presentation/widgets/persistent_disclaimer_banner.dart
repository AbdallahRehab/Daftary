import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// The "general education only, not personalized advice" notice shown on
/// every Financial Education screen (FR-015/FR-016, SC-003).
///
/// Deliberately a [StatelessWidget] with no constructor parameters: there is
/// no dismiss action, no visibility flag, and no stored "seen it" state
/// anywhere, so nothing can suppress it after a first render — the guarantee
/// is structural rather than a UI default someone could later flip. Colors
/// come from the `ColorScheme` only, so it renders under any theme.
class PersistentDisclaimerBanner extends StatelessWidget {
  const PersistentDisclaimerBanner({super.key});

  /// Stable key on the banner's root, so tests can assert presence without
  /// depending on the localized copy.
  static const Key rootKey = Key('persistent_disclaimer_banner');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      key: rootKey,
      container: true,
      label: l10n.finEduDisclaimer,
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline,
              size: 18,
              color: colorScheme.onSecondaryContainer,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.finEduDisclaimer,
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
