import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/archived_goals_cubit.dart';
import '../cubit/archived_goals_state.dart';
import '../cubit/savings_goal_actions_cubit.dart';
import '../savings_routes.dart';
import '../widgets/goal_overview_card.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_goal_actions.dart';

/// Archived goals, each with a restore action (FR-020). Mirrors
/// `ArchivedOccasionsPage`: archiving is "I've paused this", so this screen
/// is a shelf, not a bin — every goal here keeps its full history, opens to
/// its page, and can still have past entries corrected.
///
/// 021: live — an archive or restore made anywhere shows with no reload.
class ArchivedGoalsPage extends StatelessWidget {
  const ArchivedGoalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<ArchivedGoalsCubit>()..subscribe()),
        BlocProvider(create: (_) => getIt<SavingsGoalActionsCubit>()),
      ],
      child: const ArchivedGoalsView(),
    );
  }
}

/// The page body — public so widget tests can provide their own cubits.
class ArchivedGoalsView extends StatelessWidget {
  const ArchivedGoalsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ArchivedGoalsCubit>();

    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.savingsArchiveTitle)),
      body: BlocBuilder<ArchivedGoalsCubit, ArchivedGoalsState>(
        builder: (context, state) {
          if (state.isLoading && state.goals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.failure != null && state.goals.isEmpty) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.savingsOverviewLoadErrorTitle,
              message: savingsFailureMessage(
                l10n,
                state.failure ?? const UnknownFailure('Not loaded'),
              ),
              actionLabel: l10n.savingsRetryAction,
              onAction: cubit.resubscribe,
            );
          }
          if (state.isEmpty) {
            return AppEmptyView(
              icon: Icons.archive_outlined,
              title: l10n.savingsArchiveEmptyTitle,
              message: l10n.savingsArchiveEmptyMessage,
            );
          }
          return ListView.separated(
            padding:
                AppGlassInsets.of(context) +
                const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
            itemCount: state.goals.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final line = state.goals[index];
              return GoalOverviewCard(
                key: ValueKey(line.goal.id),
                line: line,
                onTap: () => context.push(SavingsRoutes.goal(line.goal.id)),
                trailing: SavingsGoalMenuButton(goal: line.goal),
                footer: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _RestoreButton(
                    line.goal.id,
                    onPressed: () {
                      restoreSavingsGoalFlow(context, line.goal);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _RestoreButton extends StatelessWidget {
  const _RestoreButton(this.goalId, {required this.onPressed});

  final String goalId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final busy = context.select<SavingsGoalActionsCubit, bool>(
      (cubit) => cubit.state.isProcessing(goalId),
    );
    return TextButton.icon(
      key: ValueKey('savingsRestore-$goalId'),
      onPressed: busy ? null : onPressed,
      icon: const Icon(Icons.unarchive_outlined),
      label: Text(AppLocalizations.of(context)!.savingsArchiveRestoreAction),
    );
  }
}
