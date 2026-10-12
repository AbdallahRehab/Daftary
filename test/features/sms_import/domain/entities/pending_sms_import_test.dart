import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/pending_sms_import.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';

/// 023 T022: `PendingSmsImport` equality and the data-model §3.1
/// invariants.
void main() {
  Matcher violates() => throwsA(isA<AssertionError>());

  group('equality', () {
    test('equal values are equal', () {
      expect(buildPendingImport(), buildPendingImport());
    });

    test('any field difference breaks equality', () {
      final base = buildPendingImport();
      expect(base, isNot(buildPendingImport(id: 'other')));
      expect(base, isNot(buildPendingImport(fingerprint: 'fp-2')));
      expect(base, isNot(buildPendingImport(hasRawText: false)));
      expect(
        base,
        isNot(buildPendingImport(warnings: {SmsWarning.dateInferred})),
      );
      expect(base, isNot(buildPendingImport(parentImportId: 'parent')));
    });
  });

  group('invariants', () {
    test('a valid item has no violation', () {
      expect(buildPendingImport().invariantViolations, isEmpty);
    });

    test('"amountMinorUnits > 0 and <= 12 whole digits when set"', () {
      expect(buildPendingImport(amount: null).invariantViolations, isEmpty);
      expect(
        buildPendingImport(
          amount: const Money.egp(99999999999999),
        ).invariantViolations,
        isEmpty,
      );
      expect(
        () => buildPendingImport(amount: const Money.egp(100000000000000)),
        violates(),
      );
      expect(() => buildPendingImport(amount: const Money.egp(0)), violates());
      expect(() => buildPendingImport(amount: const Money.egp(-5)), violates());
    });

    test('"merchant <= 120 chars"', () {
      expect(
        buildPendingImport(merchant: 'm' * 120).invariantViolations,
        isEmpty,
      );
      expect(() => buildPendingImport(merchant: 'm' * 121), violates());
    });

    test('"counterparty <= 120 chars"', () {
      expect(
        buildPendingImport(counterparty: 'c' * 120).invariantViolations,
        isEmpty,
      );
      expect(() => buildPendingImport(counterparty: 'c' * 121), violates());
    });

    test('"cardLast4 Exactly 4 digits"', () {
      expect(buildPendingImport(cardLast4: null).invariantViolations, isEmpty);
      expect(
        buildPendingImport(cardLast4: '0042').invariantViolations,
        isEmpty,
      );
      for (final bad in ['123', '12345', 'abcd', '12a4', '', '١٢٣٤']) {
        expect(() => buildPendingImport(cardLast4: bad), violates());
      }
    });

    test('"expiresAt = createdAt + 30 days"', () {
      final created = DateTime(2026, 3, 4, 10);
      expect(
        PendingSmsImport.expiryFor(created),
        created.add(const Duration(days: 30)),
      );
      expect(
        () => buildPendingImport(
          createdAt: created,
          expiresAt: created.add(const Duration(days: 31)),
        ),
        violates(),
      );
    });

    test('timeMinutes stays inside one day', () {
      expect(buildPendingImport(timeMinutes: 0).invariantViolations, isEmpty);
      expect(
        buildPendingImport(timeMinutes: 1439).invariantViolations,
        isEmpty,
      );
      expect(() => buildPendingImport(timeMinutes: 1440), violates());
      expect(() => buildPendingImport(timeMinutes: -1), violates());
    });

    test('a saved record is referenced only on an added item', () {
      expect(
        buildPendingImport(
          status: SmsImportStatus.added,
          savedRecordId: 'rec-1',
          savedRecordType: SavedRecordType.financeEntry,
        ).invariantViolations,
        isEmpty,
      );
      expect(
        () => buildPendingImport(
          savedRecordId: 'rec-1',
          savedRecordType: SavedRecordType.financeEntry,
        ),
        violates(),
      );
      expect(
        () => buildPendingImport(
          status: SmsImportStatus.added,
          savedRecordId: 'rec-1',
        ),
        violates(),
      );
    });
  });

  group('derived values', () {
    test('idempotency key is sms-import:<id> (FR-075a)', () {
      expect(buildPendingImport(id: 'abc').idempotencyKey, 'sms-import:abc');
    });

    test('isPending', () {
      expect(buildPendingImport().isPending, isTrue);
      expect(
        buildPendingImport(status: SmsImportStatus.ignored).isPending,
        isFalse,
      );
    });

    test('lists and sets are unmodifiable', () {
      final item = buildPendingImport();
      expect(() => item.amountCandidates.add(1), throwsUnsupportedError);
      expect(
        () => item.warnings.add(SmsWarning.genericParser),
        throwsUnsupportedError,
      );
    });
  });

  test('toString is redacted', () {
    final text = buildPendingImport(
      amount: const Money.egp(987654),
      merchant: 'Sentinel Shop',
      counterparty: 'Sentinel Person',
      cardLast4: '4321',
      senderId: 'SENTINELBANK',
      refHash: 'deadbeef',
      fingerprint: 'cafebabe',
    ).toString();
    for (final secret in [
      '987654',
      'Sentinel',
      '4321',
      'SENTINELBANK',
      'deadbeef',
      'cafebabe',
    ]) {
      expect(text, isNot(contains(secret)));
    }
  });
}
