import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../domain/entities/sync_conflict_item.dart';
import '../cubit/sync_conflicts_cubit.dart';
import '../cubit/sync_conflicts_state.dart';

/// 021 T074: the two versions of a record in conflict, side by side
/// (mirrored in RTL), with "Keep mine" and "Keep theirs"
/// (contracts/dart-interfaces.md §5). The version not kept is never lost:
/// it is recorded as the discarded side of the resolution.
class ConflictResolutionSheet extends StatelessWidget {
  const ConflictResolutionSheet({required this.item, super.key});

  static const keepMineKey = Key('conflict_keep_mine');
  static const keepTheirsKey = Key('conflict_keep_theirs');

  final SyncConflictItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: BlocConsumer<SyncConflictsCubit, SyncConflictsState>(
          listenWhen: (previous, current) =>
              current.resolveFailure != null &&
              previous.resolveFailure != current.resolveFailure,
          listener: (context, state) =>
              ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                SnackBar(content: Text(l10n.syncConflictResolveFailed)),
              ),
          builder: (context, state) {
            final busy = state.isResolving(item);
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.syncConflictSheetTitle, style: AppTypography.title),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.syncConflictSheetMessage,
                  style: AppTypography.bodyMuted.copyWith(color: muted),
                ),
                const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _VersionCard(
                          title: l10n.syncConflictMineLabel,
                          version: item.localSummary,
                          showGoalAmount: item.showsGoalAmount,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _VersionCard(
                          title: l10n.syncConflictTheirsLabel,
                          version: item.serverSummary,
                          showGoalAmount: item.showsGoalAmount,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  key: keepMineKey,
                  label: l10n.syncConflictKeepMine,
                  isLoading: busy,
                  onPressed: () => _resolve(context, ConflictChoice.keepMine),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppSecondaryButton(
                  key: keepTheirsKey,
                  label: l10n.syncConflictKeepTheirs,
                  onPressed: busy
                      ? null
                      : () => _resolve(context, ConflictChoice.keepTheirs),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, ConflictChoice choice) async {
    final navigator = Navigator.of(context);
    final resolved = await context.read<SyncConflictsCubit>().resolve(
      item,
      choice,
    );
    if (resolved && navigator.mounted) navigator.pop();
  }
}

class _VersionCard extends StatelessWidget {
  const _VersionCard({
    required this.title,
    required this.version,
    required this.showGoalAmount,
  });

  final String title;
  final ConflictVersion version;
  final bool showGoalAmount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final direction = switch (version.direction) {
      ConflictDirection.given => l10n.directionGiven,
      ConflictDirection.received => l10n.directionReceived,
      ConflictDirection.expense => l10n.financeTypeExpense,
      ConflictDirection.income => l10n.financeTypeIncome,
      ConflictDirection.contribution => l10n.conflictDirectionContribution,
      ConflictDirection.withdrawal => l10n.conflictDirectionWithdrawal,
    };
    final amount = EgpFormatter(
      locale: locale,
    ).formatWithSymbol(version.amount);
    final day = AppDateFormatter(locale: locale).format(version.date);
    final goalAmount = version.goalAmount;
    final goalLine = showGoalAmount && goalAmount != null
        ? l10n.conflictGoalAmount(
            EgpFormatter(locale: locale).formatWithSymbol(goalAmount),
          )
        : null;
    final note = version.note;
    // One announcement per version: whose it is, then its fields.
    final spoken = [
      title,
      amount,
      direction,
      day,
      ?goalLine,
      if (note != null && note.isNotEmpty) note,
      if (version.isDeleted) l10n.syncConflictDeletedLabel,
    ].join(', ');
    return Semantics(
      container: true,
      label: spoken,
      child: ExcludeSemantics(
        child: AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.label.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(amount, style: AppTypography.figure),
              ),
              if (goalLine != null) Text(goalLine, style: AppTypography.body),
              Text(direction, style: AppTypography.body),
              Text(
                day,
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (note != null && note.isNotEmpty)
                Text(note, style: AppTypography.body),
              if (version.isDeleted)
                Text(
                  l10n.syncConflictDeletedLabel,
                  style: AppTypography.label.copyWith(color: colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the sheet for [item], resolved through the page's
/// [SyncConflictsCubit].
Future<void> showConflictResolutionSheet(
  BuildContext context,
  SyncConflictItem item,
) {
  final cubit = context.read<SyncConflictsCubit>();
  return showAppModalSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: ConflictResolutionSheet(item: item),
    ),
  );
}
