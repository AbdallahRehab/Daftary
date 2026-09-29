import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/savings_goal_detail.dart';
import '../../domain/entities/what_if_mode.dart';
import '../cubit/what_if_cubit.dart';
import '../cubit/what_if_state.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_format.dart';
import '../widgets/what_if_result_card.dart';

/// The "what if" calculator for one goal (FR-013-FR-016): explore a
/// different monthly contribution or a target date, see the answer next to
/// the real plan, and either apply it (FR-015) or leave with the goal
/// untouched. An achieved goal gets an explanation instead (FR-016).
class WhatIfCalculatorPage extends StatelessWidget {
  const WhatIfCalculatorPage({required this.goalId, super.key});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    // Keyed by goal, so a reused route never keeps another goal's cubit.
    return BlocProvider(
      key: ValueKey(goalId),
      create: (_) => getIt<WhatIfCubit>()..load(goalId),
      child: const WhatIfCalculatorView(),
    );
  }
}

/// The page body, reading a [WhatIfCubit] from above — public so widget
/// tests can drive it with their own cubit.
class WhatIfCalculatorView extends StatefulWidget {
  const WhatIfCalculatorView({super.key});

  @override
  State<WhatIfCalculatorView> createState() => _WhatIfCalculatorViewState();
}

class _WhatIfCalculatorViewState extends State<WhatIfCalculatorView> {
  final _monthlyController = TextEditingController();

