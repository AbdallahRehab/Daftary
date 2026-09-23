import 'package:daftary/core/database/app_database.dart' as db;
import 'package:daftary/features/transactions/data/models/transaction_mapper.dart';
import 'package:daftary/features/transactions/domain/entities/money_transaction.dart'
    as domain;
import 'package:flutter_test/flutter_test.dart';

void main() {
  db.MoneyTransaction buildRow({
    required String kind,
    String? occasionId,
    bool countsTowardBalance = true,
    String source = 'manual',
    String? ocrScanId,
  }) {
    return db.MoneyTransaction(
      id: 't1',
      idempotencyKey: 'k1',
      personId: 'p1',
      amountMinorUnits: 200000,
      direction: 'given',
      kind: kind,
      date: DateTime(2026, 1, 1).millisecondsSinceEpoch,
      occasionId: occasionId,
      countsTowardBalance: countsTowardBalance,
      source: source,
      ocrScanId: ocrScanId,
      createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    );
  }

  group('kind round-trips all three values (008 T026)', () {
    for (final kind in domain.TransactionKind.values) {
      test('${kind.name} survives domain → db → domain unchanged', () {
        final dbValue = kind.dbValue;
        expect(buildRow(kind: dbValue).toDomain().kind, kind);
      });
    }

    test('an occasionContribution row is never silently read as an ordinary '
        'exchange — the bug an exhaustive switch rules out', () {
      expect(
        buildRow(kind: 'occasionContribution').toDomain().kind,
        domain.TransactionKind.occasionContribution,
      );
    });

    test('an unknown kind throws rather than defaulting', () {
      expect(() => buildRow(kind: 'somethingNew').toDomain(), throwsStateError);
    });
  });

  group('occasion columns (008)', () {
    test('occasionId and countsTowardBalance map to the entity', () {
      final mapped = buildRow(
        kind: 'occasionContribution',
        occasionId: 'o1',
        countsTowardBalance: false,
      ).toDomain();

      expect(mapped.occasionId, 'o1');
      expect(mapped.countsTowardBalance, isFalse);
      expect(mapped.isOccasionContribution, isTrue);
    });

    test('an ordinary row keeps a null occasionId and counts by default', () {
      final mapped = buildRow(kind: 'initialExchange').toDomain();

      expect(mapped.occasionId, isNull);
      expect(mapped.countsTowardBalance, isTrue);
    });
  });
}
