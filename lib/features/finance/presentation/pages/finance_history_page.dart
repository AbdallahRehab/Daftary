import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_fab.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../cloud_sync/domain/entities/sync_conflict_item.dart';
import '../../../cloud_sync/presentation/cubit/sync_conflicts_cubit.dart';
import '../../../cloud_sync/presentation/cubit/sync_conflicts_state.dart';
import '../../../cloud_sync/presentation/widgets/conflict_badge.dart';
import '../../../cloud_sync/presentation/widgets/conflict_resolution_sheet.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/entities/finance_history_filter.dart';
import '../cubit/finance_history_cubit.dart';
import '../cubit/finance_history_state.dart';
import '../widgets/category_breakdown_bar.dart';
import '../widgets/category_display_name.dart';
import '../widgets/finance_entry_change_history.dart';
import '../widgets/finance_entry_list_tile.dart';
import '../widgets/finance_summary_card.dart';
import '../widgets/period_selector.dart';

/// The finance history screen (US3): summary, per-category breakdown, and
/// the filtered entry list for one selected period — all three driven by a
/// single Cubit so they can never disagree about which period they show.
/// Navigates to [location]. No reload on return: every change a
/// destination can make — a new entry, an edited amount, a renamed or
/// archived category — reaches this screen through the Cubit's live
/// subscriptions (021).
Future<void> _push(BuildContext context, String location) =>
    context.push<void>(location);

class FinanceHistoryPage extends StatelessWidget {
  const FinanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<FinanceHistoryCubit>()..subscribe()),
        // 021: the conflict badge on each entry row (FR-035).
        BlocProvider(create: (_) => getIt<SyncConflictsCubit>()..subscribe()),
      ],
      child: const _FinanceHistoryView(),
    );
  }
}

class _FinanceHistoryView extends StatelessWidget {
  const _FinanceHistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(
        title: Text(l10n.financeHistoryTitle),
        actions: [
          // 013 T017: Reports is reached from here, so it is discoverable
          // without knowing its route. No reload on return: this history is
          // a live subscription (021), so an entry recorded from Reports'
          // empty state already shows up.
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: l10n.reportsOpenAction,
            onPressed: () => _push(context, '/finance/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: l10n.financeManageCategoriesAction,
            onPressed: () => _push(context, '/finance/categories'),
          ),
        ],
      ),
      floatingActionButton: const _AddEntryActions(),
      body: BlocBuilder<FinanceHistoryCubit, FinanceHistoryState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.isFailure) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.errorLoadTitle,
              message: l10n.messageFor(state.failure),
              actionLabel: l10n.commonRetry,
              onAction: () => context.read<FinanceHistoryCubit>().resubscribe(),
            );
          }
          // FR-017 — nothing has ever been recorded, so no period or filter
          // change could reveal anything. The only useful next step is to
          // record the first entry.
          if (state.isTrueEmpty) {
            return AppEmptyView(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.financeEmptyTitle,
              message: l10n.financeEmptyMessage,
              actionLabel: l10n.financeAddFirstEntryAction,
              onAction: () =>
                  _push(context, '/finance/entries/new?type=expense'),
            );
          }

          final categoriesById = state.categoriesById;
          final rowCount = state.entries.isEmpty ? 1 : state.entries.length;

          return RefreshIndicator(
            onRefresh: () => context.read<FinanceHistoryCubit>().resubscribe(),
            child: ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.xxl * 2,
                  ) +
                  AppGlassInsets.of(context),
              itemCount: rowCount + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _HistoryHeader(state: state);
                if (state.entries.isEmpty) {
                  // FR-018 — entries exist, just not under this period and
                  // filter. Deliberately a different message (and a
                  // different escape hatch) from the true-empty state above.
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xl),
                    child: AppEmptyView(
                      icon: Icons.filter_alt_off_outlined,
                      title: l10n.financeNoMatchTitle,
                      message: l10n.financeNoMatchMessage,
                      actionLabel: state.hasFilters
                          ? l10n.financeClearFiltersAction
                          : null,
                      onAction: state.hasFilters
                          ? () => context
                                .read<FinanceHistoryCubit>()
                                .clearFilters()
                          : null,
                    ),
                  );
                }
                final entry = state.entries[index - 1];
                final category = categoriesById[entry.categoryId];
                return BlocSelector<
                  SyncConflictsCubit,
                  SyncConflictsState,
                  SyncConflictItem?
                >(
                  selector: (conflicts) => conflicts.itemFor(
                    ConflictEntityType.financeEntry,
                    entry.id,
                  ),
                  builder: (context, conflict) => FinanceEntryListTile(
                    entry: entry,
                    categoryName: category == null
                        ? l10n.financeCategoryOther
                        : categoryDisplayName(l10n, category),
                    categoryIconKey: category?.icon ?? 'other',
                    primaryCurrency: state.primaryCurrency,
                    onEdit: () =>
                        _push(context, '/finance/entries/${entry.id}/edit'),
                    onDelete: () => _confirmDelete(context, entry),
                    onEditedTap: () => showFinanceEntryChangeHistory(
                      context,
                      entry,
                      categoryNames: {
                        for (final c in categoriesById.values)
                          c.id: categoryDisplayName(l10n, c),
                      },
                    ),
                    conflictBadge: conflict == null
                        ? null
                        : ConflictBadge(
                            onTap: () =>
                                showConflictResolutionSheet(context, conflict),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// FR-020: explicit confirmation first, then a short-window undo — the
  /// delete itself is already committed by the time the SnackBar appears
  /// (research.md Decision 8), so nothing is left pending if the app dies.
  Future<void> _confirmDelete(BuildContext context, FinanceEntry entry) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<FinanceHistoryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.financeDeleteEntryConfirmTitle,
      message: l10n.financeDeleteEntryConfirmMessage,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
    );
    if (!confirmed) return;

    await cubit.deleteEntry(entry.id);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.financeEntryDeletedMessage),
        duration: cubit.undoWindow,
        action: SnackBarAction(
          label: l10n.commonUndo,
          onPressed: () => cubit.undoDelete(entry.id),
        ),
      ),
    );
  }
}

