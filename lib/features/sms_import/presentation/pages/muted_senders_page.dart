import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../cubit/muted_senders_cubit.dart';
import '../widgets/bidi_text.dart';

/// Muted senders (T134, ui-contract §3.9): the sender ids the user
/// stopped suggestions from, each with Unmute. Ids are isolated
/// left-to-right so they never reorder inside Arabic text.
class MutedSendersPage extends StatelessWidget {
  const MutedSendersPage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final MutedSendersCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<MutedSendersCubit>())..open(),
      child: const _MutedSendersView(),
    );
  }
}

class _MutedSendersView extends StatelessWidget {
  const _MutedSendersView();

  void _onResult(BuildContext context, MutedSendersState state) {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<MutedSendersCubit>();
    final String message;
    if (state.unmuted) {
      cubit.consumeUnmuted();
      message = l10n.smsImportMuteUnmuted;
    } else if (state.unmuteFailure case final failure?) {
      cubit.consumeUnmuteFailure();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportMuteTitle)),
      body: SafeArea(
        top: false,
        bottom: false,
        child: BlocConsumer<MutedSendersCubit, MutedSendersState>(
          listenWhen: (p, c) =>
              (c.unmuted && !p.unmuted) ||
              (c.unmuteFailure != null && p.unmuteFailure != c.unmuteFailure),
          listener: _onResult,
          builder: (context, state) {
            final cubit = context.read<MutedSendersCubit>();
            return switch (state.status) {
              MutedSendersStatus.initial ||
              MutedSendersStatus.loading => const Center(
                child: CircularProgressIndicator(
                  key: ValueKey('muted_senders_loading'),
                ),
              ),
              MutedSendersStatus.error => AppEmptyView(
                title: l10n.smsImportMuteLoadError,
                message: l10n.messageFor(state.failure),
                icon: Icons.error_outline,
                actionLabel: l10n.smsImportPendingRetry,
                onAction: cubit.retry,
              ),
              MutedSendersStatus.empty => AppEmptyView(
                title: l10n.smsImportMuteEmptyTitle,
                message: l10n.smsImportMuteEmptyMessage,
                icon: Icons.notifications_off_outlined,
              ),
              MutedSendersStatus.ready => ListView(
                key: const ValueKey('muted_senders_list'),
                padding:
                    const EdgeInsets.all(AppSpacing.md) +
                    AppGlassInsets.of(context),
                children: [
                  Text(l10n.smsImportMuteHelp, style: AppTypography.body),
                  const SizedBox(height: AppSpacing.md),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final sender in state.senders)
                          ListTile(
                            key: ValueKey('muted_sender_$sender'),
                            leading: const Icon(
                              Icons.notifications_off_outlined,
                            ),
                            title: BidiText.ltr(
                              sender,
                              style: AppTypography.body,
                            ),
                            trailing: Semantics(
                              label: l10n.smsImportMuteUnmuteSemantics(
                                BidiIsolate.ltr(sender),
                              ),
                              button: true,
                              excludeSemantics: true,
                              child: TextButton(
                                key: ValueKey('muted_sender_unmute_$sender'),
                                style: TextButton.styleFrom(
                                  minimumSize: const Size(
                                    AppSizes.minTouchTarget,
                                    AppSizes.minTouchTarget,
                                  ),
                                ),
                                onPressed: state.unmuting == null
                                    ? () => cubit.unmute(sender)
                                    : null,
                                child: state.unmuting == sender
                                    ? const SizedBox.square(
                                        dimension: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(l10n.smsImportMuteUnmute),
                              ),
                            ),
                          ),
                      ],
                    ),
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
