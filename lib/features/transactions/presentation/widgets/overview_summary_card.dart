import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';

/// Renders the total-owed-to-you / total-you-owe headline figures (FR-013).
///
/// 018: a `null` total is blocked on a missing exchange rate (FR-009) and
/// renders as an em dash — never a partial or 1:1-converted figure. The
/// page pairs it with a `RateNeededBanner` naming the missing currencies.
class OverviewSummaryCard extends StatelessWidget {
  const OverviewSummaryCard({
    required this.totalOwedToUser,
    required this.totalUserOwes,
    super.key,
  });

  final Money? totalOwedToUser;
  final Money? totalUserOwes;

  static const String unavailablePlaceholder = '—';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final financeColors = context.financeColors;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _Figure(
              label: l10n.overviewTotalOwedToYou,
              amountText: _format(formatter, totalOwedToUser),
              color: financeColors.positive,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          Expanded(
            child: _Figure(
              label: l10n.overviewTotalYouOwe,
              amountText: _format(formatter, totalUserOwes),
              color: financeColors.negative,
            ),
          ),
        ],
      ),
    );
  }
}

String _format(EgpFormatter formatter, Money? total) => total == null
    ? OverviewSummaryCard.unavailablePlaceholder
    : formatter.formatWithSymbol(total);

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
          style: AppTypography.bodyMuted.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
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
