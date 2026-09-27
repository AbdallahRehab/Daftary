import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// 021 T074: the small marker on a transaction or finance-entry row whose
/// record is in a sync conflict (contracts/dart-interfaces.md §5). The
/// caller shows it only while the record is in conflict, so every other
/// row keeps its exact layout. It carries an icon *and* a label, never
/// color alone, and tapping it opens the resolution sheet.
class ConflictBadge extends StatelessWidget {
  const ConflictBadge({required this.onTap, super.key});

  static const rootKey = Key('conflict_badge');

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.syncConflictBadgeSemantics,
      excludeSemantics: true,
      child: Tooltip(
        message: l10n.syncConflictBadgeSemantics,
        child: Material(
          key: rootKey,
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sync_problem,
                    size: 14,
                    color: colorScheme.onErrorContainer,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.syncConflictBadgeLabel,
                    style: AppTypography.label.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onErrorContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
