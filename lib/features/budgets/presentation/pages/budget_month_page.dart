import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/budget_failures.dart';
import '../../domain/entities/budget_summary.dart';
import '../cubit/budget_month_cubit.dart';
import '../cubit/budget_month_state.dart';
import '../cubit/copy_budget_cubit.dart';
import '../cubit/copy_budget_state.dart';
import '../widgets/budget_category_progress_row.dart';
import '../widgets/budget_failure_message.dart';
import '../widgets/budget_month_format.dart';
import '../widgets/budget_overall_summary_card.dart';
import '../widgets/month_navigator.dart';
import '../widgets/unbudgeted_spending_card.dart';

/// One month's budget (US2/US3): the overall summary, one progress row per
/// budgeted category, and unbudgeted spending — or, when the month has no
/// budget, the FR-018 empty state offering to create one.
///
/// A [MonthNavigator] moves between months (US4), the app bar links to the
/// trend view (US5), and the empty state offers copy-forward from the most
/// recent earlier budget when one exists (US4).
class BudgetMonthPage extends StatelessWidget {
  const BudgetMonthPage({required this.month, super.key});

  /// `'YYYY-MM'` — the month the page opens on.
  final String month;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetMonthCubit>()..load(month),
      child: const BudgetMonthView(),
    );
  }
}

/// The page's widget tree without its `getIt`-resolved cubit, so widget
/// tests can drive it with a cubit over mocked use cases.
class BudgetMonthView extends StatefulWidget {
  const BudgetMonthView({super.key});

  @override
  State<BudgetMonthView> createState() => _BudgetMonthViewState();
}

class _BudgetMonthViewState extends State<BudgetMonthView> {
  /// Opens the create/edit form and re-reads the month on return — the
  /// form may have created, edited or deleted the budget.
  Future<void> _openForm(String month, {required bool editing}) async {
    final cubit = context.read<BudgetMonthCubit>();
    await context.push('/budgets/$month/${editing ? 'edit' : 'new'}');
    if (mounted) unawaited(cubit.reload());
  }

  List<Widget> _appBarActions(BudgetMonthState state) {
    final l10n = AppLocalizations.of(context)!;
    return [
      IconButton(
        key: const ValueKey('budgetTrendAction'),
        tooltip: l10n.budgetTrendTitle,
        icon: const Icon(Icons.insights_outlined),
        onPressed: () => context.push('/budgets/trend?month=${state.month}'),
      ),
      if (state.hasBudget)
        IconButton(
          tooltip: l10n.budgetFormEditTitle,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _openForm(state.month, editing: true),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<BudgetMonthCubit, BudgetMonthState>(
      builder: (context, state) {
        final cubit = context.read<BudgetMonthCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.budgetsTitle),
            actions: _appBarActions(state),
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.month.isNotEmpty)
                MonthNavigator(
                  month: state.month,
                  onChanged: cubit.monthChanged,
                ),
              Expanded(child: _buildContent(context, state, cubit)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BudgetMonthState state,
    BudgetMonthCubit cubit,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final detail = state.detail;

    if (state.isLoading && detail == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.isFailure && detail == null) {
      return AppEmptyView(
        icon: Icons.error_outline,
        title: l10n.budgetLoadErrorTitle,
        message: budgetFailureMessage(l10n, state.failure!),
        actionLabel: l10n.commonRetry,
        onAction: cubit.reload,
      );
    }
    if (detail == null || !detail.hasBudget) {
      return RefreshIndicator(
        onRefresh: cubit.reload,
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: _EmptyBudgetState(
                month: state.month,
                onCreate: () => _openForm(state.month, editing: false),
                copyAction: _CopyForwardAction(
                  // Keyed by month so navigating rebuilds the cubit for
                  // the new target instead of reusing a stale source.
                  key: ValueKey('budgetCopyForward-${state.month}'),
                  month: state.month,
                  onCopied: cubit.reload,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: cubit.reload,
      child: _BudgetDetailList(
        detail: detail,
        onEdit: () => _openForm(state.month, editing: true),
      ),
    );
  }
}

class _BudgetDetailList extends StatelessWidget {
  const _BudgetDetailList({required this.detail, required this.onEdit});

  final BudgetMonthDetail detail;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = detail.summary!;
    final lines = summary.categoryBreakdown;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        BudgetOverallSummaryCard(
          summary: summary,
          expectedIncome: detail.budget!.expectedIncome,
        ),
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
          child: Text(l10n.budgetCategoriesHeader, style: AppTypography.title),
        ),
        if (lines.isEmpty)
          AppEmptyView(
            icon: Icons.category_outlined,
            title: l10n.budgetCategoriesHeader,
            message: l10n.budgetNoAllocationsMessage,
            actionLabel: l10n.budgetFormEditTitle,
            onAction: onEdit,
          )
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    for (var i = 0; i < lines.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                      BudgetCategoryProgressRow(line: lines[i], onTap: onEdit),
                    ],
                  ],
                ),
              ),
            ),
          ),
        if (summary.unbudgetedSpending.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          UnbudgetedSpendingCard(items: summary.unbudgetedSpending),
        ],
      ],
    );
  }
}

