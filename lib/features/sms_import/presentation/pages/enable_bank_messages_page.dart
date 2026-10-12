import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../cubit/enable_flow_cubit.dart';
import '../cubit/enable_flow_state.dart';
import '../routes.dart';
import '../widgets/scan_summary_view.dart';
import '../widgets/sms_permission_banner.dart';

/// The enable flow (T119, ui-contract §3.2): Explain -> Permission ->
/// Window -> Scanning -> Done, on one page.
///
/// - The system prompt can appear only after Continue (FR-005); opening
///   this page, resuming the app or returning from App info never
///   prompts (FR-002, FR-012).
/// - On resume after App info the cubit re-checks the status and advances
///   by itself when it is now granted (FR-072).
/// - "Paste instead" is offered at every permission step.
class EnableBankMessagesPage extends StatelessWidget {
  const EnableBankMessagesPage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final EnableFlowCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<EnableFlowCubit>())..open(),
      child: const _EnableView(),
    );
  }
}

class _EnableView extends StatefulWidget {
  const _EnableView();

  @override
  State<_EnableView> createState() => _EnableViewState();
}

class _EnableViewState extends State<_EnableView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Prompt-free re-check on return from App info (FR-072).
    _lifecycle = AppLifecycleListener(
      onResume: () => context.read<EnableFlowCubit>().onResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _announce(String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(BankMessagesRoutes.hub);
    }
  }

  void _paste() => context.pushReplacement(BankMessagesRoutes.paste);

  Future<void> _reviewNow() async {
    final id = await context.read<EnableFlowCubit>().firstPendingId();
    if (!mounted) return;
    context.pushReplacement(
      id == null ? BankMessagesRoutes.hub : BankMessagesRoutes.review(id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportEnableTitle)),
      body: SafeArea(
        top: false,
        child: BlocConsumer<EnableFlowCubit, EnableFlowState>(
          listenWhen: (a, b) => a.step != b.step,
          listener: (context, state) {
            if (state.step == EnableFlowStep.done && state.summary != null) {
              _announce(ScanSummaryView.lines(l10n, state.summary!).join('\n'));
            }
          },
          builder: (context, state) {
            final cubit = context.read<EnableFlowCubit>();
            return switch (state.step) {
              EnableFlowStep.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              EnableFlowStep.unavailable => AppEmptyView(
                title: l10n.smsImportEnableUnavailableTitle,
                message: l10n.smsImportEnableUnavailableMessage,
                icon: Icons.content_paste_outlined,
                actionLabel: l10n.smsImportPasteTitle,
                onAction: _paste,
              ),
              EnableFlowStep.explain => _Scroll(
                children: [
                  _ExplainContent(l10n: l10n),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('sms_enable_continue'),
                    label: l10n.smsImportEnableContinue,
                    onPressed: cubit.acknowledgeAndContinue,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSecondaryButton(
                    label: l10n.smsImportEnableNotNow,
                    onPressed: _close,
                  ),
                  TextButton(
                    onPressed: _paste,
                    child: Text(l10n.smsImportEnablePasteInstead),
                  ),
                ],
              ),
              EnableFlowStep.requesting => _Scroll(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: AppSpacing.md),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      l10n.smsImportEnableRequesting,
                      textAlign: TextAlign.center,
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
              EnableFlowStep.denied => _PermissionStep(
                stepKey: 'denied',
                title: l10n.smsImportPermissionDeniedBanner,
                body: Text(
                  l10n.smsImportPermissionDeniedDetail,
                  style: AppTypography.body,
                ),
                primaryLabel: state.canTryAgain
                    ? l10n.smsImportPermissionTryAgain
                    : null,
                onPrimary: cubit.tryAgain,
                onPaste: _paste,
              ),
              EnableFlowStep.permanentlyDenied => _PermissionStep(
                stepKey: 'permanentlyDenied',
                title: l10n.smsImportPermissionPermanentBanner,
                body: Text(
                  l10n.smsImportPermissionPermanentDetail,
                  style: AppTypography.body,
                ),
                primaryLabel: l10n.smsImportPermissionOpenAppInfo,
                onPrimary: cubit.openAppInfo,
                onPaste: _paste,
              ),
              EnableFlowStep.restricted => _PermissionStep(
                stepKey: 'restricted',
                title: l10n.smsImportRestrictedTitle,
                body: const RestrictedSettingsSteps(),
                primaryLabel: l10n.smsImportPermissionOpenAppInfo,
                onPrimary: cubit.openAppInfo,
                secondaryLabel: l10n.smsImportPermissionTryAgain,
                onSecondary: cubit.tryAgain,
                onPaste: _paste,
              ),
              EnableFlowStep.window => _Scroll(
                children: [
                  Text(
                    l10n.smsImportEnableWindowTitle,
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ScanWindowSelector(
                    value: state.window,
                    onChanged: cubit.selectWindow,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('sms_enable_scan'),
                    label: l10n.smsImportEnableScan,
                    icon: Icons.search,
                    onPressed: cubit.startScan,
                  ),
                ],
              ),
              EnableFlowStep.scanning => _Scroll(
                children: [
                  ScanProgressPanel(
                    processed: state.processed,
                    onCancel: cubit.cancelScan,
                  ),
                ],
              ),
              EnableFlowStep.done => _Scroll(
                children: [
                  Text(
                    l10n.smsImportEnableDoneTitle,
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(child: ScanSummaryView(summary: state.summary!)),
                  const SizedBox(height: AppSpacing.lg),
                  if (state.summary!.createdPending > 0) ...[
                    AppButton(
                      key: const ValueKey('sms_enable_review_now'),
                      label: l10n.smsImportEnableReviewNow,
                      onPressed: _reviewNow,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppSecondaryButton(
                    label: l10n.smsImportEnableClose,
                    onPressed: () =>
                        context.pushReplacement(BankMessagesRoutes.hub),
                  ),
                ],
              ),
              EnableFlowStep.error => _Scroll(
                children: [
                  Text(
                    state.failedWhileScanning
                        ? l10n.smsImportScanFailedTitle
                        : l10n.smsImportEnableErrorTitle,
                    style: AppTypography.title,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    l10n.messageFor(state.failure),
                    style: AppTypography.body,
                  ),
                  if (state.failedWhileScanning) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l10n.smsImportScanInterrupted(state.processed),
                      style: AppTypography.body,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.smsImportEnableRetry,
                    onPressed: cubit.retry,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSecondaryButton(
                    label: l10n.smsImportPermissionPasteInstead,
                    onPressed: _paste,
                  ),
                ],
              ),
            };
          },
        ),
      ),
    );
  }
}

/// The 7 / 30 / 90 day choice (FR-006), shared with Settings.
class ScanWindowSelector extends StatelessWidget {
  const ScanWindowSelector({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final ScanWindow value;
  final ValueChanged<ScanWindow> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RadioGroup<ScanWindow>(
      groupValue: value,
      onChanged: (window) {
        if (enabled && window != null) onChanged(window);
      },
      child: Column(
        children: [
          for (final window in ScanWindow.values)
            RadioListTile<ScanWindow>(
              key: ValueKey('sms_scan_window_${window.days}'),
              value: window,
              enabled: enabled,
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.smsImportEnableWindowDays(window.days)),
            ),
        ],
      ),
    );
  }
}

class _Scroll extends StatelessWidget {
  const _Scroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: children,
    );
  }
}

