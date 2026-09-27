import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../currency/presentation/widgets/rate_needed_banner.dart';
import '../cubit/finance_month_summary_cubit.dart';
import '../cubit/finance_month_summary_state.dart';

/// The Overview tab's link into the finance section, carrying this month's
/// income and expense totals (research.md Decision 9).
///
/// Self-contained on purpose: it brings its own Cubit rather than adding
/// fields to `OverviewCubit`, so the existing overview behavior is
/// untouched and this card can be lifted out whole when the Home Dashboard
/// replaces it.
class FinanceMonthSummaryCard extends StatelessWidget {
  const FinanceMonthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FinanceMonthSummaryCubit>()..subscribe(),
      child: const _FinanceMonthSummaryView(),
    );
  }
}

class _FinanceMonthSummaryView extends StatelessWidget {
  const _FinanceMonthSummaryView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final financeColors = context.financeColors;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );

    return BlocBuilder<FinanceMonthSummaryCubit, FinanceMonthSummaryState>(
      builder: (context, state) {
        if (state.isLoading || state.isHidden) {
          return const SizedBox.shrink();
        }
        final summary = state.summary!;
        final totalIncome = summary.totalIncome;
        final totalExpense = summary.totalExpense;

        return AppCard(
          onTap: () => context.push('/finance'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.financeOverviewCardTitle,
                      style: AppTypography.title.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Text(
                    l10n.financeViewAllAction,
                    style: AppTypography.label.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // 018 FR-009: a month with an unconvertible currency shows
              // which rate is missing, never a partial total.
              if (summary.isBlocked ||
                  totalIncome == null ||
                  totalExpense == null)
                RateNeededBanner(
                  missingRatesFor: summary.missingRatesFor,
                  onSetRate: () => context.push('/settings/currency/rates'),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _Total(
                        label: l10n.financeSummaryTotalIncome,
                        amount: totalIncome,
                        color: financeColors.positive,
                        icon: Icons.south_west,
                        formatter: formatter,
                      ),
                    ),
                    Expanded(
                      child: _Total(
                        label: l10n.financeSummaryTotalExpense,
                        amount: totalExpense,
                        color: financeColors.negative,
                        icon: Icons.north_east,
                        formatter: formatter,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Total extends StatelessWidget {
  const _Total({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
    required this.formatter,
  });

  final String label;
  final Money amount;
  final Color color;
  final IconData icon;
  final EgpFormatter formatter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Paired with the color so the income/expense distinction never
            // rests on color alone.
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyMuted.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatter.formatWithSymbol(amount),
          style: AppTypography.title.copyWith(color: color),
        ),
      ],
    );
  }
}
