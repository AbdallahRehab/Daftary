import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/currency_picker.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/goal_form_cubit.dart';
import '../cubit/goal_form_state.dart';
import '../savings_routes.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/goal_type_picker.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_format.dart';

/// Create, or edit, a savings goal (FR-001-FR-003, FR-027, FR-029): name,
/// type, currency (create only), target, starting amount (create only),
/// monthly contribution and target date, with a live estimate preview.
class GoalFormPage extends StatelessWidget {
  const GoalFormPage({super.key, this.editingGoalId});

  /// When provided, the form edits that goal.
  final String? editingGoalId;

  @override
  Widget build(BuildContext context) {
    // Keyed by goal, so a reused route never keeps another goal's form.
    return BlocProvider(
      key: ValueKey(editingGoalId),
      create: (_) {
        final cubit = getIt<GoalFormCubit>();
        final id = editingGoalId;
        unawaited(
          id == null ? cubit.loadDefaultCurrency() : cubit.loadForEdit(id),
        );
        return cubit;
      },
      child: const GoalFormView(),
    );
  }
}

/// The form itself, reading a [GoalFormCubit] from above — public so widget
/// tests can drive it with their own cubit.
class GoalFormView extends StatefulWidget {
  const GoalFormView({super.key});

  @override
  State<GoalFormView> createState() => _GoalFormViewState();
}

class _GoalFormViewState extends State<GoalFormView> {
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();
  final _startingController = TextEditingController();
  final _monthlyController = TextEditingController();

  /// Set once an edit's prefill has been copied into the controllers, so a
  /// late load never overwrites what the user has started typing.
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    // The cubit may have finished loading before this view subscribed.
    _prefillFrom(context.read<GoalFormCubit>().state);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    _startingController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  void _prefillFrom(GoalFormState state) {
    if (_prefilled || !state.isEditMode || state.isLoading) return;
    _nameController.text = state.name;
    _targetController.text = state.targetInput;
    _monthlyController.text = state.monthlyInput;
    _prefilled = true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<GoalFormCubit, GoalFormState>(
      // Only transitions matter here — a prefill landing, a save finishing
      // — so a failure is announced once, not on every later keystroke.
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        _prefillFrom(state);
        if (state.isSuccess) {
          final goal = state.savedGoal!;
          // Edit returns to the goal page; a new goal opens its own page in
          // place of the form, so Back does not return to a spent form.
          if (state.isEditMode) {
            context.pop(true);
          } else {
            context.pushReplacement(SavingsRoutes.goal(goal.id));
          }
          return;
        }
        final failure = state.failure;
        if (state.status == GoalFormStatus.failure && failure != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(savingsFailureMessage(l10n, failure))),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<GoalFormCubit>();
        final isEdit = state.isEditMode;
        return AppScaffold(
          appBar: AppTopBar(
            title: Text(
              isEdit
                  ? l10n.savingsGoalFormEditTitle
                  : l10n.savingsGoalFormCreateTitle,
            ),
          ),
          // Builder: the glass insets are read below the scaffold, where
          // they include the bars the body extends behind.
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Builder(
                  builder: (context) => ListView(
                    padding:
                        const EdgeInsets.all(AppSpacing.md) +
                        AppGlassInsets.of(context),
                    children: [
                      AppTextField(
                        key: const ValueKey('savingsGoalNameField'),
                        label: l10n.savingsGoalNameLabel,
                        controller: _nameController,
                        onChanged: cubit.nameChanged,
                        autofocus: !isEdit,
                        maxLength: 80,
                        errorText: state.nameInvalid
                            ? l10n.savingsGoalNameRequiredError
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GoalTypePicker(
                        selectedType: state.type,
                        onTypeSelected: cubit.typeChanged,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (isEdit)
                        Text(
                          l10n.savingsGoalCurrencyFixedHint(
                            state.currency.code,
                          ),
                          key: const ValueKey('savingsGoalCurrencyFixed'),
                          style: AppTypography.bodyMuted.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        CurrencyPicker(
                          // Keyed by value: the field reads its initial value
                          // once, so a late primary-currency default must
                          // rebuild it.
                          key: ValueKey(state.currency),
                          label: l10n.savingsGoalCurrencyLabel,
                          value: state.currency,
                          onChanged: cubit.currencyChanged,
                        ),
                      const SizedBox(height: AppSpacing.md),
                      _AmountField(
                        fieldKey: const ValueKey('savingsGoalTargetField'),
                        label: l10n.savingsGoalTargetLabel,
                        controller: _targetController,
                        onChanged: cubit.targetChanged,
                        errorText: state.targetInvalid
                            ? l10n.savingsGoalTargetInvalidError
                            : null,
                      ),
                      if (!isEdit) ...[
                        const SizedBox(height: AppSpacing.md),
                        _AmountField(
                          fieldKey: const ValueKey('savingsGoalStartingField'),
                          label: l10n.savingsGoalStartingLabel,
                          controller: _startingController,
                          onChanged: cubit.startingChanged,
                          errorText: state.startingInvalid
                              ? l10n.savingsGoalStartingInvalidError
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.savingsGoalStartingHint,
                          style: AppTypography.bodyMuted.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      _AmountField(
                        fieldKey: const ValueKey('savingsGoalMonthlyField'),
                        label: l10n.savingsGoalMonthlyLabel,
                        controller: _monthlyController,
                        onChanged: cubit.monthlyChanged,
                        errorText: state.monthlyInvalid
                            ? l10n.savingsGoalMonthlyInvalidError
                            : null,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _OptionalDateField(
                        label: l10n.savingsGoalTargetDateLabel,
                        date: state.targetDate,
                        onChanged: cubit.targetDateChanged,
                        errorText: state.targetDateInvalid
                            ? l10n.savingsInvalidTargetDateError
                            : null,
                      ),
                      if (state.preview != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        GoalProgressCard(
                          key: const ValueKey('savingsGoalPreview'),
                          goal: state.previewGoal!,
                          progress: state.preview!,
                          title: l10n.savingsGoalPreviewTitle,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        key: const ValueKey('savingsGoalSubmit'),
                        label: isEdit
                            ? l10n.savingsGoalUpdateAction
                            : l10n.savingsGoalCreateAction,
                        isLoading: state.isSubmitting,
                        onPressed: cubit.submit,
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.fieldKey,
    required this.label,
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  final Key fieldKey;
  final String label;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      key: fieldKey,
      label: label,
      controller: controller,
      onChanged: onChanged,
      // Left in the ambient direction on purpose: Arabic-Indic and Western
      // digits are accepted alike.
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      errorText: errorText,
    );
  }
}

/// A date that may be left unset: tap to pick (from tomorrow on — FR-003),
/// clear to remove.
class _OptionalDateField extends StatelessWidget {
  const _OptionalDateField({
    required this.label,
    required this.date,
    required this.onChanged,
    this.errorText,
  });

  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final value = date;
    return InkWell(
      key: const ValueKey('savingsGoalTargetDateField'),
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () async {
        final now = DateTime.now();
        final tomorrow = DateTime(now.year, now.month, now.day + 1);
        final initial = value == null || value.isBefore(tomorrow)
            ? tomorrow
            : value;
        final picked = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: tomorrow,
          lastDate: DateTime(now.year + 100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          suffixIcon: value == null
              ? const Icon(Icons.event_outlined)
              : IconButton(
                  tooltip: l10n.savingsGoalTargetDateClear,
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null ? l10n.savingsGoalTargetDateNotSet : format.date(value),
        ),
      ),
    );
  }
}
