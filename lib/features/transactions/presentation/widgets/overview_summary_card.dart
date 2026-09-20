import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';

/// Renders the total-owed-to-you / total-you-owe headline figures (FR-013).
class OverviewSummaryCard extends StatelessWidget {
  const OverviewSummaryCard({
    required this.totalOwedToUser,
    required this.totalUserOwes,
    super.key,
  });

  final Money totalOwedToUser;
  final Money totalUserOwes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = EgpFormatter();
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              label: l10n.overviewTotalOwedToYou,
              amountText: formatter.formatWithSymbol(totalOwedToUser),
              color: AppColors.positive,
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.divider),
          Expanded(
            child: _Figure(
              label: l10n.overviewTotalYouOwe,
              amountText: formatter.formatWithSymbol(totalUserOwes),
              color: AppColors.negative,
            ),
          ),
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.amountText,
    required this.color,
  });

  final String label;
  final String amountText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: AppTypography.bodyMuted,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          amountText,
          style: AppTypography.amount.copyWith(color: color),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
