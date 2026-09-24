import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/date/app_clock.dart';
import '../../../../core/error/failure.dart';
import '../entities/composed_notification.dart';
import '../entities/notification_history_entry.dart';
import '../entities/notification_preference.dart';
import '../entities/notification_source_type.dart';
import '../ports/budget_insights_source.dart';
import '../ports/notification_language_provider.dart';
import '../ports/savings_insights_source.dart';
import '../repositories/notification_history_repository.dart';
import '../repositories/notification_last_run_store.dart';
import '../repositories/notification_preference_repository.dart';
import '../services/evaluate_budget_notifications.dart';
import '../services/evaluate_savings_goal_notifications.dart';
import '../services/notification_composer.dart';
import '../services/notification_phrasing_service.dart';
import '../services/notification_scheduler.dart';
import '../services/quiet_hours.dart';

/// Diagnostics for one recomputation pass (contracts/notification_engine.md)
/// — for logs and tests, never shown to the user.
class NotificationRunSummary extends Equatable {
  const NotificationRunSummary({
    this.evaluatedCount = 0,
    this.notifiedCount = 0,
    this.deferredCount = 0,
    this.failures = const [],
  });

  /// What a pass with the feature disabled returns (FR-018).
  static const NotificationRunSummary empty = NotificationRunSummary();

  /// Candidates classified this pass (budget categories plus savings goals
  /// that have a plan; FR-005 goals are not candidates).
  final int evaluatedCount;

  /// Notifications the scheduler accepted — delivered now or deferred.
  final int notifiedCount;

  /// The subset of [notifiedCount] scheduled for the end of quiet hours
  /// (FR-013).
  final int deferredCount;

  /// Every per-source or per-candidate failure. None of them stopped the
  /// rest of the pass.
  final List<Failure> failures;

  @override
  List<Object?> get props => [
    evaluatedCount,
    notifiedCount,
    deferredCount,
    failures,
  ];
}

/// The recomputation entry point (contracts/notification_engine.md), run by
/// `NotificationRecomputeTrigger`.
abstract class NotificationEngine {
  /// One full pass. `Left` only when the preference itself cannot be read;
  /// every later failure is recorded in the summary and the pass carries
  /// on. Safe to call repeatedly — an unchanged band never re-notifies
  /// (FR-015).
  Future<Either<Failure, NotificationRunSummary>> run();
}

/// Per candidate:
///
/// 1. Look up its history row — budgets by (category, month), savings goals
///    by goal id alone.
/// 2. Same band as recorded → nothing to do (FR-015).
/// 3. Otherwise notify when the band *changed from a known band* into one
///    the composer has a message for. A budget category with no row for
///    this month counts as having been [ThresholdBand.belowWarning] — a new
///    month resets every band (FR-016), so crossing 90% in it must notify.
///    A savings goal with no row at all is "unknown" and is only recorded,
///    never notified (data-model.md), so enabling the feature never
///    announces an achievement that happened long ago.
/// 4. Record the new band, whether or not a notification went out — also
///    when delivery failed, so a failure is never retried into a burst of
///    stale notifications on every later pass.
@LazySingleton(as: NotificationEngine)
class NotificationEngineImpl implements NotificationEngine {
  NotificationEngineImpl(
    this._preferences,
    this._history,
    this._budgetSource,
    this._savingsSource,
    this._evaluateBudget,
    this._evaluateSavings,
    this._composer,
    this._phrasing,
    this._scheduler,
    this._clock,
    this._language,
    this._lastRun,
  );

  final NotificationPreferenceRepository _preferences;
  final NotificationHistoryRepository _history;
  final BudgetInsightsSource _budgetSource;
  final SavingsInsightsSource _savingsSource;
  final EvaluateBudgetNotifications _evaluateBudget;
  final EvaluateSavingsGoalNotifications _evaluateSavings;
  final NotificationComposer _composer;
  final NotificationPhrasingService _phrasing;
  final NotificationScheduler _scheduler;
  final AppClock _clock;
  final NotificationLanguageProvider _language;
  final NotificationLastRunStore _lastRun;

  static const _uuid = Uuid();

