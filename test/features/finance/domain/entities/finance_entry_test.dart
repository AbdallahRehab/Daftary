import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry.dart';
import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T032: `importSource` on `FinanceEntry` (data-model §3.6).
void main() {
  final day = DateTime(2026, 3, 4);

  FinanceEntry entry({ImportProvenance? importSource}) => FinanceEntry(
    id: 'e-1',
    idempotencyKey: 'key-1',
    categoryId: 'cat-1',
    type: FinanceEntryType.expense,
    amount: const Money.egp(12550),
    date: day,
    createdAt: day,
    importSource: importSource,
  );

  test('importSource defaults to null (not imported)', () {
    final existing = FinanceEntry(
      id: 'e-1',
      idempotencyKey: 'key-1',
      categoryId: 'cat-1',
      type: FinanceEntryType.expense,
      amount: const Money.egp(12550),
      date: day,
      createdAt: day,
    );
    expect(existing.importSource, isNull);
    expect(existing, entry());
  });

  test('importSource takes part in equality', () {
    expect(
      entry(importSource: ImportProvenance.sms),
      entry(importSource: ImportProvenance.sms),
    );
    expect(entry(importSource: ImportProvenance.sms), isNot(entry()));
  });
}
