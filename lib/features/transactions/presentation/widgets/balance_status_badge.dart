import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/person_balance.dart';

/// Renders "They owe you" / "You owe them" / "Settled" from
/// [RelationshipStatus] (FR-009). Color is always paired with text and an
/// icon — status is never conveyed by color alone (accessibility).
class BalanceStatusBadge extends StatelessWidget {
  const BalanceStatusBadge({
    required this.status,
    super.key,
    this.dense = false,
  });

  final RelationshipStatus status;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final (label, background, foreground, icon) = switch (status) {
      RelationshipStatus.theyOweYou => (
        l10n.filterTheyOweYou,
        financeColors.positiveSurface,
        financeColors.positive,
        Icons.arrow_downward,
      ),
      RelationshipStatus.youOweThem => (
        l10n.filterYouOweThem,
        financeColors.negativeSurface,
        financeColors.negative,
        Icons.arrow_upward,
      ),
      RelationshipStatus.settled => (
        l10n.filterSettled,
        financeColors.neutralSurface,
        financeColors.neutral,
        Icons.check_circle_outline,
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 16, color: foreground),
          const SizedBox(width: AppSpacing.xs),
          // Flexible so a narrow parent or a large system font wraps the
          // label onto a second line instead of overflowing the pill.
          Flexible(
            child: Text(
              label,
              style: AppTypography.label.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
