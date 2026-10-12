import 'package:flutter/material.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/glass/app_modal_sheet.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sms_value_types.dart';
import 'sms_import_labels.dart';

/// The content-free scan summary (T120, FR-024, FR-097): plural count
/// lines, each a whole sentence authored per language (no fragments
/// joined), and a link to the in-memory Skipped list. No message text,
/// amount or merchant is ever shown.
class ScanSummaryView extends StatelessWidget {
  const ScanSummaryView({required this.summary, super.key});

  final ScanSummary summary;

  /// The lines, in reading order; zero counts other than "found" are left
  /// out to keep the summary short.
  static List<String> lines(AppLocalizations l10n, ScanSummary summary) => [
    if (summary.cancelled) l10n.smsImportScanCancelled,
    l10n.smsImportScanFound(summary.scanned),
    if (summary.ready > 0) l10n.smsImportScanReady(summary.ready),
    if (summary.needsReview > 0)
      l10n.smsImportScanNeedReview(summary.needsReview),
    if (summary.alreadyKnown > 0)
      l10n.smsImportScanAlreadyKnown(summary.alreadyKnown),
    if (summary.nonTransactional > 0)
      l10n.smsImportScanSkipped(summary.nonTransactional),
    if (summary.unreadable > 0)
      l10n.smsImportScanUnreadable(summary.unreadable),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final all = lines(l10n, summary);
    return Column(
      key: const ValueKey('sms_scan_summary'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, line) in all.indexed)
          Padding(
            padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
            child: Text(
              line,
              style: index == (summary.cancelled ? 1 : 0)
                  ? AppTypography.title
                  : AppTypography.body.copyWith(color: scheme.onSurface),
            ),
          ),
        if (summary.skipped.isNotEmpty)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              key: const ValueKey('sms_scan_show_skipped'),
              onPressed: () => showSkippedListSheet(context, summary.skipped),
              child: Text(l10n.smsImportScanShowSkipped),
            ),
          ),
      ],
    );
  }
}

/// The summary in a dismissible card, for the hub.
class ScanSummaryCard extends StatelessWidget {
  const ScanSummaryCard({
    required this.summary,
    required this.onDismiss,
    super.key,
  });

  final ScanSummary summary;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      container: true,
      liveRegion: true,
      child: AppCard(
        key: const ValueKey('sms_scan_summary_card'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ScanSummaryView(summary: summary)),
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: l10n.smsImportScanDismiss,
              onPressed: onDismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// The running scan: live "Processed N" and Cancel (FR-007). The list
/// below stays interactive.
class ScanProgressPanel extends StatelessWidget {
  const ScanProgressPanel({
    required this.processed,
    required this.onCancel,
    super.key,
  });

  final int processed;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = l10n.smsImportScanProgress(processed);
    return AppCard(
      key: const ValueKey('sms_scan_progress'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Indeterminate: the total is unknown while paging.
          LinearProgressIndicator(semanticsLabel: text),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(text, style: AppTypography.body),
                ),
              ),
              TextButton(
                key: const ValueKey('sms_scan_cancel'),
                onPressed: onCancel,
                child: Text(l10n.smsImportScanCancel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The Skipped list of the current scan (CHK003): bank, date and reason
/// only, never text. Held in memory by the caller; never persisted.
Future<void> showSkippedListSheet(
  BuildContext context,
  List<SkippedEntry> entries,
) => showAppModalSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext)!;
    final scheme = Theme.of(sheetContext).colorScheme;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.8,
        ),
        child: ListView(
          key: const ValueKey('sms_skipped_list'),
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.all(AppSpacing.md),
          children: [
            Text(l10n.smsImportScanSkippedTitle, style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.smsImportScanSkippedNote,
              style: AppTypography.bodyMuted.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in entries)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.block_outlined),
                title: Text(SmsImportLabels.bank(l10n, entry.bankId ?? '')),
                subtitle: Text(
                  '${l10n.smsImportScanSkipReason(entry.reason.name)}'
                  '${l10n.smsImportReviewListSeparator}'
                  '${entry.receivedAt == null ? l10n.smsImportScanSkippedNoDate : SmsImportLabels.date(sheetContext, entry.receivedAt!)}',
                ),
              ),
          ],
        ),
      ),
    );
  },
);
