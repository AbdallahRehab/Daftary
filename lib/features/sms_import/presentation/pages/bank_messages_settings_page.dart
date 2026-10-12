import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
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
import '../../domain/entities/sms_permission_status.dart';
import '../cubit/bank_messages_settings_cubit.dart';
import '../cubit/bank_messages_settings_state.dart';
import '../routes.dart';
import '../widgets/sms_import_labels.dart';
import '../widgets/sms_permission_banner.dart';
import 'enable_bank_messages_page.dart';

/// Settings -> Bank messages (T121, ui-contract §3.1).
///
/// - Shown on every platform: paste works everywhere. The Status and Scan
///   rows (and every mention of the SMS permission) exist only when the
///   SMS capability is available (CHK013, CHK036).
/// - Nothing here prompts: "Turn on" and "Allow" open the enable flow
///   (FR-002).
/// - Counts are content-free (FR-102).
class BankMessagesSettingsPage extends StatelessWidget {
  const BankMessagesSettingsPage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final BankMessagesSettingsCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<BankMessagesSettingsCubit>())..open(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Revocation (or a grant in App info) is reflected on resume,
    // prompt-free (FR-070, ui-contract §9).
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          context.read<BankMessagesSettingsCubit>().refreshPermission(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportSettingsTitle)),
      body: SafeArea(
        top: false,
        child:
            BlocConsumer<BankMessagesSettingsCubit, BankMessagesSettingsState>(
              listenWhen: (a, b) =>
                  (!a.saveFailed && b.saveFailed) ||
                  (!a.turnedOff && b.turnedOff),
              listener: (context, state) {
                final cubit = context.read<BankMessagesSettingsCubit>();
                final String message;
                if (state.turnedOff) {
                  message = switch (state.deletedPendingCount) {
                    null => l10n.smsImportSettingsTurnedOffKept,
                    final count => l10n.smsImportSettingsTurnedOffDeleted(
                      count,
                    ),
                  };
                  cubit.turnedOffShown();
                } else {
                  message = l10n.smsImportSettingsSaveFailed;
                  cubit.saveFailureShown();
                }
                SemanticsService.sendAnnouncement(
                  View.of(context),
                  message,
                  Directionality.of(context),
                );
                ScaffoldMessenger.maybeOf(context)
                  ?..hideCurrentSnackBar()
                  ..showSnackBar(SnackBar(content: Text(message)));
              },
              builder: (context, state) => switch (state.status) {
                BankMessagesSettingsStatus.initial ||
                BankMessagesSettingsStatus.loading => const _Skeleton(),
                BankMessagesSettingsStatus.error => AppEmptyView(
                  title: l10n.smsImportSettingsLoadErrorTitle,
                  message: l10n.messageFor(state.failure),
                  icon: Icons.error_outline,
                  actionLabel: l10n.smsImportSettingsRetry,
                  onAction: context.read<BankMessagesSettingsCubit>().retry,
                ),
                BankMessagesSettingsStatus.ready => _Ready(state: state),
              },
            ),
      ),
    );
  }
}

class _Ready extends StatelessWidget {
  const _Ready({required this.state});

  final BankMessagesSettingsState state;

  Future<void> _openEnable(BuildContext context) async {
    final cubit = context.read<BankMessagesSettingsCubit>();
    await context.push(BankMessagesRoutes.enable);
    await cubit.refreshPermission();
  }

  void _paste(BuildContext context) => context.push(BankMessagesRoutes.paste);

