import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/security/app_lifecycle_observer.dart';
import '../cubit/forgot_pin_cubit.dart';
import '../cubit/forgot_pin_state.dart';
import 'pin_setup_page.dart';
import 'wipe_confirmation_page.dart';

/// The Forgot-PIN entry point (015 US4), pushed from the lock screen inside
/// `AppLockGate`'s own Navigator.
///
/// Offers exactly the two recoveries that can honestly exist on a device
/// with no account or server (FR-017/FR-018):
/// - biometric re-authentication first, when enabled and available — on
///   success the user sets a new PIN via `PinSetupPage(mode: reset)` and
///   the lock screen is dismissed with every piece of data untouched;
/// - otherwise, a plain explanation that erasing this device's data is the
///   only way back in, leading to [WipeConfirmationPage].
///
/// Backing out (app-bar back, "Back to lock screen") returns to the lock
/// screen and never changes anything.
class ForgotPinPage extends StatelessWidget {
  const ForgotPinPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ForgotPinCubit>()..initialize(),
      child: const _ForgotPinView(),
    );
  }
}

class _ForgotPinView extends StatelessWidget {
  const _ForgotPinView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocListener<ForgotPinCubit, ForgotPinState>(
      listenWhen: (previous, current) =>
          previous.biometricStatus != BiometricRecoveryStatus.verified &&
          current.biometricStatus == BiometricRecoveryStatus.verified,
      listener: (context, _) => _setNewPin(context),
      // A plain Scaffold on purpose, never Liquid Glass (020): like onboarding,
      // the lock overlay (lock screen, Forgot PIN, wipe) is a full-screen
      // security flow above the router, and must stay maximally legible and
      // render-safe whatever the user's glass preference.
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.appLockForgotTitle)),
        body: SafeArea(
          child: BlocBuilder<ForgotPinCubit, ForgotPinState>(
            buildWhen: (previous, current) =>
                previous.step != current.step ||
                previous.biometricStatus != current.biometricStatus,
            builder: (context, state) => switch (state.step) {
              ForgotPinStep.resolving => const Center(
                child: CircularProgressIndicator(),
              ),
              ForgotPinStep.biometricRecovery => _BiometricRecoveryBody(
                state: state,
              ),
              ForgotPinStep.wipeExplanation ||
              ForgotPinStep.wipeConfirmation => const _WipeExplanationBody(),
            },
          ),
        ),
      ),
    );
  }

  /// Biometric recovery succeeded: set the new PIN, then unlock. Backing
  /// out of PIN setup unlocks nothing and requires a fresh biometric check.
  Future<void> _setNewPin(BuildContext context) async {
    final cubit = context.read<ForgotPinCubit>();
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const PinSetupPage(mode: PinSetupMode.reset),
      ),
    );
    if (saved == true) {
      getIt<AppLifecycleObserver>().unlock();
    } else {
      cubit.pinResetAbandoned();
    }
  }
}

class _BiometricRecoveryBody extends StatelessWidget {
  const _BiometricRecoveryBody({required this.state});

  final ForgotPinState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ForgotPinCubit>();
    final colorScheme = Theme.of(context).colorScheme;
    final failed = state.biometricStatus == BiometricRecoveryStatus.failed;
    final busy =
        state.isAuthenticating ||
        state.biometricStatus == BiometricRecoveryStatus.verified;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.fingerprint, size: 64, color: colorScheme.primary),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appLockForgotBiometricTitle,
          style: AppTypography.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.appLockForgotBiometricMessage,
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        if (failed) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(
              l10n.appLockForgotBiometricFailed,
              style: AppTypography.body.copyWith(color: colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        AppButton(
          label: failed
              ? l10n.appLockForgotBiometricRetry
              : l10n.appLockForgotBiometricAction,
          icon: Icons.fingerprint,
          isLoading: busy,
          onPressed: () => cubit.recoverWithBiometric(
            localizedReason: l10n.appLockForgotBiometricReason,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // The one alternative — never presented as anything but a wipe.
        TextButton(
          onPressed: busy ? null : cubit.chooseWipe,
          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
          child: Text(l10n.appLockForgotChooseWipeAction),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: l10n.appLockForgotBackAction,
          onPressed: busy ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }
}

class _WipeExplanationBody extends StatelessWidget {
  const _WipeExplanationBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const SizedBox(height: AppSpacing.lg),
        Icon(Icons.lock_reset, size: 64, color: colorScheme.error),
        const SizedBox(height: AppSpacing.md),
        Text(
          l10n.appLockForgotWipeTitle,
          style: AppTypography.title,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          l10n.appLockForgotWipeMessage,
          style: AppTypography.body,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () => _openConfirmation(context),
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            child: Text(l10n.appLockForgotWipeContinueAction),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: l10n.appLockForgotBackAction,
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ],
    );
  }

  Future<void> _openConfirmation(BuildContext context) async {
    final cubit = context.read<ForgotPinCubit>()..proceedToWipeConfirmation();
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cubit,
          child: const WipeConfirmationPage(),
        ),
      ),
    );
    // Back from the confirmation without wiping: discard the typed phrase.
    // A no-op after a successful wipe (the gate is gone by then anyway).
    cubit.cancelWipeConfirmation();
  }
}
