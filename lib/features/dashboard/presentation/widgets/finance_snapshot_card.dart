import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../finance/domain/entities/finance_summary.dart';

/// Home's this-month income / expenses / net figures (012 T017).
///
/// Purely presentational: it renders whatever [summary] it is handed and
/// never loads data itself, so the page's single `DashboardCubit` stays the
/// only source of truth. Each figure pairs its color with an icon and a
/// label, so the income/expense/net distinction never rests on color alone.
class FinanceSnapshotCard extends StatelessWidget {
  const FinanceSnapshotCard({required this.summary, super.key, this.onTap});

  final FinanceSummary summary;

  /// When provided, the whole card is tappable (the page routes to
  /// `/finance`) and shows a trailing chevron as the affordance.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final financeColors = context.financeColors;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final net = summary.net;
    final netColor = net.isZero
        ? financeColors.neutral
        : net.isNegative
        ? financeColors.negative
        : financeColors.positive;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.homeFinanceThisMonthTitle,
                  style: AppTypography.title.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _FigureRow(
            icon: Icons.south_west,
            label: l10n.homeFinanceIncome,
            amount: summary.totalIncome,
            color: financeColors.positive,
            formatter: formatter,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FigureRow(
            icon: Icons.north_east,
            label: l10n.homeFinanceExpenses,
            amount: summary.totalExpense,
            color: financeColors.negative,
            formatter: formatter,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Divider(height: 1, color: theme.colorScheme.outlineVariant),
          ),
          _FigureRow(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.homeFinanceNet,
            amount: net,
            color: netColor,
            formatter: formatter,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _FigureRow extends StatelessWidget {
  const _FigureRow({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.formatter,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final Money amount;
  final Color color;
  final EgpFormatter formatter;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: (emphasized ? AppTypography.label : AppTypography.body)
                .copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          formatter.formatWithSymbol(amount),
          style: (emphasized ? AppTypography.amount : AppTypography.title)
              .copyWith(color: color),
        ),
      ],
    );
  }
}
