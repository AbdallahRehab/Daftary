import 'dart:ui';

import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/numeral_locale.dart';
import '../../domain/entities/composed_notification.dart';
import '../../domain/entities/notification_candidate.dart';
import '../../domain/entities/notification_history_entry.dart';
import '../../domain/entities/notification_source_type.dart';
import '../../domain/services/notification_composer.dart';

/// [NotificationComposer] over [AppLocalizations]. Resolves strings through
/// `lookupAppLocalizations`, so it works outside any widget tree — a
/// background recomputation has no `BuildContext`.
@LazySingleton(as: NotificationComposer)
class LocalizedNotificationComposer implements NotificationComposer {
  const LocalizedNotificationComposer();

  @override
  ComposedNotification? composeBudget(
    BudgetNotificationCandidate candidate, {
    required String languageCode,
  }) {
    final l10n = _l10n(languageCode);
    final category = candidate.categoryName;
    final percent = candidate.percentageUsed;

    final String title;
    final String body;
    switch (candidate.band) {
      case ThresholdBand.nearLimit:
        title = l10n.notificationBudgetNearLimitTitle(category);
        body = l10n.notificationBudgetNearLimitBody(
          category,
          _formatPercent(percent ?? 0, languageCode),
        );
      case ThresholdBand.exceeded:
        title = l10n.notificationBudgetExceededTitle(category);
        // A zero-planned allocation has no percentage (010 data-model.md).
        body = percent == null
            ? l10n.notificationBudgetExceededNoPlanBody(category)
            : l10n.notificationBudgetExceededBody(
                category,
                _formatPercent(percent, languageCode),
              );
      default:
        return null;
    }

    return ComposedNotification(
      title: title,
      body: body,
      deepLinkTarget: NotificationDeepLinkTarget(
        type: NotificationSourceType.budgetCategory,
        id: candidate.categoryId,
        applicablePeriod: candidate.applicablePeriod,
      ),
    );
  }

  @override
  ComposedNotification? composeSavingsGoal(
    SavingsGoalNotificationCandidate candidate, {
    required String languageCode,
  }) {
    final l10n = _l10n(languageCode);
    final goal = candidate.goalName;
    final months = candidate.monthsAheadOrBehind.abs();

    final String title;
    final String body;
    switch (candidate.band) {
      case ThresholdBand.behindPace:
        title = l10n.notificationSavingsBehindPaceTitle(goal);
        body = l10n.notificationSavingsBehindPaceBody(goal, months);
      case ThresholdBand.aheadOfPace:
        title = l10n.notificationSavingsAheadOfPaceTitle(goal);
        body = l10n.notificationSavingsAheadOfPaceBody(goal, months);
      case ThresholdBand.achieved:
        title = l10n.notificationSavingsAchievedTitle(goal);
        body = l10n.notificationSavingsAchievedBody(goal);
      default:
        return null;
    }

    return ComposedNotification(
      title: title,
      body: body,
      deepLinkTarget: NotificationDeepLinkTarget(
        type: NotificationSourceType.savingsGoal,
        id: candidate.goalId,
      ),
    );
  }

  static AppLocalizations _l10n(String languageCode) {
    final supported = AppLocalizations.supportedLocales.any(
      (l) => l.languageCode == languageCode,
    );
    return lookupAppLocalizations(Locale(supported ? languageCode : 'en'));
  }

  /// Whole percent, rounded down so a category at 99.6% never reads as the
  /// "100%" an exceeded one would; Western digits in both languages
  /// ([numeralLocaleFor]).
  static String _formatPercent(double percent, String languageCode) =>
      NumberFormat.decimalPattern(
        numeralLocaleFor(languageCode),
      ).format(percent.floor());
}
