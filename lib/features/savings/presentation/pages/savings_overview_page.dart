import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_fab.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/presentation/widgets/balance_amount_text.dart'
    show openExchangeRateSettings;
import '../cubit/savings_goal_actions_cubit.dart';
import '../cubit/savings_overview_cubit.dart';
import '../cubit/savings_overview_state.dart';
import '../savings_routes.dart';
import '../widgets/goal_overview_card.dart';
import '../widgets/savings_failure_message.dart';
import '../widgets/savings_goal_actions.dart';
import '../widgets/savings_overview_summary_card.dart';

/// The savings section's home (US4): every active goal with its progress in
/// its own currency, the combined total in the primary currency — marked
/// incomplete, naming the missing rates, when a goal cannot be converted
/// (FR-019) — and FR-023's empty state for a first-time user. Each goal's
/// menu archives or deletes it (FR-020/FR-021).
///
/// 021: live — a goal created, an entry logged or a rate set (here or via
/// sync) shows with no reload.
class SavingsOverviewPage extends StatelessWidget {
  const SavingsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SavingsOverviewCubit>()..subscribe()),
        BlocProvider(create: (_) => getIt<SavingsGoalActionsCubit>()),
      ],
      child: const SavingsOverviewView(),
    );
  }
}

/// The page body, reading a [SavingsOverviewCubit] and a
/// [SavingsGoalActionsCubit] from above — public so widget tests can drive
/// it with their own cubits.
class SavingsOverviewView extends StatelessWidget {
  const SavingsOverviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<SavingsOverviewCubit>();

    return BlocBuilder<SavingsOverviewCubit, SavingsOverviewState>(
      builder: (context, state) {
        final overview = state.overview;
        return AppScaffold(
          appBar: AppTopBar(
            title: Text(l10n.savingsOverviewTitle),
            actions: [
              IconButton(
                key: const ValueKey('savingsOverviewArchived'),
                tooltip: l10n.savingsOverviewArchivedAction,
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => context.push(SavingsRoutes.archived),
              ),
            ],
          ),
          // The empty state carries its own create action; a second one
          // floating over it would only compete with it.
          floatingActionButton: overview == null || state.isEmpty
              ? null
              : AppFab.extended(
                  onPressed: () => context.push(SavingsRoutes.newGoal),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.savingsOverviewNewGoalAction),
                ),
          body: Builder(
            builder: (context) {
              if (overview == null) {
                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
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
                  icon: Icons.savings_outlined,
                  title: l10n.savingsOverviewEmptyTitle,
                  message: l10n.savingsOverviewEmptyMessage,
                  actionLabel: l10n.savingsOverviewEmptyAction,
                  onAction: () => context.push(SavingsRoutes.newGoal),
                );
              }
              return RefreshIndicator(
                onRefresh: cubit.resubscribe,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      // Under glass the body runs behind the bars; the
                      // bottom clears the FAB so the last goal is reachable.
                      padding:
                          AppGlassInsets.of(context) +
                          const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            88,
                          ),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SavingsOverviewSummaryCard(
                              overview: overview,
                              onSetRate: () =>
                                  openExchangeRateSettings(context),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                top: AppSpacing.lg,
                                bottom: AppSpacing.sm,
                              ),
                              child: Text(
                                l10n.savingsOverviewGoalsHeader,
                                style: AppTypography.title,
                              ),
                            ),
                          ),
                          // Lazy: only the goals on screen are built.
                          SliverList.separated(
                            itemCount: overview.goals.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final line = overview.goals[index];
                              return GoalOverviewCard(
                                key: ValueKey(line.goal.id),
                                line: line,
                                onTap: () => context.push(
                                  SavingsRoutes.goal(line.goal.id),
                                ),
                                trailing: SavingsGoalMenuButton(
                                  goal: line.goal,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
