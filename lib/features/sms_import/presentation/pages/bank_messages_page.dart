import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../cubit/bank_messages_cubit.dart';
import '../cubit/bank_messages_state.dart';
import '../routes.dart';
import '../widgets/pending_import_card.dart';
import '../widgets/scan_summary_view.dart';
import '../widgets/sms_permission_banner.dart';

/// The Bank messages hub, list part (T081, ui-contract §3.3): the pending
/// items in review order, the expired notice, and loading, empty and error
/// states. There is no "Add all" anywhere (FR-046): an item becomes money
/// only from its own review screen.
///
/// US2 (T120): with the SMS capability, a header carries "Scan now" (on
/// and granted), the running scan with Cancel, the content-free summary,
/// the permission banner or a "Turn on" card. Without the capability none
/// of it is rendered and the page is the paste-only list (CHK036).
///
/// US6 (T132): long-press or "Select" enters selection mode; its only
/// action is Ignore, confirmed first (FR-064). No "Add all" (FR-046).
class BankMessagesPage extends StatelessWidget {
  const BankMessagesPage({super.key, this.cubit, this.startScan = false});

  /// Tests inject a cubit; the app resolves it from DI.
  final BankMessagesCubit? cubit;

  /// Start a scan once open (Settings' "Scan now"). Ignored when the scan
  /// is not allowed; never prompts.
  final bool startScan;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final created = cubit ?? getIt<BankMessagesCubit>();
        final opened = created.open();
        if (startScan) {
          // The page may be gone before `open` completes.
          opened.then((_) {
            if (!created.isClosed) created.scan();
          });
        }
        return created;
      },
      child: const _BankMessagesView(),
    );
  }
}

class _BankMessagesView extends StatefulWidget {
  const _BankMessagesView();

  @override
  State<_BankMessagesView> createState() => _BankMessagesViewState();
}

