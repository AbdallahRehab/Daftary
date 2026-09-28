import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../../finance/presentation/widgets/category_display_name.dart';
import '../../../finance/presentation/widgets/category_icon_registry.dart';
import '../../../finance/presentation/widgets/category_picker_field.dart';
import '../cubit/budget_form_cubit.dart';
import '../cubit/budget_form_state.dart';
import '../widgets/budget_failure_message.dart';
import '../widgets/budget_month_format.dart';
import '../widgets/budget_overall_summary_card.dart';

/// Create or edit one month's budget (US1, FR-010/FR-011): the optional
/// expected income, one planned amount per expense category, a live total
/// with the non-blocking "exceeds income" hint (FR-004), and — for an
/// existing budget — delete.
class BudgetFormPage extends StatelessWidget {
  const BudgetFormPage({required this.month, super.key});

  /// `'YYYY-MM'`. The form opens in edit mode when this month already has
  /// a budget, so `/budgets/:month/new` and `/budgets/:month/edit` can
  /// never produce two budgets for one month.
  final String month;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<BudgetFormCubit>();
        unawaited(cubit.initialize(month));
        return cubit;
      },
      child: const BudgetFormView(),
    );
  }
}

/// The form's widget tree without its `getIt`-resolved cubit, so widget
/// tests can drive it with a cubit over mocked use cases.
class BudgetFormView extends StatefulWidget {
  const BudgetFormView({super.key});

  @override
  State<BudgetFormView> createState() => _BudgetFormViewState();
}

class _BudgetFormViewState extends State<BudgetFormView> {
  final TextEditingController _incomeController = TextEditingController();

  /// One controller per category row, keyed by category id — rows come and
  /// go as categories are added and removed.
  final Map<String, TextEditingController> _amountControllers = {};

