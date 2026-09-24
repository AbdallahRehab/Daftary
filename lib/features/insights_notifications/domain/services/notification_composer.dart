import '../entities/composed_notification.dart';
import '../entities/notification_candidate.dart';

/// Turns a classified candidate into a worded [ComposedNotification] through
/// the app's parameterized `gen_l10n` templates (FR-007) — never string
/// concatenation. Every number in the text comes from the candidate, which
/// in turn came from 010/011 unchanged.
abstract class NotificationComposer {
  /// `null` for [ThresholdBand.belowWarning]: returning under the warning
  /// line is not something this feature notifies about.
  ComposedNotification? composeBudget(
    BudgetNotificationCandidate candidate, {
    required String languageCode,
  });

  /// `null` for [ThresholdBand.onPace] and
  /// [ThresholdBand.noEstimateAvailable]: neither has a message.
  ComposedNotification? composeSavingsGoal(
    SavingsGoalNotificationCandidate candidate, {
    required String languageCode,
  });
}
