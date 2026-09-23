import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/occasion_summary.dart';

/// Renders an occasion's settlement label (FR-008): "Settled" on its own,
/// or the outstanding direction together with its amount.
///
/// [outstanding] is always the positive magnitude — the direction is
/// carried by [status] and by the label's own wording, never by a sign or
/// by color alone (accessibility: every state pairs text with an icon).
class SettlementStatusBadge extends StatelessWidget {
  const SettlementStatusBadge({
    required this.status,
    required this.outstanding,
    super.key,
    this.dense = false,
  });

  final SettlementStatus status;
  final Money outstanding;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final amount = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    ).formatWithSymbol(outstanding);

    final (label, background, foreground, icon) = switch (status) {
      SettlementStatus.settled => (
        l10n.occasionSettlementSettled,
        financeColors.neutralSurface,
        financeColors.neutral,
        Icons.check_circle_outline,
      ),
      SettlementStatus.moreReceived => (
        l10n.occasionSettlementMoreReceived(amount),
        financeColors.positiveSurface,
        financeColors.positive,
        Icons.arrow_downward,
      ),
      SettlementStatus.moreGiven => (
        l10n.occasionSettlementMoreGiven(amount),
        financeColors.negativeSurface,
        financeColors.negative,
        Icons.arrow_upward,
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
