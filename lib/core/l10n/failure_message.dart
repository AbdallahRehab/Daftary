import '../../features/sms_import/domain/entities/sms_import_failures.dart';
import '../../features/sms_import/domain/entities/sms_permission_status.dart';
import '../../features/sms_import/domain/entities/sms_value_types.dart';
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
    // 023: bank message import. Each failure carries codes only, so the
    // copy never contains message text, an amount or a name (FR-097).
    SmsImportFailure() => _smsImportMessage(failure),
    _ => errorUnknown,
  };

  String _smsImportMessage(SmsImportFailure failure) => switch (failure) {
    SmsCapabilityUnavailableFailure() => smsImportErrorCapabilityUnavailable,
    SmsPermissionFailure(:final status) => switch (status) {
      SmsPermissionStatus.permanentlyDenied ||
      SmsPermissionStatus.restrictedBlocked => smsImportErrorPermissionBlocked,
      SmsPermissionStatus.revoked => smsImportErrorPermissionRevoked,
      SmsPermissionStatus.unavailable => smsImportErrorCapabilityUnavailable,
      SmsPermissionStatus.denied ||
      SmsPermissionStatus.granted => smsImportErrorPermissionDenied,
    },
    SmsInboxQueryFailure() => smsImportErrorInboxQuery,
    InputTooLargeFailure(:final limit) => switch (limit) {
      InputLimit.characters => smsImportErrorTooLongCharacters,
      InputLimit.messages => smsImportErrorTooManyMessages,
    },
    NotRecognizedFailure() => smsImportErrorNotRecognized,
    ImportAlreadyDecidedFailure() => smsImportErrorAlreadyDecided,
    ImportIncompleteFailure() => smsImportErrorIncomplete,
    ProbableDuplicateFailure() => smsImportErrorProbableDuplicate,
    OriginalUnavailableFailure() => smsImportErrorOriginalUnavailable,
    ScanNotAllowedFailure(:final reason) => switch (reason) {
      ScanBlockReason.alreadyRunning => smsImportErrorScanAlreadyRunning,
      ScanBlockReason.capabilityOff => smsImportErrorCapabilityUnavailable,
      ScanBlockReason.noPermission => smsImportErrorPermissionDenied,
      ScanBlockReason.disabled ||
      ScanBlockReason.locked ||
      ScanBlockReason.debounced ||
      ScanBlockReason.notResumed => smsImportErrorScanNotAllowed,
    },
    _ => errorUnknown,
  };
}
