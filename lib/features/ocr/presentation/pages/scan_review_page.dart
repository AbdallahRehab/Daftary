import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../cubit/scan_review_cubit.dart';
import '../cubit/scan_review_state.dart';
import '../widgets/candidate_entry_card.dart';
import '../widgets/occasion_tag_picker.dart';

/// The review screen: the only path by which a scan's candidate entries can
/// become real transactions (constitution Principle X, FR-007).
///
/// Nothing on this page saves on its own. The confirm action is disabled
/// while any remaining entry is incomplete and from the instant it is
/// tapped, and backing out with corrections in hand asks first (FR-011,
/// FR-015, FR-021).
class ScanReviewPage extends StatelessWidget {
  const ScanReviewPage({required this.scanId, super.key});

  final String scanId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanReviewCubit>()..load(scanId),
      child: _ScanReviewView(scanId: scanId),
    );
  }
}

class _ScanReviewView extends StatelessWidget {
  const _ScanReviewView({required this.scanId});

  final String scanId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ScanReviewCubit>();

    return BlocConsumer<ScanReviewCubit, ScanReviewState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.requiresCancelConfirmation !=
              current.requiresCancelConfirmation,
      listener: (context, state) async {
        if (state.requiresCancelConfirmation) {
          await _promptBeforeDiscardingCorrections(context, cubit);
          return;
        }
        if (state.status == ScanReviewStatus.success) {
          // The batch is saved; the summary of what it created is the
          // honest destination, not a silent return to the camera.
          context.go('/ocr/history/$scanId');
          return;
        }
        if (state.status == ScanReviewStatus.cancelled) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/');
          }
        }
      },
      builder: (context, state) {
        return PopScope(
          // Backing out is a cancellation like any other, so it goes
          // through the same prompt rather than quietly abandoning
          // corrections (FR-015).
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.cancel();
          },
          child: AppScaffold(
            appBar: AppTopBar(
              title: Text(l10n.ocrReviewTitle),
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.ocrReviewCancelAction,
                onPressed: state.isSubmitting ? null : cubit.cancel,
              ),
            ),
            // Only the side insets: the scaffold already keeps the body
            // clear of the bars with glass OFF, and under glass the list
            // below scrolls beneath them with their insets as padding.
            body: SafeArea(
              top: false,
              bottom: false,
              child: _Body(state: state, cubit: cubit),
            ),
            bottomNavigationBar: _ConfirmBar(state: state, cubit: cubit),
          ),
        );
      },
    );
  }

  static Future<void> _promptBeforeDiscardingCorrections(
    BuildContext context,
    ScanReviewCubit cubit,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.ocrReviewCancelPromptTitle,
      message: l10n.ocrReviewCancelPromptMessage,
      confirmLabel: l10n.ocrReviewCancelPromptConfirm,
      cancelLabel: l10n.ocrReviewCancelPromptKeep,
      isDestructive: true,
    );
    if (confirmed) {
      await cubit.confirmCancel();
    } else {
      cubit.dismissCancelConfirmation();
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.cubit});

  final ScanReviewState state;
  final ScanReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (state.status) {
      case ScanReviewStatus.initial:
      case ScanReviewStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case ScanReviewStatus.loadFailure:
        return AppEmptyView(
          icon: Icons.error_outline,
          title: l10n.ocrReviewLoadErrorTitle,
          message: l10n.ocrReviewLoadErrorMessage,
          actionLabel: l10n.ocrReviewRetryAction,
          onAction: () => cubit.load(state.scanId),
        );
      case ScanReviewStatus.ready:
      case ScanReviewStatus.submitting:
      case ScanReviewStatus.success:
      case ScanReviewStatus.cancelled:
        break;
    }

    final scan = state.scan;
    if (scan == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final entries = state.orderedEntries;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        _BatchControls(state: state, cubit: cubit),
        if (state.failure != null) ...[
          const SizedBox(height: AppSpacing.md),
          _FailureBanner(
            message: state.validationFailureEntryIds.isEmpty
                ? l10n.ocrReviewSaveErrorMessage
                : l10n.ocrReviewIncompleteBatchMessage,
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (entries.isEmpty)
          AppEmptyView(
            icon: Icons.inbox_outlined,
            title: l10n.ocrReviewEmptyTitle,
            message: l10n.ocrReviewEmptyMessage,
          )
        else
          for (final entry in entries)
            Padding(
              key: ValueKey(entry.id),
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CandidateEntryCard(
                entry: entry,
                batchDefaultDirection: scan.defaultDirection,
                scanDate: scan.createdAt,
                duplicateMatches: state.duplicateMatches[entry.id] ?? const [],
                amountInvalid: state.invalidAmountEntryIds.contains(entry.id),
                highlightIncomplete: state.validationFailureEntryIds.contains(
                  entry.id,
                ),
                onPersonNameChanged: (name) =>
                    cubit.personNameChanged(entry.id, name),
                onPersonSelected: (person) =>
                    cubit.personSelected(entry.id, person),
                onDuplicatesDismissed: () =>
                    cubit.dismissDuplicateMatches(entry.id),
                onAmountChanged: (text) => cubit.amountChanged(entry.id, text),
                onDirectionChanged: (direction) =>
                    cubit.directionChanged(entry.id, direction),
                onDateChanged: (date) => cubit.dateChanged(entry.id, date),
                onNotesChanged: (notes) => cubit.notesChanged(entry.id, notes),
                onDiscard: () => cubit.discardEntry(entry.id),
              ),
            ),
      ],
    );
  }
}

