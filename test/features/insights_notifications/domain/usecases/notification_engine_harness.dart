import 'package:daftary/core/date/app_clock.dart';
import 'package:daftary/core/error/failure.dart';
import 'package:daftary/features/insights_notifications/data/services/localized_notification_composer.dart';
import 'package:daftary/features/insights_notifications/domain/entities/composed_notification.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:daftary/features/insights_notifications/domain/ports/budget_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/ports/notification_language_provider.dart';
import 'package:daftary/features/insights_notifications/domain/ports/savings_insights_source.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_history_repository.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_last_run_store.dart';
import 'package:daftary/features/insights_notifications/domain/repositories/notification_preference_repository.dart';
import 'package:daftary/features/insights_notifications/domain/services/evaluate_budget_notifications.dart';
import 'package:daftary/features/insights_notifications/domain/services/evaluate_savings_goal_notifications.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_phrasing_service.dart';
import 'package:daftary/features/insights_notifications/domain/services/notification_scheduler.dart';
import 'package:daftary/features/insights_notifications/domain/usecases/notification_engine.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

/// Shared fixture for the `NotificationEngine` suites (T021/T022,
/// T029/T030). Every I/O boundary is mocked; the two pure evaluators and
/// the `gen_l10n` composer are the real ones, so a test observes the same
/// band and wording production would.

class MockPreferenceRepository extends Mock
    implements NotificationPreferenceRepository {}

class MockHistoryRepository extends Mock
    implements NotificationHistoryRepository {}

class MockBudgetSource extends Mock implements BudgetInsightsSource {}

class MockSavingsSource extends Mock implements SavingsInsightsSource {}

class MockPhrasingService extends Mock implements NotificationPhrasingService {}

class MockScheduler extends Mock implements NotificationScheduler {}

class FakeClock implements AppClock {
  FakeClock(this.current);

  DateTime current;

  @override
  DateTime now() => current;
}

class FakeLanguageProvider implements NotificationLanguageProvider {
  String code = 'en';

  @override
  Future<String> currentLanguageCode() async => code;
}

class FakeLastRunStore implements NotificationLastRunStore {
  DateTime? value;

  @override
  Future<DateTime?> read() async => value;

  @override
  Future<void> write(DateTime completedAt) async => value = completedAt;
}

/// A stateful history double for multi-run cooldown scenarios, with the
/// same band-change-only upsert semantics as the real repository.
class InMemoryHistoryRepository implements NotificationHistoryRepository {
  final Map<String, NotificationHistoryEntry> rows = {};

  static String _key(NotificationSourceType t, String id, String? period) =>
      '${t.name}|$id|$period';

  @override
  Future<Either<Failure, NotificationHistoryEntry?>> find(
    NotificationSourceType sourceType,
    String sourceId,
    String? applicablePeriod,
  ) async => Right(rows[_key(sourceType, sourceId, applicablePeriod)]);

  @override
  Future<Either<Failure, NotificationHistoryEntry>> upsert(
    NotificationHistoryEntry entry,
  ) async {
    final key = _key(entry.sourceType, entry.sourceId, entry.applicablePeriod);
    final existing = rows[key];
    if (existing != null &&
        existing.lastNotifiedBand == entry.lastNotifiedBand) {
      return Right(existing);
    }
    return Right(rows[key] = entry);
  }
}

const enabledPreference = NotificationPreference(
  isEnabled: true,
  budgetWarningsEnabled: true,
  savingsCheckInsEnabled: true,
  osPermissionGranted: true,
);

NotificationHistoryEntry historyEntry({
  required NotificationSourceType type,
  required String sourceId,
  required ThresholdBand band,
  String? period,
}) => NotificationHistoryEntry(
  id: 'h-$sourceId',
  sourceType: type,
  sourceId: sourceId,
  applicablePeriod: period,
  lastNotifiedBand: band,
  lastNotifiedAt: DateTime(2026, 9, 1),
);

