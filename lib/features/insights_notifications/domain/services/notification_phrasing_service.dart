import '../entities/composed_notification.dart';

/// An optional rewording step over an already-composed notification
/// (research.md Decision 3).
///
/// The parameter type is the whole guarantee: an implementation only ever
/// receives finished title/body text built from real 010/011 values, never
/// a raw candidate or snapshot, so it has no number of its own to supply
/// (FR-008). A future AI-backed implementation may change tone, never
/// facts.
abstract class NotificationPhrasingService {
  Future<ComposedNotification> compose(ComposedNotification draft);
}
