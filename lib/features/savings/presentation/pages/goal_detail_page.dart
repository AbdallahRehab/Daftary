import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/savings_contribution.dart';
import '../../domain/entities/savings_goal_detail.dart';
import '../cubit/goal_detail_cubit.dart';
import '../cubit/goal_detail_state.dart';
import '../cubit/savings_goal_actions_cubit.dart';
import '../savings_routes.dart';
import '../widgets/contribution_list_tile.dart';
import '../widgets/goal_progress_card.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_format.dart';
import '../widgets/savings_goal_actions.dart';

/// One goal in full (FR-004/FR-008/FR-010-FR-012/FR-017): its progress
/// card, the actions to add or withdraw money (hidden, with an explanation,
/// while archived — FR-020), and its full history with per-entry edit and
/// delete (FR-009).
///
/// 021: live — an entry saved on its form, or a change applied by sync,
/// reaches the open page with no reload. Also the 017 deep-link target.
class GoalDetailPage extends StatelessWidget {
  const GoalDetailPage({required this.goalId, super.key});

  final String goalId;

  @override
  Widget build(BuildContext context) {
    // Keyed by goal: when the router reuses this page for another goal
    // (e.g. a 017 notification tap while a goal is open), the cubits are
    // created afresh instead of staying on the previous goal.
    return KeyedSubtree(
      key: ValueKey(goalId),
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => getIt<GoalDetailCubit>()..subscribe(goalId),
          ),
          BlocProvider(create: (_) => getIt<SavingsGoalActionsCubit>()),
        ],
        child: const GoalDetailView(),
      ),
    );
  }
}

/// The page body, reading a [GoalDetailCubit] from above — public so widget
/// tests can drive it with their own cubit.
class GoalDetailView extends StatelessWidget {
  const GoalDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocConsumer<GoalDetailCubit, GoalDetailState>(
      listenWhen: (previous, current) =>
          previous.isDeleted != current.isDeleted ||
          (current.failure != null && previous.failure != current.failure),
      listener: (context, state) {
        if (state.isDeleted) {
          if (ModalRoute.of(context)?.isCurrent ?? true) context.pop(true);
          return;
        }
        // A failed action on a loaded goal (e.g. a delete that would leave
        // the balance negative) — explained once, then cleared.
        final failure = state.failure;
        if (failure != null && state.detail != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(savingsFailureMessage(l10n, failure))),
          );
          context.read<GoalDetailCubit>().failureShown();
        }
      },
      builder: (context, state) {
        final cubit = context.read<GoalDetailCubit>();
        final detail = state.detail;

        if (detail == null) {
          if (state.isLoading) {
            return const AppScaffold(
              appBar: AppTopBar(),
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return AppScaffold(
            appBar: const AppTopBar(),
            body: AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.savingsGoalLoadErrorTitle,
              message: savingsFailureMessage(
                l10n,
                state.failure ?? const UnknownFailure('Goal not loaded'),
              ),
              actionLabel: l10n.savingsRetryAction,
              onAction: cubit.resubscribe,
            ),
          );
        }

        final goal = detail.goal;
        return AppScaffold(
          appBar: AppTopBar(
            title: Text(goal.name),
            actions: [
              IconButton(
                tooltip: l10n.savingsGoalEditAction,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(SavingsRoutes.editGoal(goal.id)),
              ),
              // Archive/restore and delete (FR-020/FR-021). A delete that
              // succeeds closes the page through the live subscription.
              SavingsGoalMenuButton(goal: goal),
            ],
          ),
          // Builder: the glass insets are read below the scaffold, where
          // they include the bars the body extends behind.
          body: Builder(
            builder: (context) => CustomScrollView(
              slivers: [
                SliverPadding(
                  padding:
                      AppGlassInsets.of(context) +
                      const EdgeInsets.only(bottom: AppSpacing.xxl),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(child: _Header(detail: detail)),
                      if (detail.history.isEmpty)
                        SliverToBoxAdapter(
                          child: AppEmptyView(
                            icon: Icons.savings_outlined,
                            title: l10n.savingsGoalHistoryEmptyTitle,
                            message: l10n.savingsGoalHistoryEmptyMessage,
                          ),
                        )
                      else
                        // Lazy: a goal with hundreds of entries builds only
                        // the rows on screen.
                        SliverList.builder(
                          itemCount: detail.history.length,
                          itemBuilder: (context, index) {
                            final entry = detail.history[index];
                            return ContributionListTile(
                              key: ValueKey(entry.id),
                              entry: entry,
                              goalCurrency: goal.currency,
                              onAction: (action) =>
                                  _onEntryAction(context, entry, action),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onEntryAction(
    BuildContext context,
    SavingsContribution entry,
    ContributionTileAction action,
  ) async {
    switch (action) {
      case ContributionTileAction.edit:
        await context.push(SavingsRoutes.editEntry(entry.goalId, entry.id));
      case ContributionTileAction.delete:
        final l10n = AppLocalizations.of(context)!;
        final cubit = context.read<GoalDetailCubit>();
        final confirmed = await showAppConfirmDialog(
          context,
          title: l10n.savingsEntryDeleteConfirmTitle,
          message: l10n.savingsEntryDeleteConfirmMessage,
          confirmLabel: l10n.savingsEntryDeleteAction,
          isDestructive: true,
        );
        if (confirmed) await cubit.deleteEntry(entry.id);
    }
  }
}

/// Everything above the history: type, progress, the add/withdraw actions
/// (or the archived explanation), and the history heading.
class _Header extends StatelessWidget {
  const _Header({required this.detail});

  final SavingsGoalDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final goal = detail.goal;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (goal.type != null) ...[
            Row(
              children: [
                Icon(savingsGoalTypeIcon(goal.type), color: muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    savingsGoalTypeLabel(l10n, goal.type),
                    style: AppTypography.bodyMuted.copyWith(color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          GoalProgressCard(goal: goal, progress: detail.progress),
          const SizedBox(height: AppSpacing.md),
          if (goal.isArchived)
            Row(
              key: const ValueKey('savingsArchivedNotice'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.archive_outlined, color: muted),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.savingsGoalArchivedNotice,
                    style: AppTypography.body,
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    key: const ValueKey('savingsLogContribution'),
                    label: l10n.savingsLogContributionAction,
                    icon: Icons.add,
                    onPressed: () => context.push(SavingsRoutes.log(goal.id)),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppSecondaryButton(
                    key: const ValueKey('savingsLogWithdrawal'),
                    label: l10n.savingsLogWithdrawalAction,
                    onPressed: () => context.push(
                      SavingsRoutes.log(goal.id, withdrawal: true),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // FR-013/FR-014. Offered for an achieved goal too: the
            // calculator itself explains there is nothing left to plan
            // (FR-016), rather than the entry point silently vanishing.
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                key: const ValueKey('savingsWhatIfEntry'),
                icon: const Icon(Icons.calculate_outlined),
                label: Text(l10n.savingsWhatIfAction),
                onPressed: () => context.push(SavingsRoutes.whatIf(goal.id)),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text(l10n.savingsGoalHistoryHeader, style: AppTypography.title),
        ],
      ),
    );
  }
}