  /// "Turn off" (FR-078, ui-contract §3.1): asks whether to also delete
  /// the pending items. Keeping them is the default, also when the dialog
  /// is dismissed; deleting needs the explicit destructive choice.
  Future<void> _turnOff(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BankMessagesSettingsCubit>();
    final delete = await showAppConfirmDialog(
      context,
      title: l10n.smsImportSettingsTurnOffTitle,
      message: l10n.smsImportSettingsTurnOffMessage,
      confirmLabel: l10n.smsImportSettingsTurnOffDelete,
      cancelLabel: l10n.smsImportSettingsTurnOffKeep,
      isDestructive: true,
    );
    await cubit.turnOff(deletePending: delete);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<BankMessagesSettingsCubit>();
    final scheme = Theme.of(context).colorScheme;
    final settings = state.settings;
    final counts = state.counts;
    return ListView(
      key: const ValueKey('sms_settings_ready'),
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        if (state.capabilityAvailable) ...[
          _Section(
            key: const ValueKey('sms_settings_status_section'),
            icon: Icons.sms_outlined,
            title: l10n.smsImportSettingsStatusTitle,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A Wrap, so the chip moves under the label at large
                  // text sizes instead of overflowing.
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      Text(
                        l10n.smsImportSettingsTitle,
                        style: AppTypography.body,
                      ),
                      Chip(
                        key: const ValueKey('sms_settings_status_chip'),
                        label: Text(
                          l10n.smsImportSettingsStatusLabel(
                            state.statusLabel.name,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!state.isEnabled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      key: const ValueKey('sms_settings_turn_on'),
                      label: l10n.smsImportSettingsTurnOn,
                      onPressed: () => _openEnable(context),
                    ),
                  ] else ...[
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      key: const ValueKey('sms_settings_turn_off'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(
                          AppSizes.minTouchTarget,
                        ),
                      ),
                      onPressed: state.submitting == null
                          ? () => _turnOff(context)
                          : null,
                      icon:
                          state.submitting ==
                              BankMessagesSettingsControl.turnOff
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.power_settings_new),
                      label: Text(l10n.smsImportSettingsTurnOff),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_bannerStatus(state) case final status?) ...[
            const SizedBox(height: AppSpacing.sm),
            SmsPermissionBanner(
              status: status,
              onPaste: () => _paste(context),
              onAllow: () => _openEnable(context),
              onOpenAppInfo: cubit.openAppInfo,
              onShowMeHow: () => showRestrictedGuidanceSheet(
                context,
                onOpenAppInfo: cubit.openAppInfo,
                onPaste: () => _paste(context),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
        ],
        if (state.showScanSection) ...[
          _Section(
            key: const ValueKey('sms_settings_scan_section'),
            icon: Icons.search,
            title: l10n.smsImportSettingsScanTitle,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.smsImportSettingsWindowTitle,
                    style: AppTypography.body,
                  ),
                  ScanWindowSelector(
                    value: settings.scanWindow,
                    enabled:
                        state.submitting != BankMessagesSettingsControl.window,
                    onChanged: cubit.setWindow,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    key: const ValueKey('sms_settings_scan_now'),
                    label: l10n.smsImportScanNow,
                    icon: Icons.search,
                    onPressed: () => context.push(BankMessagesRoutes.hubScan),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    settings.lastScanAt == null
                        ? l10n.smsImportSettingsNeverScanned
                        : l10n.smsImportSettingsLastScan(
                            SmsImportLabels.date(context, settings.lastScanAt!),
                          ),
                    style: AppTypography.bodyMuted.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.smsImportSettingsCountsTitle,
                    style: AppTypography.body,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  for (final line in [
                    l10n.smsImportSettingsCountScanned(counts.scanned),
                    l10n.smsImportSettingsCountRecognized(counts.recognized),
                    l10n.smsImportSettingsCountAdded(counts.added),
                    l10n.smsImportSettingsCountIgnored(counts.ignored),
                  ])
                    Text(
                      line,
                      style: AppTypography.bodyMuted.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        _Section(
          key: const ValueKey('sms_settings_preferences_section'),
          icon: Icons.tune,
          title: l10n.smsImportSettingsPreferencesTitle,
          child: SwitchListTile(
            key: const ValueKey('sms_settings_count_cash'),
            title: Text(l10n.smsImportSettingsCountCash),
            subtitle: Text(l10n.smsImportSettingsCountCashHelp),
            value: settings.countCashWithdrawals,
            onChanged: state.submitting == BankMessagesSettingsControl.countCash
                ? null
                : cubit.setCountCashWithdrawals,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          key: const ValueKey('sms_settings_manage_section'),
          icon: Icons.folder_open_outlined,
          title: l10n.smsImportSettingsManageTitle,
          child: Column(
            children: [
              // The lasting way back to the pending list on every
              // platform, paste-only ones included (CHK036).
              ListTile(
                key: const ValueKey('sms_settings_pending'),
                leading: const Icon(Icons.inbox_outlined),
                title: Text(l10n.smsImportSettingsPending),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(BankMessagesRoutes.hub),
              ),
              ListTile(
                key: const ValueKey('sms_settings_paste'),
                leading: const Icon(Icons.content_paste_outlined),
                title: Text(l10n.smsImportPasteTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _paste(context),
              ),
              ListTile(
                key: const ValueKey('sms_settings_ignored'),
                leading: const Icon(Icons.visibility_off_outlined),
                title: Text(l10n.smsImportIgnoredTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(BankMessagesRoutes.ignored),
              ),
              ListTile(
                key: const ValueKey('sms_settings_muted'),
                leading: const Icon(Icons.notifications_off_outlined),
                title: Text(l10n.smsImportMuteTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(BankMessagesRoutes.senders),
              ),
              ListTile(
                key: const ValueKey('sms_settings_learned'),
                leading: const Icon(Icons.school_outlined),
                title: Text(l10n.smsImportMappingsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(BankMessagesRoutes.learned),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _Section(
          icon: Icons.lock_outline,
          title: l10n.smsImportSettingsPrivacyTitle,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppSpacing.md),
            child: Text(
              l10n.smsImportSettingsPrivacyText,
              style: AppTypography.body,
            ),
          ),
        ),
      ],
    );
  }

  /// The banner in Settings: the feature is on but the permission is not
  /// usable, or the permission is blocked (ui-contract §3.1, §3.7).
  static SmsPermissionStatus? _bannerStatus(BankMessagesSettingsState state) {
    final label = state.statusLabel;
    if (label == SmsImportStatusLabel.permissionOff ||
        label == SmsImportStatusLabel.blocked) {
      return state.permission;
    }
    return null;
  }
}

/// A titled group sharing one [AppCard], in the style of the main
/// Settings page.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
    super.key,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.xs,
            start: AppSpacing.xs,
            end: AppSpacing.xs,
          ),
          child: Semantics(
            header: true,
            child: Row(
              children: [
                Icon(icon, size: 18, color: onSurfaceVariant),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.label.copyWith(
                      color: onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AppCard(padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}

/// Skeleton rows from `AppCard`; no spinner-only screen.
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ExcludeSemantics(
      child: ListView(
        key: const ValueKey('sms_settings_skeleton'),
        padding:
            const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
              child: AppCard(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
