import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../../people/domain/entities/person.dart';
import '../../domain/entities/money_transaction.dart';
import '../cubit/transaction_form_cubit.dart';
import '../cubit/transaction_form_state.dart';
import '../widgets/duplicate_warning_sheet.dart';
import '../widgets/person_picker_field.dart';

/// Record (or edit) a money transaction: pick/inline-create a person,
/// amount, direction, date, and an optional note (FR-004, and edit mode for
/// US6/T100).
class TransactionFormPage extends StatelessWidget {
  const TransactionFormPage({
    super.key,
    this.personId,
    this.editingTransaction,
    this.editingPerson,
  });

  /// When provided, the form opens pre-bound to this person (skipping the
  /// picker) — used when navigating here from a person's own detail page.
  final String? personId;

  /// When both are provided, the form opens in edit mode prefilled from
  /// this transaction (T100 — US6).
  final MoneyTransaction? editingTransaction;
  final Person? editingPerson;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<TransactionFormCubit>();
        final transaction = editingTransaction;
        final person = editingPerson;
        if (transaction != null && person != null) {
          cubit.loadForEdit(transaction, person);
        } else {
          // New records default to the primary currency (018 FR-003);
          // edits keep the record's own currency (set by loadForEdit).
          unawaited(cubit.loadDefaultCurrency());
          if (personId != null) {
            unawaited(cubit.initializeWithPerson(personId!));
          }
        }
        return cubit;
      },
      child: const _TransactionFormView(),
    );
  }
}

class _TransactionFormView extends StatelessWidget {
  const _TransactionFormView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<TransactionFormCubit, TransactionFormState, bool>(
          selector: (state) => state.isEditMode,
          builder: (context, isEditMode) => Text(
            isEditMode
                ? l10n.transactionFormEditTitle
                : l10n.transactionFormCreateTitle,
          ),
        ),
      ),
      body: BlocConsumer<TransactionFormCubit, TransactionFormState>(
        listenWhen: (previous, current) =>
            previous.status != current.status ||
            previous.duplicateMatches.isEmpty !=
                current.duplicateMatches.isEmpty,
        listener: (context, state) {
          if (state.duplicateMatches.isNotEmpty) {
            showDuplicateWarningSheet(
              context,
              matches: state.duplicateMatches,
              onPickExisting: context
                  .read<TransactionFormCubit>()
                  .pickDuplicateMatch,
              onCreateNewAnyway: context
                  .read<TransactionFormCubit>()
                  .confirmCreateDespitePendingDuplicate,
            );
          }
          if (state.status == TransactionFormStatus.success) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(l10n.savedConfirmation)));
            final savedTransaction = state.savedTransaction;
            Navigator.of(context).pop(savedTransaction);
          } else if (state.status == TransactionFormStatus.failure) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(content: Text(l10n.messageFor(state.failure))),
              );
          }
        },
        builder: (context, state) {
          final cubit = context.read<TransactionFormCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!state.isEditMode)
                  PersonPickerField(
                    query: state.personQuery,
                    results: state.personSearchResults,
                    selectedPerson: state.selectedPerson,
                    errorText: state.personSelectionRequired
                        ? l10n.personRequiredError
                        : state.personFailure == null
                        ? null
                        : l10n.messageFor(state.personFailure),
                    onQueryChanged: cubit.onPersonQueryChanged,
                    onPersonSelected: cubit.selectExistingPerson,
                    onCreateNew: cubit.createNewPerson,
                  )
                else
                  // The person is immutable once a transaction exists
                  // (renaming happens on their own profile) — rendered as
                  // a locked field rather than a live `TextField`, so it
                  // never implies typing here would do anything.
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: l10n.personLabel,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      suffixIcon: const Icon(Icons.lock_outline, size: 18),
                    ),
                    child: Text(
                      state.selectedPerson?.name ?? '',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<TransactionDirection>(
                  segments: [
                    ButtonSegment(
                      value: TransactionDirection.given,
                      label: Text(l10n.directionGiven),
                    ),
                    ButtonSegment(
                      value: TransactionDirection.received,
                      label: Text(l10n.directionReceived),
                    ),
                  ],
                  selected: {state.direction},
                  onSelectionChanged: (selection) =>
                      cubit.directionChanged(selection.first),
                ),
                // `kind` is immutable after creation (Clarifications) — in
                // edit mode a repayment is shown read-only, never offered
                // as an editable field.
                if (state.isEditMode &&
                    state.kind == TransactionKind.repayment) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Chip(label: Text(l10n.repaymentLabel)),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.amountLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: state.amountInvalid
                      ? l10n.amountInvalidError
                      : state.amountErrorMessage,
                  onChanged: cubit.amountChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                CurrencyPicker(
                  // Keyed by value: the underlying form field only reads
                  // its initial value once, so a late-arriving primary-
                  // currency default must rebuild it.
                  key: ValueKey(state.currency),
                  value: state.currency,
                  onChanged: cubit.currencyChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDateField(
                  label: l10n.dateLabel,
                  date: state.date,
                  onDateChanged: cubit.dateChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.noteLabel,
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
