import 'package:flutter/material.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/money/egp_formatter.dart';
import '../../../../core/money/money.dart';

/// An explicit "this cannot be undone" confirmation shown before
/// `DeleteTransaction` is called (FR-016, US6 Acceptance Scenario 3).
/// Returns `true` only if the user confirmed.
///
/// 022 E6: when [laterRepaymentCount] is above zero the message also warns
/// that those repayments were recorded after this row, and shows the
/// balance with [personName] that deleting would leave ([resultingNet],
/// positive = they owe you; `null` when it cannot be computed). It never
/// blocks deletion.
Future<bool> showDeleteTransactionConfirmDialog(
  BuildContext context, {
  int laterRepaymentCount = 0,
  String? personName,
  Money? resultingNet,
}) {
  final l10n = AppLocalizations.of(context)!;
  var message = l10n.deleteTransactionConfirmMessage;
  if (laterRepaymentCount > 0) {
    final formatter = EgpFormatter(
      locale: Localizations.localeOf(context).languageCode,
    );
    final net = resultingNet;
    final name = personName ?? l10n.personLabel;
    final result = net == null
        ? l10n.repaymentPreviewUnavailable
        : switch (net.minorUnits.sign) {
            1 => l10n.personDetailTheyOweYou(
              name,
              formatter.formatWithSymbol(net.abs()),
            ),
            -1 => l10n.personDetailYouOweThem(
              name,
              formatter.formatWithSymbol(net.abs()),
            ),
            _ => l10n.personDetailSettled,
          };
    message =
        '$message\n\n${l10n.deleteLaterRepaymentsWarning(laterRepaymentCount, result)}';
  }
  return showAppConfirmDialog(
    context,
    title: l10n.deleteTransactionConfirmTitle,
    message: message,
    confirmLabel: l10n.commonDelete,
    cancelLabel: l10n.commonCancel,
    isDestructive: true,
  );
}
