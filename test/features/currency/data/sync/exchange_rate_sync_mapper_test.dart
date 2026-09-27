import 'dart:convert';

import 'package:daftary/core/database/app_database.dart';
import 'package:daftary/core/sync/sync_entity_type.dart';
import 'package:daftary/features/currency/data/sync/exchange_rate_sync_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ExchangeRateSyncMapper();

  Map<String, Object?> overTheWire(Map<String, Object?> m) =>
      jsonDecode(jsonEncode(m)) as Map<String, Object?>;

  const row = ExchangeRate(
    id: 'rate_USD_EGP',
    currencyCode: 'USD',
    relativeToCurrencyCode: 'EGP',
    rateMicros: 48500000,
    lastUpdatedAt: 1790000000000,
  );

  test('is the exchange_rate mapper', () {
    expect(mapper.type, SyncEntityType.exchangeRate);
  });

  test('emits rate_micros as a string and the pair id', () {
    final wire = mapper.toWire(row);
    expect(wire['rate_micros'], '48500000');
    expect(wire['id'], 'rate_USD_EGP');
    expect(wire['currency_code'], 'USD');
    expect(wire['relative_to_currency_code'], 'EGP');
  });

  test('the id always follows the pair', () {
    expect(ExchangeRateSyncMapper.idFor('SAR', 'EGP'), 'rate_SAR_EGP');
    final legacy = row.copyWith(id: '5f0c-uuid');
    expect(mapper.toWire(legacy)['id'], 'rate_USD_EGP');
  });

  test('round-trips losslessly', () {
    expect(
      mapper.fromWire(overTheWire(mapper.toWire(row))),
      row.toCompanion(false),
    );
    final huge = row.copyWith(rateMicros: 9007199254740993);
    expect(
      mapper.fromWire(overTheWire(mapper.toWire(huge))),
      huge.toCompanion(false),
    );
  });
}
