import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T019: every `dbValue` round-trips, and an unknown stored string maps
/// to a safe default without throwing.
void main() {
  const unknownInputs = <String?>[null, '', 'UNKNOWN', 'Pending', ' scan'];

  group('SmsSource', () {
    test('db values are the stored origin strings', () {
      expect(SmsSource.values.map((s) => s.dbValue), [
        'scan',
        'catchup',
        'paste',
        'share',
      ]);
    });

    test('round-trips', () {
      for (final value in SmsSource.values) {
        expect(SmsSource.fromDb(value.dbValue), value);
      }
    });

    test('unknown -> paste (no sender, capped confidence)', () {
      for (final input in unknownInputs) {
        expect(SmsSource.fromDb(input), SmsSource.paste);
      }
    });

    test('derived flags', () {
      expect(SmsSource.inboxScan.hasSender, isTrue);
      expect(SmsSource.catchUpScan.hasReceivedAt, isTrue);
      expect(SmsSource.paste.hasSender, isFalse);
      expect(SmsSource.share.hasReceivedAt, isFalse);
      expect(SmsSource.paste.capsConfidenceAtMedium, isTrue);
      expect(SmsSource.share.capsConfidenceAtMedium, isTrue);
      expect(SmsSource.inboxScan.capsConfidenceAtMedium, isFalse);
      expect(SmsSource.catchUpScan.capsConfidenceAtMedium, isFalse);
    });
  });

  group('SmsImportStatus', () {
    test('db values', () {
      expect(SmsImportStatus.values.map((s) => s.dbValue), [
        'pending',
        'added',
        'ignored',
        'duplicate',
        'expired',
      ]);
    });

    test('round-trips', () {
      for (final value in SmsImportStatus.values) {
        expect(SmsImportStatus.fromDb(value.dbValue), value);
      }
    });

    test('unknown -> a terminal, non-undoable status (never pending)', () {
      for (final input in unknownInputs) {
        final status = SmsImportStatus.fromDb(input);
        expect(status, SmsImportStatus.duplicateClosed);
        expect(status.isTerminal, isTrue);
        expect(status.isUndoable, isFalse);
      }
    });

    test('only ignored and expired are undoable; only pending is open', () {
      expect(SmsImportStatus.values.where((s) => s.isUndoable), [
        SmsImportStatus.ignored,
        SmsImportStatus.expired,
      ]);
      expect(SmsImportStatus.values.where((s) => !s.isTerminal), [
        SmsImportStatus.pending,
      ]);
    });
  });

  group('SmsKind', () {
    test('db values are snake_case and include authorization_reversal', () {
      expect(SmsKind.authorizationReversal.dbValue, 'authorization_reversal');
      expect(SmsKind.cardPurchase.dbValue, 'card_purchase');
      for (final kind in SmsKind.values) {
        expect(kind.dbValue, matches(RegExp(r'^[a-z]+(_[a-z]+)*$')));
      }
    });

    test('round-trips; unknown -> unknown', () {
      for (final value in SmsKind.values) {
        expect(SmsKind.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(SmsKind.fromDb(input), SmsKind.unknown);
      }
    });
  });

  group('SmsDirection', () {
    test('round-trips; unknown -> unknown', () {
      expect(SmsDirection.values.map((d) => d.dbValue), [
        'debit',
        'credit',
        'unknown',
      ]);
      for (final value in SmsDirection.values) {
        expect(SmsDirection.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(SmsDirection.fromDb(input), SmsDirection.unknown);
      }
    });
  });

  group('SuggestedRecordType', () {
    test('round-trips; unknown -> unset', () {
      for (final value in SuggestedRecordType.values) {
        expect(SuggestedRecordType.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(SuggestedRecordType.fromDb(input), SuggestedRecordType.unset);
      }
    });

    test('only the four record types are savable (no repayment, NG8)', () {
      expect(SuggestedRecordType.values.where((t) => t.isSavable), [
        SuggestedRecordType.expense,
        SuggestedRecordType.income,
        SuggestedRecordType.given,
        SuggestedRecordType.received,
      ]);
      expect(SuggestedRecordType.expense.isFinanceEntry, isTrue);
      expect(SuggestedRecordType.given.isPersonTransaction, isTrue);
      expect(SuggestedRecordType.ignore.isSavable, isFalse);
      expect(SuggestedRecordType.unset.isSavable, isFalse);
    });
  });

  group('SavedRecordType', () {
    test('round-trips; unknown -> null', () {
      for (final value in SavedRecordType.values) {
        expect(SavedRecordType.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(SavedRecordType.fromDb(input), isNull);
      }
    });
  });

  group('TombstoneOutcome', () {
    test('round-trips; unknown -> duplicate', () {
      expect(TombstoneOutcome.values.map((o) => o.dbValue), [
        'added',
        'ignored',
        'duplicate',
        'expired',
      ]);
      for (final value in TombstoneOutcome.values) {
        expect(TombstoneOutcome.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(TombstoneOutcome.fromDb(input), TombstoneOutcome.duplicate);
      }
    });
  });

  group('SmsWarning', () {
    test('includes the FR-030a, FR-024b and FR-051d values', () {
      expect(
        SmsWarning.values,
        containsAll([
          SmsWarning.feeFromMessage,
          SmsWarning.reversalHint,
          SmsWarning.possibleOwnTransfer,
          SmsWarning.unverifiedProfile,
        ]),
      );
      expect(SmsWarning.values, hasLength(17));
    });

    test('db values are unique and round-trip; unknown -> null', () {
      final dbValues = SmsWarning.values.map((w) => w.dbValue).toSet();
      expect(dbValues, hasLength(SmsWarning.values.length));
      for (final value in SmsWarning.values) {
        expect(SmsWarning.fromDb(value.dbValue), value);
      }
      for (final input in unknownInputs) {
        expect(SmsWarning.fromDb(input), isNull);
      }
    });
  });

  group('ScanWindow', () {
    test('7, 30 and 90 days; default 30; never above 90', () {
      expect(ScanWindow.values.map((w) => w.days), [7, 30, 90]);
      expect(ScanWindow.defaultWindow, ScanWindow.days30);
      for (final window in ScanWindow.values) {
        expect(window.days, lessThanOrEqualTo(90));
        expect(ScanWindow.fromDays(window.days), window);
      }
    });

    test('unknown -> 30', () {
      for (final days in [null, 0, 1, 31, 91, 365, -7]) {
        expect(ScanWindow.fromDays(days), ScanWindow.days30);
      }
    });
  });
}
