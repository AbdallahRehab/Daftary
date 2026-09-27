import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/people/data/sync/person_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = PersonSyncMapper();

  const row = PeopleData(
    id: 'p1',
    name: 'Mona Ali',
    normalizedName: 'mona ali',
    phoneNumber: '+201000000000',
    avatarPath: '/data/user/0/app/avatars/p1.jpg',
    relationshipTag: 'friend',
    notes: 'Neighbour',
    isArchived: true,
    createdAt: 1700000000123,
    updatedAt: 1700000500456,
  );

  test('is the person mapper', () {
    expect(mapper.type, SyncEntityType.person);
  });

  test('emits exactly the person wire fields', () {
    final wire = mapper.toWire(row);
    expect(wire.keys.toSet(), {
      'id',
      'name',
      'normalized_name',
      'phone_number',
      'relationship_tag',
      'notes',
      'is_archived',
      'client_created_at',
      'client_updated_at',
      'deleted_at',
    });
    expect(wire['client_created_at'], '2023-11-14T22:13:20.123Z');
    expect(wire['is_archived'], true);
  });

  test('never emits avatar_path', () {
    final wire = mapper.toWire(row);
    expect(wire.containsKey('avatar_path'), isFalse);
    expect(jsonEncode(wire), isNot(contains('avatars/p1.jpg')));
  });

  test('round-trips losslessly apart from avatarPath', () {
    final wire =
        jsonDecode(jsonEncode(mapper.toWire(row))) as Map<String, Object?>;
    final back = mapper.fromWire(wire);
    expect(
      back,
      row.copyWith(avatarPath: const Value(null)).toCompanion(false),
    );
  });

  test('keeps the existing local avatarPath on apply', () {
    final wire = mapper.toWire(row.copyWith(name: 'Mona A.'));
    final back = mapper.fromWire(wire, existingLocal: row);
    expect(back.avatarPath, const Value('/data/user/0/app/avatars/p1.jpg'));
    expect(back.name, const Value('Mona A.'));
  });

  test('nullable fields round-trip as null', () {
    const bare = PeopleData(
      id: 'p2',
      name: 'X',
      normalizedName: 'x',
      isArchived: false,
      createdAt: 1,
      updatedAt: 2,
    );
    expect(mapper.fromWire(mapper.toWire(bare)), bare.toCompanion(false));
  });

  test('rejects a malformed payload', () {
    final wire = mapper.toWire(row)..['is_archived'] = 'yes';
    expect(() => mapper.fromWire(wire), throwsFormatException);
  });
}
