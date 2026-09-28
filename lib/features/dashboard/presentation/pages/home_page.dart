import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../currency/presentation/widgets/rate_needed_banner.dart';
import '../../../transactions/domain/entities/overview_summary.dart';
import '../../../transactions/presentation/widgets/balance_amount_text.dart';
import '../cubit/dashboard_cubit.dart';
import '../cubit/dashboard_state.dart';
import '../cubit/load_status.dart';
import '../widgets/finance_snapshot_card.dart';
import '../widgets/insights_placeholder_card.dart';
import '../widgets/overview_summary_card.dart';
import '../widgets/placeholder_section_card.dart';
import '../widgets/quick_action_row.dart';
import '../widgets/snapshot_error_card.dart';
import '../widgets/upcoming_placeholder_card.dart';

/// Home (012): the financial snapshot (balances + this month's finance),
/// quick actions, the section entry points, the per-person balance lists,
/// and the Insights/Upcoming placeholders — in progressive-disclosure
/// order. Relocated from the retired `OverviewPage`; still served at
/// `/overview` (research.md Decision 5).
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardCubit>()..load(),
      child: const HomeView(),
    );
  }
}

/// Home's content, reading the nearest [DashboardCubit] — split from
/// [HomePage] so tests can provide a cubit of their own.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.homeTitle)),
      body: BlocBuilder<DashboardCubit, DashboardState>(
        builder: (context, state) {
          final cubit = context.read<DashboardCubit>();
          if (state.isFullyLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isFullFailure) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.commonError,
              message: l10n.homeFullErrorMessage,
              actionLabel: l10n.commonRetry,
              onAction: cubit.load,
            );
          }
          if (state.isCombinedEmpty) {
            return RefreshIndicator(
              onRefresh: cubit.refresh,
              child: ListView(
                padding:
                    const EdgeInsets.all(AppSpacing.md) +
                    AppGlassInsets.of(context),
                children: [
                  AppEmptyView(
                    icon: Icons.waving_hand_outlined,
                    title: l10n.homeEmptyTitle,
                    message: l10n.homeEmptyMessage,
                    actionLabel: l10n.homeEmptyAction,
                    onAction: () => _openThenRefresh(context, '/people/new'),
                  ),
                  ..._quickActions(context, l10n, cubit),
                  ..._sections(context, l10n),
                ],
              ),
            );
          }

          final overview = state.overviewSummary;
          return RefreshIndicator(
            onRefresh: cubit.refresh,
            child: ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                _SectionHeader(title: l10n.homeFinancialSnapshotTitle),
                // 018 FR-009: a total that depends on a currency with no
                // exchange rate is shown as blocked, naming the currencies.
                if (overview != null && overview.isBlocked) ...[
                  RateNeededBanner(
                    missingRatesFor: overview.missingRatesFor,
                    onSetRate: () => openExchangeRateSettings(context),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                _overviewCard(l10n, state, cubit),
                if (state.isAllSettled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  PlaceholderSectionCard(
                    icon: Icons.check_circle_outline,
                    title: l10n.overviewAllSettledTitle,
                    message: l10n.overviewAllSettledMessage,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _financeCard(context, l10n, state, cubit),
                ..._quickActions(context, l10n, cubit),
                ..._sections(context, l10n),
                if (overview != null &&
                    overview.peopleTheyOweYou.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionTheyOweYou),
                  ...overview.peopleTheyOweYou.map(
                    (p) => _PersonSummaryRow(
                      summary: p,
                      color: context.financeColors.positive,
                    ),
                  ),
                ],
                if (overview != null &&
                    overview.peopleYouOweThem.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionYouOweThem),
                  ...overview.peopleYouOweThem.map(
                    (p) => _PersonSummaryRow(
                      summary: p,
                      color: context.financeColors.negative,
                    ),
                  ),
                ],
                // Blocked balances whose currencies point in opposite
                // directions: neither "owes you" nor "you owe" is knowable
                // until a rate is set (018).
                if (overview != null &&
                    overview.peopleRateNeeded.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.rateNeededTitle),
                  ...overview.peopleRateNeeded.map(
                    (p) => _PersonSummaryRow(summary: p),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                const InsightsPlaceholderCard(),
                const SizedBox(height: AppSpacing.sm),
                const UpcomingPlaceholderCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _overviewCard(
    AppLocalizations l10n,
    DashboardState state,
    DashboardCubit cubit,
  ) {
    final summary = state.overviewSummary;
    if (state.overviewStatus == LoadStatus.failure) {
      return SnapshotErrorCard(
        message: l10n.homeOverviewLoadError,
        onRetry: cubit.retryOverview,
      );
    }
    if (state.overviewStatus == LoadStatus.loading || summary == null) {
      return const _SnapshotLoadingCard();
    }
    return OverviewSummaryCard(
      totalOwedToUser: summary.totalOwedToUser,
      totalUserOwes: summary.totalUserOwes,
    );
  }

  Widget _financeCard(
    BuildContext context,
    AppLocalizations l10n,
    DashboardState state,
    DashboardCubit cubit,
  ) {
    final summary = state.financeSummary;
    if (state.financeStatus == LoadStatus.failure) {
      return SnapshotErrorCard(
        message: l10n.homeFinanceLoadError,
        onRetry: cubit.retryFinance,
      );
    }
    if (state.financeStatus == LoadStatus.loading || summary == null) {
      return const _SnapshotLoadingCard();
    }
    // The finance section's entry point (007 research.md Decision 9).
    return FinanceSnapshotCard(
      summary: summary,
      onTap: () => _openThenRefresh(context, '/finance'),
    );
  }

  List<Widget> _quickActions(
    BuildContext context,
    AppLocalizations l10n,
    DashboardCubit cubit,
  ) {
    return [
      const SizedBox(height: AppSpacing.lg),
      _SectionHeader(title: l10n.homeQuickActionsTitle),
      QuickActionRow(onReturn: cubit.refresh),
    ];
  }

  /// The section entry points carried over from the retired Overview page:
  /// budgets, occasions, and paper scanning are reached from here rather
  /// than from extra bottom-nav tabs (008/010 research.md Decision 9).
  List<Widget> _sections(BuildContext context, AppLocalizations l10n) {
    return [
      const SizedBox(height: AppSpacing.lg),
      _SectionHeader(title: l10n.homeSectionsTitle),
      const _BudgetsEntryCard(),
      Card(
        child: ListTile(
          leading: const Icon(Icons.celebration_outlined),
          title: Text(l10n.occasionsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openThenRefresh(context, '/occasions'),
        ),
      ),
      // Scanning a paper list is an entry point, so it sits with the other
      // section links rather than behind People (009 FR-001).
      Card(
        child: ListTile(
          leading: const Icon(Icons.document_scanner_outlined),
          title: Text(l10n.ocrCaptureTitle),
          subtitle: Text(l10n.ocrCaptureHeadline),
          // Past scans get their own button rather than a long-press: an
          // affordance nobody can see is not an affordance.
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: l10n.ocrHistoryTitle,
                onPressed: () => _openThenRefresh(context, '/ocr/history'),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _openThenRefresh(context, '/ocr/scan'),
        ),
      ),
      // The AI assistant's persistent entry point (014 T028/T044). Opens
      // the chat, which shows a disabled state linking to settings until
      // the user has entered a key and accepted the disclosure (FR-001).
      Card(
        child: ListTile(
          leading: const Icon(Icons.auto_awesome_outlined),
          title: Text(l10n.aiAssistantTitle),
          subtitle: Text(l10n.aiAssistantHomeEntrySubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openThenRefresh(context, '/ai-assistant/chat'),
        ),
      ),
    ];
  }
}

/// Pushes [location] and refreshes Home once it pops, so anything changed
/// there is reflected without a manual pull-to-refresh (FR-011).
Future<void> _openThenRefresh(BuildContext context, String location) async {
  await context.push<void>(location);
  if (context.mounted) {
    await context.read<DashboardCubit>().refresh();
  }
}

/// Stands in for one snapshot card while only that side is (re)loading,
/// e.g. during a single-side retry.
class _SnapshotLoadingCard extends StatelessWidget {
  const _SnapshotLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: SizedBox(
        height: AppSpacing.xl * 2,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

/// The budgets section's entry point (010 T026). Always opens the current
/// month, which offers to create a budget when there is none (FR-018).
class _BudgetsEntryCard extends StatelessWidget {
  const _BudgetsEntryCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: Text(l10n.budgetsTitle),
        subtitle: Text(l10n.budgetsOverviewEntrySubtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            _openThenRefresh(context, '/budgets/${BudgetMonth.current()}'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Text(title, style: AppTypography.title),
    );
  }
}

class _PersonSummaryRow extends StatelessWidget {
  const _PersonSummaryRow({required this.summary, this.color});

  final PersonSummary summary;

  /// The amount's color; `null` for a row whose direction is unknown.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final net = summary.net;
    final amountText = net != null
        ? EgpFormatter(locale: locale).formatWithSymbol(net.abs())
        : formatNativeNets(summary.nativeNets, locale: locale);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _openThenRefresh(context, '/people/${summary.personId}'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(summary.name, style: AppTypography.body),
                  if (summary.isArchived)
                    Text(
                      l10n.archivedLabel,
                      style: AppTypography.bodyMuted.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (summary.isBlocked) ...[
              Icon(
                Icons.currency_exchange,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                semanticLabel: l10n.rateNeededTitle,
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            // Only a blocked row's multi-currency text can grow long, so
            // only it is allowed to shrink/wrap (018).
            if (summary.isBlocked)
              Flexible(child: _amount(amountText))
            else
              _amount(amountText),
          ],
        ),
      ),
    );
  }

  Widget _amount(String text) => Text(
    text,
    textAlign: TextAlign.end,
    style: AppTypography.figure.copyWith(color: color),
  );
}
