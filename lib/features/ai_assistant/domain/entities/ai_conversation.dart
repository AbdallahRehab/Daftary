import 'package:equatable/equatable.dart';

/// The single, continuous, locally-stored conversation between the user and
/// the assistant (014 data-model.md). Not multi-thread in this iteration:
/// exactly one row ever exists per installation, created lazily the first
/// time it is needed — never user-creatable directly.
///
/// Clearing the conversation (FR-012) deletes its messages; disabling the
/// assistant does not.
class AIConversation extends Equatable {
  const AIConversation({
    required this.id,
    required this.createdAt,
    required this.lastActivityAt,
  });

  final String id;

  /// Set once, when the conversation is first created.
  final DateTime createdAt;

  /// Bumped whenever a new `AIMessage` is appended.
  final DateTime lastActivityAt;

  @override
  List<Object?> get props => [id, createdAt, lastActivityAt];
}
