import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/scan_history_cubit.dart';
import '../cubit/scan_history_state.dart';
import '../widgets/scan_history_tile.dart';

/// Every retained scan, newest first (FR-018, User Story 5).
///
/// A scan that produced nothing is still listed rather than hidden — the
/// user asked for it, and "this one came to nothing" is exactly the kind of
/// thing a history is for (User Story 5, Acceptance Scenario 3).
class ScanHistoryPage extends StatelessWidget {
  const ScanHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ScanHistoryCubit>()..load(),
      child: const _ScanHistoryView(),
    );
  }
}

class _ScanHistoryView extends StatelessWidget {
  const _ScanHistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ScanHistoryCubit>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ocrHistoryTitle)),
      body: BlocBuilder<ScanHistoryCubit, ScanHistoryState>(
        builder: (context, state) {
          if (state.isLoading && state.scans.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.hasFailed && state.scans.isEmpty) {
            return AppEmptyView(
              icon: Icons.error_outline,
              title: l10n.ocrHistoryErrorTitle,
              message: state.failure?.message ?? l10n.ocrHistoryErrorMessage,
              actionLabel: l10n.commonRetry,
              onAction: cubit.load,
            );
          }

          if (state.isEmpty) {
            return AppEmptyView(
              icon: Icons.document_scanner_outlined,
              title: l10n.ocrHistoryEmptyTitle,
              message: l10n.ocrHistoryEmptyMessage,
            );
          }

          return RefreshIndicator(
            onRefresh: cubit.load,
            // `builder`, not a Column: a long-running user can accumulate
            // a lot of scans, and only the visible handful should decode
            // their thumbnail.
            child: ListView.builder(
              itemCount: state.scans.length,
              itemBuilder: (context, index) {
                final scan = state.scans[index];
                return ScanHistoryTile(
                  scan: scan,
                  onTap: () async {
                    await context.push('/ocr/history/${scan.id}');
                    // The detail screen can delete the scan it was
                    // showing, so the list is re-read on return rather
                    // than left displaying a row that no longer exists.
                    if (context.mounted) unawaited(cubit.load());
                  },
                  onDelete: () => _confirmDelete(context, cubit, scan.id),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ScanHistoryCubit cubit,
    String scanId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.ocrHistoryDeleteTitle,
      // The message spells out that the transactions survive. Deleting a
      // scan is safe precisely because it only costs the photo and the
      // audit trail, and a user who thinks it might erase their money will
      // either never use it or use it and be badly surprised (FR-023).
      message: l10n.ocrHistoryDeleteMessage,
      confirmLabel: l10n.ocrHistoryDeleteConfirm,
      isDestructive: true,
    );
    if (!confirmed) return;
    await cubit.deleteScan(scanId);
  }
}