class _BankMessagesViewState extends State<_BankMessagesView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // A revoked permission is detected on resume, prompt-free (FR-070,
    // ui-contract §9).
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<BankMessagesCubit>().refreshScanContext(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _confirmIgnore(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BankMessagesCubit>();
    final count = cubit.state.selectedIds.length;
    if (count == 0) return;
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.smsImportPendingIgnoreConfirmTitle(count),
      message: l10n.smsImportPendingIgnoreConfirmMessage,
      confirmLabel: l10n.smsImportPendingIgnoreConfirm,
      cancelLabel: MaterialLocalizations.of(context).cancelButtonLabel,
    );
    if (confirmed) await cubit.ignoreSelected();
  }

  void _onBatchResult(BuildContext context, BankMessagesState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BankMessagesCubit>();
    final String message;
    if (state.ignoredCount case final count?) {
      cubit.consumeIgnoredCount();
      message = l10n.smsImportPendingIgnoredCount(count);
    } else if (state.ignoreFailure case final failure?) {
      message = l10n.messageFor(failure);
    } else {
      return;
    }
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  PreferredSizeWidget _appBar(BuildContext context, BankMessagesState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BankMessagesCubit>();
    if (state.selectionMode) {
      final count = state.selectedIds.length;
      return AppTopBar(
        leading: IconButton(
          key: const ValueKey('bank_messages_cancel_selection'),
          icon: const Icon(Icons.close),
          tooltip: l10n.smsImportPendingCancelSelection,
          onPressed: state.ignoring ? null : cubit.cancelSelection,
        ),
        title: Semantics(
          liveRegion: true,
          child: Text(l10n.smsImportPendingSelectedCount(count)),
        ),
        actions: [
          // The only batch action (FR-046, FR-064).
          if (state.ignoring)
            const Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.md),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              key: const ValueKey('bank_messages_ignore_selected'),
              onPressed: count == 0 ? null : () => _confirmIgnore(context),
              icon: const Icon(Icons.visibility_off_outlined),
              label: Text(l10n.smsImportPendingIgnoreSelected),
            ),
        ],
      );
    }
    return AppTopBar(
      title: Text(l10n.smsImportPendingTitle),
      actions: [
        if (state.status == BankMessagesStatus.ready)
          IconButton(
            key: const ValueKey('bank_messages_select'),
            icon: const Icon(Icons.checklist),
            tooltip: l10n.smsImportPendingSelect,
            onPressed: cubit.startSelection,
          ),
        PopupMenuButton<String>(
          key: const ValueKey('bank_messages_overflow'),
          tooltip: l10n.smsImportScanMore,
          onSelected: (location) => _openThenRefresh(context, location),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: BankMessagesRoutes.paste,
              child: Text(l10n.smsImportPasteTitle),
            ),
            PopupMenuItem(
              key: const ValueKey('bank_messages_menu_ignored'),
              value: BankMessagesRoutes.ignored,
              child: Text(l10n.smsImportPendingMenuIgnored),
            ),
            PopupMenuItem(
              value: BankMessagesRoutes.settings,
              child: Text(l10n.smsImportSettingsTitle),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<BankMessagesCubit, BankMessagesState>(
      listenWhen: (p, c) =>
          (c.ignoredCount != null && p.ignoredCount != c.ignoredCount) ||
          (c.ignoreFailure != null && p.ignoreFailure != c.ignoreFailure),
      listener: _onBatchResult,
      builder: (context, state) {
        final cubit = context.read<BankMessagesCubit>();
        return PopScope(
          // Back leaves selection mode first.
          canPop: !state.selectionMode,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop) cubit.cancelSelection();
          },
          child: AppScaffold(
            appBar: _appBar(context, state),
            body: SafeArea(
              top: false,
              bottom: false,
              // A context below the scaffold, so `AppGlassInsets.of` in
              // `_body` sees the bars' insets under glass.
              child: Builder(
                builder: (context) => _body(context, l10n, state, cubit),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    BankMessagesState state,
    BankMessagesCubit cubit,
  ) {
    final notice = state.showExpiredNotice && !state.selectionMode
        ? _ExpiredNotice(
            count: state.expiredNoticeCount,
            onDismiss: cubit.dismissExpiredNotice,
          )
        : null;
    final header = state.selectionMode
        ? const <Widget>[]
        : _scanHeader(context, state, cubit);
    return switch (state.status) {
      BankMessagesStatus.initial ||
      BankMessagesStatus.loading => const _Skeleton(),
      BankMessagesStatus.error => AppEmptyView(
        title: l10n.smsImportPendingLoadErrorTitle,
        message: l10n.messageFor(state.failure),
        icon: Icons.error_outline,
        actionLabel: l10n.smsImportPendingRetry,
        onAction: cubit.retry,
      ),
      // Not scrollable as a whole, so the glass insets pad the column: the
      // header stays clear of the top bar and the action of the bottom bar.
      BankMessagesStatus.empty => Padding(
        padding: AppGlassInsets.of(context),
        child: Column(
          children: [
            if (header.isNotEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md,
                  end: AppSpacing.md,
                  top: AppSpacing.md,
                ),
                child: Column(children: header),
              ),
            ?notice,
            Expanded(
              child: AppEmptyView(
                title: l10n.smsImportPendingEmptyTitle,
                message: l10n.smsImportPendingEmptyMessage,
                icon: Icons.sms_outlined,
                // Android, on and granted: Scan now (US2).
                // Everywhere else: Paste (US4).
                actionLabel: state.canScan
                    ? l10n.smsImportScanNow
                    : l10n.smsImportPasteTitle,
                onAction: state.canScan
                    ? (state.scanning ? null : cubit.scan)
                    : () => context.push(BankMessagesRoutes.paste),
              ),
            ),
          ],
        ),
      ),
      BankMessagesStatus.ready => ListView(
        padding:
            const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
        children: [
          ...header,
          ?notice,
          for (final item in state.items)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: PendingImportCard(
                item: item,
                selectionMode: state.selectionMode,
                selected: state.selectedIds.contains(item.id),
                enabled: !state.ignoring,
                onLongPress: state.selectionMode
                    ? null
                    : () => cubit.startSelection(item.id),
                onTap: state.selectionMode
                    ? () => cubit.toggleSelected(item.id)
                    : () => context.push(BankMessagesRoutes.review(item.id)),
              ),
            ),
        ],
      ),
    };
  }
}

/// Opens [location], then re-reads the scan context (permission and
/// settings may have changed on the way), prompt-free.
Future<void> _openThenRefresh(BuildContext context, String location) async {
  final cubit = context.read<BankMessagesCubit>();
  await context.push(location);
  await cubit.refreshScanContext();
}

/// The scan header (ui-contract §3.3): nothing without the capability.
List<Widget> _scanHeader(
  BuildContext context,
  BankMessagesState state,
  BankMessagesCubit cubit,
) {
  if (!state.scanAvailable) return const [];
  final l10n = AppLocalizations.of(context)!;
  Widget spaced(Widget child) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
    child: child,
  );
  void paste() => context.push(BankMessagesRoutes.paste);
  void enable() => _openThenRefresh(context, BankMessagesRoutes.enable);
  final banner = state.bannerStatus;
  return [
    if (state.scanning)
      spaced(
        ScanProgressPanel(
          processed: state.scanProcessed,
          onCancel: cubit.cancelScan,
        ),
      )
    else if (state.canScan && state.status != BankMessagesStatus.empty)
      spaced(
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton.tonalIcon(
            key: const ValueKey('bank_messages_scan_now'),
            onPressed: cubit.scan,
            icon: const Icon(Icons.search),
            label: Text(l10n.smsImportScanNow),
          ),
        ),
      ),
    if (state.scanSummary case final summary?)
      spaced(
        ScanSummaryCard(summary: summary, onDismiss: cubit.dismissScanSummary),
      ),
    if (state.scanFailure case final failure?)
      spaced(
        Semantics(
          liveRegion: true,
          child: AppCard(
            key: const ValueKey('bank_messages_scan_failure'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.messageFor(failure), style: AppTypography.body),
                      // Partial results are kept (ui-contract §3.2).
                      Text(
                        l10n.smsImportScanInterrupted(state.scanProcessed),
                        style: AppTypography.bodyMuted,
                      ),
                    ],
                  ),
                ),
                if (state.canScan)
                  TextButton(
                    onPressed: cubit.scan,
                    child: Text(l10n.smsImportScanRetry),
                  ),
              ],
            ),
          ),
        ),
      ),
    if (banner != null)
      spaced(
        SmsPermissionBanner(
          status: banner,
          onPaste: paste,
          onAllow: enable,
          onOpenAppInfo: cubit.openAppInfo,
          onShowMeHow: () => showRestrictedGuidanceSheet(
            context,
            onOpenAppInfo: cubit.openAppInfo,
            onPaste: paste,
          ),
        ),
      )
    else if (state.showTurnOn)
      spaced(
        AppCard(
          key: const ValueKey('bank_messages_turn_on'),
          child: Row(
            children: [
              const Icon(Icons.sms_outlined),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.smsImportScanTurnOnTitle,
                  style: AppTypography.body,
                ),
              ),
              TextButton(
                onPressed: enable,
                child: Text(l10n.smsImportScanTurnOn),
              ),
            ],
          ),
        ),
      ),
  ];
}

/// "N suggestions expired. You can restore them from Ignored items."
/// (FR-025), dismissible.
class _ExpiredNotice extends StatelessWidget {
  const _ExpiredNotice({required this.count, required this.onDismiss});

  final int count;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Semantics(
        liveRegion: true,
        child: AppCard(
          child: Row(
            children: [
              Icon(Icons.history_toggle_off, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.smsImportPendingExpiredNotice(count),
                  style: AppTypography.body,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.smsImportPendingExpiredDismiss,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton cards while loading; no spinner-only screen.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar(double widthFactor) => FractionallySizedBox(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: widthFactor,
      child: Container(
        height: 14,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );
    return ExcludeSemantics(
      child: ListView(
        key: const ValueKey('bank_messages_skeleton'),
        padding:
            const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(0.3),
                    const SizedBox(height: AppSpacing.sm),
                    bar(0.6),
                    const SizedBox(height: AppSpacing.sm),
                    bar(0.45),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
