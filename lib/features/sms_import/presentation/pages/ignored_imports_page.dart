import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../cubit/ignored_imports_cubit.dart';
import '../widgets/bidi_text.dart';
import '../widgets/sms_import_labels.dart';

/// Ignored items (T133, ui-contract §3.8): the ignored and expired items
/// of the last 30 days with Undo. Only the six kept fields are shown,
/// never the message. After Undo the item comes back only when the user
/// taps Scan now, or pastes or shares the message again (FR-068); without
/// bank-message scanning the Scan clause is left out.
class IgnoredImportsPage extends StatelessWidget {
  const IgnoredImportsPage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final IgnoredImportsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<IgnoredImportsCubit>())..open(),
      child: const _IgnoredImportsView(),
    );
  }
}

class _IgnoredImportsView extends StatelessWidget {
  const _IgnoredImportsView();

  void _onResult(BuildContext context, IgnoredImportsState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<IgnoredImportsCubit>();
    final String message;
    if (state.restored) {
      cubit.consumeRestored();
      message = state.scanAvailable
          ? l10n.smsImportIgnoredRestored
          : l10n.smsImportIgnoredRestoredPasteOnly;
    } else if (state.undoFailure case final failure?) {
      cubit.consumeUndoFailure();
      message = l10n.messageFor(failure);
    } else {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportIgnoredTitle)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocConsumer<IgnoredImportsCubit, IgnoredImportsState>(
          listenWhen: (p, c) =>
              (c.restored && !p.restored) ||
              (c.undoFailure != null && p.undoFailure != c.undoFailure),
          listener: _onResult,
          builder: (context, state) {
            final cubit = context.read<IgnoredImportsCubit>();
            return switch (state.status) {
              IgnoredImportsStatus.initial ||
              IgnoredImportsStatus.loading => const _Skeleton(),
              IgnoredImportsStatus.error => AppEmptyView(
                title: l10n.smsImportIgnoredLoadError,
                message: l10n.messageFor(state.failure),
                icon: Icons.error_outline,
                actionLabel: l10n.smsImportPendingRetry,
                onAction: cubit.retry,
              ),
              IgnoredImportsStatus.empty => AppEmptyView(
                title: l10n.smsImportIgnoredEmptyTitle,
                message: l10n.smsImportIgnoredEmptyMessage,
                icon: Icons.visibility_off_outlined,
              ),
              IgnoredImportsStatus.ready => ListView(
                key: const ValueKey('ignored_imports_list'),
                padding:
                    const EdgeInsets.all(AppSpacing.md) +
                    AppGlassInsets.of(context),
                children: [
                  Text(l10n.smsImportIgnoredHelp, style: AppTypography.body),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    state.scanAvailable
                        ? l10n.smsImportIgnoredComesBack
                        : l10n.smsImportIgnoredComesBackPasteOnly,
                    key: const ValueKey('ignored_imports_comes_back'),
                    style: AppTypography.bodyMuted,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  for (final item in state.items)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                        bottom: AppSpacing.sm,
                      ),
                      child: _IgnoredRow(
                        item: item,
                        daysLeft: state.daysLeft(item),
                        undoing: state.undoingId == item.id,
                        enabled: state.undoingId == null,
                        onUndo: () => cubit.undo(item.id),
                      ),
                    ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

/// One ignored or expired item: status, days left, amount, merchant,
/// date, bank and Undo.
class _IgnoredRow extends StatelessWidget {
  _IgnoredRow({
    required this.item,
    required this.daysLeft,
    required this.undoing,
    required this.enabled,
    required this.onUndo,
  }) : super(key: ValueKey('ignored_import_${item.id}'));

  final PendingSmsImport item;
  final int? daysLeft;
  final bool undoing;
  final bool enabled;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final statusText = item.status == SmsImportStatus.expired
        ? l10n.smsImportIgnoredStatusExpired
        : l10n.smsImportIgnoredStatusIgnored;
    final amount = item.amount;
    final amountText = amount == null
        ? l10n.smsImportIgnoredNoAmount
        : SmsImportLabels.money(context, amount);
    final name = item.merchant ?? item.counterparty;
    final occurredOn = item.occurredOn;
    final dateText = occurredOn == null
        ? null
        : SmsImportLabels.date(context, occurredOn);
    final bank = SmsImportLabels.bank(l10n, item.bankId);
    final left = daysLeft;
    final leftText = left == null ? null : l10n.smsImportIgnoredDaysLeft(left);
    final summary = [
      statusText,
      amountText,
      if (name != null) BidiIsolate.auto(name),
      ?dateText,
      bank,
      ?leftText,
    ].join(l10n.smsImportReviewListSeparator);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The item reads as one node; Undo stays a separate button.
          Semantics(
            container: true,
            label: summary,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.status == SmsImportStatus.expired
                              ? Icons.history_toggle_off
                              : Icons.visibility_off_outlined,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(statusText, style: AppTypography.label),
                      ],
                    ),
                    if (leftText != null)
                      Text(leftText, style: AppTypography.bodyMuted),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  amountText,
                  style: amount == null
                      ? AppTypography.body.copyWith(
                          color: scheme.onSurfaceVariant,
                        )
                      : AppTypography.figure,
                ),
                if (name != null)
                  BidiText.auto(name, style: AppTypography.body, maxLines: 2),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    if (dateText != null)
                      Text(dateText, style: AppTypography.bodyMuted),
                    Text(bank, style: AppTypography.bodyMuted),
                  ],
                ),
              ],
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              key: ValueKey('ignored_import_undo_${item.id}'),
              style: TextButton.styleFrom(
                minimumSize: const Size(
                  AppSizes.minTouchTarget,
                  AppSizes.minTouchTarget,
                ),
              ),
              onPressed: enabled ? onUndo : null,
              icon: undoing
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.undo),
              label: Text(l10n.smsImportIgnoredUndo),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton rows while loading; no spinner-only screen.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: ListView(
        key: const ValueKey('ignored_imports_skeleton'),
        padding:
            const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
