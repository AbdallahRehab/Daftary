import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/finance_entry_type.dart';
import '../../domain/repositories/category_repository.dart';
import '../../domain/repositories/finance_repository.dart';
import '../cubit/finance_entry_form_cubit.dart';
import '../cubit/finance_entry_form_state.dart';
import '../widgets/category_picker_field.dart';

/// Record (or correct) one income or expense entry: direction, amount,
/// category, date, and an optional note (FR-001/FR-002, and edit mode for
/// FR-019).
class FinanceEntryFormPage extends StatelessWidget {
  const FinanceEntryFormPage({
    super.key,
    this.initialType = FinanceEntryType.expense,
    this.editingEntryId,
  });

  /// Which direction the form opens on — the Add Expense and Add Income
  /// entry points are the same form, differing only here (T031).
  final FinanceEntryType initialType;

  /// When provided, the form opens in edit mode prefilled from that entry.
  final String? editingEntryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<FinanceEntryFormCubit>();
        final entryId = editingEntryId;
        if (entryId != null) {
          unawaited(_loadForEdit(cubit, entryId));
        } else {
          unawaited(cubit.initialize(type: initialType));
        }
        return cubit;
      },
      child: const _FinanceEntryFormView(),
    );
  }

  /// Resolves the entry and its category before handing both to the cubit.
  /// The category is fetched by id rather than taken from the picker's
  /// active-only set precisely because it may since have been archived,
  /// which must not stop the entry that uses it from being edited (FR-011).
  static Future<void> _loadForEdit(
    FinanceEntryFormCubit cubit,
    String entryId,
  ) async {
    final entryResult = await getIt<FinanceRepository>().getEntryById(entryId);
    await entryResult.match((_) async {}, (entry) async {
      final categoryResult = await getIt<CategoryRepository>()
          .getCategoryById(entry.categoryId);
      categoryResult.match(
        (_) {},
        (category) => cubit.loadForEdit(entry, category),
      );
    });
  }
}

class _FinanceEntryFormView extends StatefulWidget {
  const _FinanceEntryFormView();

  @override
  State<_FinanceEntryFormView> createState() => _FinanceEntryFormViewState();
}

class _FinanceEntryFormViewState extends State<_FinanceEntryFormView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Edit mode prefills asynchronously (the entry is read after the form is
  /// already on screen), so the controllers are synced from state rather
  /// than seeded once at construction — and only when the text actually
  /// differs, so the caret is never moved out from under the user.
  void _syncControllers(FinanceEntryFormState state) {
    if (_amountController.text != state.amountInput) {
      _amountController.text = state.amountInput;
    }
    final note = state.note ?? '';
    if (_noteController.text != note) {
      _noteController.text = note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title:
            BlocSelector<FinanceEntryFormCubit, FinanceEntryFormState, String>(
              selector: (state) => state.isEditMode
                  ? l10n.financeEntryFormEditTitle
                  : state.type == FinanceEntryType.income
                  ? l10n.financeEntryFormIncomeTitle
                  : l10n.financeEntryFormExpenseTitle,
              builder: (context, title) => Text(title),
            ),
      ),
      body: BlocConsumer<FinanceEntryFormCubit, FinanceEntryFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.amountInput != current.amountInput ||
            previous.note != current.note,
        listener: (context, state) {
          _syncControllers(state);
          if (state.status == FinanceEntryFormStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.savedConfirmation)));
            Navigator.of(context).pop(state.savedEntry);
          } else if (state.status == FinanceEntryFormStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage ?? l10n.errorUnknown),
                ),
              );
          }
        },
        builder: (context, state) {
          final cubit = context.read<FinanceEntryFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<FinanceEntryType>(
                  segments: [
                    ButtonSegment(
                      value: FinanceEntryType.expense,
                      label: Text(l10n.financeTypeExpense),
                      icon: const Icon(Icons.north_east, size: 16),
                    ),
                    ButtonSegment(
                      value: FinanceEntryType.income,
                      label: Text(l10n.financeTypeIncome),
                      icon: const Icon(Icons.south_west, size: 16),
                    ),
                  ],
                  selected: {state.type},
                  onSelectionChanged: (selection) =>
                      unawaited(cubit.typeChanged(selection.first)),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.amountLabel,
                  controller: _amountController,
                  // Arabic-Indic digits are normalized on parse
                  // (`NumeralParser`), so both numeral systems are typeable
                  // here (FR-024).
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: state.amountInvalid
                      ? l10n.amountInvalidError
                      : null,
                  onChanged: cubit.amountChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDateField(
                  label: l10n.dateLabel,
                  date: state.date,
                  onDateChanged: cubit.dateChanged,
                  // Future dates are accepted as planned/scheduled entries
                  // (FR-001).
                  lastDate: DateTime(DateTime.now().year + 5),
                ),
                const SizedBox(height: AppSpacing.md),
                CategoryPickerField(
                  categories: state.categories,
                  type: state.type,
                  selectedCategoryId: state.selectedCategoryId,
                  isLoading: state.isLoadingCategories,
                  errorText: state.categorySelectionRequired
                      ? l10n.financeCategoryRequiredError
                      : null,
                  onCategorySelected: cubit.categorySelected,
                  onManageCategories: () => context.push('/finance/categories'),
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.noteLabel,
                  controller: _noteController,
                  maxLines: 3,
                  onChanged: cubit.noteChanged,
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