  @override
  void dispose() {
    _monthlyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<WhatIfCubit, WhatIfState>(
      listenWhen: (previous, current) =>
          previous.applyStatus != current.applyStatus ||
          (current.failure != null && previous.failure != current.failure),
      listener: (context, state) {
        if (state.applyStatus == WhatIfApplyStatus.applied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.savingsWhatIfAppliedMessage)),
          );
          context.pop(true);
          return;
        }
        // A failed calculation or apply on a loaded goal — explained once.
        final failure = state.failure;
        if (failure != null && state.status == WhatIfStatus.ready) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(savingsFailureMessage(l10n, failure))),
          );
          context.read<WhatIfCubit>().failureShown();
        }
      },
      builder: (context, state) {
        final cubit = context.read<WhatIfCubit>();
        final appBar = AppTopBar(title: Text(l10n.savingsWhatIfTitle));
        final detail = state.detail;

        switch (state.status) {
          case WhatIfStatus.loading:
            return AppScaffold(
              appBar: appBar,
              body: const Center(child: CircularProgressIndicator()),
            );
          case WhatIfStatus.failure:
            return AppScaffold(
              appBar: appBar,
              body: AppEmptyView(
                icon: Icons.error_outline,
                title: l10n.savingsGoalLoadErrorTitle,
                message: savingsFailureMessage(
                  l10n,
                  state.failure ?? const UnknownFailure('Goal not loaded'),
                ),
                actionLabel: l10n.savingsRetryAction,
                onAction: () => cubit.load(state.goalId),
              ),
            );
          case WhatIfStatus.achieved:
            // FR-016: say so plainly; no calculator, nothing misleading.
            return AppScaffold(
              appBar: appBar,
              body: AppEmptyView(
                key: const ValueKey('savingsWhatIfAchieved'),
                icon: Icons.emoji_events_outlined,
                title: l10n.savingsWhatIfAchievedTitle,
                message: l10n.savingsWhatIfAchievedMessage,
                actionLabel: l10n.savingsWhatIfBackAction,
                onAction: () => context.pop(),
              ),
            );
          case WhatIfStatus.ready:
            break;
        }

        return AppScaffold(
          appBar: appBar,
          // Builder: the glass insets are read below the scaffold, where
          // they include the bars the body extends behind.
          body: Builder(
            builder: (context) => ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                _CurrentPlan(detail: detail!),
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<WhatIfMode>(
                  key: const ValueKey('savingsWhatIfModePicker'),
                  segments: [
                    ButtonSegment(
                      value: WhatIfMode.monthlyContribution,
                      icon: const Icon(Icons.payments_outlined),
                      label: Text(
                        l10n.savingsWhatIfModeMonthly,
                        key: const ValueKey('savingsWhatIfModeMonthly'),
                      ),
                    ),
                    ButtonSegment(
                      value: WhatIfMode.targetDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        l10n.savingsWhatIfModeDate,
                        key: const ValueKey('savingsWhatIfModeDate'),
                      ),
                    ),
                  ],
                  selected: {state.mode},
                  onSelectionChanged: (selected) =>
                      cubit.modeChanged(selected.first),
                ),
                const SizedBox(height: AppSpacing.md),
                switch (state.mode) {
                  WhatIfMode.monthlyContribution => AppTextField(
                    key: const ValueKey('savingsWhatIfMonthlyField'),
                    label: l10n.savingsWhatIfMonthlyLabel,
                    controller: _monthlyController,
                    onChanged: cubit.monthlyChanged,
                    // Arabic-Indic and Western digits are accepted alike.
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    errorText: state.monthlyInvalid
                        ? l10n.savingsWhatIfMonthlyInvalidError
                        : null,
                  ),
                  WhatIfMode.targetDate => _TargetDateField(
                    date: state.targetDate,
                    onChanged: cubit.targetDateChanged,
                    errorText: state.targetDateInvalid
                        ? l10n.savingsInvalidTargetDateError
                        : null,
                  ),
                },
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  key: const ValueKey('savingsWhatIfCalculate'),
                  label: l10n.savingsWhatIfCalculateAction,
                  icon: Icons.calculate_outlined,
                  isLoading: state.isCalculating,
                  onPressed: state.isApplying ? null : cubit.calculate,
                ),
                if (state.result != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  WhatIfResultCard(
                    key: const ValueKey('savingsWhatIfResult'),
                    goal: detail.goal,
                    progress: detail.progress,
                    result: state.result!,
                    mode: state.resultMode ?? state.mode,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                // FR-015: always visible, so it is never unclear whether
                // exploring saved anything.
                Text(
                  l10n.savingsWhatIfPreviewNotice,
                  key: const ValueKey('savingsWhatIfPreviewNotice'),
                  style: AppTypography.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        key: const ValueKey('savingsWhatIfCancel'),
                        label: l10n.savingsWhatIfCancelAction,
                        onPressed: state.isApplying
                            ? null
                            : () => context.pop(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('savingsWhatIfApply'),
                        label: l10n.savingsWhatIfApplyAction,
                        icon: Icons.check,
                        isLoading: state.isApplying,
                        onPressed: state.canApply ? cubit.apply : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// The goal's real plan, the baseline every what-if is compared against.
class _CurrentPlan extends StatelessWidget {
  const _CurrentPlan({required this.detail});

  final SavingsGoalDetail detail;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final goal = detail.goal;
    final monthly = goal.monthlyContribution;
    final targetDate = goal.targetDate;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final mutedStyle = AppTypography.bodyMuted.copyWith(color: muted);

    return AppCard(
      key: const ValueKey('savingsWhatIfCurrentPlan'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.savingsWhatIfCurrentPlanTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.savingsWhatIfCurrentRemaining(
              format.money(detail.progress.remainingAmount),
            ),
            style: AppTypography.body,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            monthly == null
                ? l10n.savingsWhatIfCurrentNoMonthly
                : l10n.savingsWhatIfCurrentMonthly(format.money(monthly)),
            style: mutedStyle,
          ),
          if (targetDate != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.savingsWhatIfCurrentTargetDate(format.date(targetDate)),
              style: mutedStyle,
            ),
          ],
        ],
      ),
    );
  }
}

/// The hypothetical target date: tap to pick, from tomorrow on (FR-016).
class _TargetDateField extends StatelessWidget {
  const _TargetDateField({
    required this.date,
    required this.onChanged,
    this.errorText,
  });

  final DateTime? date;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final format = SavingsFormat.of(context);
    final l10n = format.l10n;
    final value = date;
    return InkWell(
      key: const ValueKey('savingsWhatIfTargetDateField'),
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
          labelText: l10n.savingsWhatIfTargetDateLabel,
          errorText: errorText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          suffixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(
          value == null
              ? l10n.savingsWhatIfTargetDateNotSet
              : format.date(value),
        ),
      ),
    );
  }
}
