import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_assistant_failures.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/usecases/ask_financial_question.dart';
import '../../domain/usecases/clear_conversation.dart';
import '../../domain/usecases/get_ai_assistant_settings.dart';
import '../../domain/usecases/get_conversation.dart';
import '../../domain/usecases/get_proactive_observation.dart';
import 'chat_state.dart';

/// Drives the assistant's chat screen (User Stories 2–7).
///
/// - **Send** (US2, FR-019): the question is shown optimistically as
///   [ChatState.pendingQuestion] while [AskFinancialQuestion] runs; a
///   second send/retry is refused synchronously until it completes.
/// - **Failures** (US6, FR-017/FR-018): an AI failure persists the question
///   as `failed` with its reason, so the latest page is reloaded to show
///   that row; the page renders an `AIFailureBanner` from its
///   `failureReason`. [retry] re-sends its content without retyping. A
///   local failure (the question couldn't be saved) keeps the text in
///   [ChatState.unsavedQuestion] for [retryUnsaved].
/// - **History** (US4): [loadEarlier] pages backwards; [clear] wipes it
///   (the page confirms first).
/// - **Disable mid-flight** (US5, T062): every send captures a generation
///   token. [assistantDisabled] — or a [load] that finds the assistant
///   off, or the use case itself reporting it off — bumps the token, so a
///   late result is discarded instead of rendered, and the pending
///   question is shown as interrupted. Re-enabling is only possible in
///   settings (full key + consent flow); this cubit never enables.
/// - **Proactive observation** (US7, FR-020): checked on every [load] of an
///   enabled assistant and appended when one qualifies.
@injectable
class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._getSettings,
    this._getConversation,
    this._askQuestion,
    this._clearConversation,
    this._getObservation,
  ) : super(const ChatState());

  final GetAIAssistantSettings _getSettings;
  final GetConversation _getConversation;
  final AskFinancialQuestion _askQuestion;
  final ClearConversation _clearConversation;
  final GetProactiveObservation _getObservation;

  static const int pageSize = GetConversation.defaultPageSize;

  /// Bumped whenever an in-flight result must no longer be rendered
  /// (disable, clear).
  int _generation = 0;
  String _languageCode = 'en';

  /// (Re)loads settings and the latest page, then checks for a proactive
  /// observation. Safe to call again, e.g. after returning from settings:
  /// content already shown stays visible while it refreshes.
  ///
  /// [languageCode] is the app's current language, used for the
  /// observation's narration; the last one given is remembered.
  Future<void> load({String? languageCode}) async {
    if (languageCode != null) _languageCode = languageCode;
    if (!state.isReady) {
      emit(state.copyWith(status: ChatStatus.loading, clearFailure: true));
    }

    final settingsResult = await _getSettings();
    if (isClosed) return;
    final settings = settingsResult.toNullable();
    if (settings == null) {
      _emitLoadFailure(settingsResult.getLeft().toNullable()!);
      return;
    }
    if (!settings.isEnabled) {
      assistantDisabled();
      return;
    }

    final page = await _getConversation(limit: pageSize);
    if (isClosed) return;
    final messages = page.toNullable();
    if (messages == null) {
      _emitLoadFailure(page.getLeft().toNullable()!);
      return;
    }
    emit(
      state.copyWith(
        status: ChatStatus.ready,
        messages: messages,
        hasMore: messages.length == pageSize,
        clearInterruptedQuestion: true,
        clearFailure: true,
      ),
    );
    await _checkObservation();
  }

  /// Asks [question] (trimmed). Ignored when blank, while another question
  /// is in flight (FR-019), or when the assistant is not ready.
  Future<void> send(String question) async {
    final text = question.trim();
    if (text.isEmpty || !state.canSend) return;
    await _ask(text);
  }

  /// Re-sends a failed question's own content (FR-018). The failed row is
  /// replaced: the use case deletes it once the new attempt has an outcome,
  /// which is then shown at the end of the conversation.
  Future<void> retry(AIMessage failed) async {
    if (!failed.isFailed || !state.canSend) return;
    await _ask(failed.content, retryOf: failed);
  }

  /// Re-sends the question that couldn't be saved locally.
  Future<void> retryUnsaved() async {
    final text = state.unsavedQuestion;
    if (text == null || !state.canSend) return;
    await _ask(text);
  }

  /// The assistant was turned off (T062): any in-flight result is dropped
  /// and its question shown as interrupted; nothing more can be sent.
  void assistantDisabled() {
    _generation++;
    emit(
      ChatState(
        status: ChatStatus.disabled,
        interruptedQuestion: state.pendingQuestion ?? state.interruptedQuestion,
      ),
    );
  }

  /// Loads the next older page and puts it above what is shown.
  Future<void> loadEarlier() async {
    if (!state.isReady || !state.hasMore || state.isLoadingMore) return;
    final generation = _generation;
    emit(state.copyWith(isLoadingMore: true));
    final result = await _getConversation(
      limit: pageSize,
      offset: state.messages.length,
    );
    if (isClosed || generation != _generation) return;
    result.fold(
      (_) => emit(
        state.copyWith(
          isLoadingMore: false,
          outcome: ChatOutcome.loadEarlierFailed,
        ),
      ),
      (older) {
        final shown = {for (final m in state.messages) m.id};
        emit(
          state.copyWith(
            isLoadingMore: false,
            hasMore: older.length == pageSize,
            messages: [
              for (final m in older)
                if (!shown.contains(m.id)) m,
              ...state.messages,
            ],
          ),
        );
      },
    );
  }

  /// Permanently deletes the whole conversation (FR-012). The page asks
  /// for confirmation before calling this.
  Future<void> clear() async {
    if (!state.canClear || state.isLoadingMore) return;
    emit(state.copyWith(isClearing: true));
    final result = await _clearConversation();
    if (isClosed) return;
    result.fold(
      (_) => emit(
        state.copyWith(isClearing: false, outcome: ChatOutcome.clearFailed),
      ),
      (_) {
        _generation++;
        emit(ChatState(status: ChatStatus.ready, outcome: ChatOutcome.cleared));
      },
    );
  }

  // --------------------------------------------------------------- helpers

  Future<void> _ask(String text, {AIMessage? retryOf}) async {
    final generation = _generation;
    emit(
      state.copyWith(
        pendingQuestion: text,
        // The retried row leaves the list now; its outcome is appended at
        // the end, exactly where the use case persists it.
        messages: retryOf == null
            ? null
            : [
                for (final m in state.messages)
                  if (m.id != retryOf.id) m,
              ],
        clearUnsavedQuestion: true,
        clearInterruptedQuestion: true,
        clearFailure: true,
      ),
    );

    final result = await _askQuestion(text, retryOfMessageId: retryOf?.id);
    // A result arriving after a disable/clear is discarded, never shown.
    if (isClosed || generation != _generation) return;

    final failure = result.getLeft().toNullable();
    if (failure == null) {
      final value = result.toNullable()!;
      emit(
        state.copyWith(
          messages: [...state.messages, value.question, value.answer],
          clearPendingQuestion: true,
        ),
      );
      return;
    }
    if (failure is AIAssistantDisabledFailure) {
      assistantDisabled();
      return;
    }
    await _showPersistedFailure(failure, text, retryOf, generation);
  }

  /// An AI failure persisted the question as `failed`; reload the latest
  /// messages (enough to cover everything shown) so that row appears.
  Future<void> _showPersistedFailure(
    Failure failure,
    String text,
    AIMessage? retryOf,
    int generation,
  ) async {
    final limit = math.max(pageSize, state.messages.length + 1);
    final page = await _getConversation(limit: limit);
    if (isClosed || generation != _generation) return;
    final messages = page.toNullable();
    if (messages == null) {
      emit(
        state.copyWith(
          clearPendingQuestion: true,
          unsavedQuestion: text,
          failure: failure,
        ),
      );
      return;
    }
    // A local failure may have left nothing persisted for this question
    // (and, on retry, possibly the old failed row back in place).
    final persisted = failure is AIAssistantFailure;
    final retriedRowBack =
        retryOf != null && messages.any((m) => m.id == retryOf.id);
    emit(
      state.copyWith(
        messages: messages,
        hasMore: limit > pageSize ? state.hasMore : messages.length == limit,
        clearPendingQuestion: true,
        unsavedQuestion: persisted || retriedRowBack ? null : text,
        failure: persisted ? null : failure,
        clearFailure: persisted,
      ),
    );
  }

  Future<void> _checkObservation() async {
    final generation = _generation;
    final result = await _getObservation(languageCode: _languageCode);
    if (isClosed || generation != _generation || !state.isReady) return;
    final observation = result.toNullable();
    if (observation == null) return;
    if (state.messages.any((m) => m.id == observation.id)) return;
    emit(state.copyWith(messages: [...state.messages, observation]));
  }

  void _emitLoadFailure(Failure failure) {
    emit(
      state.copyWith(
        status: ChatStatus.loadFailure,
        failure: failure,
        clearPendingQuestion: true,
      ),
    );
  }

  @override
  String toString() => 'ChatCubit(${state.status})';
}
