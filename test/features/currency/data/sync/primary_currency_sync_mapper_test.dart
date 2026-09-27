import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/sync/primary_currency_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = PrimaryCurrencySyncMapper();

  const row = PrimaryCurrencySetting(
    id: 'singleton',
    currencyCode: 'USD',
    updatedAt: 1790000000000,
  );

  test('is the primary_currency mapper', () {
    expect(mapper.type, SyncEntityType.primaryCurrency);
  });

  test("uses the id 'singleton' and carries currency_code", () {
    final wire = mapper.toWire(row);
    expect(wire['id'], 'singleton');
    expect(wire['currency_code'], 'USD');
    expect(wire['client_updated_at'], '2026-09-21T14:13:20.000Z');
  });

  test('round-trips losslessly', () {
    final wire =
        jsonDecode(jsonEncode(mapper.toWire(row))) as Map<String, Object?>;
    expect(mapper.fromWire(wire), row.toCompanion(false));
  });
}
