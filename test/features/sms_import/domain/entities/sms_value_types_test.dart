import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/parse_result.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/builders.dart';

/// 023 T027: shared value types.
void main() {
  group('ScanCancellationToken', () {
    test('starts not cancelled; cancel is sticky and idempotent', () {
      final token = ScanCancellationToken();
      expect(token.isCancelled, isFalse);
      token.cancel();
      expect(token.isCancelled, isTrue);
      token.cancel();
      expect(token.isCancelled, isTrue);
    });

    test('tokens are independent', () {
      final a = ScanCancellationToken();
      final b = ScanCancellationToken();
      a.cancel();
      expect(b.isCancelled, isFalse);
    });
  });

  group('equality', () {
    test('RawIncoming', () {
      final at = DateTime(2026, 3, 4);
      expect(
        RawIncoming(text: 't', sender: 'S', receivedAt: at, providerId: 1),
        RawIncoming(text: 't', sender: 'S', receivedAt: at, providerId: 1),
      );
      expect(const RawIncoming(text: 't'), isNot(const RawIncoming(text: 'u')));
    });

    test('NewPendingImport', () {
      expect(
        NewPendingImport(item: buildPendingImport(), rawMasked: 'm'),
        NewPendingImport(item: buildPendingImport(), rawMasked: 'm'),
      );
      expect(
        NewPendingImport(item: buildPendingImport(), rawMasked: 'm'),
        isNot(NewPendingImport(item: buildPendingImport())),
      );
    });

    test('ScanSummary with its content-free skipped list', () {
      final at = DateTime(2026, 3, 4);
      ScanSummary summary() => ScanSummary(
        scanned: 5,
        recognized: 3,
        createdPending: 2,
        ready: 1,
        needsReview: 1,
        alreadyKnown: 1,
        nonTransactional: 1,
        unreadable: 1,
        skipped: [
          SkippedEntry(
            bankId: 'nbe',
            receivedAt: at,
            reason: SkipReason.noAmount,
          ),
        ],
      );
      expect(summary(), summary());
      expect(summary(), isNot(ScanSummary(scanned: 5)));
      expect(ScanSummary().cancelled, isFalse);
      expect(ScanSummary().skipped, isEmpty);
      expect(
        () =>
            summary().skipped.add(const SkippedEntry(reason: SkipReason.empty)),
        throwsUnsupportedError,
      );
    });

    test('SkipReason covers every UnreadableReason', () {
      for (final reason in UnreadableReason.values) {
        expect(SkipReason.fromUnreadable(reason).name, reason.name);
      }
    });

    test('small value types', () {
      expect(
        const SavedRecordRef(id: 'a', type: SavedRecordType.financeEntry),
        const SavedRecordRef(id: 'a', type: SavedRecordType.financeEntry),
      );
      expect(KnownKeys(fingerprints: {'a'}), KnownKeys(fingerprints: {'a'}));
      expect(const PurgeResult(rows: 1), const PurgeResult(rows: 1));
      expect(
        const ScanProgress(processed: 2),
        const ScanProgress(processed: 2),
      );
      expect(const SmsImportCounts(added: 1), const SmsImportCounts(added: 1));
      expect(
        const EnableResult(status: SmsPermissionStatus.granted, enabled: true),
        const EnableResult(status: SmsPermissionStatus.granted, enabled: true),
      );
      expect(const UndoResult().needsRescan, isTrue);
      expect(
        const CatchUpSkipped(ScanBlockReason.debounced),
        const CatchUpSkipped(ScanBlockReason.debounced),
      );
      expect(
        CatchUpRan(ScanSummary(scanned: 1)),
        CatchUpRan(ScanSummary(scanned: 1)),
      );
      expect(
        const ScanWindowChanged(ScanWindow.days7),
        const ScanWindowChanged(ScanWindow.days7),
      );
      expect(
        const CountCashChanged(true),
        isNot(const CountCashChanged(false)),
      );
      expect(const OnboardingDismissed(), const OnboardingDismissed());
    });

    test('ReparseCandidate', () {
      expect(
        const ReparseCandidate(
          id: 'a',
          source: SmsSource.paste,
          ruleVersion: 'nbe@1',
        ),
        const ReparseCandidate(
          id: 'a',
          source: SmsSource.paste,
          ruleVersion: 'nbe@1',
        ),
      );
    });
  });

  group('SavedRecordWindow', () {
    final day = DateTime(2026, 3, 4);
    DuplicateRecordRef ref(String id, Money amount) => DuplicateRecordRef(
      id: id,
      recordType: SavedRecordType.financeEntry,
      type: SuggestedRecordType.expense,
      amount: amount,
      date: day,
    );

    test('indexes by currency and amount', () {
      final window = SavedRecordWindow([
        ref('a', const Money.egp(100)),
        ref('b', const Money.egp(100)),
        ref('c', const Money.fromMinorUnits(100, Currency.usd)),
      ]);
      expect(window.withAmount(const Money.egp(100)).map((r) => r.id), [
        'a',
        'b',
      ]);
      expect(
        window
            .withAmount(const Money.fromMinorUnits(100, Currency.usd))
            .map((r) => r.id),
        ['c'],
      );
      expect(window.withAmount(const Money.egp(101)), isEmpty);
    });
  });

  group('redaction', () {
    test('types that carry message text never print it', () {
      const secret = 'Sentinel 987654';
      expect(
        const RawIncoming(text: secret).toString(),
        isNot(contains('Sentinel')),
      );
      expect(
        const OriginalMessage(
          text: secret,
          direction: TextDirectionHint.rtl,
        ).toString(),
        isNot(contains('Sentinel')),
      );
      expect(
        NewPendingImport(
          item: buildPendingImport(),
          rawMasked: secret,
        ).toString(),
        isNot(contains('Sentinel')),
      );
      expect(
        DuplicateRecordRef(
          id: 'x',
          recordType: SavedRecordType.moneyTransaction,
          type: SuggestedRecordType.given,
          amount: const Money.egp(987654),
          date: DateTime(2026, 3, 4),
        ).toString(),
        isNot(contains('987654')),
      );
    });
  });
}
