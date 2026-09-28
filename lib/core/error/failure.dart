import 'package:equatable/equatable.dart';

import '../money/currency.dart';

/// Base type for every predictable, typed failure surfaced by a repository
/// or use case. Never thrown — always returned via `Either<Failure, T>`.
abstract class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// A precondition on the input data was not met (e.g. non-positive amount,
/// empty name) before persistence was attempted.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// The local database/storage layer failed to read or write.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// The requested entity does not exist.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// An unexpected, non-domain-specific error.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message);
}

// 021 Offline-First Cloud Sync — infrastructure failures raised by the sync
// layer (research.md Decision 20). They surface only through the sync status,
// never on an existing screen.

/// The device could not reach the cloud (no connection, socket or handshake
/// error). Transient: retried with backoff.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// A cloud request exceeded its timeout. Transient.
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message);
}

/// The cloud service failed (5xx, 429, connection-level API errors).
/// Transient.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// The cloud session is missing, expired or invalid.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(super.message);
}

/// The cloud refused the request for this owner (row-level security).
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}

/// The cloud rejected an operation by rule. [reason] is a code only (for
/// example `validation` or `person_has_transactions`), never record content.
class SyncRejectedFailure extends Failure {
  const SyncRejectedFailure(this.reason, [String? message])
    : super(message ?? 'sync rejected: $reason');

  final String reason;

  @override
  List<Object?> get props => [message, reason];
}

/// A conflict-resolution action was invalid (for example the conflict no
/// longer exists). A detected conflict itself is state, not a failure.
class SyncConflictFailure extends Failure {
  const SyncConflictFailure(super.message);
}

/// Why an email code request or confirmation was refused (021 US6).
enum EmailAuthErrorReason {
  /// The code is wrong or has expired.
  invalidCode,

  /// The address is not a valid email.
  invalidEmail,

  /// The address already belongs to another account.
  emailInUse,

  /// No account uses this address (signing in to an existing account).
  accountNotFound,

  /// Too many codes were requested; wait before asking again.
  rateLimited,
}

/// The cloud refused an email code step. [reason] is a code only; the email
/// itself is never part of a failure.
class EmailAuthFailure extends Failure {
  const EmailAuthFailure(this.reason) : super('email auth refused');

  final EmailAuthErrorReason reason;

  @override
  List<Object?> get props => [message, reason];
}

/// 018 FR-009: a figure that needs an exchange rate the user has not set
/// yet. Returned by aggregates that cannot show a partial total — the UI
/// names [missingRatesFor] and offers to set a rate, and never falls back
/// to a 1:1 conversion.
class RatesMissingFailure extends Failure {
  RatesMissingFailure(this.missingRatesFor)
    : super(
        'Exchange rate needed for '
        '${missingRatesFor.map((c) => c.code).join(', ')}',
      );

  final List<Currency> missingRatesFor;

  @override
  List<Object?> get props => [message, missingRatesFor];
}
