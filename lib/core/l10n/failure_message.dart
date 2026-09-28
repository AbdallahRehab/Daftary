import '../error/failure.dart';
import 'app_localizations.dart';

/// Maps a typed [Failure] to user-facing copy. A failure's own `message` is
/// developer diagnostics (English, often carrying raw exception text) and
/// is never shown on screen.
extension FailureMessage on AppLocalizations {
  String messageFor(Failure? failure) => switch (failure) {
    ValidationFailure() => errorValidation,
    NotFoundFailure() => errorNotFound,
    CacheFailure() => errorCache,
    NetworkFailure() => errorSyncNetwork,
    TimeoutFailure() => errorSyncTimeout,
    ServerFailure() => errorSyncServer,
    UnauthorizedFailure() => errorSyncUnauthorized,
    ForbiddenFailure() => errorSyncForbidden,
    SyncRejectedFailure() => errorSyncRejected,
    SyncConflictFailure() => errorSyncConflict,
    EmailAuthFailure(:final reason) => switch (reason) {
      EmailAuthErrorReason.invalidCode => syncEmailErrorInvalidCode,
      EmailAuthErrorReason.invalidEmail => syncEmailErrorInvalidEmail,
      EmailAuthErrorReason.emailInUse => syncEmailErrorEmailInUse,
      EmailAuthErrorReason.accountNotFound => syncEmailErrorAccountNotFound,
      EmailAuthErrorReason.rateLimited => syncEmailErrorRateLimited,
    },
    RatesMissingFailure(:final missingRatesFor) => rateNeededMessage(
      missingRatesFor.map((c) => c.code).join(', '),
    ),
    _ => errorUnknown,
  };
}