/// Everything above the entry list: period, totals, filters, breakdown.
class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.state});

  final FinanceHistoryState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<FinanceHistoryCubit>();
    final summary = state.summary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PeriodSelector(
          preset: state.periodPreset,
          period: state.period,
          onPresetSelected: cubit.periodChanged,
          onCustomRangeSelected: (start, end) => cubit.periodChanged(
            FinancePeriodPreset.custom,
            customRange: DateRange(start: start, end: end),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (summary != null) FinanceSummaryCard(summary: summary),
        const SizedBox(height: AppSpacing.md),
        _FilterControls(state: state),
        const SizedBox(height: AppSpacing.md),
        CategoryBreakdownBar(
          breakdown: state.breakdown,
          categoriesById: state.categoriesById,
        ),
      ],
    );
  }
}

class _FilterControls extends StatelessWidget {
  const _FilterControls({required this.state});

  final FinanceHistoryState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<FinanceHistoryCubit>();
    final categories = state.filterableCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.financeFilterTypeLabel,
          style: AppTypography.label.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          children: [
            _TypeChip(
              label: l10n.filterAll,
              isSelected: state.typeFilter == null,
              onSelected: () => cubit.typeFilterChanged(null),
            ),
            _TypeChip(
              label: l10n.financeTypeIncome,
              isSelected: state.typeFilter == FinanceEntryType.income,
              onSelected: () =>
                  cubit.typeFilterChanged(FinanceEntryType.income),
            ),
            _TypeChip(
              label: l10n.financeTypeExpense,
              isSelected: state.typeFilter == FinanceEntryType.expense,
              onSelected: () =>
                  cubit.typeFilterChanged(FinanceEntryType.expense),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String?>(
          initialValue: state.categoryFilter,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.financeFilterCategoryLabel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          items: [
            DropdownMenuItem<String?>(child: Text(l10n.filterAll)),
            for (final category in categories)
              DropdownMenuItem<String?>(
                value: category.id,
                child: Text(_labelFor(l10n, category)),
              ),
          ],
          onChanged: cubit.categoryFilterChanged,
        ),
        if (state.hasFilters) ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
              label: Text(l10n.financeClearFiltersAction),
              onPressed: cubit.clearFilters,
            ),
          ),
        ],
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, Category category) {
    final name = categoryDisplayName(l10n, category);
    return category.isArchived ? '$name (${l10n.archivedLabel})' : name;
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
    );
  }
}

/// The two entry-creation actions (FR-001/FR-002), kept visually distinct
/// so recording an expense — the far more frequent action — stays the
/// primary one.
class _AddEntryActions extends StatelessWidget {
  const _AddEntryActions();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppFab.small(
          heroTag: 'finance-add-income',
          tooltip: l10n.financeAddIncomeAction,
          onPressed: () => _push(context, '/finance/entries/new?type=income'),
          child: const Icon(Icons.arrow_downward),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppFab.extended(
          heroTag: 'finance-add-expense',
          onPressed: () => _push(context, '/finance/entries/new?type=expense'),
          icon: const Icon(Icons.add),
          label: Text(l10n.financeAddExpenseAction),
        ),
      ],
    );
  }
}
