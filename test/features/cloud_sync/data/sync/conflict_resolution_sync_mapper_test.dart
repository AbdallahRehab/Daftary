import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/cloud_sync/data/sync/conflict_resolution_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ConflictResolutionSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  final row = ConflictResolutionRow(
    id: 'r1',
    entityType: 'money_transaction',
    entityId: 't1',
    chosenSide: 'local',
    discardedValuesJson: jsonEncode({
      'amount_minor': '150000',
      'note': 'server note',
    }),
    resolvedAt: 1790000000000,
  );

  test('is the conflict_resolution mapper', () {
    expect(mapper.type, SyncEntityType.conflictResolution);
  });

  test('emits discarded_values as an object and resolved_at as ISO', () {
    final wire = mapper.toWire(row);
    expect(wire['discarded_values'], {
      'amount_minor': '150000',
      'note': 'server note',
    });
    expect(wire['resolved_at'], '2026-09-21T14:13:20.000Z');
    expect(wire['chosen_side'], 'local');
    expect(wire['entity_type'], 'money_transaction');
  });

  test('round-trips losslessly for both entity types and sides', () {
    for (final entityType in ['money_transaction', 'finance_entry']) {
      for (final side in ['local', 'server']) {
        final r = row.copyWith(entityType: entityType, chosenSide: side);
        expect(
          mapper.fromWire(overTheWire(mapper.toWire(r))),
          r.toCompanion(false),
        );
      }
    }
  });

  test('rejects an unknown entity type or side', () {
    expect(
      () => mapper.fromWire(mapper.toWire(row)..['entity_type'] = 'person'),
      throwsFormatException,
    );
    expect(
      () => mapper.fromWire(mapper.toWire(row)..['chosen_side'] = 'both'),
      throwsFormatException,
    );
  });
}
