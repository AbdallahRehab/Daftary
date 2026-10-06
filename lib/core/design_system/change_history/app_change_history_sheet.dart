import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../date/app_date_formatter.dart';
import '../../error/failure.dart';
import '../../l10n/app_localizations.dart';
import '../app_empty_view.dart';
import '../glass/app_modal_sheet.dart';
import '../tokens.dart';
import 'change_history_cubit.dart';
import 'change_history_row.dart';
import 'change_history_state.dart';

/// Minimum touch/row height (accessibility: 48dp targets).
const double _minRowHeight = 48;

/// The read-only change-history list (022 C3), driven by the
/// [ChangeHistoryCubit] above it: loading, empty and error states, one
/// screen-reader label per row. All copy comes from ARB and dates go
/// through [AppDateFormatter].
class AppChangeHistorySheet extends StatelessWidget {
  const AppChangeHistorySheet({super.key});

  /// Opens the sheet over [history]; the cubit lives as long as the sheet.
  static Future<void> show(
    BuildContext context, {
    required Stream<Either<Failure, List<ChangeHistoryRow>>> history,
  }) {
    return showAppModalSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlocProvider(
        create: (_) => ChangeHistoryCubit(history),
        child: const AppChangeHistorySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Semantics(
                header: true,
                child: Text(
                  l10n.changeHistoryTitle,
                  style: AppTypography.title,
                ),
              ),
            ),
            Flexible(
              child: BlocBuilder<ChangeHistoryCubit, ChangeHistoryState>(
                builder: (context, state) => switch (state.status) {
                  ChangeHistoryStatus.loading => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  ChangeHistoryStatus.empty => AppEmptyView(
                    title: l10n.changeHistoryTitle,
                    message: l10n.changeHistoryEmpty,
                    icon: Icons.history,
                  ),
                  ChangeHistoryStatus.failure => AppEmptyView(
                    title: l10n.changeHistoryTitle,
                    message: l10n.changeHistoryLoadError,
                    icon: Icons.error_outline,
                  ),
                  ChangeHistoryStatus.success => _RowList(rows: state.rows),
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowList extends StatelessWidget {
  const _RowList({required this.rows});

  final List<ChangeHistoryRow> rows;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formatter = AppDateFormatter(locale: locale);
    final l10n = AppLocalizations.of(context)!;
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final row = rows[index];
        final date = formatter.formatDateTime(row.timestamp);
        final details = row.fields
            .map((f) => f.label.isEmpty ? f.value : '${f.label}: ${f.value}')
            .join('. ');
        return Semantics(
          container: true,
          label: l10n.changeHistoryRowSemantics(row.label, date, details),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              key: const ValueKey('change-history-row'),
              constraints: const BoxConstraints(minHeight: _minRowHeight),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(row.label, style: AppTypography.body),
                        ),
                        Text(
                          date,
                          style: AppTypography.bodyMuted.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    for (final field in row.fields)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: field.label.isEmpty
                            ? Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  field.value,
                                  style: AppTypography.body,
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      field.label,
                                      style: AppTypography.bodyMuted.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      field.value,
                                      style: AppTypography.body,
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