  @override
  void dispose() {
    _incomeController.dispose();
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Edit mode prefills asynchronously, so controllers are synced from
  /// state — and only when the text differs, so the caret is never moved
  /// out from under the user.
  void _syncControllers(BudgetFormState state) {
    if (_incomeController.text != state.incomeInput) {
      _incomeController.text = state.incomeInput;
    }
    final liveIds = {for (final draft in state.allocations) draft.categoryId};
    for (final id in [..._amountControllers.keys]) {
      if (!liveIds.contains(id)) _amountControllers.remove(id)!.dispose();
    }
    for (final draft in state.allocations) {
      final controller = _amountControllers.putIfAbsent(
        draft.categoryId,
        TextEditingController.new,
      );
      if (controller.text != draft.amountInput) {
        controller.text = draft.amountInput;
      }
    }
  }

  Future<void> _confirmDelete(BudgetFormState state) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BudgetFormCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.budgetDeleteConfirmTitle,
      message: l10n.budgetDeleteConfirmMessage(
        BudgetMonthFormat.long(context, state.month),
      ),
      confirmLabel: l10n.commonDelete,
      isDestructive: true,
    );
    if (confirmed) await cubit.deleteBudget();
  }

  Future<void> _manageCategories() async {
    final cubit = context.read<BudgetFormCubit>();
    await context.push('/finance/categories');
    if (mounted) unawaited(cubit.reloadCategories());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<BudgetFormCubit, BudgetFormState>(
      listener: (context, state) {
        _syncControllers(state);
        final messenger = ScaffoldMessenger.of(context);
        switch (state.status) {
          case BudgetFormStatus.success:
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.savedConfirmation)));
            context.pop(true);
          case BudgetFormStatus.deleted:
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.budgetDeletedConfirmation)),
              );
            context.pop(true);
          case BudgetFormStatus.failure:
            messenger
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(budgetFailureMessage(l10n, state.failure!)),
                ),
              );
          case BudgetFormStatus.loading ||
              BudgetFormStatus.editing ||
              BudgetFormStatus.submitting ||
              BudgetFormStatus.deleting:
            break;
        }
      },
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.incomeInput != current.incomeInput ||
          previous.allocations != current.allocations,
      builder: (context, state) {
        final cubit = context.read<BudgetFormCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.isEditMode
                  ? l10n.budgetFormEditTitle
                  : l10n.budgetFormCreateTitle,
            ),
            actions: [
              if (state.isEditMode && state.budgetId != null)
                IconButton(
                  tooltip: l10n.budgetDeleteAction,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: state.isBusy ? null : () => _confirmDelete(state),
                ),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : _FormBody(
                  state: state,
                  cubit: cubit,
                  incomeController: _incomeController,
                  amountControllers: _amountControllers,
                  onManageCategories: _manageCategories,
                ),
        );
      },
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.state,
    required this.cubit,
    required this.incomeController,
    required this.amountControllers,
    required this.onManageCategories,
  });

  final BudgetFormState state;
  final BudgetFormCubit cubit;
  final TextEditingController incomeController;
  final Map<String, TextEditingController> amountControllers;
  final VoidCallback onManageCategories;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final muted = AppTypography.bodyMuted.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final available = state.availableCategories;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.budgetFormMonthLabel, style: muted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            BudgetMonthFormat.long(context, state.month),
            style: AppTypography.title,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: l10n.budgetExpectedIncomeLabel,
            controller: incomeController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            errorText: _amountErrorText(l10n, state.incomeError),
            onChanged: cubit.expectedIncomeChanged,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.budgetExpectedIncomeHelp, style: muted),
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.budgetAllocationsHeader, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          if (state.allocations.isEmpty)
            Text(l10n.budgetAllocationsEmpty, style: muted)
          else
            for (final draft in state.allocations)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  bottom: AppSpacing.sm,
                ),
                child: _AllocationEditorRow(
                  key: ValueKey('allocation-${draft.categoryId}'),
                  draft: draft,
                  controller: amountControllers.putIfAbsent(
                    draft.categoryId,
                    () => TextEditingController(text: draft.amountInput),
                  ),
                  onChanged: (text) =>
                      cubit.allocationAmountChanged(draft.categoryId, text),
                  onRemove: state.isBusy
                      ? null
                      : () => cubit.allocationRemoved(draft.categoryId),
                ),
              ),
          const SizedBox(height: AppSpacing.sm),
          _TotalPlannedRow(
            total: formatter.formatWithSymbol(
              Money.fromMinorUnits(
                state.totalPlannedMinorUnits,
                state.currency,
              ),
            ),
          ),
          if (state.plannedExceedsIncome) ...[
            const SizedBox(height: AppSpacing.sm),
            BudgetExceedsIncomeNotice(
              excess: Money.fromMinorUnits(
                state.excessOverIncomeMinorUnits,
                state.currency,
              ),
              footnote: l10n.budgetExceedsIncomeSaveNote,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.budgetAddCategoryHeader, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                // 007's own picker, fed only active expense categories not
                // already on this budget (FR-001/FR-021). A tap adds the
                // category as a new row rather than "selecting" it.
                if (available.isEmpty &&
                    state.categories.isNotEmpty &&
                    !state.isLoadingCategories) ...[
                  Text(l10n.budgetAllCategoriesAdded, style: muted),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: onManageCategories,
                      icon: const Icon(Icons.tune, size: 18),
                      label: Text(l10n.financeManageCategoriesAction),
                    ),
                  ),
                ] else
                  CategoryPickerField(
                    categories: available,
                    type: CategoryType.expense,
                    isLoading: state.isLoadingCategories,
                    onCategorySelected: cubit.categoryAdded,
                    onManageCategories: onManageCategories,
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: l10n.commonSave,
            isLoading: state.isSubmitting,
            onPressed: state.isDeleting ? null : cubit.submit,
          ),
        ],
      ),
    );
  }
}

String? _amountErrorText(AppLocalizations l10n, BudgetAmountError? error) =>
    switch (error) {
      null => null,
      BudgetAmountError.required => l10n.budgetAmountRequiredError,
      BudgetAmountError.invalid => l10n.budgetAmountInvalidError,
      BudgetAmountError.negative => l10n.budgetAmountNegativeError,
    };

class _AllocationEditorRow extends StatelessWidget {
  const _AllocationEditorRow({
    required this.draft,
    required this.controller,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final BudgetAllocationDraft draft;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = draft.categoryName.isEmpty
        ? l10n.budgetCategoryMissingName
        : categoryDisplayNameFor(
            l10n,
            iconKey: draft.categoryIcon,
            name: draft.categoryName,
          );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
          child: Icon(
            CategoryIconRegistry.iconFor(draft.categoryIcon),
            size: 20,
            color: CategoryIconRegistry.colorFor(context, CategoryType.expense),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                draft.isCategoryArchived
                    ? '$name · ${l10n.budgetCategoryArchivedTag}'
                    : name,
                style: AppTypography.label.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              AppTextField(
                label: l10n.budgetPlannedAmountLabel,
                controller: controller,
                // Arabic-Indic digits are normalized on parse, so both
                // numeral systems are typeable here.
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: _amountErrorText(l10n, draft.amountError),
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpacing.md),
          child: IconButton(
            tooltip: l10n.budgetRemoveAllocationAction,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

class _TotalPlannedRow extends StatelessWidget {
  const _TotalPlannedRow({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.budgetTotalPlannedLabel,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Text(total, style: AppTypography.amount),
      ],
    );
  }
}
