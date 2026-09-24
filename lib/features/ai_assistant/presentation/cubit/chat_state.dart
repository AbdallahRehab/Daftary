import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/ai_message.dart';
import '../../domain/entities/grounding_refs.dart';
import '../../domain/tools/get_proactive_observation_tool.dart';

enum ChatStatus {
  loading,

  /// The settings or the conversation could not be read at all.
  loadFailure,

  /// The assistant is off: nothing can be sent; the page links to its
  /// settings (FR-014/FR-016).
  disabled,

  /// The conversation is shown and questions can be asked.
  ready,
}

/// A one-shot outcome the page reports (snackbar) once.
enum ChatOutcome { cleared, clearFailed, loadEarlierFailed }

/// Immutable state for `ChatCubit` (constitution Principle IV).
class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.loading,
    this.messages = const [],
    this.pendingQuestion,
    this.interruptedQuestion,
    this.unsavedQuestion,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isClearing = false,
    this.failure,
    this.outcome,
  });

  final ChatStatus status;

  /// The persisted conversation loaded so far, oldest → newest. A failed
  /// question is an ordinary entry with `status == failed` and its
  /// `failureReason` — the page renders its banner from that (FR-018).
  final List<AIMessage> messages;

  /// The question currently in flight, shown optimistically at the end of
  /// the list until its outcome arrives. Non-null ⇔ [isSending].
  final String? pendingQuestion;

  /// A question that was in flight when the assistant was turned off: its
  /// late result was discarded, and it is shown as not answered (T062).
  final String? interruptedQuestion;

  /// A question whose attempt failed locally (e.g. it couldn't be saved),
  /// so it exists only here; the page offers a local-failure retry.
  final String? unsavedQuestion;

  /// Older messages exist beyond the loaded ones.
  final bool hasMore;
  final bool isLoadingMore;
  final bool isClearing;

  /// Why [ChatStatus.loadFailure] happened, or the last local failure.
  final Failure? failure;

  /// Set only on the emission completing an action; never carried over.
  final ChatOutcome? outcome;

  /// A question is awaiting its answer — every send/retry is refused
  /// (FR-019).
  bool get isSending => pendingQuestion != null;

  bool get isReady => status == ChatStatus.ready;

  /// Nothing to show at all — the page's empty state.
  bool get isEmpty =>
      messages.isEmpty &&
      pendingQuestion == null &&
      interruptedQuestion == null &&
      unsavedQuestion == null;

  /// Whether a send action is currently possible.
  bool get canSend => isReady && !isSending && !isClearing;

  /// Clearing needs something to clear and no request in flight.
  bool get canClear =>
      isReady && !isSending && !isClearing && messages.isNotEmpty;

  /// A proactive observation (User Story 7) is an ordinary assistant
  /// message whose grounding names the observation tool.
  static bool isObservation(AIMessage message) =>
      !message.isFromUser &&
      GroundingRefsCodec.decode(
        message.groundingRefsJson,
      ).any((ref) => ref.toolName == GetProactiveObservationTool.toolName);

  ChatState copyWith({
    ChatStatus? status,
    List<AIMessage>? messages,
    String? pendingQuestion,
    bool clearPendingQuestion = false,
    String? interruptedQuestion,
    bool clearInterruptedQuestion = false,
    String? unsavedQuestion,
    bool clearUnsavedQuestion = false,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isClearing,
    Failure? failure,
    bool clearFailure = false,
    ChatOutcome? outcome,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
      pendingQuestion: clearPendingQuestion
          ? null
          : (pendingQuestion ?? this.pendingQuestion),
      interruptedQuestion: clearInterruptedQuestion
          ? null
          : (interruptedQuestion ?? this.interruptedQuestion),
      unsavedQuestion: clearUnsavedQuestion
          ? null
          : (unsavedQuestion ?? this.unsavedQuestion),
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isClearing: isClearing ?? this.isClearing,
      failure: clearFailure ? null : (failure ?? this.failure),
      outcome: outcome,
    );
  }

  @override
  List<Object?> get props => [
    status,
    messages,
    pendingQuestion,
    interruptedQuestion,
    unsavedQuestion,
    hasMore,
    isLoadingMore,
    isClearing,
    failure,
    outcome,
  ];
}
