import '../entities/sms_import_enums.dart';
import '../entities/sms_value_types.dart';

/// One scan at a time across `RunInboxScan` and `RunCatchUpScan` (FR-013).
/// In memory.
///
/// - An explicit scan cancels a running catch-up (through the catch-up's
///   [ScanCancellationToken]) and waits for it to stop, then runs.
/// - A catch-up while any scan runs does not run: [runExclusive] returns
///   `null` and the caller reports `skipped(alreadyRunning)`.
abstract class ScanCoordinator {
  /// Runs [body] exclusively. [token] is the caller's token; the
  /// coordinator may cancel it to make way for an explicit scan.
  Future<T?> runExclusive<T>(
    ScanKind kind,
    ScanCancellationToken token,
    Future<T> Function() body,
  );

  /// Whether any scan is running.
  bool get isRunning;
}
