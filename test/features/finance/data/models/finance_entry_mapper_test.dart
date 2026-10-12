import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/finance/data/models/finance_entry_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023: the local `finance_entries.import_source` column maps to
/// `FinanceEntry.importSource`.
void main() {
  db.FinanceEntry buildRow({String? importSource}) => db.FinanceEntry(
    id: 'e1',
    idempotencyKey: 'k1',
    categoryId: 'c1',
    type: 'expense',
    amountMinorUnits: 150000,
    currencyCode: 'EGP',
    date: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    importSource: importSource,
  );

  test('NULL reads as not imported', () {
    expect(buildRow().toDomain().importSource, isNull);
  });

  test("'sms' reads as the SMS provenance", () {
    final entry = buildRow(importSource: 'sms').toDomain();
    expect(entry.importSource, ImportProvenance.sms);
    expect(entry.importSource!.isSms, isTrue);
  });

  test('an unknown value is kept unchanged and never throws', () {
    final entry = buildRow(importSource: 'wallet').toDomain();
    expect(entry.importSource!.isUnknown, isTrue);
    expect(entry.importSource!.wire, 'wallet');
  });

  test('the field takes part in equality', () {
    expect(
      buildRow(importSource: 'sms').toDomain(),
      isNot(buildRow().toDomain()),
    );
  });
}
