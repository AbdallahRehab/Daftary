import 'package:injectable/injectable.dart';

/// The current wall-clock time, injected rather than read via
/// `DateTime.now()` so time-dependent logic (e.g. 017's quiet-hours
/// deferral and catch-up interval) is deterministic under test.
abstract class AppClock {
  /// The current local time.
  DateTime now();
}

@LazySingleton(as: AppClock)
class SystemAppClock implements AppClock {
  const SystemAppClock();

  @override
  DateTime now() => DateTime.now();
}
