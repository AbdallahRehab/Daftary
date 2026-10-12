import '../../../../core/error/failure.dart';
import 'review_draft.dart';
import 'sms_import_enums.dart';
import 'sms_permission_status.dart';
import 'sms_value_types.dart';

/// Failures of the bank-message import feature (domain-interfaces §1).
///
/// Every message is a fixed English token. No failure carries message
/// text, an amount, a merchant, a name or digits from a message
/// (FR-097, FR-101, invariant 5): the subtypes carry codes and counts only,
/// and [toString] prints the type, the token and those codes.
///
/// Save and storage errors reuse [CacheFailure] with a fixed token; an
/// inner failure's message is never passed through.
abstract class SmsImportFailure extends Failure {
  const SmsImportFailure(super.message);

  /// The codes this failure carries, for [toString]. Never content.
  List<Object?> get codes => const [];

  @override
  List<Object?> get props => [message, ...codes];

  @override
  String toString() {
    final extra = codes.isEmpty ? '' : ', ${codes.join(', ')}';
    return '$runtimeType($message$extra)';
  }
}

/// Capability off: READ_SMS not declared, or not Android.
class SmsCapabilityUnavailableFailure extends SmsImportFailure {
  const SmsCapabilityUnavailableFailure() : super('sms_capability_unavailable');
}

/// Permission not usable. [status] drives the dedicated UI state
/// (FR-069, FR-070, FR-072).
class SmsPermissionFailure extends SmsImportFailure {
  const SmsPermissionFailure(this.status) : super('sms_permission_unusable');

  /// denied | permanentlyDenied | restrictedBlocked | revoked.
  final SmsPermissionStatus status;

  @override
  List<Object?> get codes => [status.name];
}

/// The provider query failed; retried at the next resume.
class SmsInboxQueryFailure extends SmsImportFailure {
  const SmsInboxQueryFailure() : super('sms_inbox_query_failed');
}

/// Which input bound was exceeded (FR-017).
enum InputLimit {
  characters(10000),
  messages(50);

  const InputLimit(this.max);

  /// The bound itself: 10,000 characters or 50 messages.
  final int max;
}

/// Pasted or shared text exceeded a bound (FR-017). Nothing was stored.
class InputTooLargeFailure extends SmsImportFailure {
  const InputTooLargeFailure(this.limit) : super('sms_input_too_large');

  final InputLimit limit;

  int get max => limit.max;

  @override
  List<Object?> get codes => [limit.name];
}

/// Paste or share text had no recognized bank message (FR-018). Nothing was
/// stored.
class NotRecognizedFailure extends SmsImportFailure {
  const NotRecognizedFailure() : super('sms_not_recognized');
}

/// Add attempted on an item that is no longer pending (double tap, retry
/// after a type switch; FR-075a).
class ImportAlreadyDecidedFailure extends SmsImportFailure {
  const ImportAlreadyDecidedFailure(this.status)
    : super('sms_import_already_decided');

  final SmsImportStatus status;

  @override
  List<Object?> get codes => [status.name];
}

/// Required fields incomplete or invalid on Add (FR-043a). Field codes
/// only.
class ImportIncompleteFailure extends SmsImportFailure {
  ImportIncompleteFailure(Set<ReviewField> fields)
    : fields = Set.unmodifiable(fields),
      super('sms_import_incomplete');

  final Set<ReviewField> fields;

  @override
  List<Object?> get codes => [
    for (final field in ReviewField.values)
      if (fields.contains(field)) field.name,
  ];
}

/// A probable duplicate exists and the caller did not override it
/// (FR-060). Not an error to log: the UI shows the side-by-side sheet.
class ProbableDuplicateFailure extends SmsImportFailure {
  const ProbableDuplicateFailure(this.finding)
    : super('sms_import_probable_duplicate');

  final DuplicateFinding finding;

  @override
  List<Object?> get props => [message, finding];

  @override
  List<Object?> get codes => [finding.tier.name];
}

/// The original text cannot be shown (key loss, tag failure, decided item;
/// FR-045, FR-074a).
class OriginalUnavailableFailure extends SmsImportFailure {
  const OriginalUnavailableFailure() : super('sms_original_unavailable');
}

/// A scan or catch-up was not allowed to run.
class ScanNotAllowedFailure extends SmsImportFailure {
  const ScanNotAllowedFailure(this.reason) : super('sms_scan_not_allowed');

  final ScanBlockReason reason;

  @override
  List<Object?> get codes => [reason.name];
}
