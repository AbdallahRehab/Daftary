import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../budgets/domain/entities/budget_month.dart';
import '../../../finance/presentation/widgets/finance_month_summary_card.dart';
import '../../domain/entities/overview_summary.dart';
import '../cubit/overview_cubit.dart';
import '../cubit/overview_state.dart';
import '../widgets/overview_summary_card.dart';

/// A single screen that totals and groups every person into "owes me," "I
/// owe," and "settled" (User Story 4).
class OverviewPage extends StatelessWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<OverviewCubit>()..load(),
      child: const _OverviewView(),
    );
  }
}

class _OverviewView extends StatelessWidget {
  const _OverviewView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.overviewTitle)),
      body: BlocBuilder<OverviewCubit, OverviewState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == OverviewStatus.failure || state.summary == null) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.commonError,
              message: state.errorMessage ?? l10n.errorUnknown,
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<OverviewCubit>().load(),
            );
          }

          final summary = state.summary!;
          if (state.isAllSettled) {
            return RefreshIndicator(
              onRefresh: () => context.read<OverviewCubit>().load(),
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  // Settled balances do not mean nothing happened this
                  // month, so the finance link stays visible here.
                  const FinanceMonthSummaryCard(),
                  const SizedBox(height: AppSpacing.md),
                  const _BudgetsEntryCard(),
                  // The occasions section's entry point, alongside finance's
                  // and for the same reason (008 research.md Decision 9): the
                  // section is reached from here rather than from a fourth
                  // bottom-nav tab.
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.celebration_outlined),
                      title: Text(l10n.occasionsTitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/occasions'),
                    ),
                  ),
                  // Scanning a paper list is an entry point, so it sits with
                  // the other section links rather than behind People
                  // (009 FR-001, docs/project.txt §12 Quick Actions).
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.document_scanner_outlined),
                      title: Text(l10n.ocrCaptureTitle),
                      subtitle: Text(l10n.ocrCaptureHeadline),
                      // Past scans get their own button rather than a long-press:
                      // an affordance nobody can see is not an affordance.
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.history),
                            tooltip: l10n.ocrHistoryTitle,
                            onPressed: () => context.push('/ocr/history'),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => context.push('/ocr/scan'),
                    ),
                  ),
                  SizedBox(
                    height: 420,
                    child: AppEmptyView(
                      icon: Icons.check_circle_outline,
                      title: l10n.overviewAllSettledTitle,
                      message: l10n.overviewAllSettledMessage,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<OverviewCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                OverviewSummaryCard(
                  totalOwedToUser: summary.totalOwedToUser,
                  totalUserOwes: summary.totalUserOwes,
                ),
                const SizedBox(height: AppSpacing.md),
                // The finance section's entry point (research.md
                // Decision 9). It brings its own Cubit, so nothing about
                // OverviewCubit's existing behavior changes.
                const FinanceMonthSummaryCard(),
                const SizedBox(height: AppSpacing.md),
                const _BudgetsEntryCard(),
                // The occasions section's entry point, alongside finance's
                // and for the same reason (008 research.md Decision 9): the
                // section is reached from here rather than from a fourth
                // bottom-nav tab.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.celebration_outlined),
                    title: Text(l10n.occasionsTitle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/occasions'),
                  ),
                ),
                // See the settled-state branch above: same entry point, so
                // "scan a paper" is reachable whether or not anything is
                // currently outstanding.
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.document_scanner_outlined),
                    title: Text(l10n.ocrCaptureTitle),
                    subtitle: Text(l10n.ocrCaptureHeadline),
                    // Past scans get their own button rather than a long-press:
                    // an affordance nobody can see is not an affordance.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.history),
                          tooltip: l10n.ocrHistoryTitle,
                          onPressed: () => context.push('/ocr/history'),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => context.push('/ocr/scan'),
                  ),
                ),
                if (summary.peopleTheyOweYou.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionTheyOweYou),
                  ...summary.peopleTheyOweYou.map(
                    (p) => _PersonSummaryRow(summary: p),
                  ),
                ],
                if (summary.peopleYouOweThem.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _SectionHeader(title: l10n.overviewSectionYouOweThem),
                  ...summary.peopleYouOweThem.map(
                    (p) => _PersonSummaryRow(summary: p),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The budgets section's entry point (010 T026), beside finance's and for
/// the same reason (research.md Decision 9): budgets are reached from here
/// rather than from a fourth bottom-nav tab. Always opens the current
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
        onTap: () => context.push('/budgets/${BudgetMonth.current()}'),
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
  const _PersonSummaryRow({required this.summary});

  final PersonSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final color = summary.net.isPositive
        ? context.financeColors.positive
        : context.financeColors.negative;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => context.push('/people/${summary.personId}'),
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
            Text(
              formatter.formatWithSymbol(summary.net.abs()),
              style: AppTypography.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
