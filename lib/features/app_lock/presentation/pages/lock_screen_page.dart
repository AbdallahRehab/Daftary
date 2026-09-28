import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/security/app_lifecycle_observer.dart';
import '../cubit/lock_screen_cubit.dart';
import '../cubit/lock_screen_state.dart';
import 'forgot_pin_page.dart';
import '../widgets/lockout_countdown_banner.dart';
import '../widgets/pin_pad.dart';

/// The full-screen lock overlay shown by `core/security/AppLockGate` while
/// the app is locked (wired in `main.dart`'s `MaterialApp.router` builder,
/// research.md Decision 5) — not a go_router route, and not dismissible:
/// the only ways out are a correct PIN or a successful biometric check,
/// which call `AppLifecycleObserver.unlock()`.
///
/// The gate builds a fresh page (and so a fresh [LockScreenCubit]) every
/// time the app locks, so each lock re-reads the configuration, lockout
/// state and biometric availability, and auto-prompts biometrics again.
class LockScreenPage extends StatelessWidget {
  const LockScreenPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LockScreenCubit>(),
      child: const _LockScreenView(),
    );
  }
}

class _LockScreenView extends StatefulWidget {
  const _LockScreenView();

  @override
  State<_LockScreenView> createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<_LockScreenView> {
  late final AppLifecycleListener _lifecycle;
  bool _started = false;

  /// The biometric prompt is owed as soon as the app is in the foreground:
  /// the app often locks while it is still in the background (timeout
  /// "Immediately", or the inactivity timer firing), where no OS prompt can
  /// be shown.
  bool _promptOnResume = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      // Truly backgrounded (not just a system dialog or the biometric
      // prompt itself, which only make the app `inactive`): prompt again on
      // return, without looping on a cancelled prompt.
      onHide: () => _promptOnResume = true,
      onResume: () {
        if (!_promptOnResume) return;
        _promptOnResume = false;
        context.read<LockScreenCubit>().promptBiometricIfAvailable();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    final inForeground =
        lifecycleState == null || lifecycleState == AppLifecycleState.resumed;
    _promptOnResume = !inForeground;
    context.read<LockScreenCubit>().start(
      biometricReason: AppLocalizations.of(context)!.appLockLockBiometricReason,
      promptBiometric: inForeground,
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LockScreenCubit, LockScreenState>(
      listenWhen: (previous, current) =>
          !previous.isUnlocked && current.isUnlocked,
      listener: (context, _) => getIt<AppLifecycleObserver>().unlock(),
      builder: (context, state) {
        // Belt and braces with AppLockGate's back-button interception: the
        // lock screen itself can never be popped.
        return PopScope(
          canPop: false,
          // A plain Scaffold on purpose, never Liquid Glass (020): like onboarding,
          // the lock overlay (lock screen, Forgot PIN, wipe) is a full-screen
          // security flow above the router, and must stay maximally legible and
          // render-safe whatever the user's glass preference.
          child: Scaffold(
            body: SafeArea(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _LockScreenBody(state: state),
            ),
          ),
        );
      },
    );
  }
}

class _LockScreenBody extends StatelessWidget {
  const _LockScreenBody({required this.state});

  final LockScreenState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<LockScreenCubit>();
    final cooldown = state.cooldownRemaining;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.lg,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(
                  Icons.lock_outline,
                  size: 32,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Semantics(
                header: true,
                child: Text(
                  l10n.appLockLockTitle,
                  style: AppTypography.headline,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.appLockLockPrompt,
                style: AppTypography.body.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _StatusLine(state: state),
              if (cooldown != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LockoutCountdownBanner(
                  remaining: cooldown,
                  biometricStillAvailable: state.canUseBiometric,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinPad(
                enabled: state.isPinEntryEnabled,
                onSubmitted: cubit.submitPin,
              ),
              if (state.canUseBiometric) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton.icon(
                  key: const Key('lock_screen.biometric'),
                  onPressed: state.isVerifyingBiometric || state.isUnlocked
                      ? null
                      : cubit.authenticateWithBiometric,
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.appLockLockUseBiometric),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                key: const Key('lock_screen.forgot_pin'),
                onPressed: state.isUnlocked
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ForgotPinPage(),
                        ),
                      ),
                child: Text(l10n.appLockForgotTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The single line of feedback under the prompt: an error after a failed
/// attempt, "checking…" while a PIN is verified, or the biometric-pending
/// hint. Announced to screen readers as it changes.
class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.state});

  final LockScreenState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final (String? text, bool isError) = switch (state) {
      LockScreenState(status: LockScreenStatus.verifyingPin) => (
        l10n.appLockLockVerifying,
        false,
      ),
      LockScreenState(message: final message?) => (
        switch (message) {
          LockScreenMessage.incorrectPin => l10n.appLockLockIncorrectPin,
          LockScreenMessage.biometricFailed => l10n.appLockLockBiometricFailed,
          LockScreenMessage.biometricUnavailable =>
            l10n.appLockLockBiometricUnavailable,
          LockScreenMessage.unexpected => l10n.appLockLockUnexpectedError,
        },
        true,
      ),
      LockScreenState(status: LockScreenStatus.verifyingBiometric) => (
        l10n.appLockLockBiometricInProgress,
        false,
      ),
      _ => (null, false),
    };

    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: text == null
            ? const SizedBox.shrink()
            : Text(
                text,
                key: const Key('lock_screen.status'),
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: isError
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }
}