/// The two choices that apply to the whole batch: the fallback direction
/// (FR-005) and the optional occasion tag (FR-014).
class _BatchControls extends StatelessWidget {
  const _BatchControls({required this.state, required this.cubit});

  final ScanReviewState state;
  final ScanReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final defaultDirection = state.scan?.defaultDirection;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.ocrReviewBatchSectionTitle, style: AppTypography.title),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.ocrReviewBatchSectionMessage,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.ocrReviewBatchDirectionLabel,
            style: AppTypography.label.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          SegmentedButton<TransactionDirection>(
            segments: [
              ButtonSegment(
                value: TransactionDirection.received,
                label: Text(l10n.ocrReviewDirectionReceived),
                icon: const Icon(Icons.south_west, size: 16),
              ),
              ButtonSegment(
                value: TransactionDirection.given,
                label: Text(l10n.ocrReviewDirectionGiven),
                icon: const Icon(Icons.north_east, size: 16),
              ),
            ],
            selected: defaultDirection == null ? const {} : {defaultDirection},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: (selection) {
              if (selection.isEmpty) return;
              cubit.setDefaultDirection(selection.first);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          OccasionTagPicker(
            selectedOccasionId: state.scan?.occasionId,
            onOccasionSelected: cubit.tagToOccasion,
          ),
        ],
      ),
    );
  }
}

class _FailureBanner extends StatelessWidget {
  const _FailureBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({required this.state, required this.cubit});

  final ScanReviewState state;
  final ScanReviewCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    if (state.status == ScanReviewStatus.loading ||
        state.status == ScanReviewStatus.loadFailure ||
        state.status == ScanReviewStatus.initial) {
      return const SizedBox.shrink();
    }

    // Opaque: under glass the body scrolls beneath this bar (padded clear
    // of it), and its buttons must never sit over the entries. With glass
    // OFF this is the scaffold's own background, so nothing changes.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!state.canConfirm && !state.isSubmitting)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Text(
                    state.activeEntries.isEmpty
                        ? l10n.ocrReviewNothingToConfirm
                        : l10n.ocrReviewConfirmBlockedHint,
                    style: AppTypography.bodyMuted.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              AppButton(
                label: l10n.ocrReviewConfirmAction,
                icon: Icons.check,
                isLoading: state.isSubmitting,
                // Null the moment anything is incomplete or a save is in
                // flight — the cubit refuses a second call too, but the
                // button should never look tappable while it would be
                // ignored (FR-021).
                onPressed: state.canConfirm ? cubit.confirm : null,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSecondaryButton(
                label: l10n.ocrReviewCancelAction,
                onPressed: state.isSubmitting ? null : cubit.cancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
