import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/pin_setup_cubit.dart';
import '../cubit/pin_setup_state.dart';
import '../widgets/lockout_countdown_banner.dart';
import '../widgets/pin_pad.dart';

export '../cubit/pin_setup_state.dart' show PinSetupMode;

/// Sets, changes, or resets the App Lock PIN — enter it, then enter it
/// again to confirm (FR-002/FR-023). Push it with a plain `Navigator` push
/// (or `context.push`) and await the result:
///
/// - [PinSetupMode.initialSetup]: stores the first PIN (`SetPin`). Does NOT
///   enable App Lock — the caller runs `EnableAppLock` on `true`.
/// - [PinSetupMode.change]: first re-authenticates with the current PIN
///   (with the usual lockout rules) or biometrics, then `ChangePin`.
/// - [PinSetupMode.reset]: the caller already re-authenticated (Forgot PIN
///   via biometrics); goes straight to entering the new PIN -> `ChangePin`.
///
/// Pops `true` once the PIN is saved; `false` (close button) or `null`
/// (system back) when cancelled. Provides its own [PinSetupCubit].
class PinSetupPage extends StatelessWidget {
  const PinSetupPage({super.key, required this.mode});

  final PinSetupMode mode;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PinSetupCubit>(param1: mode)..start(),
      child: const _PinSetupView(),
    );
  }
}

class _PinSetupView extends StatelessWidget {
  const _PinSetupView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<PinSetupCubit>();

    return BlocConsumer<PinSetupCubit, PinSetupState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (context, _) => Navigator.of(context).pop(true),
      builder: (context, state) {
        final isConfirming = state.step == PinSetupStep.confirmNew;
        final locked = state.isBusy || state.isSuccess;
        return PopScope(
          // Back from the confirmation goes back to choosing the PIN rather
          // than abandoning the flow; nothing leaves mid-save.
          canPop: !locked && !isConfirming,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !locked && isConfirming) cubit.startOver();
          },
          child: Scaffold(
            appBar: AppBar(
              title: Text(switch (state.mode) {
                PinSetupMode.initialSetup => l10n.appLockPinSetupTitle,
                PinSetupMode.change => l10n.appLockPinChangeTitle,
                PinSetupMode.reset => l10n.appLockPinResetTitle,
              }),
              leading: IconButton(
                key: const Key('pin_setup.close'),
                icon: const Icon(Icons.close),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: locked
                    ? null
                    : () => Navigator.of(context).pop(false),
              ),
            ),
            body: SafeArea(child: _PinSetupBody(state: state)),
          ),
        );
      },
    );
  }
}

class _PinSetupBody extends StatelessWidget {
  const _PinSetupBody({required this.state});

  final PinSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<PinSetupCubit>();
    final cooldown = state.cooldownRemaining;
    final isVerifyingCurrent = state.step == PinSetupStep.verifyCurrent;

    final (String prompt, String hint) = switch (state.step) {
      PinSetupStep.verifyCurrent => (
        l10n.appLockPinVerifyCurrentPrompt,
        l10n.appLockPinVerifyCurrentHint,
      ),
      PinSetupStep.enterNew => (
        l10n.appLockPinEnterNewPrompt,
        l10n.appLockPinEnterNewHint,
      ),
      PinSetupStep.confirmNew => (
        l10n.appLockPinConfirmNewPrompt,
        l10n.appLockPinConfirmNewHint,
      ),
    };

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
              Semantics(
                header: true,
                child: Text(
                  prompt,
                  key: const Key('pin_setup.prompt'),
                  style: AppTypography.title,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                hint,
                style: AppTypography.body.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              _FeedbackLine(state: state),
              if (isVerifyingCurrent && cooldown != null) ...[
                const SizedBox(height: AppSpacing.sm),
                LockoutCountdownBanner(
                  remaining: cooldown,
                  biometricStillAvailable: state.canUseBiometric,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PinPad(
                // A fresh pad per step, so no digits carry over.
                key: ValueKey(state.step),
                enabled: state.isPinEntryEnabled,
                onSubmitted: switch (state.step) {
                  PinSetupStep.verifyCurrent => cubit.submitCurrentPin,
                  PinSetupStep.enterNew => cubit.submitNewPin,
                  PinSetupStep.confirmNew => cubit.submitConfirmation,
                },
              ),
              const SizedBox(height: AppSpacing.md),
              if (isVerifyingCurrent && state.canUseBiometric)
                TextButton.icon(
                  key: const Key('pin_setup.biometric'),
                  onPressed: state.isBusy
                      ? null
                      : () => cubit.authenticateWithBiometric(
                          localizedReason: l10n.appLockPinBiometricReason,
                        ),
                  icon: const Icon(Icons.fingerprint),
                  label: Text(l10n.appLockPinUseBiometric),
                ),
              if (state.step == PinSetupStep.confirmNew)
                TextButton(
                  key: const Key('pin_setup.start_over'),
                  onPressed: state.isBusy || state.isSuccess
                      ? null
                      : cubit.startOver,
                  child: Text(l10n.appLockPinStartOver),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Saving progress, or the message from the last attempt; announced to
/// screen readers as it changes.
class _FeedbackLine extends StatelessWidget {
  const _FeedbackLine({required this.state});

  final PinSetupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    final Widget content;
    if (state.status == PinSetupStatus.saving) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(child: Text(l10n.appLockPinSaving)),
        ],
      );
    } else if (state.message case final message?) {
      content = Text(
        switch (message) {
          PinSetupMessage.mismatch => l10n.appLockPinMismatch,
          PinSetupMessage.invalidPin => l10n.appLockPinInvalid,
          PinSetupMessage.incorrectCurrentPin =>
            l10n.appLockPinIncorrectCurrent,
          PinSetupMessage.biometricFailed => l10n.appLockPinBiometricFailed,
          PinSetupMessage.biometricUnavailable =>
            l10n.appLockPinBiometricUnavailable,
          PinSetupMessage.unexpected => l10n.appLockPinUnexpectedError,
        },
        key: const Key('pin_setup.message'),
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: colorScheme.error),
      );
    } else {
      content = const SizedBox.shrink();
    }

    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 40),
        child: Center(child: content),
      ),
    );
  }
}
