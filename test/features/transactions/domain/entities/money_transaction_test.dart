import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/core/provenance/record_provenance.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T032: `importSource` on `MoneyTransaction` and the derived
/// `provenance` getter (data-model §3.6, analysis M8).
void main() {
  final day = DateTime(2026, 3, 4);

  MoneyTransaction transaction({
    TransactionSource source = TransactionSource.manual,
    String? ocrScanId,
    ImportProvenance? importSource,
  }) => MoneyTransaction(
    id: 't-1',
    idempotencyKey: 'key-1',
    personId: 'p-1',
    amount: const Money.egp(5000),
    direction: TransactionDirection.given,
    kind: TransactionKind.initialExchange,
    date: day,
    createdAt: day,
    source: source,
    ocrScanId: ocrScanId,
    importSource: importSource,
  );

  test('importSource defaults to null (not imported)', () {
    final existing = MoneyTransaction(
      id: 't-1',
      idempotencyKey: 'key-1',
      personId: 'p-1',
      amount: const Money.egp(5000),
      direction: TransactionDirection.given,
      kind: TransactionKind.initialExchange,
      date: day,
      createdAt: day,
    );
    expect(existing.importSource, isNull);
    expect(existing, transaction());
  });

  test('importSource takes part in equality', () {
    expect(
      transaction(importSource: ImportProvenance.sms),
      transaction(importSource: ImportProvenance.sms),
    );
    expect(
      transaction(importSource: ImportProvenance.sms),
      isNot(transaction()),
    );
    expect(
      transaction(importSource: ImportProvenance.fromWire('future')),
      isNot(transaction(importSource: ImportProvenance.sms)),
    );
  });

  group('provenance', () {
    test('manual when typed in', () {
      expect(transaction().provenance, RecordProvenance.manual);
    });

    test('sms when confirmed from a bank message, although source stays '
        'manual (FR-086)', () {
      final imported = transaction(importSource: ImportProvenance.sms);
      expect(imported.source, TransactionSource.manual);
      expect(imported.provenance, RecordProvenance.sms);
    });

    test('ocr when confirmed from a paper scan', () {
      expect(
        transaction(
          source: TransactionSource.ocr,
          ocrScanId: 'scan-1',
        ).provenance,
        RecordProvenance.ocr,
      );
    });

    test('an unknown future provenance reads as manual', () {
      expect(
        transaction(
          importSource: ImportProvenance.fromWire('future'),
        ).provenance,
        RecordProvenance.manual,
      );
    });
  });
}
