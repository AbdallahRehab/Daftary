import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/security/app_lifecycle_observer.dart';
import '../../../data_privacy/presentation/widgets/typed_confirmation_field.dart';
import '../cubit/forgot_pin_cubit.dart';
import '../cubit/forgot_pin_state.dart';

/// The Forgot-PIN wipe's final gate (FR-019, constitution Financial Domain
/// Override): the permanent warning up front, then two deliberate actions —
/// typing the localized phrase (the same one 013's "Delete my data" asks
/// for, since it is the same wipe), then tapping the now-enabled button.
///
/// Pushed by `ForgotPinPage` inside `AppLockGate`'s own Navigator, sharing
/// its [ForgotPinCubit]. Leaving before confirming changes nothing.
///
/// After a successful wipe the app is sent to first-launch onboarding:
/// `OnboardingCubit` has already been re-resolved by the cubit, so going to
/// `/` lets the router's existing onboarding redirect take over; the lock
/// screen is then dismissed, since App Lock's configuration is gone too.
/// `appRouter` is used directly because this page lives above the router
/// (in the gate's Navigator), where `GoRouter.of(context)` cannot reach.
class WipeConfirmationPage extends StatefulWidget {
  const WipeConfirmationPage({super.key});

  @override
  State<WipeConfirmationPage> createState() => _WipeConfirmationPageState();
}

class _WipeConfirmationPageState extends State<WipeConfirmationPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-run on a locale change, so the gate always expects the phrase the
    // label is currently asking for.
    context.read<ForgotPinCubit>().setExpectedPhrase(
      AppLocalizations.of(context)!.deleteDataConfirmPhrase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ForgotPinCubit>();

    return BlocConsumer<ForgotPinCubit, ForgotPinState>(
      listenWhen: (previous, current) => !previous.isWiped && current.isWiped,
      listener: (context, _) {
        appRouter.go('/');
        getIt<AppLifecycleObserver>().unlock();
      },
      builder: (context, state) {
        final isBusy = state.isWiping || state.isWiped;
        return PopScope(
          // Leaving mid-wipe would not stop it, only hide its outcome.
          canPop: !isBusy,
          // A plain Scaffold on purpose, never Liquid Glass (020): like onboarding,
          // the lock overlay (lock screen, Forgot PIN, wipe) is a full-screen
          // security flow above the router, and must stay maximally legible and
          // render-safe whatever the user's glass preference.
          child: Scaffold(
            appBar: AppBar(title: Text(l10n.appLockWipeTitle)),
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const _PermanentWarning(),
                  const SizedBox(height: AppSpacing.lg),
                  TypedConfirmationField(
                    expectedPhrase: state.wipeInput.expectedPhrase,
                    onChanged: cubit.updateTypedPhrase,
                  ),
                  if (state.wipeFailed) ...[
                    const SizedBox(height: AppSpacing.md),
                    _FailureNotice(message: l10n.appLockWipeError),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  _DestructiveButton(
                    label: state.wipeFailed
                        ? l10n.retry
                        : l10n.appLockWipeConfirmAction,
                    inProgressLabel: l10n.appLockWipeInProgress,
                    isInProgress: isBusy,
                    onPressed: state.canConfirmWipe ? cubit.confirmWipe : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppSecondaryButton(
                    label: l10n.appLockWipeCancelAction,
                    onPressed: isBusy
                        ? null
                        : () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// States, before anything else on the page, that the wipe is permanent.
class _PermanentWarning extends StatelessWidget {
  const _PermanentWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appLockWipeWarningTitle,
                  style: AppTypography.title.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.appLockWipeWarningMessage,
                  style: AppTypography.body.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown after a failed wipe, which was rolled back across the database
/// and App Lock's keys alike — so it can truthfully say nothing changed.
class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.body.copyWith(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

/// [AppButton]'s shape in the theme's error colors, with a label next to
/// the spinner while the wipe runs.
class _DestructiveButton extends StatelessWidget {
  const _DestructiveButton({
    required this.label,
    required this.inProgressLabel,
    required this.isInProgress,
    required this.onPressed,
  });

  final String label;
  final String inProgressLabel;
  final bool isInProgress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: FilledButton(
        onPressed: isInProgress ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: isInProgress
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(child: Text(inProgressLabel)),
                ],
              )
            : Text(label),
      ),
    );
  }
}
