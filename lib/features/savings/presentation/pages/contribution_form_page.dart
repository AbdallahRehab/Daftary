import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_date_field.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/money/money.dart';
import '../../domain/entities/savings_contribution.dart';
import '../cubit/contribution_form_cubit.dart';
import '../cubit/contribution_form_state.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_format.dart';

/// Log a contribution or withdrawal against a goal, or edit one
/// (FR-005/FR-006/FR-009): amount, currency (the goal's by default; any
/// other is converted at save time — FR-028), date, optional note, and — for
/// a new entry only — the contribution/withdrawal toggle.
class ContributionFormPage extends StatelessWidget {
  const ContributionFormPage({
    required this.goalId,
    super.key,
    this.type = ContributionType.contribution,
    this.editingContributionId,
  });

  final String goalId;

  /// The initial type of a new entry.
  final ContributionType type;

  /// When provided, the form edits that entry; its type is then fixed.
  final String? editingContributionId;

  @override
  Widget build(BuildContext context) {
    // Keyed by what it opens, so a reused route never keeps another
    // entry's form.
    return BlocProvider(
      key: ValueKey((goalId, type, editingContributionId)),
      create: (_) {
        final cubit = getIt<ContributionFormCubit>();
        unawaited(
          cubit.initialize(
            goalId: goalId,
            type: type,
            contributionId: editingContributionId,
          ),
        );
        return cubit;
      },
      child: const ContributionFormView(),
    );
  }
}

/// The form itself, reading a [ContributionFormCubit] from above — public so
/// widget tests can drive it with their own cubit.
class ContributionFormView extends StatefulWidget {
  const ContributionFormView({super.key});

  @override
  State<ContributionFormView> createState() => _ContributionFormViewState();
}

class _ContributionFormViewState extends State<ContributionFormView> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    // The cubit may have finished loading before this view subscribed.
    _prefillFrom(context.read<ContributionFormCubit>().state);
  }

  void _prefillFrom(ContributionFormState state) {
    if (_prefilled || state.isLoading) return;
    _amountController.text = state.amountInput;
    _noteController.text = state.note;
    _prefilled = true;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ContributionFormCubit, ContributionFormState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        _prefillFrom(state);
        if (state.isSuccess) context.pop(true);
      },
      builder: (context, state) {
        final format = SavingsFormat.of(context);
        final l10n = format.l10n;
        final cubit = context.read<ContributionFormCubit>();
        final goal = state.goal;
        final title = state.isEditMode
            ? l10n.savingsContributionFormEditTitle
            : state.isWithdrawal
            ? l10n.savingsContributionFormWithdrawTitle
            : l10n.savingsContributionFormAddTitle;

        if (state.isLoading) {
          return AppScaffold(
            appBar: AppTopBar(title: Text(title)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (goal == null) {
          return AppScaffold(
            appBar: AppTopBar(title: Text(title)),
            body: AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.savingsGoalLoadErrorTitle,
              message: state.failure == null
                  ? l10n.savingsGoalNotFoundError
                  : savingsFailureMessage(l10n, state.failure!),
            ),
          );
        }

        final theme = Theme.of(context);
        final muted = AppTypography.bodyMuted.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        );
        final failure = state.failure;
        return AppScaffold(
          appBar: AppTopBar(title: Text(title)),
          body: Builder(
            builder: (context) => ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                if (!state.isEditMode) ...[
                  SegmentedButton<ContributionType>(
                    key: const ValueKey('savingsEntryTypeToggle'),
                    segments: [
                      ButtonSegment(
                        value: ContributionType.contribution,
                        icon: const Icon(Icons.south_west),
                        label: Text(l10n.savingsEntryContribution),
                      ),
                      ButtonSegment(
                        value: ContributionType.withdrawal,
                        icon: const Icon(Icons.north_east),
                        label: Text(l10n.savingsEntryWithdrawal),
                      ),
                    ],
                    selected: {state.type},
                    onSelectionChanged: (selected) =>
                        cubit.typeChanged(selected.first),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (state.blocksNewEntry) ...[
                  Text(
                    l10n.savingsGoalArchivedNotice,
                    key: const ValueKey('savingsEntryArchivedNotice'),
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppTextField(
                  key: const ValueKey('savingsEntryAmountField'),
                  label: l10n.savingsContributionAmountLabel,
                  controller: _amountController,
                  onChanged: cubit.amountChanged,
                  autofocus: !state.isEditMode,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  errorText: state.amountInvalid
                      ? l10n.savingsContributionAmountInvalidError
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
                CurrencyPicker(
                  // Keyed by value: the field reads its initial value once.
                  key: ValueKey(state.currency),
                  value: state.currency,
                  onChanged: cubit.currencyChanged,
                ),
                if (state.needsConversion) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.savingsContributionConversionHint(goal.currency.code),
                    key: const ValueKey('savingsEntryConversionHint'),
                    style: muted,
                  ),
                ],
                if (state.isWithdrawal && !state.isEditMode) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.savingsWithdrawalAvailableHint(
                      format.money(
                        Money.fromMinorUnits(
                          state.availableMinorUnits,
                          goal.currency,
                        ),
                      ),
                    ),
                    style: muted,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                AppDateField(
                  label: l10n.savingsContributionDateLabel,
                  date: state.date,
                  onDateChanged: cubit.dateChanged,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  label: l10n.savingsContributionNoteLabel,
                  controller: _noteController,
                  onChanged: cubit.noteChanged,
                  maxLines: 2,
                  maxLength: 200,
                ),
                // Inline rather than a snackbar: a missing rate or an
                // over-withdrawal is something to fix on this form, so the
                // explanation stays next to it.
                if (failure != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    savingsFailureMessage(l10n, failure),
                    key: const ValueKey('savingsEntryFailure'),
                    style: AppTypography.body.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  key: const ValueKey('savingsEntrySubmit'),
                  label: l10n.savingsContributionSaveAction,
                  isLoading: state.isSubmitting,
                  onPressed: state.blocksNewEntry ? null : cubit.submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
