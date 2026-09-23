import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/occasion_summary.dart';
import 'settlement_status_badge.dart';

/// An occasion's total received, total given, net, and settlement label
/// (FR-007/FR-008) — all read from the same [OccasionSummary] instance, so
/// the four figures can never be a moment apart from each other.
class OccasionTotalsCard extends StatelessWidget {
  const OccasionTotalsCard({required this.summary, super.key});

  final OccasionSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final net = summary.net;
    final netColor = net.isNegative
        ? financeColors.negative
        : net.isZero
        ? financeColors.neutral
        : financeColors.positive;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _TotalsFigure(
                  label: l10n.occasionDetailTotalReceived,
                  value: formatter.formatWithSymbol(summary.totalReceived),
                  color: financeColors.positive,
                ),
              ),
              Expanded(
                child: _TotalsFigure(
                  label: l10n.occasionDetailTotalGiven,
                  value: formatter.formatWithSymbol(summary.totalGiven),
                  color: financeColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _TotalsFigure(
            label: l10n.occasionDetailNet,
            // Signed on purpose: `EgpFormatter.format` renders the minus,
            // so an occasion that gave out more is never read as a surplus.
            value: formatter.formatWithSymbol(net),
            color: netColor,
            isProminent: true,
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SettlementStatusBadge(
              status: summary.settlementStatus,
              outstanding: summary.outstanding,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalsFigure extends StatelessWidget {
  const _TotalsFigure({
    required this.label,
    required this.value,
    required this.color,
    this.isProminent = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool isProminent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: (isProminent ? AppTypography.amount : AppTypography.body)
              .copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
