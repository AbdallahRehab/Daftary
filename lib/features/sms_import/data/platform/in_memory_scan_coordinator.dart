import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_value_types.dart';
import '../../domain/services/scan_coordinator.dart';

/// One scan at a time across `RunInboxScan` and `RunCatchUpScan` (FR-013,
/// analysis M11), in memory:
///
/// - a catch-up requested while any scan runs does not run and returns
///   `null` (the caller reports `skipped(alreadyRunning)`);
/// - an explicit scan cancels a running catch-up through the catch-up's
///   token, waits for it to finish, then runs;
/// - an explicit scan requested while another explicit scan runs waits for
///   it, then runs;
/// - a scan whose own token was cancelled while it waited does not run.
///
/// The body's own errors propagate to its caller and always release the
/// slot.
@LazySingleton(as: ScanCoordinator)
class InMemoryScanCoordinator implements ScanCoordinator {
  _Run? _current;

  @override
  bool get isRunning => _current != null;

  @override
  Future<T?> runExclusive<T>(
    ScanKind kind,
    ScanCancellationToken token,
    Future<T> Function() body,
  ) async {
    while (_current != null) {
      final running = _current!;
      if (kind == ScanKind.catchUp) return null;
      if (running.kind == ScanKind.catchUp) running.token.cancel();
      await running.done.future;
    }
    if (token.isCancelled) return null;
    final run = _Run(kind, token);
    _current = run;
    try {
      return await body();
    } finally {
      _current = null;
      run.done.complete();
    }
  }
}

class _Run {
  _Run(this.kind, this.token);

  final ScanKind kind;
  final ScanCancellationToken token;
  final Completer<void> done = Completer<void>();
}
