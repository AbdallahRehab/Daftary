/// Whether the app is in the resumed state. Scans stop between pages when
/// it is not (FR-008a).
abstract class AppLifecycleStateSource {
  bool get isResumed;
}
