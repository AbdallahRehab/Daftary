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
    _ => errorUnknown,
  };
}
