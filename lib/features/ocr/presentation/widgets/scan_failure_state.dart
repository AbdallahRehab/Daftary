import 'package:flutter/material.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/media/attachment_picker_service.dart';
import '../../domain/entities/ocr_failures.dart';

/// The one place a scan failure is explained to the user (FR-004, User
/// Story 4).
///
/// Every branch renders a reason *and* a way forward, because the failure
/// modes this feature has are all recoverable in a different way: a blank
/// photo needs a new photo, unparseable text needs a tighter crop, a denied
/// permission needs Settings. A shared "something went wrong" would be
/// technically true and practically useless.
///
/// [Failure.message] is never shown: it is developer text, sometimes an
/// exception string, and often untranslated.
class ScanFailureState extends StatelessWidget {
  const ScanFailureState({
    required this.failure,
    super.key,
    this.onRetakePhoto,
    this.onRecrop,
    this.onEnterManually,
    this.onOpenSettings,
  });

  final Failure failure;

  /// Go back to capture and take another photo.
  final VoidCallback? onRetakePhoto;

  /// Stay on the same photo and adjust the crop before retrying (FR-002) —
  /// the cheapest recovery, so it is offered first where it can help.
  final VoidCallback? onRecrop;

  /// Leave the scan flow for ordinary manual entry. Always offered: it is
  /// the one path that works no matter what went wrong.
  final VoidCallback? onEnterManually;

  /// Opens the OS app-settings screen. Optional because not every host
  /// screen can provide it; when absent, the permission branch still
  /// explains what to do.
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final _FailureCopy copy = _copyFor(l10n);

    return Center(
      child: SingleChildScrollView(
        padding:
            const EdgeInsets.all(AppSpacing.xl) + AppGlassInsets.of(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(copy.icon, size: 48, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              copy.title,
              style: AppTypography.title,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              copy.message,
              style: AppTypography.bodyMuted.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ..._actions(l10n),
          ],
        ),
      ),
    );
  }

  _FailureCopy _copyFor(AppLocalizations l10n) {
    if (failure is NoTextRecognizedFailure) {
      return _FailureCopy(
        icon: Icons.image_not_supported_outlined,
        title: l10n.ocrFailureNoTextTitle,
        message: l10n.ocrFailureNoTextMessage,
      );
    }
    if (failure is NoCandidatesParsedFailure) {
      return _FailureCopy(
        icon: Icons.format_list_bulleted_outlined,
        title: l10n.ocrFailureNoCandidatesTitle,
        message: l10n.ocrFailureNoCandidatesMessage,
      );
    }
    if (failure is PermissionDeniedFailure) {
      return _FailureCopy(
        icon: Icons.lock_outline,
        title: l10n.ocrFailurePermissionTitle,
        message: l10n.ocrFailurePermissionMessage,
      );
    }
    if (failure is OcrUnavailableFailure) {
      return _FailureCopy(
        icon: Icons.phonelink_erase_outlined,
        title: l10n.ocrFailureUnsupportedTitle,
        message: l10n.ocrFailureUnsupportedMessage,
      );
    }
    return _FailureCopy(
      icon: Icons.error_outline,
      title: l10n.ocrFailureGenericTitle,
      message: l10n.ocrFailureGenericMessage,
    );
  }

  /// The recovery actions, ordered by how likely each is to actually help
  /// for this particular failure.
  List<Widget> _actions(AppLocalizations l10n) {
    final actions = <Widget>[];

    void add(Widget button) {
      if (actions.isNotEmpty) {
        actions.add(const SizedBox(height: AppSpacing.sm));
      }
      actions.add(SizedBox(width: double.infinity, child: button));
    }

    if (failure is PermissionDeniedFailure) {
      if (onOpenSettings != null) {
        add(
          AppButton(
            label: l10n.ocrFailureOpenSettings,
            onPressed: onOpenSettings,
            icon: Icons.settings_outlined,
          ),
        );
      }
    } else if (failure is NoCandidatesParsedFailure) {
      // Text was found, so the photo itself is usable — re-cropping to
      // just the list is far more likely to work than a new photo.
      if (onRecrop != null) {
        add(AppButton(label: l10n.ocrFailureRecrop, onPressed: onRecrop));
      }
      if (onRetakePhoto != null) {
        add(
          AppSecondaryButton(
            label: l10n.ocrFailureRetakePhoto,
            onPressed: onRetakePhoto,
          ),
        );
      }
    } else if (failure is OcrUnavailableFailure) {
      // Deliberately no retry: nothing about this device will change.
    } else {
      if (onRetakePhoto != null) {
        add(
          AppButton(
            label: l10n.ocrFailureRetakePhoto,
            onPressed: onRetakePhoto,
            icon: Icons.photo_camera_outlined,
          ),
        );
      }
      if (onRecrop != null) {
        add(
          AppSecondaryButton(label: l10n.ocrFailureRecrop, onPressed: onRecrop),
        );
      }
    }

    if (onEnterManually != null) {
      add(
        AppSecondaryButton(
          label: l10n.ocrFailureManualEntry,
          onPressed: onEnterManually,
        ),
      );
    }
    return actions;
  }
}

class _FailureCopy {
  const _FailureCopy({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;
}
