import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/occasion_attachment.dart';

/// An occasion's photos (FR-017): a thumbnail grid, tap to view full
/// screen, and a remove action behind a confirmation.
///
/// Every thumbnail degrades to a placeholder when its file is no longer on
/// disk. That is a real possibility — a user can clear app storage or
/// restore a backup without the media — and a missing photo must never
/// become a red error box on top of an otherwise usable occasion.
class OccasionAttachmentGallery extends StatelessWidget {
  const OccasionAttachmentGallery({
    required this.attachments,
    super.key,
    this.onRemove,
  });

  final List<OccasionAttachment> attachments;
  final void Function(OccasionAttachment attachment)? onRemove;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: attachments.length,
      itemBuilder: (context, index) {
        final attachment = attachments[index];
        return _AttachmentThumbnail(
          attachment: attachment,
          onRemove: onRemove == null ? null : () => onRemove!(attachment),
        );
      },
    );
  }
}

class _AttachmentThumbnail extends StatelessWidget {
  const _AttachmentThumbnail({required this.attachment, this.onRemove});

  final OccasionAttachment attachment;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final file = File(attachment.filePath);
    final exists = file.existsSync();

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (exists)
            GestureDetector(
              onTap: () => _openFullScreen(context, file),
              child: Image.file(
                file,
                fit: BoxFit.cover,
                // A file that vanishes between `existsSync` and decoding is
                // still possible; the placeholder covers that race too.
                errorBuilder: (context, _, _) => const _MissingPhoto(),
              ),
            )
          else
            const _MissingPhoto(),
          if (onRemove != null)
            PositionedDirectional(
              top: 0,
              end: 0,
              // The only deliberately un-themed colours in this feature:
              // this button sits on top of the photo itself, and the
              // viewer below uses a black backdrop in both themes, as
              // every photo viewer does — a surface colour here would
              // tint the photo rather than frame it.
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  iconSize: 18,
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  constraints: const BoxConstraints(),
                  tooltip: l10n.occasionRemoveAttachmentAction,
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => _confirmRemove(context, l10n),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.occasionRemoveAttachmentConfirmTitle,
      message: l10n.occasionRemoveAttachmentConfirmMessage,
      confirmLabel: l10n.occasionRemoveAttachmentAction,
      isDestructive: true,
    );
    if (confirmed) onRemove!();
  }

  /// Deliberately a plain black [Scaffold] and [AppBar], not the glass
  /// `AppScaffold` (020): an immersive photo viewer frames the photo on
  /// black in both themes, so there is no app content for a glass bar to
  /// float over, and a tinted bar would only cover part of the photo.
  void _openFullScreen(BuildContext context, File file) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                file,
                errorBuilder: (context, _, _) => const _MissingPhoto(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MissingPhoto extends StatelessWidget {
  const _MissingPhoto();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.financeColors.neutralSurface,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: context.financeColors.neutral,
      ),
    );
  }
}
