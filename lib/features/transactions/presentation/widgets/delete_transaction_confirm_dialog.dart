import 'package:flutter/material.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/l10n/app_localizations.dart';

/// An explicit "this cannot be undone" confirmation shown before
/// `DeleteTransaction` is called (FR-016, US6 Acceptance Scenario 3).
/// Returns `true` only if the user confirmed.
Future<bool> showDeleteTransactionConfirmDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return showAppConfirmDialog(
    context,
    title: l10n.deleteTransactionConfirmTitle,
    message: l10n.deleteTransactionConfirmMessage,
    confirmLabel: l10n.commonDelete,
    cancelLabel: l10n.commonCancel,
    isDestructive: true,
  );
}
