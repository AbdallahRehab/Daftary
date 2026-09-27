import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/sync_runtime_status.dart';
import '../../domain/entities/sync_status.dart';

/// What the status line says, most important first.
enum SyncDisplayState {
  unavailable,
  off,
  syncing,
  authRequired,
  unreadable,
  offline,
  conflict,
  failed,
  retrying,
  pending,
  upToDate,
}

/// Picks the one state the user most needs to know about.
SyncDisplayState syncDisplayStateOf(SyncStatus status) {
  if (!status.available) return SyncDisplayState.unavailable;
  if (!status.enabled || status.runtime == SyncRuntimeStatus.disabled) {
    return SyncDisplayState.off;
  }
  if (status.runtime == SyncRuntimeStatus.syncing) {
    return SyncDisplayState.syncing;
  }
  if (status.runtime == SyncRuntimeStatus.authRequired) {
    return SyncDisplayState.authRequired;
  }
  if (status.problem == SyncProblem.unreadableCloudData) {
    return SyncDisplayState.unreadable;
  }
  if (status.runtime == SyncRuntimeStatus.offline) {
    return SyncDisplayState.offline;
  }
  if (status.conflicts > 0) return SyncDisplayState.conflict;
  if (status.failed > 0) return SyncDisplayState.failed;
  if (status.runtime == SyncRuntimeStatus.backingOff) {
    return SyncDisplayState.retrying;
  }
  if (status.pending > 0) return SyncDisplayState.pending;
  return SyncDisplayState.upToDate;
}

/// The localized one-line status.
String syncStatusText(AppLocalizations l10n, SyncStatus status) =>
    switch (syncDisplayStateOf(status)) {
      SyncDisplayState.unavailable => l10n.syncStatusUnavailable,
      SyncDisplayState.off => l10n.syncStatusOff,
      SyncDisplayState.syncing => l10n.syncStatusSyncing,
      SyncDisplayState.authRequired => l10n.syncStatusAuthRequired,
      SyncDisplayState.unreadable => l10n.syncStatusUnreadable,
      SyncDisplayState.offline => l10n.syncStatusOffline,
      SyncDisplayState.conflict => l10n.syncStatusConflict,
      SyncDisplayState.failed => l10n.syncStatusFailed,
      SyncDisplayState.retrying => l10n.syncStatusRetrying,
      SyncDisplayState.pending => l10n.syncStatusPending(status.pending),
      SyncDisplayState.upToDate => l10n.syncStatusUpToDate,
    };

/// 021 T080: an icon and the status text. The icon always comes with the
/// text, never color alone.
class SyncStatusLine extends StatelessWidget {
  const SyncStatusLine({required this.status, super.key});

  static const textKey = Key('sync_status_text');

  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final state = syncDisplayStateOf(status);
    final (icon, color) = switch (state) {
      SyncDisplayState.unavailable || SyncDisplayState.off => (
        Icons.cloud_off_outlined,
        colors.onSurfaceVariant,
      ),
      SyncDisplayState.syncing => (Icons.sync, colors.primary),
      SyncDisplayState.offline => (
        Icons.wifi_off_outlined,
        colors.onSurfaceVariant,
      ),
      SyncDisplayState.authRequired ||
      SyncDisplayState.unreadable ||
      SyncDisplayState.conflict ||
      SyncDisplayState.failed => (Icons.sync_problem, colors.error),
      SyncDisplayState.retrying ||
      SyncDisplayState.pending => (Icons.cloud_upload_outlined, colors.primary),
      SyncDisplayState.upToDate => (Icons.cloud_done_outlined, colors.primary),
    };
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            syncStatusText(l10n, status),
            key: textKey,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
