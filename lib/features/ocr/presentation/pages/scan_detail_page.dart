import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';
import '../../../transactions/domain/entities/money_transaction.dart';
import '../../../transactions/presentation/widgets/transaction_list_tile.dart';
import '../../domain/entities/candidate_entry.dart';
import '../../domain/entities/ocr_scan_detail.dart';
import '../cubit/scan_detail_cubit.dart';
import '../cubit/scan_detail_state.dart';
import '../widgets/scan_history_tile.dart';

/// One past scan in full (FR-018, User Story 5 AC2): the original image,
/// the candidate entries as they ended up, and every transaction the scan
/// produced — each linking through to its person's detail screen (001), so
/// an OCR-sourced amount is never a dead end.
///
/// 021: live — a produced transaction edited or deleted from its person's
/// screen, or through sync, updates the page with no reload (FR-031).
class ScanDetailPage extends StatelessWidget {
  const ScanDetailPage({required this.scanId, super.key});

  final String scanId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanDetailCubit>()..subscribe(scanId),
      child: const _ScanDetailView(),
    );
  }
}

class _ScanDetailView extends StatelessWidget {
  const _ScanDetailView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ScanDetailCubit>();

    return BlocListener<ScanDetailCubit, ScanDetailState>(
      listenWhen: (previous, current) =>
          current.isDeleted && !previous.isDeleted,
      listener: (context, state) {
        // The record this page exists to show is gone, so the page goes
        // with it rather than re-rendering an empty shell.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.ocrScanDetailDeletedMessage)),
        );
        if (context.canPop()) context.pop();
      },
      child: AppScaffold(
        appBar: AppTopBar(
          title: Text(l10n.ocrScanDetailTitle),
          actions: [
            BlocBuilder<ScanDetailCubit, ScanDetailState>(
              builder: (context, state) {
                final detail = state.detail;
                if (detail == null) return const SizedBox.shrink();
                return IconButton(
                  tooltip: l10n.ocrScanDetailDeleteAction,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, cubit, detail),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<ScanDetailCubit, ScanDetailState>(
          builder: (context, state) {
            final detail = state.detail;
            if (state.isLoading && detail == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (detail == null) {
              return AppEmptyView(
                icon: Icons.error_outline,
                title: l10n.ocrScanDetailErrorTitle,
                message:
                    state.failure?.message ?? l10n.ocrScanDetailErrorMessage,
              );
            }
            return _DetailBody(detail: detail);
          },
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScanDetailCubit cubit,
    OcrScanDetail detail,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.ocrScanDetailDeleteTitle,
      // Deliberately states the count of surviving transactions rather
      // than a vague "this cannot be undone". Deleting a scan removes the
      // photo and the audit trail and *nothing else* — the money stays
      // (data-model.md Relationships, FR-023). A user who misreads this
      // dialog either avoids a safe action forever or takes it expecting
      // their records to vanish; neither is acceptable, so the dialog
      // names the number.
      message: l10n.ocrScanDetailDeleteMessage(detail.transactions.length),
      confirmLabel: l10n.ocrScanDetailDeleteConfirm,
      isDestructive: true,
    );
    if (!confirmed) return;
    await cubit.delete();
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final OcrScanDetail detail;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).languageCode;
    final dateLabel = AppDateFormatter(
      locale: locale,
    ).format(detail.scan.createdAt);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        _SourceImage(imagePath: detail.scan.sourceImagePath),
        const SizedBox(height: AppSpacing.md),
        Text(dateLabel, style: AppTypography.title),
        const SizedBox(height: AppSpacing.xs),
        Text(
          scanStatusLabel(l10n, detail.scan.status),
          style: AppTypography.bodyMuted.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        _SectionHeading(label: l10n.ocrScanDetailEntriesTitle),
        const SizedBox(height: AppSpacing.sm),
        if (detail.entries.isEmpty)
          Text(
            l10n.ocrScanDetailNoEntries,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final entry in detail.entries)
                  _CandidateEntryRow(
                    entry: entry,
                    currency: detail.scan.currency,
                  ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.lg),

        _SectionHeading(label: l10n.ocrScanDetailTransactionsTitle),
        const SizedBox(height: AppSpacing.sm),
        if (detail.transactions.isEmpty)
          // A scan that produced nothing is still a legitimate history
          // row; say so plainly instead of showing a blank section
          // (User Story 5, Acceptance Scenario 3).
          Text(
            l10n.ocrScanDetailNoTransactionsMessage,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          Text(
            l10n.ocrScanDetailTransactionsKeptNote,
            style: AppTypography.bodyMuted.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final transaction in detail.transactions)
                  TransactionListTile(
                    transaction: transaction,
                    // Straight to the person's detail screen (001), where
                    // this row sits in its full context alongside the
                    // running balance it feeds.
                    onTap: () =>
                        context.push('/people/${transaction.personId}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// The scan's original image, pinch/drag-zoomable so the reviewer can read
/// the paper itself rather than squint at a shrunk-to-fit copy.
class _SourceImage extends StatelessWidget {
  const _SourceImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        color: colorScheme.surfaceContainerHighest,
        constraints: const BoxConstraints(maxHeight: 360, minHeight: 180),
        width: double.infinity,
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(
            File(imagePath),
            fit: BoxFit.contain,
            // The image file can be gone (backup restore, OS purge) while
            // the scan row survives. That degrades this screen to "entries
            // and transactions only"; it must not crash it.
            errorBuilder: (context, error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: 40,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.ocrScanDetailImageMissing,
                    style: AppTypography.bodyMuted.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Text(label, style: AppTypography.title);
}

/// One candidate entry frozen in whatever state the review left it:
/// confirmed, discarded, or never acted on.
class _CandidateEntryRow extends StatelessWidget {
  const _CandidateEntryRow({required this.entry, required this.currency});

  final CandidateEntry entry;

  /// The scan's currency (018): every amount on the page is in it.
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final locale = Localizations.localeOf(context).languageCode;
    final amount = entry.amountMinorUnits;
    final amountLabel = amount == null
        ? l10n.ocrScanDetailNoAmount
        : EgpFormatter(
            locale: locale,
          ).formatWithSymbol(Money.fromMinorUnits(amount, currency));
    final directionLabel = switch (entry.direction) {
      TransactionDirection.given => l10n.directionGiven,
      TransactionDirection.received => l10n.directionReceived,
      null => null,
    };
    final statusLabel = switch (entry.status) {
      CandidateEntryStatus.pendingReview =>
        l10n.ocrScanDetailEntryStatusPending,
      CandidateEntryStatus.confirmed => l10n.ocrScanDetailEntryStatusConfirmed,
      CandidateEntryStatus.discarded => l10n.ocrScanDetailEntryStatusDiscarded,
    };
    final statusColor = switch (entry.status) {
      CandidateEntryStatus.confirmed => financeColors.positive,
      CandidateEntryStatus.discarded => colorScheme.onSurfaceVariant,
      CandidateEntryStatus.pendingReview => financeColors.warning,
    };
    final name = entry.personName.trim();

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      title: Text(
        name.isEmpty ? l10n.ocrScanDetailUnknownPerson : name,
        // A discarded row is struck through: it is part of the scan's
        // record but produced nothing, and it must not read as money.
        style: AppTypography.body.copyWith(
          decoration: entry.isDiscarded ? TextDecoration.lineThrough : null,
          color: entry.isDiscarded ? colorScheme.onSurfaceVariant : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              amountLabel,
              style: AppTypography.bodyMuted.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (directionLabel != null)
              Text(
                directionLabel,
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            Text(
              statusLabel,
              style: AppTypography.label.copyWith(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}
