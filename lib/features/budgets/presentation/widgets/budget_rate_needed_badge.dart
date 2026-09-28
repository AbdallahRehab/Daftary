import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';

/// 018 FR-009: stands in for the `OverBudgetWarningBadge` of a budget line,
/// the overall card or a trend month whose spend needs a missing exchange
/// rate — its status is unknown, so it is neither on track nor over.
///
/// Uses the same tertiary-container colors as `RateNeededBanner`, so the
/// row marker and the screen's banner read as one thing; an icon and a
/// text label mean it never relies on color alone.
class BudgetRateNeededBadge extends StatelessWidget {
  const BudgetRateNeededBadge({super.key, this.dense = false});

  /// A smaller pill for use inside a list row.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = colorScheme.onTertiaryContainer;
    final label = l10n.budgetRateNeededBadge;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: dense ? AppSpacing.sm : AppSpacing.md,
          vertical: dense ? AppSpacing.xs / 2 : AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.currency_exchange,
              size: dense ? 14 : 16,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
