import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../domain/entities/app_lock_config.dart';
import '../../domain/entities/app_lock_failures.dart';
import '../../domain/entities/lockout_state.dart';
import '../cubit/app_lock_settings_cubit.dart';
import '../cubit/app_lock_settings_state.dart';
import '../widgets/unlock_method_toggle_tile.dart';
import 'pin_setup_page.dart';

/// Settings → Security (User Story 6): App Lock on/off, biometric unlock,
/// the inactivity timeout and Change PIN, plus a read-only note that
/// screenshot protection is always on (FR-020 — deliberately not a toggle).
class SecuritySettingsPage extends StatelessWidget {
  const SecuritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AppLockSettingsCubit>(
      create: (_) => getIt<AppLockSettingsCubit>()..load(),
      child: const _SecuritySettingsView(),
    );
  }
}

class _SecuritySettingsView extends StatelessWidget {
  const _SecuritySettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.securitySettingsTitle)),
      body: BlocConsumer<AppLockSettingsCubit, AppLockSettingsState>(
        listenWhen: (previous, current) =>
            current.outcome != null ||
            (current.failure != null && previous.failure != current.failure),
        listener: _showResult,
        builder: (context, state) {
          switch (state.status) {
            case AppLockSettingsStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case AppLockSettingsStatus.loadFailure:
              return _LoadFailure(
                onRetry: () => context.read<AppLockSettingsCubit>().load(),
              );
            case AppLockSettingsStatus.ready:
            case AppLockSettingsStatus.submitting:
              return _SecuritySettingsList(state: state);
          }
        },
      ),
    );
  }

  void _showResult(BuildContext context, AppLockSettingsState state) {
    final l10n = AppLocalizations.of(context)!;
    final message = switch (state.outcome) {
      AppLockSettingsOutcome.enabled => l10n.appLockSettingsEnabledMessage,
      AppLockSettingsOutcome.disabled => l10n.appLockSettingsDisabledMessage,
      AppLockSettingsOutcome.pinChanged =>
        l10n.appLockSettingsPinChangedMessage,
      null =>
        state.failure is BiometricUnavailableFailure
            ? l10n.appLockSettingsBiometricUnavailable
            : l10n.appLockSettingsSaveFailed,
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SecuritySettingsList extends StatelessWidget {
  const _SecuritySettingsList({required this.state});

  final AppLockSettingsState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AppLockSettingsCubit>();
    final enabled = state.isEnabled;
    final interactive = !state.isSubmitting;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _SecuritySection(
          icon: Icons.lock_outline,
          title: l10n.appLockSettingsSectionTitle,
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.pin_outlined),
                title: Text(l10n.appLockSettingsToggleTitle),
                subtitle: Text(l10n.appLockSettingsToggleSubtitle),
                value: enabled,
                onChanged: interactive
                    ? (on) => on ? _enable(context) : _disable(context)
                    : null,
              ),
              if (enabled) ...[
                const Divider(height: 1, indent: AppSpacing.md),
                UnlockMethodToggleTile(
                  icon: Icons.fingerprint,
                  title: l10n.appLockSettingsBiometricTitle,
                  subtitle: l10n.appLockSettingsBiometricSubtitle,
                  unavailableMessage: l10n.appLockSettingsBiometricUnavailable,
                  isAvailable: state.isBiometricAvailable,
                  value: state.config.isBiometricEnabled,
                  onChanged: interactive ? cubit.setBiometricEnabled : null,
                ),
                const Divider(height: 1, indent: AppSpacing.md),
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: Text(l10n.appLockSettingsChangePinTile),
                  trailing: const Icon(Icons.chevron_right),
                  enabled: interactive,
                  onTap: () => _changePin(context),
                ),
              ],
            ],
          ),
        ),
        if (enabled) ...[
          const SizedBox(height: AppSpacing.lg),
          _SecuritySection(
            icon: Icons.timer_outlined,
            title: l10n.appLockSettingsTimeoutTitle,
            child: RadioGroup<InactivityTimeout>(
              groupValue: state.config.inactivityTimeout,
              onChanged: (timeout) => timeout == null || !interactive
                  ? null
                  : cubit.setInactivityTimeout(timeout),
              child: Column(
                children: [
                  for (final timeout in InactivityTimeout.values) ...[
                    if (timeout != InactivityTimeout.values.first)
                      const Divider(height: 1, indent: AppSpacing.md),
                    RadioListTile<InactivityTimeout>(
                      title: Text(_timeoutLabel(l10n, timeout)),
                      value: timeout,
                      enabled: interactive,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        _SecuritySection(
          icon: Icons.screenshot_monitor_outlined,
          title: l10n.appLockSettingsScreenshotProtectionTitle,
          child: ListTile(
            leading: const Icon(Icons.visibility_off_outlined),
            title: Text(l10n.appLockSettingsScreenshotProtectionStatus),
            subtitle: Text(l10n.appLockSettingsScreenshotProtectionBody),
          ),
        ),
      ],
    );
  }

  static String _timeoutLabel(
    AppLocalizations l10n,
    InactivityTimeout timeout,
  ) => switch (timeout) {
    InactivityTimeout.immediately => l10n.appLockSettingsTimeoutImmediately,
    InactivityTimeout.after30s => l10n.appLockSettingsTimeout30Seconds,
    InactivityTimeout.after1min => l10n.appLockSettingsTimeout1Minute,
    InactivityTimeout.after5min => l10n.appLockSettingsTimeout5Minutes,
  };

  /// FR-002/FR-027: a fresh PIN is set before App Lock turns on — always,
  /// after a disable, since disabling deletes the old one.
  Future<void> _enable(BuildContext context) async {
    final cubit = context.read<AppLockSettingsCubit>();
    if (cubit.needsPinSetup) {
      final pinSet = await _pushPinSetup(context, PinSetupMode.initialSetup);
      if (pinSet != true) return;
    }
    await cubit.enableAfterPinSetup();
  }

  /// FR-023: `PinSetupPage` re-authenticates with the current PIN or
  /// biometrics itself before accepting a new PIN.
  Future<void> _changePin(BuildContext context) async {
    final cubit = context.read<AppLockSettingsCubit>();
    final changed = await _pushPinSetup(context, PinSetupMode.change);
    if (changed == true) await cubit.pinChanged();
  }

  /// FR-026: confirm, then re-authenticate (biometric first when enabled,
  /// otherwise — or if that is declined — the current PIN), then disable.
  Future<void> _disable(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<AppLockSettingsCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.appLockSettingsDisableTitle,
      message: l10n.appLockSettingsDisableMessage,
      confirmLabel: l10n.appLockSettingsDisableConfirm,
      isDestructive: true,
    );
    if (!confirmed || !context.mounted) return;
    var authenticated = await cubit.reauthenticateWithBiometric(
      localizedReason: l10n.appLockSettingsBiometricReason,
    );
    if (!authenticated && context.mounted) {
      authenticated =
          await showDialog<bool>(
            context: context,
            builder: (_) => BlocProvider.value(
              value: cubit,
              child: const _PinReauthDialog(),
            ),
          ) ??
          false;
    }
    if (!authenticated) {
      cubit.cancelReauthentication();
      return;
    }
    await cubit.disable();
  }

  Future<bool?> _pushPinSetup(BuildContext context, PinSetupMode mode) {
    // Above the bottom navigation, like every other full-screen flow.
    return Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        fullscreenDialog: true,
        builder: (_) => PinSetupPage(mode: mode),
      ),
    );
  }
}

