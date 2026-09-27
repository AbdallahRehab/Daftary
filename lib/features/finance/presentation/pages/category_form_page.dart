import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../cubit/category_form_cubit.dart';
import '../cubit/category_form_state.dart';
import '../widgets/category_display_name.dart';
import '../widgets/category_icon_registry.dart';

/// Create/edit form for a [Category] (US4, FR-007/FR-009).
///
/// The type selector appears only in create mode: a category's type is
/// immutable afterwards, so edit mode has nothing to show there rather than
/// a disabled control implying the choice could be revisited.
class CategoryFormPage extends StatelessWidget {
  const CategoryFormPage({
    super.key,
    this.editingCategoryId,
    this.initialType = CategoryType.expense,
  });

  /// When provided, the form opens in edit mode, prefilled from the
  /// category this id resolves to.
  final String? editingCategoryId;

  /// Which direction a newly created category belongs to — normally the one
  /// the management screen was showing. Ignored in edit mode.
  final CategoryType initialType;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<CategoryFormCubit>();
        final id = editingCategoryId;
        if (id == null) {
          cubit.initializeForCreate(initialType);
        } else {
          // Resolved by id rather than passed as a route `extra`, so a deep
          // link (or a cold start straight onto this route) prefills the
          // same way an in-app navigation does.
          unawaited(_loadForEdit(cubit, id));
        }
        return cubit;
      },
      child: const _CategoryFormView(),
    );
  }

  static Future<void> _loadForEdit(CategoryFormCubit cubit, String id) async {
    final result = await getIt<CategoryRepository>().getCategoryById(id);
    if (cubit.isClosed) return;
    result.match((failure) => cubit.loadFailed(failure), cubit.loadForEdit);
  }
}

class _CategoryFormView extends StatefulWidget {
  const _CategoryFormView();

  @override
  State<_CategoryFormView> createState() => _CategoryFormViewState();
}

class _CategoryFormViewState extends State<_CategoryFormView> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(
        title: BlocSelector<CategoryFormCubit, CategoryFormState, bool>(
          selector: (state) => state.isEditMode,
          builder: (context, isEditMode) => Text(
            isEditMode
                ? l10n.financeCategoryFormEditTitle
                : l10n.financeCategoryFormCreateTitle,
          ),
        ),
      ),
      body: BlocConsumer<CategoryFormCubit, CategoryFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status || previous.name != current.name,
        listener: (context, state) {
          // `loadForEdit` resolves asynchronously, so the prefilled name
          // arrives after the field is already built — mirror it in, but
          // never fight the user's own typing.
          if (_nameController.text != state.name) {
            _nameController.value = TextEditingValue(
              text: state.name,
              selection: TextSelection.collapsed(offset: state.name.length),
            );
          }
          switch (state.status) {
            case CategoryFormStatus.success:
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/finance/categories');
              }
            case CategoryFormStatus.failure:
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.messageFor(state.failure))),
                );
            case CategoryFormStatus.idle:
            case CategoryFormStatus.submitting:
              break;
          }
        },
        builder: (context, state) {
          final cubit = context.read<CategoryFormCubit>();
          final duplicate = state.duplicateExisting;
          return SingleChildScrollView(
            padding:
                const EdgeInsets.all(AppSpacing.md) +
                AppGlassInsets.of(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  key: const ValueKey('categoryNameField'),
                  label: l10n.financeCategoryNameLabel,
                  maxLength: 40,
                  controller: _nameController,
                  autofocus: !state.isEditMode,
                  errorText: state.nameInvalid
                      ? l10n.financeCategoryNameRequiredError
                      : null,
                  onChanged: cubit.nameChanged,
                ),
                if (duplicate != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.financeCategoryDuplicateError(
                      categoryDisplayName(l10n, duplicate),
                    ),
                    style: AppTypography.bodyMuted.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (!state.isEditMode) ...[
                  const SizedBox(height: AppSpacing.md),
                  _FieldLabel(label: l10n.financeCategoryTypeLabel),
                  const SizedBox(height: AppSpacing.xs),
                  SegmentedButton<CategoryType>(
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
                    selected: {state.type ?? CategoryType.expense},
                    onSelectionChanged: (selection) =>
                        cubit.typeChanged(selection.first),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _FieldLabel(label: l10n.financeCategoryIconLabel),
                if (state.iconInvalid) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.financeCategoryIconRequiredError,
                    style: AppTypography.bodyMuted.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                _IconPicker(
                  selectedKey: state.icon,
                  type: state.type ?? CategoryType.expense,
                  onSelected: cubit.iconChanged,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.commonSave,
                  isLoading: state.isSubmitting,
                  onPressed: cubit.submit,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTypography.bodyMuted.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// The bounded icon grid the whole picker is (research.md Decision 10): a
/// curated key set, never a free-form icon/color picker.
class _IconPicker extends StatelessWidget {
  const _IconPicker({
    required this.selectedKey,
    required this.type,
    required this.onSelected,
  });

  final String? selectedKey;
  final CategoryType type;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = CategoryIconRegistry.colorFor(context, type);
    return GridView.count(
      crossAxisCount: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.sm,
      crossAxisSpacing: AppSpacing.sm,
      children: [
        for (final option in CategoryIconRegistry.allOptions)
          InkWell(
            key: ValueKey('categoryIcon_${option.key}'),
            onTap: () => onSelected(option.key),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: option.key == selectedKey
                    ? CategoryIconRegistry.surfaceColorFor(context, type)
                    : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: option.key == selectedKey
                    ? Border.all(color: accent, width: 2)
                    : null,
              ),
              child: Icon(
                option.icon,
                color: option.key == selectedKey
                    ? accent
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