class _ExplainContent extends StatelessWidget {
  const _ExplainContent({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget point(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      child: MergeSemantics(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(body, style: AppTypography.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    return Column(
      key: const ValueKey('sms_enable_explain'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.smsImportEnableExplainTitle, style: AppTypography.title),
        const SizedBox(height: AppSpacing.md),
        point(
          Icons.sms_outlined,
          l10n.smsImportEnableWhatIsReadTitle,
          l10n.smsImportEnableWhatIsRead,
        ),
        point(
          Icons.shield_outlined,
          l10n.smsImportEnableNeverTitle,
          l10n.smsImportEnableNever,
        ),
        point(
          Icons.toggle_off_outlined,
          l10n.smsImportEnableTurnOffTitle,
          l10n.smsImportEnableTurnOff,
        ),
      ],
    );
  }
}

/// One permission outcome: explanation, the next action, and the
/// paste/share fallback, which is always visible (FR-012, FR-072).
class _PermissionStep extends StatelessWidget {
  const _PermissionStep({
    required this.stepKey,
    required this.title,
    required this.body,
    required this.onPaste,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String stepKey;
  final String title;
  final Widget body;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      key: ValueKey('sms_enable_step_$stepKey'),
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        Semantics(header: true, child: Text(title, style: AppTypography.title)),
        const SizedBox(height: AppSpacing.sm),
        body,
        const SizedBox(height: AppSpacing.lg),
        if (primaryLabel != null) ...[
          AppButton(label: primaryLabel!, onPressed: onPrimary),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (secondaryLabel != null) ...[
          AppSecondaryButton(label: secondaryLabel!, onPressed: onSecondary),
          const SizedBox(height: AppSpacing.sm),
        ],
        AppSecondaryButton(
          label: l10n.smsImportPermissionPasteInstead,
          onPressed: onPaste,
        ),
      ],
    );
  }
}