/// Asks for the current PIN before App Lock is disabled (FR-026). A wrong
/// PIN counts toward the lockout like one on the lock screen, and an active
/// cooldown is explained rather than silently ignored (FR-013).
class _PinReauthDialog extends StatefulWidget {
  const _PinReauthDialog();

  @override
  State<_PinReauthDialog> createState() => _PinReauthDialogState();
}

class _PinReauthDialogState extends State<_PinReauthDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text;
    if (_checking || pin.length < 4) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _checking = true);
    final attempt = await context
        .read<AppLockSettingsCubit>()
        .reauthenticateWithPin(pin);
    if (!mounted) return;
    if (attempt?.isSuccess ?? false) {
      Navigator.of(context).pop(true);
      return;
    }
    _controller.clear();
    setState(() {
      _checking = false;
      _error = switch (attempt?.outcome) {
        UnlockOutcome.incorrectPin => l10n.appLockSettingsReauthIncorrect,
        UnlockOutcome.lockedOut => l10n.appLockSettingsReauthLockedOut(
          _formatCooldown(attempt!.remainingCooldown ?? Duration.zero),
        ),
        _ => l10n.appLockSettingsReauthFailed,
      };
    });
  }

  /// `m:ss`, rounded up so a cooldown never reads as `0:00` while active.
  static String _formatCooldown(Duration remaining) {
    final seconds = (remaining.inMilliseconds / 1000).ceil();
    final minutes = seconds ~/ 60;
    return '$minutes:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.appLockSettingsReauthTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.appLockSettingsReauthMessage),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            autofocus: true,
            obscureText: true,
            enabled: !_checking,
            keyboardType: TextInputType.number,
            maxLength: 6,
            // PINs are ASCII digits regardless of the UI locale.
            textDirection: TextDirection.ltr,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: l10n.appLockSettingsReauthPinLabel,
              errorText: _error,
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _checking ? null : _submit,
          child: Text(l10n.appLockSettingsReauthConfirm),
        ),
      ],
    );
  }
}

class _LoadFailure extends StatelessWidget {
  const _LoadFailure({required this.onRetry});

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
            Text(l10n.appLockSettingsLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// Same titled, icon-led [AppCard] grouping as the main Settings page.
class _SecuritySection extends StatelessWidget {
  const _SecuritySection({
    required this.icon,
    required this.title,
    required this.child,
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
          padding: const EdgeInsets.only(
            bottom: AppSpacing.xs,
            left: AppSpacing.xs,
            right: AppSpacing.xs,
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.label.copyWith(color: onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        AppCard(padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}
