import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/delete_account_cubit.dart';
import '../cubit/delete_account_state.dart';
import '../widgets/typed_confirmation_field.dart';

/// The single most destructive screen in the app (US3). A dedicated page
/// rather than a dialog (research.md Decision 8): the permanent warning is
/// shown up front (FR-014), and deletion needs two deliberate actions —
/// typing the localized phrase, then tapping the now-enabled button
/// (FR-015). On success it navigates to `/`; the router's existing
/// onboarding redirect does the rest (research.md Decision 6).
class DeleteDataConfirmationPage extends StatelessWidget {
  const DeleteDataConfirmationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DeleteAccountCubit>(),
      child: const _DeleteDataConfirmationView(),
    );
  }
}

class _DeleteDataConfirmationView extends StatefulWidget {
  const _DeleteDataConfirmationView();

  @override
  State<_DeleteDataConfirmationView> createState() =>
      _DeleteDataConfirmationViewState();
}

class _DeleteDataConfirmationViewState
    extends State<_DeleteDataConfirmationView> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-run on a locale change, so the gate always expects the phrase the
    // label is currently asking for.
    context.read<DeleteAccountCubit>().setExpectedPhrase(
      AppLocalizations.of(context)!.deleteDataConfirmPhrase,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<DeleteAccountCubit>();

    return BlocConsumer<DeleteAccountCubit, DeleteAccountState>(
      listenWhen: (previous, current) =>
          !previous.isSuccess && current.isSuccess,
      listener: (context, _) => context.go('/'),
      builder: (context, state) {
        final isBusy = state.isInProgress || state.isSuccess;
        return PopScope(
          // Leaving mid-wipe would not stop it, only hide its outcome.
          canPop: !isBusy,
          child: AppScaffold(
            appBar: AppTopBar(title: Text(l10n.deleteDataTitle)),
            // Under glass the body starts behind the app bar: the list takes
            // the top inset (read below the scaffold, via Builder), SafeArea
            // the rest (as with glass OFF, where the top padding is zero).
            body: SafeArea(
              top: false,
              child: Builder(
                builder: (context) => ListView(
                  padding:
                      const EdgeInsets.all(AppSpacing.md) +
                      AppGlassInsets.of(context),
                  children: [
                    const _PermanentWarning(),
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: isBusy
                            ? null
                            : () => context.push('/settings/export'),
                        icon: const Icon(Icons.ios_share_outlined),
                        label: Text(l10n.deleteDataExportFirstAction),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TypedConfirmationField(
                      expectedPhrase: state.input.expectedPhrase,
                      onChanged: cubit.updateTypedPhrase,
                    ),
                    if (state.hasFailed) ...[
                      const SizedBox(height: AppSpacing.md),
                      _FailureNotice(
                        // 021: the cloud copy could not be reached, so the
                        // whole deletion stopped before touching anything.
                        message: switch (state.failure) {
                          NetworkFailure() || TimeoutFailure() =>
                            l10n.deleteDataCloudUnreachableError,
                          _ => l10n.deleteDataError,
                        },
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    _DestructiveButton(
                      label: state.hasFailed
                          ? l10n.retry
                          : l10n.deleteDataConfirmAction,
                      inProgressLabel: l10n.deleteDataInProgress,
                      isInProgress: isBusy,
                      onPressed: state.canConfirm ? cubit.confirmDelete : null,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppSecondaryButton(
                      label: l10n.deleteDataCancelAction,
                      onPressed: isBusy ? null : () => _leave(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _leave(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/settings');
    }
  }
}

/// FR-014: states, before anything else on the page, that this is
/// permanent and irreversible.
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
                  l10n.deleteDataWarningTitle,
                  style: AppTypography.title.copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.deleteDataWarningMessage,
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

/// Shown after a failed wipe. The wipe is a single transaction, so the
/// message can truthfully say nothing was removed (FR-018).
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

/// [AppButton]'s shape in the theme's error colors. A separate widget
/// rather than an [AppButton] variant: this is the app's only destructive
/// primary action, and while running it shows a label next to the
/// spinner (FR-019) instead of a bare spinner.
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
