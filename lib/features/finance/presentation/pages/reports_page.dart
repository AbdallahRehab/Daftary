import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/spending_trend_point.dart';
import '../cubit/reports_cubit.dart';
import '../cubit/reports_state.dart';
import '../widgets/category_breakdown_chart.dart';
import '../widgets/monthly_trend_chart.dart';

/// The Reports screen (013 US1): the recent-months income/expense trend and
/// an expense breakdown for a selectable period, both read from 007's
/// existing aggregation (FR-001–FR-003).
class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  /// Where the app bar's shortcut leads (research.md Decision 9, SC-002).
  static const String exportLocation = '/settings/export';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ReportsCubit>()..load(),
      child: const ReportsView(),
    );
  }
}

/// The screen itself, reading a [ReportsCubit] from the tree — split from
/// [ReportsPage] so tests can supply their own Cubit.
class ReportsView extends StatelessWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reportsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: l10n.reportsExportAction,
            onPressed: () => context.push<void>(ReportsPage.exportLocation),
          ),
        ],
      ),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          final cubit = context.read<ReportsCubit>();
          switch (state.status) {
            case ReportsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ReportsStatus.failure:
              // FR-005 — never a blank or stuck screen.
              return AppEmptyView(
                icon: Icons.error_outline,
                title: l10n.commonError,
                message: l10n.reportsLoadError,
                actionLabel: l10n.retry,
                onAction: cubit.load,
              );
            case ReportsStatus.empty:
              // FR-004 — nothing recorded anywhere yet; the only useful next
              // step is the first entry.
              return AppEmptyView(
                icon: Icons.insights_outlined,
                title: l10n.reportsEmptyTitle,
                message: l10n.reportsEmptyMessage,
                actionLabel: l10n.reportsEmptyAction,
                onAction: () async {
                  await context.push<void>('/finance/entries/new?type=expense');
                  if (!cubit.isClosed) await cubit.load();
                },
              );
            case ReportsStatus.success:
              return RefreshIndicator(
                onRefresh: cubit.load,
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    _TrendCard(trend: state.trend),
                    const SizedBox(height: AppSpacing.md),
                    _BreakdownCard(state: state),
                  ],
                ),
              );
          }
        },
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.trend});

  final List<SpendingTrendPoint> trend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportsTrendTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.reportsTrendSubtitle(ReportsCubit.trendMonths),
            style: AppTypography.bodyMuted.copyWith(color: onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          MonthlyTrendChart(points: trend),
          if (trend.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            _LatestMonthTotals(point: trend.last),
          ],
        ],
      ),
    );
  }
}

/// The newest month's exact figures under the chart — the bars show shape,
/// this shows the numbers. Each figure carries its label and icon, so the
/// meaning never rests on color alone.
class _LatestMonthTotals extends StatelessWidget {
  const _LatestMonthTotals({required this.point});

  final SpendingTrendPoint point;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeColors = context.financeColors;
    final net = point.netMinorUnits;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Figure(
            icon: MonthlyTrendChart.incomeIcon,
            label: l10n.reportsIncome,
            minorUnits: point.totalIncomeMinorUnits,
            color: financeColors.positive,
          ),
        ),
        Expanded(
          child: _Figure(
            icon: MonthlyTrendChart.expenseIcon,
            label: l10n.reportsExpenses,
            minorUnits: point.totalExpenseMinorUnits,
            color: financeColors.negative,
          ),
        ),
        Expanded(
          child: _Figure(
            icon: Icons.drag_handle,
            label: l10n.reportsNet,
            minorUnits: net,
            color: net < 0
                ? financeColors.negative
                : (net > 0 ? financeColors.positive : financeColors.neutral),
          ),
        ),
      ],
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.icon,
    required this.label,
    required this.minorUnits,
    required this.color,
  });

  final IconData icon;
  final String label;
  final int minorUnits;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.label.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          formatter.formatWithSymbol(Money.fromMinorUnits(minorUnits)),
          style: AppTypography.body.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ReportsCubit>();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.reportsBreakdownTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              for (final period in ReportsPeriod.values)
                ChoiceChip(
                  label: Text(_periodLabel(l10n, period)),
                  selected: state.breakdownPeriod == period,
                  onSelected: (_) => cubit.changeBreakdownPeriod(period),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          switch (state.breakdownStatus) {
            ReportsBreakdownStatus.loading => const Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: Center(child: CircularProgressIndicator()),
            ),
            // Only the breakdown failed — the trend above stays usable, so
            // the error and its retry stay inside this card.
            ReportsBreakdownStatus.failure => Column(
              children: [
                Text(
                  l10n.reportsLoadError,
                  textAlign: TextAlign.center,
                  style: AppTypography.body,
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                  onPressed: cubit.retryBreakdown,
                ),
              ],
            ),
            ReportsBreakdownStatus.success => CategoryBreakdownChart(
              items: state.breakdown,
            ),
          },
        ],
      ),
    );
  }

  static String _periodLabel(AppLocalizations l10n, ReportsPeriod period) =>
      switch (period) {
        ReportsPeriod.thisMonth => l10n.reportsPeriodThisMonth,
        ReportsPeriod.lastMonth => l10n.reportsPeriodLastMonth,
        ReportsPeriod.last3Months => l10n.reportsPeriodLast3Months,
        ReportsPeriod.last6Months => l10n.reportsPeriodLast6Months,
      };
}
