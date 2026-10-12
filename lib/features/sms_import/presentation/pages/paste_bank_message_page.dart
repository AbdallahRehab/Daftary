import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_button.dart';
import '../../../../core/design_system/app_card.dart';
import '../../../../core/design_system/app_text_field.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/failure_message.dart';
import '../../domain/entities/sms_import_failures.dart';
import '../cubit/paste_cubit.dart';
import '../cubit/paste_state.dart';
import '../routes.dart';

/// The Paste screen (T091, ui-contract §3.5, US4): paste on every
/// platform, and the landing screen of an Android share.
///
/// - The clipboard is read only inside the Paste button's `onPressed`
///   (FR-015): never in `initState`, on a route push, on resume or on
///   focus.
/// - The field never feeds the keyboard's learning (no autocorrect, no
///   suggestions, no IME personalized learning).
/// - No text is ever part of the route: a share waits in the in-memory
///   `SharedTextInbox`, which the cubit consumes after unlock (FR-016a).
/// - Screen-capture protection is app-wide and always on, so this page
///   needs no opt-in (discovery permissions-lifecycle L3).
class PasteBankMessagePage extends StatelessWidget {
  const PasteBankMessagePage({super.key, this.cubit});

  /// Tests inject a cubit; the app resolves it from DI.
  final PasteCubit? cubit;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => (cubit ?? getIt<PasteCubit>())..open(),
      child: const _PasteView(),
    );
  }
}

/// Where "Enter manually" goes: the existing expense form.
const String _manualEntryLocation = '/finance/entries/new?type=expense';

class _PasteView extends StatefulWidget {
  const _PasteView();

  @override
  State<_PasteView> createState() => _PasteViewState();
}

