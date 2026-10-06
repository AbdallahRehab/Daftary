import 'package:flutter/widgets.dart';

import '../../../../core/design_system/change_history/app_change_history_sheet.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/finance_entry.dart';
import '../../domain/usecases/watch_entry_audit_history.dart';
import '../mappers/finance_entry_audit_row_mapper.dart';

/// Opens the read-only change-history sheet of [entry] (022 D2), through the
/// shared `ChangeHistoryCubit`. [categoryNames] maps a category id to its
/// display name, so the previous category of an edit can be named. [watch]
/// defaults to the registered use case; tests inject their own.
///
/// Limitation (as the transaction sheet): [entry] is the entry as it was when
/// the sheet opened; the "after" of the last edit is not re-read if the entry
/// changes while the sheet stays open.
Future<void> showFinanceEntryChangeHistory(
  BuildContext context,
  FinanceEntry entry, {
  required Map<String, String> categoryNames,
  WatchEntryAuditHistory? watch,
}) {
  final mapper = FinanceEntryAuditRowMapper(
    l10n: AppLocalizations.of(context)!,
    locale: Localizations.localeOf(context).languageCode,
    categoryNames: categoryNames,
  );
  final history = (watch ?? getIt<WatchEntryAuditHistory>())(
    entry.id,
  ).map((result) => result.map((audits) => mapper.rows(audits, entry)));
  return AppChangeHistorySheet.show(context, history: history);
}
