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
import '../../../people/domain/repositories/people_repository.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/domain/repositories/transactions_repository.dart';
import '../../../transactions/presentation/widgets/duplicate_warning_sheet.dart';
import '../../../transactions/presentation/widgets/person_picker_field.dart';
import '../../domain/entities/occasion_type.dart';
import '../../domain/repositories/occasions_repository.dart';
import '../cubit/participant_form_cubit.dart';
import '../cubit/participant_form_state.dart';

/// Record, or correct, one participant's contribution to an occasion
/// (FR-003/FR-004 and, in edit mode, FR-010).
class ParticipantFormPage extends StatelessWidget {
  const ParticipantFormPage({
    required this.occasionId,
    super.key,
    this.editingTransactionId,
  });

  final String occasionId;

  /// When provided, the form edits that existing contribution — the exact
  /// same row the person's own profile screen edits (FR-010).
  final String? editingTransactionId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = getIt<ParticipantFormCubit>();
        unawaited(_initialize(cubit));
        return cubit;
      },
      child: const _ParticipantFormView(),
    );
  }

  /// The occasion's type is fetched first either way, because it decides
  /// the `countsTowardBalance` default for a new contribution (FR-018) and
  /// labels the screen for an existing one.
  Future<void> _initialize(ParticipantFormCubit cubit) async {
    final detail = await getIt<OccasionsRepository>().getOccasionDetail(
      occasionId,
    );
    final type = detail.match(
      (_) => OccasionType.other,
      (d) => d.occasion.type,
    );

    final transactionId = editingTransactionId;
    if (transactionId == null) {
      cubit.initialize(occasionId: occasionId, occasionType: type);
      return;
    }

    final rows = await getIt<TransactionsRepository>()
        .getContributionsForOccasion(occasionId);
    final MoneyTransaction? row = rows.match(
      (_) => null,
      (list) => list.where((t) => t.id == transactionId).firstOrNull,
    );
    if (row == null) {
      cubit.initialize(occasionId: occasionId, occasionType: type);
      return;
    }

    final person = await getIt<PeopleRepository>().getPersonById(row.personId);
    person.match(
      (_) => cubit.initialize(occasionId: occasionId, occasionType: type),
      (p) => cubit.loadForEdit(transaction: row, person: p, occasionType: type),
    );
  }
}

class _ParticipantFormView extends StatefulWidget {
  const _ParticipantFormView();

  @override
  State<_ParticipantFormView> createState() => _ParticipantFormViewState();
}

class _ParticipantFormViewState extends State<_ParticipantFormView> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<ParticipantFormCubit, ParticipantFormState>(
      listener: (context, state) {
        if (state.isEditMode && !_prefilled) {
          _amountController.text = state.amountInput;
          _noteController.text = state.note ?? '';
          _prefilled = true;
        }
        if (state.isSuccess) context.pop(true);
        if (state.duplicateMatches.isNotEmpty) {
          final cubit = context.read<ParticipantFormCubit>();
          showDuplicateWarningSheet(
            context,
            matches: state.duplicateMatches,
            onPickExisting: cubit.pickDuplicateMatch,
            onCreateNewAnyway: cubit.confirmCreateDespitePendingDuplicate,
          ).then((_) {
            if (context.mounted) cubit.dismissDuplicateWarning();
          });
        }
        final failure = state.failure ?? state.personFailure;
        if (failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message)));
        }
      },
      builder: (context, state) {
        final cubit = context.read<ParticipantFormCubit>();
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.isEditMode
                  ? l10n.occasionParticipantFormEditTitle
                  : l10n.occasionParticipantFormAddTitle,
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              PersonPickerField(
                query: state.personQuery,
                results: state.personSearchResults,
                selectedPerson: state.selectedPerson,
                onQueryChanged: cubit.onPersonQueryChanged,
                onPersonSelected: cubit.selectExistingPerson,
                onCreateNew: cubit.createNewPerson,
                errorText: state.personSelectionRequired
                    ? l10n.occasionParticipantPersonLabel
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.occasionParticipantAmountLabel,
                controller: _amountController,
                onChanged: cubit.amountChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                // Left as the ambient direction on purpose: the field
                // accepts Arabic-Indic and Western digits alike (FR-022).
                errorText: state.amountInvalid
                    ? l10n.occasionParticipantAmountInvalidError
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<TransactionDirection>(
                segments: [
                  ButtonSegment(
                    value: TransactionDirection.received,
                    label: Text(l10n.occasionParticipantDirectionReceived),
                  ),
                  ButtonSegment(
                    value: TransactionDirection.given,
                    label: Text(l10n.occasionParticipantDirectionGiven),
                  ),
                ],
                selected: {state.direction},
                onSelectionChanged: (selected) =>
                    cubit.directionChanged(selected.first),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDateField(
                label: l10n.occasionDateLabel,
                date: state.date,
                onDateChanged: cubit.dateChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: l10n.occasionParticipantNoteLabel,
                controller: _noteController,
                onChanged: cubit.noteChanged,
                maxLines: 2,
              ),
              const SizedBox(height: AppSpacing.sm),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.countsTowardBalance,
                onChanged: cubit.countsTowardBalanceChanged,
                title: Text(
                  l10n.occasionParticipantCountsTowardBalanceLabel,
                  style: AppTypography.body,
                ),
                // Always visible, not only for condolences: the toggle's
                // default is the surprising part, and a user who finds it
                // already off deserves to read why without hunting.
                subtitle: Text(
                  l10n.occasionParticipantCountsTowardBalanceHint,
                  style: AppTypography.bodyMuted,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: state.isEditMode
                    ? l10n.occasionParticipantUpdateAction
                    : l10n.occasionParticipantSaveAction,
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
