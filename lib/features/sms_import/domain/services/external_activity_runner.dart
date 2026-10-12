/// Runs work that shows a system activity (the permission dialog) without
/// App Lock treating it as leaving the app. Keeps the domain free of the
/// Flutter lifecycle observer.
abstract class ExternalActivityRunner {
  /// Completes with [body]'s result once the activity returns.
  Future<T> run<T>(Future<T> Function() body);
}
