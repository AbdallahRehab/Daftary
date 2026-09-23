import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/finance_summary.dart';

/// Total income, total expenses, and net for the selected period (FR-014).
///
/// Every color comes from `context.financeColors` rather than a constant,
/// so the income/expense distinction (FR-005) survives a theme switch —
/// and the net reads in the *negative* role whenever the period overspent,
/// which is the number the user most needs to not misread.
class FinanceSummaryCard extends StatelessWidget {
  const FinanceSummaryCard({required this.summary, super.key});

  final FinanceSummary summary;

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
                child: _SummaryFigure(
                  label: l10n.financeSummaryTotalIncome,
                  value: formatter.formatWithSymbol(summary.totalIncome),
                  color: financeColors.positive,
                ),
              ),
              Expanded(
                child: _SummaryFigure(
                  label: l10n.financeSummaryTotalExpense,
                  value: formatter.formatWithSymbol(summary.totalExpense),
                  color: financeColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.md),
          _SummaryFigure(
            label: l10n.financeSummaryNet,
            // Signed on purpose: `EgpFormatter.format` renders the minus,
            // so an overspent period is never mistaken for a surplus.
            value: formatter.formatWithSymbol(net),
            color: netColor,
            isProminent: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryFigure extends StatelessWidget {
  const _SummaryFigure({
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