class EngineHarness {
  EngineHarness({DateTime? now, NotificationHistoryRepository? history})
    : clock = FakeClock(now ?? DateTime(2026, 9, 24, 12)),
      history = history ?? MockHistoryRepository() {
    registerDefaults();
  }

  static void registerFallbacks() {
    registerFallbackValue(
      const ComposedNotification(
        title: '',
        body: '',
        deepLinkTarget: NotificationDeepLinkTarget(
          type: NotificationSourceType.savingsGoal,
          id: 'fallback',
        ),
      ),
    );
    registerFallbackValue(
      historyEntry(
        type: NotificationSourceType.savingsGoal,
        sourceId: 'fallback',
        band: ThresholdBand.onPace,
      ),
    );
    registerFallbackValue(NotificationSourceType.budgetCategory);
  }

  final preferences = MockPreferenceRepository();
  final NotificationHistoryRepository history;
  final budgetSource = MockBudgetSource();
  final savingsSource = MockSavingsSource();
  final phrasing = MockPhrasingService();
  final scheduler = MockScheduler();
  final FakeClock clock;
  final language = FakeLanguageProvider();
  final lastRun = FakeLastRunStore();

  MockHistoryRepository get historyMock => history as MockHistoryRepository;

  late final NotificationEngine engine = NotificationEngineImpl(
    preferences,
    history,
    budgetSource,
    savingsSource,
    const EvaluateBudgetNotificationsImpl(),
    const EvaluateSavingsGoalNotificationsImpl(),
    const LocalizedNotificationComposer(),
    phrasing,
    scheduler,
    clock,
    language,
    lastRun,
  );

  void registerDefaults() {
    givenPreference(enabledPreference);
    givenBudgets(const []);
    givenGoals(const []);
    when(() => phrasing.compose(any())).thenAnswer(
      (i) async => i.positionalArguments.first as ComposedNotification,
    );
    when(
      () => scheduler.scheduleOrDeliver(
        any(),
        deliverAt: any(named: 'deliverAt'),
      ),
    ).thenAnswer((_) async => const Right(unit));
    if (history is MockHistoryRepository) {
      when(
        () => historyMock.find(any(), any(), any()),
      ).thenAnswer((_) async => const Right(null));
      when(() => historyMock.upsert(any())).thenAnswer(
        (i) async =>
            Right(i.positionalArguments.first as NotificationHistoryEntry),
      );
    }
  }

  void givenPreference(NotificationPreference preference) {
    when(
      () => preferences.getPreference(),
    ).thenAnswer((_) async => Right(preference));
  }

  void givenBudgets(List<BudgetCategorySnapshot> categories) {
    when(
      () => budgetSource.currentMonthCategories(),
    ).thenAnswer((_) async => Right(categories));
  }

  void givenGoals(List<SavingsGoalSnapshot> goals) {
    when(
      () => savingsSource.activeGoals(),
    ).thenAnswer((_) async => Right(goals));
  }

  void givenHistory(NotificationHistoryEntry entry) {
    when(
      () => historyMock.find(
        entry.sourceType,
        entry.sourceId,
        entry.applicablePeriod,
      ),
    ).thenAnswer((_) async => Right(entry));
  }

  /// Every notification handed to the scheduler, in order.
  List<ComposedNotification> scheduled() => verify(
    () => scheduler.scheduleOrDeliver(
      captureAny(),
      deliverAt: any(named: 'deliverAt'),
    ),
  ).captured.cast<ComposedNotification>();

  void verifyNothingScheduled() => verifyNever(
    () =>
        scheduler.scheduleOrDeliver(any(), deliverAt: any(named: 'deliverAt')),
  );

  /// Every history row upserted, in order.
  List<NotificationHistoryEntry> upserted() => verify(
    () => historyMock.upsert(captureAny()),
  ).captured.cast<NotificationHistoryEntry>();
}
