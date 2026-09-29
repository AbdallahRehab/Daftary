import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/savings_goal.dart';
import '../cubit/savings_goal_actions_cubit.dart';
import '../cubit/savings_goal_actions_state.dart';
import 'savings_failure_message.dart';

/// The archive, restore and delete flows (FR-020/FR-021) as the user sees
/// them — confirmations, the "archive instead" offer and the snackbars —
/// shared by the overview, the archived list and the goal page. Each reads
/// the [SavingsGoalActionsCubit] provided above [context].

/// Archives [goal], offering an undo.
Future<void> archiveSavingsGoalFlow(
  BuildContext context,
  SavingsGoal goal,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<SavingsGoalActionsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await cubit.archive(goal.id);
  _report(
    messenger,
    l10n,
    result,
    done: l10n.savingsArchiveDoneMessage,
    undo: () => cubit.restore(goal.id),
  );
}

/// Restores an archived [goal].
Future<void> restoreSavingsGoalFlow(
  BuildContext context,
  SavingsGoal goal,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<SavingsGoalActionsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final result = await cubit.restore(goal.id);
  _report(messenger, l10n, result, done: l10n.savingsArchiveRestoredMessage);
}

/// Confirms, then deletes [goal]. FR-021: a goal with history is not
/// deleted — the user is told why and offered to archive it instead.
Future<void> deleteSavingsGoalFlow(
  BuildContext context,
  SavingsGoal goal,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cubit = context.read<SavingsGoalActionsCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showAppConfirmDialog(
    context,
    title: l10n.savingsDeleteConfirmTitle(goal.name),
    message: l10n.savingsDeleteConfirmMessage,
    confirmLabel: l10n.savingsDeleteAction,
    isDestructive: true,
  );
  if (!confirmed) return;
  final result = await cubit.delete(goal.id);
  if (result.status != GoalActionStatus.hasHistory) {
    _report(messenger, l10n, result, done: l10n.savingsDeleteDoneMessage);
    return;
  }
  if (!context.mounted) return;
  final archiveInstead = await showAppConfirmDialog(
    context,
    title: l10n.savingsDeleteBlockedTitle,
    message: l10n.savingsDeleteBlockedMessage,
    confirmLabel: l10n.savingsDeleteBlockedArchiveAction,
  );
  if (!archiveInstead || !context.mounted) return;
  await archiveSavingsGoalFlow(context, goal);
}

void _report(
  ScaffoldMessengerState messenger,
  AppLocalizations l10n,
  GoalActionResult result, {
  required String done,
  VoidCallback? undo,
}) {
  if (result.status == GoalActionStatus.ignored) return;
  final succeeded = result.status == GoalActionStatus.done;
  final message = succeeded
      ? done
      : savingsFailureMessage(l10n, result.failure!);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        action: !succeeded || undo == null
            ? null
            : SnackBarAction(
                label: l10n.savingsArchiveUndoAction,
                onPressed: undo,
              ),
      ),
    );
}

enum _GoalMenuAction { archive, restore, delete }

/// A goal's options menu: archive (or restore, when archived) and delete.
///
/// Reads the [SavingsGoalActionsCubit] only when an option is chosen; a
/// repeated choice while one is in flight is ignored by the cubit.
class SavingsGoalMenuButton extends StatelessWidget {
  const SavingsGoalMenuButton({required this.goal, super.key});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopupMenuButton<_GoalMenuAction>(
      key: ValueKey('savingsGoalMenu-${goal.id}'),
      tooltip: l10n.savingsOverviewGoalActionsTooltip,
      icon: const Icon(Icons.more_vert),
      onSelected: (action) => switch (action) {
        _GoalMenuAction.archive => archiveSavingsGoalFlow(context, goal),
        _GoalMenuAction.restore => restoreSavingsGoalFlow(context, goal),
        _GoalMenuAction.delete => deleteSavingsGoalFlow(context, goal),
      },
      itemBuilder: (context) => [
        if (goal.isArchived)
          PopupMenuItem(
            value: _GoalMenuAction.restore,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.unarchive_outlined),
              title: Text(l10n.savingsArchiveRestoreAction),
            ),
          )
        else
          PopupMenuItem(
            value: _GoalMenuAction.archive,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n.savingsArchiveAction),
            ),
          ),
        PopupMenuItem(
          value: _GoalMenuAction.delete,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: Text(l10n.savingsDeleteAction),
          ),
        ),
      ],
    );
  }
}
