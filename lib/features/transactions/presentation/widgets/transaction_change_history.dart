import 'package:flutter/widgets.dart';

import '../../../../core/design_system/change_history/app_change_history_sheet.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/money_transaction.dart';
import '../../domain/usecases/watch_transaction_audit_history.dart';
import '../mappers/transaction_audit_row_mapper.dart';

/// Opens the read-only change-history sheet of [transaction] (022 C3).
/// [watch] defaults to the registered use case; tests inject their own.
Future<void> showTransactionChangeHistory(
  BuildContext context,
  MoneyTransaction transaction, {
  WatchTransactionAuditHistory? watch,
}) {
  // Limitation: `transaction` is the entity as it was when the sheet
  // opened. The history stream is live, but the "after" of the last edit
  // is not re-read if the record changes while the sheet stays open.
  final mapper = TransactionAuditRowMapper(
    l10n: AppLocalizations.of(context)!,
    locale: Localizations.localeOf(context).languageCode,
  );
  final history = (watch ?? getIt<WatchTransactionAuditHistory>())(
    transaction.id,
  ).map((result) => result.map((entries) => mapper.rows(entries, transaction)));
  return AppChangeHistorySheet.show(context, history: history);
}
