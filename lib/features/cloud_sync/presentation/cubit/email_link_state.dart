import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';

/// Where the email form is: [sending] the code, [codeSent] (waiting for the
/// user to type it), [verifying] it, then [success] or [failure].
enum EmailLinkStep { initial, sending, codeSent, verifying, success, failure }

/// Link an email to this device's account, or sign in to an existing one
/// (research.md Decision 11).
enum EmailLinkMode { link, signIn }

/// Immutable state for `EmailLinkCubit` (constitution Principle IV).
class EmailLinkState extends Equatable {
  const EmailLinkState({
    this.step = EmailLinkStep.initial,
    this.mode = EmailLinkMode.link,
    this.email = '',
    this.codeSent = false,
    this.failure,
  });

  final EmailLinkStep step;
  final EmailLinkMode mode;

  /// Kept in memory for the confirm step only; never logged or persisted.
  final String email;

  /// Whether a code was sent, so a failure keeps the code field on screen.
  final bool codeSent;
  final Failure? failure;

  bool get isBusy =>
      step == EmailLinkStep.sending || step == EmailLinkStep.verifying;

  EmailLinkState copyWith({
    EmailLinkStep? step,
    EmailLinkMode? mode,
    String? email,
    bool? codeSent,
    Failure? failure,
  }) {
    return EmailLinkState(
      step: step ?? this.step,
      mode: mode ?? this.mode,
      email: email ?? this.email,
      codeSent: codeSent ?? this.codeSent,
      failure: failure,
    );
  }

  @override
  List<Object?> get props => [step, mode, email, codeSent, failure];

  /// Never prints the email.
  @override
  String toString() =>
      'EmailLinkState(step: $step, mode: $mode, codeSent: $codeSent, '
      'failure: ${failure.runtimeType})';
}
