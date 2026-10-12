import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/presentation/widgets/category_display_name.dart';
import '../cubit/learned_categories_cubit.dart';
import '../widgets/bidi_text.dart';

/// Learned categories (T139, FR-056, ui-contract §3.9): each learned
/// merchant -> category, with Remove, and "Clear learned categories"
/// behind a destructive confirmation. A mapping whose category was
/// archived or deleted shows "Category removed".
class LearnedCategoriesPage extends StatelessWidget {
  const LearnedCategoriesPage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final LearnedCategoriesCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<LearnedCategoriesCubit>())..open(),
      child: const _LearnedCategoriesView(),
    );
  }
}

class _LearnedCategoriesView extends StatelessWidget {
  const _LearnedCategoriesView();

  void _onResult(BuildContext context, LearnedCategoriesState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<LearnedCategoriesCubit>();
    final String message;
    if (state.removed) {
      cubit.consumeRemoved();
      message = l10n.smsImportMappingsRemoved;
    } else if (state.cleared) {
      cubit.consumeCleared();
      message = l10n.smsImportMappingsCleared;
    } else if (state.actionFailure case final failure?) {
      cubit.consumeActionFailure();
      message = l10n.messageFor(failure);
    } else {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<LearnedCategoriesCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.smsImportMappingsClearConfirmTitle,
      message: l10n.smsImportMappingsClearConfirmMessage,
      confirmLabel: l10n.smsImportMappingsClearConfirm,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
      isDestructive: true,
    );
    if (confirmed) await cubit.clearAll();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportMappingsTitle)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocConsumer<LearnedCategoriesCubit, LearnedCategoriesState>(
          listenWhen: (p, c) =>
              (c.removed && !p.removed) ||
              (c.cleared && !p.cleared) ||
              (c.actionFailure != null && p.actionFailure != c.actionFailure),
          listener: _onResult,
          builder: (context, state) {
            final cubit = context.read<LearnedCategoriesCubit>();
            return switch (state.status) {
              LearnedCategoriesStatus.initial ||
              LearnedCategoriesStatus.loading => const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('learned_categories_loading'),
                ),
              ),
              LearnedCategoriesStatus.error => AppEmptyView(
                title: l10n.smsImportMappingsLoadError,
                message: l10n.messageFor(state.failure),
                icon: Icons.error_outline,
                actionLabel: l10n.smsImportPendingRetry,
                onAction: cubit.retry,
              ),
              LearnedCategoriesStatus.empty => AppEmptyView(
                title: l10n.smsImportMappingsEmptyTitle,
                message: l10n.smsImportMappingsEmptyMessage,
                icon: Icons.school_outlined,
              ),
              LearnedCategoriesStatus.ready => ListView(
                key: const ValueKey('learned_categories_list'),
                padding:
                    const EdgeInsets.all(AppSpacing.md) +
                    AppGlassInsets.of(context),
                children: [
                  Text(l10n.smsImportMappingsHelp, style: AppTypography.body),
                  const SizedBox(height: AppSpacing.xs),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.smsImportMappingsCount(state.rows.length),
                      style: AppTypography.bodyMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final row in state.rows)
                          _MappingTile(row: row, state: state, cubit: cubit),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    key: const ValueKey('learned_categories_clear'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                      minimumSize: const Size.fromHeight(
                        AppSizes.minTouchTarget,
                      ),
                    ),
                    onPressed: state.isSubmitting
                        ? null
                        : () => _confirmClear(context),
                    icon: state.clearing
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_sweep_outlined),
                    label: Text(l10n.smsImportMappingsClear),
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

class _MappingTile extends StatelessWidget {
  const _MappingTile({
    required this.row,
    required this.state,
    required this.cubit,
  });

  final LearnedCategoryRow row;
  final LearnedCategoriesState state;
  final LearnedCategoriesCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final mapping = row.mapping;
    final merchant = mapping.merchantKey;
    final typeLabel = mapping.entryType == FinanceEntryType.income
        ? l10n.financeTypeIncome
        : l10n.financeTypeExpense;
    final category = row.category;
    final categoryLabel = category == null
        ? l10n.smsImportMappingsCategoryRemoved
        : categoryDisplayName(l10n, category);
    final keySuffix = '${mapping.entryType.name}_$merchant';
    return ListTile(
      key: ValueKey('learned_category_$keySuffix'),
      title: Semantics(
        label: l10n.smsImportMappingsRowSemantics(
          BidiIsolate.auto(merchant),
          typeLabel,
          categoryLabel,
        ),
        excludeSemantics: true,
        child: BidiText.auto(merchant, style: AppTypography.body),
      ),
      subtitle: ExcludeSemantics(
        child: Wrap(
          spacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(typeLabel, style: AppTypography.bodyMuted),
            Text(
              l10n.smsImportReviewListSeparator.trim(),
              style: AppTypography.bodyMuted,
            ),
            if (category == null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    size: 16,
                    color: scheme.error,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    categoryLabel,
                    key: ValueKey('learned_category_removed_$keySuffix'),
                    style: AppTypography.bodyMuted.copyWith(
                      color: scheme.error,
                    ),
                  ),
                ],
              )
            else
              Text(categoryLabel, style: AppTypography.bodyMuted),
          ],
        ),
      ),
      trailing: TextButton(
        key: ValueKey('learned_category_remove_$keySuffix'),
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppSizes.minTouchTarget,
            AppSizes.minTouchTarget,
          ),
        ),
        onPressed: state.isSubmitting ? null : () => cubit.remove(mapping),
        // The button keeps its tap action for screen readers; only its
        // label is replaced by the one naming the merchant.
        child: Semantics(
          label: l10n.smsImportMappingsRemoveSemantics(
            BidiIsolate.auto(merchant),
          ),
          excludeSemantics: true,
          child: state.removing == mapping
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.smsImportMappingsRemove),
        ),
      ),
    );
  }
}
