import 'package:daftary/core/database/app_database.dart'
    hide NotificationPreference, isNull;
import 'package:daftary/features/insights_notifications/data/datasources/notifications_dao.dart';
import 'package:daftary/features/insights_notifications/data/repositories/notification_preference_repository_impl.dart';
import 'package:daftary/features/insights_notifications/domain/entities/notification_preference.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late NotificationPreferenceRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    repository = NotificationPreferenceRepositoryImpl(NotificationsDao(db));
  });

  Future<NotificationPreference> load() async =>
      (await repository.getPreference()).getOrElse(
        (f) => fail('unexpected $f'),
      );

  test('with no stored row, returns the defaults: off, both categories on, '
      'no quiet hours, no permission (FR-010)', () async {
    final preference = await load();

    expect(preference, NotificationPreference.defaults);
    expect(preference.isEnabled, isFalse);
    expect(preference.budgetWarningsEnabled, isTrue);
    expect(preference.savingsCheckInsEnabled, isTrue);
    expect(preference.hasQuietHours, isFalse);
    expect(preference.osPermissionGranted, isFalse);
    expect(await db.select(db.notificationPreferences).get(), isEmpty);
  });

  test('save round-trips every field', () async {
    const preference = NotificationPreference(
      isEnabled: true,
      budgetWarningsEnabled: false,
      savingsCheckInsEnabled: true,
      quietHoursStart: 22 * 60,
      quietHoursEnd: 8 * 60,
      osPermissionGranted: true,
    );

    final saved = await repository.savePreference(preference);

    expect(saved.getOrElse((f) => fail('unexpected $f')), preference);
    expect(await load(), preference);
  });

  test('saving again replaces the single row', () async {
    await repository.savePreference(
      NotificationPreference.defaults.copyWith(
        isEnabled: true,
        quietHoursStart: 60,
        quietHoursEnd: 120,
      ),
    );
    await repository.savePreference(
      (await load()).copyWith(clearQuietHours: true),
    );

    expect(await db.select(db.notificationPreferences).get(), hasLength(1));
    final preference = await load();
    expect(preference.isEnabled, isTrue);
    expect(preference.quietHoursStart, isNull);
    expect(preference.quietHoursEnd, isNull);
  });
}
