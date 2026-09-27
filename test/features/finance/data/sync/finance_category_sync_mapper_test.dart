import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/finance/data/sync/finance_category_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = FinanceCategorySyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  const custom = FinanceCategory(
    id: 'c1',
    name: 'Pets',
    normalizedName: 'pets',
    type: 'expense',
    icon: 'pets',
    isDefault: false,
    isArchived: true,
    createdAt: 1790000000000,
    updatedAt: 1790000100000,
  );

  const rentSeed = FinanceCategory(
    id: 'seed_rent',
    name: 'Rent',
    normalizedName: 'rent',
    type: 'expense',
    icon: 'rent',
    isDefault: true,
    isArchived: false,
    createdAt: 1,
    updatedAt: 1,
  );

  test('is the finance_category mapper', () {
    expect(mapper.type, SyncEntityType.financeCategory);
  });

  test('maps icon to icon_key and carries type and is_default', () {
    final wire = mapper.toWire(rentSeed);
    expect(wire['icon_key'], 'rent');
    expect(wire.containsKey('icon'), isFalse);
    expect(wire['type'], 'expense');
    expect(wire['is_default'], true);
  });

  test('round-trips custom and seeded categories losslessly', () {
    for (final row in [custom, rentSeed]) {
      expect(
        mapper.fromWire(overTheWire(mapper.toWire(row))),
        row.toCompanion(false),
      );
    }
  });

  test('rejects an unknown type', () {
    expect(
      () => mapper.fromWire(mapper.toWire(custom)..['type'] = 'saving'),
      throwsFormatException,
    );
  });

  group('isPristineSeed', () {
    test('an untouched seed is pristine', () {
      expect(isPristineSeed(rentSeed), isTrue);
    });

    test('a renamed seed is not pristine', () {
      expect(isPristineSeed(rentSeed.copyWith(name: 'Home rent')), isFalse);
    });

    test('an archived seed is not pristine', () {
      expect(isPristineSeed(rentSeed.copyWith(isArchived: true)), isFalse);
    });

    test('a re-iconed seed is not pristine', () {
      expect(isPristineSeed(rentSeed.copyWith(icon: 'other')), isFalse);
    });

    test('a custom category or unknown seed key is not pristine', () {
      expect(isPristineSeed(custom), isFalse);
      expect(isPristineSeed(rentSeed.copyWith(id: 'seed_unknown')), isFalse);
    });
  });
}