class _PasteViewState extends State<_PasteView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The only clipboard read of the feature: inside the tap (FR-015).
  Future<void> _onPastePressed() async {
    final text = await context.read<PasteCubit>().pasteFromClipboard();
    if (!mounted || text == null) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onProcessPressed() {
    FocusScope.of(context).unfocus();
    context.read<PasteCubit>().process(_controller.text);
  }

  void _onTryAgain() {
    context.read<PasteCubit>().reset();
  }

  void _announce(BuildContext context, String message) {
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );
  }

  void _onState(BuildContext context, PasteState state) {
    final l10n = AppLocalizations.of(context)!;
    switch (state.status) {
      case PasteStatus.recognized:
        final summary = _summaryText(l10n, state);
        _announce(context, summary);
        final ids = state.result?.newIds ?? const <String>[];
        if (ids.isEmpty) return;
        _controller.clear();
        ScaffoldMessenger.maybeOf(
          context,
        )?.showSnackBar(SnackBar(content: Text(summary)));
        if (ids.length == 1) {
          context.pushReplacement(BankMessagesRoutes.review(ids.single));
        } else {
          context.go(BankMessagesRoutes.hub);
        }
      case PasteStatus.clipboardEmpty:
        _announce(context, l10n.smsImportPasteNothingTitle);
      case PasteStatus.notRecognized:
        _announce(context, l10n.smsImportPasteNotRecognizedTitle);
      case PasteStatus.tooLarge:
        _announce(context, l10n.smsImportPasteTooLargeTitle);
      case PasteStatus.unreadableOnly:
        _announce(context, l10n.smsImportPasteUnreadableTitle);
      case PasteStatus.error:
        _announce(context, l10n.messageFor(state.failure));
      case PasteStatus.processing:
        _announce(
          context,
          state.fromShare
              ? l10n.smsImportShareProcessing
              : l10n.smsImportPasteProcessing,
        );
      case PasteStatus.ready:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(title: Text(l10n.smsImportPasteTitle)),
      body: SafeArea(
        top: false,
        child: BlocConsumer<PasteCubit, PasteState>(
          listenWhen: (previous, current) => previous != current,
          listener: _onState,
          builder: (context, state) {
            final busy = state.isProcessing;
            return ListView(
              padding:
                  const EdgeInsets.all(AppSpacing.md) +
                  AppGlassInsets.of(context),
              children: [
                Text(l10n.smsImportPasteIntro, style: AppTypography.body),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  key: const ValueKey('paste_bank_message_field'),
                  label: l10n.smsImportPasteFieldLabel,
                  controller: _controller,
                  enabled: !busy,
                  maxLines: 8,
                  keyboardType: TextInputType.multiline,
                  privateInput: true,
                  onChanged: (_) => context.read<PasteCubit>().reset(),
                ),
                const SizedBox(height: AppSpacing.xs),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    final over = value.text.length > InputLimit.characters.max;
                    final scheme = Theme.of(context).colorScheme;
                    return Text(
                      l10n.smsImportPasteCharacterCount(value.text.length),
                      key: const ValueKey('paste_bank_message_counter'),
                      style: AppTypography.bodyMuted.copyWith(
                        color: over ? scheme.error : scheme.onSurfaceVariant,
                      ),
                    );
                  },
                ),
                Text(
                  l10n.smsImportPasteLimits,
                  style: AppTypography.bodyMuted.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppSecondaryButton(
                      key: const ValueKey('paste_bank_message_paste'),
                      label: l10n.smsImportPasteButton,
                      onPressed: busy ? null : _onPastePressed,
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) => AppButton(
                        key: const ValueKey('paste_bank_message_process'),
                        label: l10n.smsImportPasteProcess,
                        isLoading: busy,
                        onPressed: value.text.trim().isEmpty
                            ? null
                            : _onProcessPressed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _StatusPanel(state: state, onTryAgain: _onTryAgain),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Two whole localized lines; no punctuation is glued between fragments
/// (ui-contract §8.6).
String _summaryText(AppLocalizations l10n, PasteState state) => [
  l10n.smsImportPasteRecognized(state.recognizedCount),
  l10n.smsImportPasteSkipped(state.skippedCount),
].join('\n');

/// The result of the last paste or share (ui-contract §3.5 states).
class _StatusPanel extends StatelessWidget {
  const _StatusPanel({required this.state, required this.onTryAgain});

  final PasteState state;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    void enterManually() => context.push(_manualEntryLocation);
    void openList() => context.go(BankMessagesRoutes.hub);

    return switch (state.status) {
      PasteStatus.ready => const SizedBox.shrink(),
      PasteStatus.processing => _Panel(
        key: const ValueKey('paste_state_processing'),
        icon: Icons.hourglass_top,
        title: state.fromShare
            ? l10n.smsImportShareProcessing
            : l10n.smsImportPasteProcessing,
        showProgress: true,
      ),
      PasteStatus.clipboardEmpty => _Panel(
        key: const ValueKey('paste_state_nothing'),
        icon: Icons.content_paste_off,
        title: l10n.smsImportPasteNothingTitle,
        message: l10n.smsImportErrorClipboardEmpty,
      ),
      PasteStatus.notRecognized => _Panel(
        key: const ValueKey('paste_state_not_recognized'),
        icon: Icons.help_outline,
        title: l10n.smsImportPasteNotRecognizedTitle,
        message: l10n.smsImportErrorNotRecognized,
        shared: state.fromShare,
        actions: [
          (l10n.smsImportPasteEnterManually, enterManually, true),
          (l10n.smsImportPasteTryAgain, onTryAgain, false),
        ],
      ),
      PasteStatus.tooLarge => _Panel(
        key: const ValueKey('paste_state_too_large'),
        icon: Icons.warning_amber_outlined,
        title: l10n.smsImportPasteTooLargeTitle,
        message: switch (state.tooLargeLimit) {
          InputLimit.messages => l10n.smsImportErrorTooManyMessages,
          _ => l10n.smsImportErrorTooLongCharacters,
        },
        shared: state.fromShare,
        actions: [(l10n.smsImportPasteTryAgain, onTryAgain, false)],
      ),
      PasteStatus.unreadableOnly => _Panel(
        key: const ValueKey('paste_state_unreadable'),
        icon: Icons.report_outlined,
        title: l10n.smsImportPasteUnreadableTitle,
        message: l10n.smsImportPasteUnreadableMessage,
        shared: state.fromShare,
        actions: [
          (l10n.smsImportPasteEnterManually, enterManually, true),
          (l10n.smsImportPasteTryAgain, onTryAgain, false),
        ],
      ),
      PasteStatus.recognized => _Panel(
        key: const ValueKey('paste_state_recognized'),
        icon: Icons.check_circle_outline,
        title: l10n.smsImportPasteRecognized(state.recognizedCount),
        message: [
          l10n.smsImportPasteSkipped(state.skippedCount),
          if (state.result?.newIds.isEmpty ?? true)
            l10n.smsImportPasteAlreadyListed,
        ].join('\n'),
        shared: state.fromShare,
        actions: [(l10n.smsImportPasteOpenList, openList, true)],
      ),
      PasteStatus.error => _Panel(
        key: const ValueKey('paste_state_error'),
        icon: Icons.error_outline,
        title: l10n.messageFor(state.failure),
        actions: [(l10n.smsImportPasteTryAgain, onTryAgain, false)],
      ),
    };
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.icon,
    required this.title,
    super.key,
    this.message,
    this.shared = false,
    this.showProgress = false,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String? message;
  final bool shared;
  final bool showProgress;

  /// (label, onPressed, primary).
  final List<(String, VoidCallback, bool)> actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (shared) ...[
              Text(
                l10n.smsImportShareReceived,
                style: AppTypography.bodyMuted.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showProgress)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                else
                  Icon(icon, color: scheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(title, style: AppTypography.title)),
              ],
            ),
            if (message case final text?) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(text, style: AppTypography.body),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final (label, onPressed, primary) in actions)
                    primary
                        ? AppButton(label: label, onPressed: onPressed)
                        : AppSecondaryButton(
                            label: label,
                            onPressed: onPressed,
                          ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
