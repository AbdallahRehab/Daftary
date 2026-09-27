import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/notification_settings_cubit.dart';
import '../cubit/notification_settings_state.dart';
import '../widgets/notification_category_toggle_tile.dart';
import '../widgets/permission_denied_banner.dart';
import '../widgets/quiet_hours_range_picker.dart';

/// Route path for this screen, kept beside the page (reached from a
/// Settings row, spec.md Assumptions "Navigation placement").
abstract final class NotificationSettingsRoutes {
  static const String settings = '/settings/notifications';
}

/// Opens the device's notification settings for this app (FR-012).
Future<void> openDeviceNotificationSettings() =>
    AppSettings.openAppSettings(type: AppSettingsType.notification);

/// The notification settings screen (US3). Provides its own
/// [NotificationSettingsCubit] and loads it; [NotificationSettingsView]
/// renders against whichever cubit is in scope.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NotificationSettingsCubit>()..load(),
      child: const NotificationSettingsView(),
    );
  }
}

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({
    super.key,
    this.onOpenDeviceSettings = openDeviceNotificationSettings,
  });

  /// Overridable so tests never reach the platform channel.
  final Future<void> Function() onOpenDeviceSettings;

  @override
  State<NotificationSettingsView> createState() =>
      _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Returning from device settings may have granted or revoked permission
  /// (FR-012) — re-check live, never prompting.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationSettingsCubit>().refreshPermission();
    }
  }

  /// FR-011: the OS prompt appears only after the user has turned the
  /// feature on and read why the permission is needed.
  Future<void> _onMasterChanged(
    BuildContext context,
    NotificationSettingsState state,
    bool enabled,
  ) async {
    final cubit = context.read<NotificationSettingsCubit>();
    if (enabled && !state.preference.osPermissionGranted) {
      final l10n = AppLocalizations.of(context)!;
      final confirmed = await showAppConfirmDialog(
        context,
        title: l10n.notificationPermissionRationaleTitle,
        message: l10n.notificationPermissionRationaleMessage,
        confirmLabel: l10n.notificationPermissionRationaleConfirm,
      );
      if (!confirmed) return;
    }
    await cubit.setEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.notificationSettingsTitle)),
      body: BlocConsumer<NotificationSettingsCubit, NotificationSettingsState>(
        listenWhen: (previous, current) =>
            !previous.isSaveFailing && current.isSaveFailing,
        listener: (context, state) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(l10n.notificationSettingsSaveFailed)),
            );
        },
        builder: (context, state) => switch (state.status) {
          NotificationSettingsStatus.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          NotificationSettingsStatus.loadFailure => _LoadFailureView(
            onRetry: () => context.read<NotificationSettingsCubit>().load(),
          ),
          NotificationSettingsStatus.ready => _buildReady(context, state),
        },
      ),
    );
  }

  Widget _buildReady(BuildContext context, NotificationSettingsState state) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<NotificationSettingsCubit>();
    final preference = state.preference;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md) + AppGlassInsets.of(context),
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            key: const Key('notification_master_switch'),
            value: preference.isEnabled,
            onChanged: state.isRequestingPermission
                ? null
                : (enabled) => _onMasterChanged(context, state, enabled),
            secondary: Icon(
              Icons.notifications_active_outlined,
              color: colorScheme.primary,
            ),
            title: Text(
              l10n.notificationSettingsMasterTitle,
              style: AppTypography.title,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                preference.isEnabled
                    ? l10n.notificationSettingsMasterOnDescription
                    : l10n.notificationSettingsMasterOffDescription,
                style: AppTypography.bodyMuted.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        if (state.showPermissionDeniedBanner) ...[
          const SizedBox(height: AppSpacing.md),
          PermissionDeniedBanner(onOpenSettings: widget.onOpenDeviceSettings),
        ],
        if (preference.isEnabled) ...[
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(title: l10n.notificationSettingsCategoriesHeader),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                NotificationCategoryToggleTile(
                  key: const Key('notification_budget_warnings_toggle'),
                  icon: Icons.account_balance_wallet_outlined,
                  title: l10n.notificationBudgetWarningsTitle,
                  description: l10n.notificationBudgetWarningsSubtitle,
                  value: preference.budgetWarningsEnabled,
                  onChanged: cubit.setBudgetWarningsEnabled,
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                NotificationCategoryToggleTile(
                  key: const Key('notification_savings_check_ins_toggle'),
                  icon: Icons.savings_outlined,
                  title: l10n.notificationSavingsCheckInsTitle,
                  description: l10n.notificationSavingsCheckInsSubtitle,
                  value: preference.savingsCheckInsEnabled,
                  onChanged: cubit.setSavingsCheckInsEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionLabel(title: l10n.notificationQuietHoursTitle),
          AppCard(
            padding: EdgeInsets.zero,
            child: QuietHoursRangePicker(
              start: preference.quietHoursStart,
              end: preference.quietHoursEnd,
              suggestedStart:
                  NotificationSettingsCubit.suggestedQuietHoursStart,
              suggestedEnd: NotificationSettingsCubit.suggestedQuietHoursEnd,
              onEnabledChanged: cubit.setQuietHoursEnabled,
              onRangeChanged: (start, end) =>
                  cubit.setQuietHours(start: start, end: end),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.xs,
        end: AppSpacing.xs,
        bottom: AppSpacing.xs,
      ),
      child: Text(
        title,
        style: AppTypography.label.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LoadFailureView extends StatelessWidget {
  const _LoadFailureView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.notificationSettingsLoadFailed,
              textAlign: TextAlign.center,
              style: AppTypography.body,
            ),
            const SizedBox(height: AppSpacing.md),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
