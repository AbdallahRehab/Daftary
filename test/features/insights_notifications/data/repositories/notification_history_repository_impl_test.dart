import 'package:daftary/core/database/app_database.dart' hide isNull;
import 'package:daftary/features/insights_notifications/data/datasources/notifications_dao.dart';
import 'package:daftary/features/insights_notifications/data/repositories/notification_history_repository_impl.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_history_entry.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_source_type.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// T017 — [NotificationHistoryRepositoryImpl] against an in-memory database:
/// upsert-on-band-change-only, and one row per (source, period).
void main() {
  late AppDatabase db;
  late NotificationHistoryRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    repository = NotificationHistoryRepositoryImpl(NotificationsDao(db));
  });

  NotificationHistoryEntry entry({
    String id = 'h1',
    NotificationSourceType sourceType = NotificationSourceType.budgetCategory,
    String sourceId = 'cat-food',
    String? period = '2026-09',
    ThresholdBand band = ThresholdBand.nearLimit,
    DateTime? at,
  }) {
    return NotificationHistoryEntry(
      id: id,
      sourceType: sourceType,
      sourceId: sourceId,
      applicablePeriod: period,
      lastNotifiedBand: band,
      lastNotifiedAt: at ?? DateTime(2026, 9, 10, 9),
    );
  }

  Future<NotificationHistoryEntry?> find(
    NotificationSourceType type,
    String sourceId,
    String? period,
  ) async => (await repository.find(
    type,
    sourceId,
    period,
  )).getOrElse((f) => fail('unexpected $f'));

  Future<int> rowCount() async =>
      (await db.select(db.notificationHistory).get()).length;

  test('find returns null for a source that was never notified', () async {
    expect(
      await find(NotificationSourceType.budgetCategory, 'cat-food', '2026-09'),
      isNull,
    );
  });

  test('upsert inserts the first entry and find reads it back', () async {
    final stored = (await repository.upsert(
      entry(),
    )).getOrElse((f) => fail('unexpected $f'));

    expect(stored, entry());
    expect(
      await find(NotificationSourceType.budgetCategory, 'cat-food', '2026-09'),
      entry(),
    );
  });

  test('an unchanged band leaves the stored row untouched', () async {
    await repository.upsert(entry());

    final result = await repository.upsert(
      entry(id: 'h2', at: DateTime(2026, 9, 11, 9)),
    );

    final stored = result.getOrElse((f) => fail('unexpected $f'));
    expect(stored.id, 'h1');
    expect(stored.lastNotifiedAt, DateTime(2026, 9, 10, 9));
    expect(await rowCount(), 1);
  });

  test('a changed band updates the same row in place', () async {
    await repository.upsert(entry());

    final at = DateTime(2026, 9, 12, 9);
    await repository.upsert(
      entry(id: 'h2', band: ThresholdBand.exceeded, at: at),
    );

    final stored = await find(
      NotificationSourceType.budgetCategory,
      'cat-food',
      '2026-09',
    );
    expect(stored!.id, 'h1');
    expect(stored.lastNotifiedBand, ThresholdBand.exceeded);
    expect(stored.lastNotifiedAt, at);
    expect(await rowCount(), 1);
  });

  test('a new month is a separate row (FR-016)', () async {
    await repository.upsert(entry());
    await repository.upsert(entry(id: 'h2', period: '2026-10'));

    expect(await rowCount(), 2);
    expect(
      (await find(
        NotificationSourceType.budgetCategory,
        'cat-food',
        '2026-10',
      ))!.id,
      'h2',
    );
  });

  test('savings-goal rows (null period) are also upserted, not '
      'duplicated', () async {
    final goal = entry(
      sourceType: NotificationSourceType.savingsGoal,
      sourceId: 'goal-1',
      period: null,
      band: ThresholdBand.behindPace,
    );
    await repository.upsert(goal);
    await repository.upsert(goal.copyWithId('h2'));
    await repository.upsert(
      entry(
        id: 'h3',
        sourceType: NotificationSourceType.savingsGoal,
        sourceId: 'goal-1',
        period: null,
        band: ThresholdBand.achieved,
      ),
    );

    expect(await rowCount(), 1);
    final stored = await find(
      NotificationSourceType.savingsGoal,
      'goal-1',
      null,
    );
    expect(stored!.lastNotifiedBand, ThresholdBand.achieved);
  });

  test('the same id under a different source type is a different '
      'source', () async {
    await repository.upsert(entry(sourceId: 'same'));
    await repository.upsert(
      entry(
        id: 'h2',
        sourceType: NotificationSourceType.savingsGoal,
        sourceId: 'same',
        period: null,
        band: ThresholdBand.onPace,
      ),
    );
    expect(await rowCount(), 2);
  });

  group('UNIQUE(source_type, source_id, applicable_period)', () {
    Future<void> rawInsert(String id, String? period) => db
        .into(db.notificationHistory)
        .insert(
          NotificationHistoryCompanion.insert(
            id: id,
            sourceType: 'savingsGoal',
            sourceId: 'goal-1',
            applicablePeriod: Value(period),
            lastNotifiedBand: 'onPace',
            lastNotifiedAt: 0,
          ),
        );

    test('rejects a duplicate (source, period) written around the '
        'repository', () async {
      await rawInsert('a', '2026-09');
      await expectLater(rawInsert('b', '2026-09'), throwsA(anything));
    });

    test('also rejects a duplicate when the period is null', () async {
      await rawInsert('a', null);
      await expectLater(rawInsert('b', null), throwsA(anything));
    });
  });
}

extension on NotificationHistoryEntry {
  NotificationHistoryEntry copyWithId(String id) => NotificationHistoryEntry(
    id: id,
    sourceType: sourceType,
    sourceId: sourceId,
    applicablePeriod: applicablePeriod,
    lastNotifiedBand: lastNotifiedBand,
    lastNotifiedAt: lastNotifiedAt,
  );
}
