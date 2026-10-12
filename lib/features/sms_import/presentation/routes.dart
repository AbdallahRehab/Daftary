/// Route paths of the bank-message import screens (ui-contract §1),
/// declared in `app_router.dart` inside the People-branch `ShellRoute`.
///
/// Nothing sensitive is ever part of a path: the review route carries only
/// the pending item's UUID, and the paste route carries no text (shared
/// text lives only in the in-memory `SharedTextInbox`; FR-016a, FR-080).
/// Static paths must be declared before [reviewPattern], so no literal is
/// captured as an id.
abstract final class BankMessagesRoutes {
  /// The pending list, scan entry and state banners.
  static const String hub = '/bank-messages';

  /// The hub's query parameter that starts a scan on open (Settings'
  /// "Scan now"). A command, never content.
  static const String scanQuery = 'scan';

  /// The hub, starting a scan on open.
  static const String hubScan = '$hub?$scanQuery=now';

  /// Explanation -> permission -> window -> scan.
  static const String enable = '$hub/enable';

  /// Paste or share entry. No text in the URL.
  static const String paste = '$hub/paste';

  /// The 30-day Undo list.
  static const String ignored = '$hub/ignored';

  /// Muted senders (FR-065).
  static const String senders = '$hub/senders';

  /// Learned categories (FR-056).
  static const String learned = '$hub/learned';

  /// The review route's path parameter.
  static const String importIdParam = 'importId';

  /// The review route as declared in the router (declared last).
  static const String reviewPattern = '$hub/review/:$importIdParam';

  /// The review location of one pending item, by id only.
  static String review(String importId) =>
      '$hub/review/${Uri.encodeComponent(importId)}';

  /// The Settings entry, next to `/settings/ai-assistant` (FR-050c).
  static const String settings = '/settings/bank-messages';
}
