import 'package:equatable/equatable.dart';

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
