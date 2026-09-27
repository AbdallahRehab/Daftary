import 'dart:async';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/database/watch_tables.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late List<void> events;
  late StreamSubscription<void> sub;

  const settle = Duration(milliseconds: 150);

  Future<void> insertPerson(String id) => db
      .into(db.people)
      .insert(
        PeopleCompanion.insert(
          id: id,
          name: 'Name $id',
          normalizedName: 'name $id',
          createdAt: 1,
          updatedAt: 1,
        ),
      );

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Open (and seed) before listening, so setup writes are not counted.
    await db.customSelect('SELECT 1').get();
    events = [];
    sub = db.changesOf({db.people, db.moneyTransactions}).listen(events.add);
    await Future<void>.delayed(settle);
  });

  tearDown(() async {
    await sub.cancel();
    await db.close();
  });

  test('emits once immediately', () {
    expect(events, hasLength(1));
  });

  test('a write to a watched table emits one event', () async {
    await insertPerson('p1');
    await Future<void>.delayed(settle);
    expect(events, hasLength(2));
  });

  test('a write to an unwatched table emits nothing', () async {
    await db
        .into(db.appSettings)
        .insert(
          AppSettingsCompanion.insert(
            id: 'singleton',
            languageCode: 'en',
            updatedAt: 1,
          ),
        );
    await Future<void>.delayed(settle);
    expect(events, hasLength(1));
  });

  test('five writes within 50 ms collapse into one event', () async {
    for (var i = 0; i < 5; i++) {
      await insertPerson('p$i');
    }
    await Future<void>.delayed(settle);
    expect(events, hasLength(2));
  });
}
