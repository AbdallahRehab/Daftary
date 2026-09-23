import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../finance/presentation/widgets/category_display_name.dart';
import '../cubit/budget_trend_cubit.dart';
import '../cubit/budget_trend_state.dart';
import '../widgets/budget_trend_chart.dart';

/// The spending trend view (US5, FR-014): planned vs. actual over the most
/// recent 6 months, overall or for one expense category.
///
/// With fewer than two budgeted months in the window it shows the
/// "not enough history yet" state instead of a chart — a single bar group
/// would read as a trend when it is not one.
class BudgetTrendPage extends StatelessWidget {
  const BudgetTrendPage({this.endMonth, super.key});

  /// The last month of the window (`'YYYY-MM'`) — typically the month the
  /// user was looking at. `null` means the current month.
  final String? endMonth;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<BudgetTrendCubit>()..load(endMonth: endMonth),
      child: const _BudgetTrendView(),
    );
  }
}

class _BudgetTrendView extends StatelessWidget {
  const _BudgetTrendView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgetTrendTitle)),
      body: BlocBuilder<BudgetTrendCubit, BudgetTrendState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              if (state.categories.isNotEmpty) ...[
                _CategorySelector(state: state),
                const SizedBox(height: AppSpacing.md),
              ],
              _Body(state: state),
            ],
          );
        },
      ),
    );
  }
}

class _CategorySelector extends StatelessWidget {
  const _CategorySelector({required this.state});

  final BudgetTrendState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String?>(
      // Keyed on the selection so a cubit-side reset (e.g. the selected
      // category was archived meanwhile) is reflected, not just user picks.
      key: ValueKey(state.selectedCategoryId),
      initialValue: state.selectedCategoryId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.budgetTrendCategoryLabel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      items: [
        DropdownMenuItem<String?>(child: Text(l10n.budgetTrendOverall)),
        for (final category in state.categories)
          DropdownMenuItem<String?>(
            value: category.id,
            child: Text(categoryDisplayName(l10n, category)),
          ),
      ],
      onChanged: context.read<BudgetTrendCubit>().categoryChanged,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final BudgetTrendState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.isFailure) {
      return AppEmptyView(
        icon: Icons.error_outline,
        title: l10n.commonError,
        message: state.failure?.message ?? l10n.commonError,
        actionLabel: l10n.commonRetry,
        onAction: () =>
            context.read<BudgetTrendCubit>().load(endMonth: state.endMonth),
      );
    }

    if (state.isInsufficientHistory) {
      return AppEmptyView(
        icon: Icons.insights_outlined,
        title: l10n.budgetTrendInsufficientTitle,
        message: l10n.budgetTrendInsufficientMessage,
      );
    }

    final title = state.selectedCategory == null
        ? l10n.budgetTrendOverall
        : categoryDisplayName(l10n, state.selectedCategory!);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.budgetTrendSubtitle,
            style: AppTypography.bodyMuted.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          BudgetTrendChart(points: state.points),
        ],
      ),
    );
  }
}
