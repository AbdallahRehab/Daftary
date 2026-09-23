import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import 'delete_confirmation_input.dart';

/// - [confirming]: the user is reading the warning / typing the phrase.
/// - [inProgress]: the wipe is running; further confirms are ignored.
/// - [success]: every table is wiped and onboarding has been re-resolved.
/// - [error]: the wipe failed and was rolled back — nothing was deleted
///   (FR-018); the user may retry.
enum DeleteStatus { confirming, inProgress, success, error }

/// Immutable state for `DeleteAccountCubit` (constitution Principle IV —
/// updated exclusively via [copyWith]).
class DeleteAccountState extends Equatable {
  const DeleteAccountState({
    this.input = const DeleteConfirmationInput(),
    this.status = DeleteStatus.confirming,
    this.failure,
  });

  final DeleteConfirmationInput input;
  final DeleteStatus status;

  /// Typed, so the page decides the wording (always the localized
  /// "nothing was removed" message — the failure is never partial).
  final Failure? failure;

  bool get isInProgress => status == DeleteStatus.inProgress;
  bool get isSuccess => status == DeleteStatus.success;
  bool get hasFailed => status == DeleteStatus.error;

  /// Whether the destructive button should be enabled — the same rule
  /// `confirmDelete()` enforces.
  bool get canConfirm =>
      input.isConfirmationEnabled &&
      (status == DeleteStatus.confirming || status == DeleteStatus.error);

  DeleteAccountState copyWith({
    DeleteConfirmationInput? input,
    DeleteStatus? status,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return DeleteAccountState(
      input: input ?? this.input,
      status: status ?? this.status,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [input, status, failure];
}
