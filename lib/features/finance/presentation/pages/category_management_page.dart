import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../cubit/category_management_cubit.dart';
import '../cubit/category_management_state.dart';
import '../widgets/category_display_name.dart';
import '../widgets/category_icon_registry.dart';

/// Category management (US4): one direction at a time, active categories
/// first and archived ones below, each editable and removable.
///
/// Archived categories are shown rather than hidden — archiving takes a
/// category out of the *entry* picker (FR-011), and the screen whose job is
/// managing categories is precisely where the user has to be able to see
/// and rename one afterwards.
class CategoryManagementPage extends StatelessWidget {
  const CategoryManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CategoryManagementCubit>()..load(),
      child: const _CategoryManagementView(),
    );
  }
}

class _CategoryManagementView extends StatelessWidget {
  const _CategoryManagementView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.financeCategoryManagementTitle)),
      floatingActionButton:
          BlocBuilder<CategoryManagementCubit, CategoryManagementState>(
            buildWhen: (previous, current) => previous.type != current.type,
            builder: (context, state) => FloatingActionButton.extended(
              onPressed: () => _openForm(context, type: state.type),
              icon: const Icon(Icons.add),
              label: Text(l10n.financeAddCategoryAction),
            ),
          ),
      body: BlocConsumer<CategoryManagementCubit, CategoryManagementState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage &&
            current.errorMessage != null &&
            current.status != CategoryManagementStatus.failure,
        listener: (context, state) {
          // A removal that failed leaves the list intact, so it is reported
          // transiently rather than replacing the screen with an error view.
          final duplicate = state.duplicateExisting;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  duplicate == null
                      ? (state.errorMessage ?? l10n.commonError)
                      : l10n.financeCategoryDuplicateError(
                          categoryDisplayName(l10n, duplicate),
                        ),
                ),
              ),
            );
        },
        builder: (context, state) {
          return Column(
            children: [
              _TypeToggle(selected: state.type),
              Expanded(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _TypeToggle extends StatelessWidget {
  const _TypeToggle({required this.selected});

  final CategoryType selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SegmentedButton<CategoryType>(
        segments: [
          ButtonSegment(
            value: CategoryType.expense,
            label: Text(l10n.financeTypeExpense),
          ),
          ButtonSegment(
            value: CategoryType.income,
            label: Text(l10n.financeTypeIncome),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (selection) => context
            .read<CategoryManagementCubit>()
            .typeChanged(selection.first),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final CategoryManagementState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == CategoryManagementStatus.failure) {
      return AppEmptyView(
        icon: Icons.error_outline,
        title: l10n.commonError,
        message: state.errorMessage ?? l10n.commonError,
        actionLabel: l10n.commonRetry,
        onAction: () => context.read<CategoryManagementCubit>().load(),
      );
    }

    if (state.isEmpty) {
      return AppEmptyView(
        icon: Icons.label_outline,
        title: l10n.financeNoCategoriesTitle,
        message: l10n.financeNoCategoriesMessage,
        actionLabel: l10n.financeAddCategoryAction,
        onAction: () => _openForm(context, type: state.type),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xxl * 2,
      ),
      children: [
        if (state.active.isNotEmpty) ...[
          _SectionHeader(label: l10n.financeCategorySectionActive),
          for (final category in state.active) _CategoryRow(category: category),
        ],
        if (state.archived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _SectionHeader(label: l10n.financeCategorySectionArchived),
          for (final category in state.archived)
            _CategoryRow(category: category),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.sm),
      child: Text(
        label,
        style: AppTypography.label.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final Category category;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        onTap: () => _openForm(context, editingCategoryId: category.id),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: CategoryIconRegistry.surfaceColorFor(
                  context,
                  category.type,
                ),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                CategoryIconRegistry.iconFor(category.icon),
                color: CategoryIconRegistry.colorFor(context, category.type),
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryDisplayName(l10n, category),
                    style: AppTypography.body,
                  ),
                  if (category.isArchived) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      l10n.financeCategoryArchivedNotice,
                      style: AppTypography.bodyMuted.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.commonEdit,
              onPressed: () =>
                  _openForm(context, editingCategoryId: category.id),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.financeRemoveCategoryAction,
              onPressed: () => _confirmRemove(context, category),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context, Category category) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<CategoryManagementCubit>();
    // The message explains that the outcome — archived or deleted — is
    // decided by whether entries reference the category, because the user
    // cannot choose it and should not be surprised by it (FR-010).
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.financeRemoveCategoryConfirmTitle,
      message: l10n.financeRemoveCategoryConfirmMessage,
      confirmLabel: l10n.commonDelete,
      cancelLabel: l10n.commonCancel,
      isDestructive: true,
    );
    if (!confirmed) return;
    await cubit.removeCategory(category.id);
  }
}

Future<void> _openForm(
  BuildContext context, {
  String? editingCategoryId,
  CategoryType? type,
}) async {
  final cubit = context.read<CategoryManagementCubit>();
  await (editingCategoryId == null
      ? context.push<void>('/finance/categories/new', extra: type)
      : context.push<void>('/finance/categories/$editingCategoryId/edit'));
  // Re-read after the push resolves: the form owns its own cubit, so this
  // screen only learns about a create/edit by asking again.
  if (cubit.isClosed) return;
  await cubit.load();
}