  @override
  Future<Either<Failure, NotificationRunSummary>> run() async {
    final preferenceResult = await _preferences.getPreference();
    if (preferenceResult case Left(:final value)) return Left(value);
    final preference = preferenceResult.getOrElse(
      (_) => NotificationPreference.defaults,
    );

    final now = _clock.now();
    if (!preference.isEnabled) {
      await _lastRun.write(now);
      return const Right(NotificationRunSummary.empty);
    }

    final pass = _Pass(
      now: now,
      deliverAt: quietHoursDeliveryTime(preference, now),
      languageCode: await _language.currentLanguageCode(),
    );

    if (preference.budgetWarningsEnabled) await _runBudgets(pass);
    if (preference.savingsCheckInsEnabled) await _runSavings(pass);

    await _lastRun.write(now);
    return Right(pass.summary());
  }

  Future<void> _runBudgets(_Pass pass) async {
    final result = await _budgetSource.currentMonthCategories();
    final categories = result.fold((failure) {
      pass.failures.add(failure);
      return const <BudgetCategorySnapshot>[];
    }, (categories) => categories);

    for (final candidate in _evaluateBudget.evaluate(categories)) {
      await _process(
        pass,
        sourceType: NotificationSourceType.budgetCategory,
        sourceId: candidate.categoryId,
        applicablePeriod: candidate.applicablePeriod,
        band: candidate.band,
        bandWhenUnrecorded: ThresholdBand.belowWarning,
        compose: () =>
            _composer.composeBudget(candidate, languageCode: pass.languageCode),
      );
    }
  }

  Future<void> _runSavings(_Pass pass) async {
    final result = await _savingsSource.activeGoals();
    final goals = result.fold((failure) {
      pass.failures.add(failure);
      return const <SavingsGoalSnapshot>[];
    }, (goals) => goals);

    for (final goal in goals) {
      final candidate = _evaluateSavings.evaluate(goal, now: pass.now);
      if (candidate == null) continue; // FR-005: no plan, nothing to say.
      await _process(
        pass,
        sourceType: NotificationSourceType.savingsGoal,
        sourceId: candidate.goalId,
        applicablePeriod: null,
        band: candidate.band,
        bandWhenUnrecorded: null,
        compose: () => _composer.composeSavingsGoal(
          candidate,
          languageCode: pass.languageCode,
        ),
      );
    }
  }

  /// [bandWhenUnrecorded] is the band assumed when no history row exists;
  /// `null` means "unknown", which never notifies.
  Future<void> _process(
    _Pass pass, {
    required NotificationSourceType sourceType,
    required String sourceId,
    required String? applicablePeriod,
    required ThresholdBand band,
    required ThresholdBand? bandWhenUnrecorded,
    required ComposedNotification? Function() compose,
  }) async {
    pass.evaluated++;
    try {
      final found = await _history.find(sourceType, sourceId, applicablePeriod);
      if (found case Left(:final value)) {
        pass.failures.add(value);
        return;
      }
      final recorded = found.getOrElse((_) => null)?.lastNotifiedBand;
      if (recorded == band) return;

      final previous = recorded ?? bandWhenUnrecorded;
      if (previous != null && previous != band) {
        final draft = compose();
        if (draft != null) await _deliver(pass, draft);
      }

      final saved = await _history.upsert(
        NotificationHistoryEntry(
          id: _uuid.v4(),
          sourceType: sourceType,
          sourceId: sourceId,
          applicablePeriod: applicablePeriod,
          lastNotifiedBand: band,
          lastNotifiedAt: pass.now,
        ),
      );
      if (saved case Left(:final value)) pass.failures.add(value);
    } catch (e) {
      pass.failures.add(
        UnknownFailure('Notification pass failed for $sourceId: $e'),
      );
    }
  }

  Future<void> _deliver(_Pass pass, ComposedNotification draft) async {
    final notification = await _phrasing.compose(draft);
    final result = await _scheduler.scheduleOrDeliver(
      notification,
      deliverAt: pass.deliverAt,
    );
    result.fold(pass.failures.add, (_) {
      pass.notified++;
      if (pass.deliverAt != null) pass.deferred++;
    });
  }
}

/// Mutable bookkeeping for one [NotificationEngineImpl.run] call.
class _Pass {
  _Pass({
    required this.now,
    required this.deliverAt,
    required this.languageCode,
  });

  final DateTime now;

  /// Non-null while inside quiet hours (FR-013).
  final DateTime? deliverAt;
  final String languageCode;

  int evaluated = 0;
  int notified = 0;
  int deferred = 0;
  final List<Failure> failures = [];

  NotificationRunSummary summary() => NotificationRunSummary(
    evaluatedCount: evaluated,
    notifiedCount: notified,
    deferredCount: deferred,
    failures: List.unmodifiable(failures),
  );
}
