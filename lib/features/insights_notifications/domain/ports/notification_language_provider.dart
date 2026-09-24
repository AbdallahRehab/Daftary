/// The language a notification should be worded in — the app's current
/// display language, resolved outside any widget tree (a recomputation pass
/// has no `BuildContext`).
abstract class NotificationLanguageProvider {
  /// An ISO 639-1 code such as `'en'` or `'ar'`.
  Future<String> currentLanguageCode();
}
