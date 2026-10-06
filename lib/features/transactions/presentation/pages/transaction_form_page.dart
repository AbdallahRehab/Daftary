import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
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
    this.initialDirection,
  });

  /// When provided, the form opens pre-bound to this person (skipping the
  /// picker) — used when navigating here from a person's own detail page.
  final String? personId;

  /// When both are provided, the form opens in edit mode prefilled from
  /// this transaction (T100 — US6).
  final MoneyTransaction? editingTransaction;
  final Person? editingPerson;

  /// When provided (and not editing), the form opens with this direction
  /// preselected — e.g. from Home's "Money received"/"Money given" quick
  /// actions (012 FR-007).
  final TransactionDirection? initialDirection;

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
          final direction = initialDirection;
          if (direction != null) cubit.directionChanged(direction);
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

class _TransactionFormView extends StatefulWidget {
  const _TransactionFormView();

  @override
  State<_TransactionFormView> createState() => _TransactionFormViewState();
}

class _TransactionFormViewState extends State<_TransactionFormView> {
  // Seeded once from the cubit so edit mode opens prefilled with the
  // record's amount and note; afterwards the fields own their text and
  // report changes through `onChanged`.
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final state = context.read<TransactionFormCubit>().state;
    _amountController = TextEditingController(text: state.amountInput);
    _noteController = TextEditingController(text: state.note ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(
        title: BlocSelector<TransactionFormCubit, TransactionFormState, bool>(
          selector: (state) => state.isEditMode,
          builder: (context, isEditMode) => Text(
            isEditMode
                ? l10n.transactionFormEditTitle
                : l10n.transactionFormCreateTitle,
          ),
        ),
      ),
      body: MultiBlocListener(
        listeners: [
          // 022 E3: confirm a currency change made while editing.
          BlocListener<TransactionFormCubit, TransactionFormState>(
            listenWhen: (previous, current) =>
                previous.pendingCurrency != current.pendingCurrency &&
                current.pendingCurrency != null,
            listener: (context, state) =>
                _confirmCurrencyChange(context, state),
          ),
          // 022 C4: ask before saving a possible duplicate.
          BlocListener<TransactionFormCubit, TransactionFormState>(
            listenWhen: (previous, current) =>
                previous.possibleDuplicate != current.possibleDuplicate &&
                current.possibleDuplicate != null,
            listener: (context, state) => _confirmDuplicate(context),
          ),
        ],
        child: _buildForm(context, l10n),
      ),
    );
  }

  Future<void> _confirmCurrencyChange(
    BuildContext context,
    TransactionFormState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TransactionFormCubit>();
    final pending = state.pendingCurrency!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.editCurrencyConfirmTitle,
      message: l10n.editCurrencyConfirmMessage(
        state.amountInput,
        state.currency.code,
        pending.code,
      ),
      confirmLabel: l10n.commonConfirm,
      cancelLabel: l10n.commonCancel,
    );
    if (cubit.isClosed) return;
    if (confirmed) {
      cubit.confirmCurrencyChange();
    } else {
      cubit.cancelCurrencyChange();
    }
  }

  Future<void> _confirmDuplicate(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<TransactionFormCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.transactionDuplicateTitle,
      message: l10n.transactionDuplicateMessage,
      confirmLabel: l10n.commonSave,
      cancelLabel: l10n.commonCancel,
    );
    if (cubit.isClosed) return;
    if (confirmed) {
      await cubit.confirmDuplicate();
    } else {
      cubit.cancelDuplicate();
    }
  }

  Widget _buildForm(BuildContext context, AppLocalizations l10n) {
    return BlocConsumer<TransactionFormCubit, TransactionFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.duplicateMatches.isEmpty != current.duplicateMatches.isEmpty,
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
          padding:
              const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
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
              if (state.isEditMode &&
                  state.kind == TransactionKind.repayment) ...[
                // `kind` is immutable after creation (Clarifications), and
                // a repayment's direction is fixed by the balance it
                // settled (022 A1): shown as text, never as a control.
                Semantics(
                  label: l10n.repaymentDirectionLockedSemantics(
                    state.direction == TransactionDirection.given
                        ? l10n.directionGiven
                        : l10n.directionReceived,
                    l10n.repaymentDirectionLockedHint,
                  ),
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.lock_outline),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              state.direction == TransactionDirection.given
                                  ? l10n.directionGiven
                                  : l10n.directionReceived,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          l10n.repaymentDirectionLockedHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Chip(label: Text(l10n.repaymentLabel)),
                ),
              ] else
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
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.amountLabel,
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                errorText: state.amountInvalid ? l10n.amountInvalidError : null,
                onChanged: cubit.amountChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              CurrencyPicker(
                // Keyed by value: the underlying form field only reads
                // its initial value once, so a late-arriving primary-
                // currency default must rebuild it.
                key: ValueKey(
                  '${state.currency.code}_'
                  '${state.pendingCurrency?.code}',
                ),
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
                controller: _noteController,
                maxLength: 500,
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
    );
  }
}
