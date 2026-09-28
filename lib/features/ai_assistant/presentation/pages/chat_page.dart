import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_confirm_dialog.dart';
import '../../../../core/design_system/app_empty_view.dart';
import '../../../../core/design_system/glass/app_glass_insets.dart';
import '../../../../core/design_system/glass/app_scaffold.dart';
import '../../../../core/design_system/glass/app_top_bar.dart';
import '../../../../core/design_system/tokens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/ai_failure_banner.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'ai_settings_page.dart';

/// The assistant's single continuous conversation (014 US2–US7): message
/// history with "show earlier" paging, a typing indicator while a question
/// is in flight, a failure banner with retry under every failed question,
/// clear-with-confirmation, and a disabled state linking to settings.
class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const String location = '/ai-assistant/chat';

  @override
  Widget build(BuildContext context) {
    // Read here, not inside `create`: a provider's create callback runs
    // once and must not subscribe to an InheritedWidget.
    final languageCode = Localizations.localeOf(context).languageCode;
    return BlocProvider(
      create: (_) => getIt<ChatCubit>()..load(languageCode: languageCode),
      child: const ChatView(),
    );
  }
}

/// The page's content, reading the nearest [ChatCubit] — split from
/// [ChatPage] so tests can provide a cubit of their own.
class ChatView extends StatelessWidget {
  const ChatView({super.key});

  /// Opens settings and reloads on return: the user may have turned the
  /// assistant off (in-flight result discarded, T062) or on, or changed
  /// the key.
  static Future<void> openSettings(BuildContext context) async {
    final cubit = context.read<ChatCubit>();
    final languageCode = Localizations.localeOf(context).languageCode;
    await context.push<void>(AISettingsPage.location);
    if (!cubit.isClosed) await cubit.load(languageCode: languageCode);
  }

  Future<void> _confirmClear(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final cubit = context.read<ChatCubit>();
    final confirmed = await showAppConfirmDialog(
      context,
      title: l10n.aiChatClearConfirmTitle,
      message: l10n.aiChatClearConfirmMessage,
      confirmLabel: l10n.aiChatClearConfirmAction,
      isDestructive: true,
    );
    if (confirmed) await cubit.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppTopBar(
        title: Text(l10n.aiChatTitle),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (previous, current) =>
                previous.canClear != current.canClear,
            builder: (context, state) => IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.aiChatClearAction,
              onPressed: state.canClear ? () => _confirmClear(context) : null,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.aiChatSettingsAction,
            onPressed: () => openSettings(context),
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (_, current) => current.outcome != null,
        listener: (context, state) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(switch (state.outcome!) {
                  ChatOutcome.cleared => l10n.aiChatClearedMessage,
                  ChatOutcome.clearFailed => l10n.aiChatClearFailed,
                  ChatOutcome.loadEarlierFailed => l10n.aiChatLoadFailed,
                }),
              ),
            );
        },
        builder: (context, state) {
          final cubit = context.read<ChatCubit>();
          switch (state.status) {
            case ChatStatus.loading:
              return const Center(child: CircularProgressIndicator());
            case ChatStatus.loadFailure:
              return AppEmptyView(
                icon: Icons.error_outline,
                title: l10n.commonError,
                message: l10n.aiChatLoadFailed,
                actionLabel: l10n.commonRetry,
                onAction: () => cubit.load(),
              );
            case ChatStatus.disabled:
              return _DisabledView(
                interruptedQuestion: state.interruptedQuestion,
              );
            case ChatStatus.ready:
              return Column(
                children: [
                  Expanded(
                    child: state.isEmpty
                        ? AppEmptyView(
                            icon: Icons.auto_awesome_outlined,
                            title: l10n.aiChatEmptyTitle,
                            message: l10n.aiChatEmptyMessage,
                          )
                        : _MessageList(state: state),
                  ),
                  _ChatInput(enabled: state.canSend, onSend: cubit.send),
                ],
              );
          }
        },
      ),
    );
  }
}

/// The conversation, newest at the bottom. Built reversed so the list
/// starts (and stays) scrolled to the latest message.
class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final ChatState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ChatCubit>();
    // Bottom → top.
    final items = <Widget>[
      if (state.isSending) const TypingIndicator(key: ValueKey('typing')),
      if (state.pendingQuestion case final pending?)
        ChatBubble(
          key: const ValueKey('pending'),
          text: pending,
          isFromUser: true,
        ),
      if (state.unsavedQuestion case final unsaved?) ...[
        AIFailureBanner.localStorage(
          key: const ValueKey('unsaved-banner'),
          onRetry: state.canSend ? cubit.retryUnsaved : null,
        ),
        ChatBubble(
          key: const ValueKey('unsaved'),
          text: unsaved,
          isFromUser: true,
          isFailed: true,
        ),
      ],
      for (final message in state.messages.reversed) ...[
        if (message.failureReason case final reason?)
          AIFailureBanner(
            key: ValueKey('banner-${message.id}'),
            reason: reason,
            onRetry: state.canSend ? () => cubit.retry(message) : null,
            onUpdateKey: () => ChatView.openSettings(context),
          ),
        ChatBubble.fromMessage(
          message,
          key: ValueKey(message.id),
          isObservation: ChatState.isObservation(message),
        ),
      ],
      if (state.hasMore)
        Padding(
          key: const ValueKey('load-earlier'),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Center(
            child: state.isLoadingMore
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton.icon(
                    onPressed: cubit.loadEarlier,
                    icon: const Icon(Icons.history),
                    label: Text(
                      AppLocalizations.of(context)!.aiChatLoadEarlierAction,
                    ),
                  ),
          ),
        ),
    ];
    return ListView.builder(
      reverse: true,
      // Under glass the body starts behind the app bar, so the oldest end
      // of the conversation takes the top inset. The bottom one belongs to
      // the composer below (its SafeArea), which keeps the newest bubble
      // and the composer above the bottom bar or the keyboard.
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.sm) +
          AppGlassInsets.of(context).copyWith(bottom: 0),
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

class _ChatInput extends StatefulWidget {
  const _ChatInput({required this.enabled, required this.onSend});

  /// Whether a question can be sent now (not while one is in flight).
  final bool enabled;
  final ValueChanged<String> onSend;

  @override
  State<_ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<_ChatInput> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _canSend => widget.enabled && _hasText;

  void _send() {
    if (!_canSend) return;
    final text = _controller.text;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                // The hint disappears once the user types; the label keeps
                // the field's purpose announced to screen readers.
                child: Semantics(
                  label: l10n.aiChatInputHint,
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: l10n.aiChatInputHint,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filled(
                icon: const Icon(Icons.send_rounded),
                tooltip: l10n.aiChatSendAction,
                onPressed: _canSend ? _send : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown while the assistant is off: nothing can be sent, and the way back
/// on is the full settings flow (FR-016).
class _DisabledView extends StatelessWidget {
  const _DisabledView({this.interruptedQuestion});

  final String? interruptedQuestion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = AppEmptyView(
      icon: Icons.power_settings_new,
      title: l10n.aiChatDisabledTitle,
      message: l10n.aiChatDisabledMessage,
      actionLabel: l10n.aiChatOpenSettingsAction,
      onAction: () => ChatView.openSettings(context),
    );
    final interrupted = interruptedQuestion;
    if (interrupted == null) return disabled;
    return ListView(
      padding:
          const EdgeInsets.symmetric(vertical: AppSpacing.md) +
          AppGlassInsets.of(context),
      children: [
        ChatBubble(text: interrupted, isFromUser: true, isInterrupted: true),
        const SizedBox(height: AppSpacing.lg),
        disabled,
      ],
    );
  }
}
