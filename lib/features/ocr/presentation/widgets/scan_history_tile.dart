import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/date/app_date_formatter.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/ocr_scan.dart';

/// The human-readable outcome of a past scan (FR-018). Kept next to the
/// tile rather than inside it so the detail screen labels a scan's state
/// with exactly the same words the list did.
String scanStatusLabel(AppLocalizations l10n, ScanStatus status) {
  switch (status) {
    case ScanStatus.processing:
      return l10n.ocrHistoryStatusProcessing;
    case ScanStatus.needsReview:
      return l10n.ocrHistoryStatusNeedsReview;
    case ScanStatus.confirmed:
      return l10n.ocrHistoryStatusConfirmed;
    case ScanStatus.discarded:
      return l10n.ocrHistoryStatusDiscarded;
    case ScanStatus.failed:
      return l10n.ocrHistoryStatusFailed;
  }
}

/// One row of the scan history: a thumbnail of the paper, the date it was
/// scanned, and what came of it (FR-018).
class ScanHistoryTile extends StatelessWidget {
  const ScanHistoryTile({
    required this.scan,
    super.key,
    this.confirmedEntryCount,
    this.onTap,
    this.onDelete,
  });

  final OcrScan scan;

  /// How many entries this scan confirmed, when the caller happens to know
  /// it. The history query returns scans alone — entry counts live with
  /// the entries — so this is usually `null`, and the row then reports the
  /// outcome by status only rather than inventing a number (FR-018's
  /// "where that is known").
  final int? confirmedEntryCount;

  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final financeColors = context.financeColors;
    final dateLabel = AppDateFormatter(
      locale: Localizations.localeOf(context).languageCode,
    ).format(scan.createdAt);
    final count = confirmedEntryCount;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      leading: ScanThumbnail(imagePath: scan.sourceImagePath),
      title: Text(dateLabel, style: AppTypography.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              scanStatusLabel(l10n, scan.status),
              style: AppTypography.bodyMuted.copyWith(
                color: scan.status == ScanStatus.failed
                    ? financeColors.warning
                    : colorScheme.onSurfaceVariant,
              ),
            ),
            if (count != null)
              Text(
                l10n.ocrHistoryConfirmedEntries(count),
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            IconButton(
              tooltip: l10n.ocrHistoryDeleteAction,
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// The scan's image as a small square.
///
/// The file lives in the app's sandbox and can legitimately be gone — a
/// restore from backup, a cleaner app, an OS purge — so a missing file
/// renders a placeholder instead of throwing inside a list item and taking
/// the whole history screen down with it (FR-023).
class ScanThumbnail extends StatelessWidget {
  const ScanThumbnail({required this.imagePath, super.key, this.size = 56});

  final String imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: SizedBox(
        width: size,
        height: size,
        child: Image.file(
          File(imagePath),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => ColoredBox(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.image_not_supported_outlined,
              color: colorScheme.onSurfaceVariant,
              size: size / 2,
            ),
          ),
        ),
      ),
    );
  }
}