/// FR-018: the month has no budget. Always offers "create"; [copyAction]
/// is the slot for US4's copy-forward offer, shown beneath it when present
/// (and simply absent when there is nothing to copy — US4 scenario 3).
class _EmptyBudgetState extends StatelessWidget {
  const _EmptyBudgetState({
    required this.month,
    required this.onCreate,
    this.copyAction,
  });

  final String month;
  final VoidCallback onCreate;
  final Widget? copyAction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: onSurfaceVariant,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.budgetEmptyTitle(BudgetMonthFormat.long(context, month)),
            style: AppTypography.title,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.budgetEmptyMessage,
            style: AppTypography.bodyMuted.copyWith(color: onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            key: const ValueKey('budgetCreateAction'),
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: Text(l10n.budgetCreateAction),
          ),
          if (copyAction != null) ...[
            const SizedBox(height: AppSpacing.sm),
            copyAction!,
          ],
        ],
      ),
    );
  }
}

/// US4's copy-forward offer: resolves the most recent earlier budget and,
/// when there is one, offers to copy it into [month]. Renders nothing when
/// there is no source (US4 scenario 3) — "create" remains the only path.
class _CopyForwardAction extends StatelessWidget {
  const _CopyForwardAction({
    required this.month,
    required this.onCopied,
    super.key,
  });

  final String month;
  final Future<void> Function() onCopied;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CopyBudgetCubit>()..load(month),
      child: BlocConsumer<CopyBudgetCubit, CopyBudgetState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          final messenger = ScaffoldMessenger.of(context);
          if (state.isSuccess && state.source != null) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  l10n.budgetCopySuccess(
                    BudgetMonthFormat.long(context, state.source!.month),
                  ),
                ),
              ),
            );
            unawaited(onCopied());
          } else if (state.status == CopyBudgetStatus.copyFailure) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(
                  state.failure is BudgetAlreadyExistsForMonthFailure
                      ? l10n.budgetCopyAlreadyExists
                      : l10n.budgetCopyFailed,
                ),
              ),
            );
            // The month may have gained a budget elsewhere; show it.
            if (state.failure is BudgetAlreadyExistsForMonthFailure) {
              unawaited(onCopied());
            }
          }
        },
        builder: (context, state) {
          final source = state.source;
          if (source == null) return const SizedBox.shrink();
          final l10n = AppLocalizations.of(context)!;
          final sourceLabel = BudgetMonthFormat.long(context, source.month);
          return Column(
            children: [
              OutlinedButton.icon(
                key: const ValueKey('budgetCopyForwardAction'),
                onPressed: state.canCopy
                    ? context.read<CopyBudgetCubit>().copy
                    : null,
                icon: state.isCopying
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.content_copy_outlined),
                label: Text(
                  state.isCopying
                      ? l10n.budgetCopyInProgress
                      : l10n.budgetCopyFromMonthAction(sourceLabel),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.budgetCopyFromMonthMessage(sourceLabel),
                style: AppTypography.bodyMuted.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}
