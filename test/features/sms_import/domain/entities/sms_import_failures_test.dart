import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/core/provenance/import_provenance.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T025: no failure carries message text, an amount, a merchant or a
/// name (domain-interfaces §1, invariant 5).
void main() {
  // Sentinel digits that only an amount, a date or an id could carry.
  const sentinelAmount = 987654321;
  final sentinelDate = DateTime(2031, 7, 19);

  final finding = DuplicateFinding(
    tier: DuplicateTier.probable,
    probableBasis: ProbableBasis.savedRecord,
    matchedPendingId: 'pending-424242',
    matchedRecord: DuplicateRecordRef(
      id: 'record-737373',
      recordType: SavedRecordType.financeEntry,
      type: SuggestedRecordType.expense,
      amount: const Money.egp(sentinelAmount),
      date: sentinelDate,
      importProvenance: ImportProvenance.sms,
    ),
  );

  final failures = <SmsImportFailure>[
    const SmsCapabilityUnavailableFailure(),
    const SmsPermissionFailure(SmsPermissionStatus.restrictedBlocked),
    const SmsInboxQueryFailure(),
    const InputTooLargeFailure(InputLimit.characters),
    const InputTooLargeFailure(InputLimit.messages),
    const NotRecognizedFailure(),
    const ImportAlreadyDecidedFailure(SmsImportStatus.added),
    ImportIncompleteFailure({ReviewField.amount, ReviewField.category}),
    ProbableDuplicateFailure(finding),
    const OriginalUnavailableFailure(),
    const ScanNotAllowedFailure(ScanBlockReason.alreadyRunning),
  ];

  test('every failure is a Failure with a fixed token message', () {
    for (final failure in failures) {
      expect(failure, isA<Failure>());
      expect(failure.message, matches(RegExp(r'^sms_[a-z_]+$')));
    }
  });

  test('no message or toString contains digits', () {
    for (final failure in failures) {
      expect(failure.message, isNot(contains(RegExp(r'[0-9]'))));
      expect(
        failure.toString(),
        isNot(contains(RegExp(r'[0-9]'))),
        reason: '${failure.runtimeType}',
      );
    }
  });

  test('the duplicate finding leaks no sentinel through toString', () {
    final text = ProbableDuplicateFailure(finding).toString();
    for (final sentinel in ['987654321', '2031', '424242', '737373']) {
      expect(text, isNot(contains(sentinel)));
    }
    expect(finding.toString(), isNot(contains('987654321')));
    expect(finding.matchedRecord.toString(), isNot(contains('987654321')));
  });

  test('codes are carried as values', () {
    expect(
      const SmsPermissionFailure(SmsPermissionStatus.revoked).status,
      SmsPermissionStatus.revoked,
    );
    expect(const InputTooLargeFailure(InputLimit.characters).max, 10000);
    expect(const InputTooLargeFailure(InputLimit.messages).max, 50);
    expect(ImportIncompleteFailure({ReviewField.person}).fields, {
      ReviewField.person,
    });
    expect(
      const ScanNotAllowedFailure(ScanBlockReason.locked).toString(),
      contains('locked'),
    );
  });

  test('equality by codes', () {
    expect(
      const SmsPermissionFailure(SmsPermissionStatus.denied),
      const SmsPermissionFailure(SmsPermissionStatus.denied),
    );
    expect(
      const SmsPermissionFailure(SmsPermissionStatus.denied),
      isNot(const SmsPermissionFailure(SmsPermissionStatus.revoked)),
    );
    expect(
      ImportIncompleteFailure({ReviewField.amount}),
      ImportIncompleteFailure({ReviewField.amount}),
    );
    expect(
      ImportIncompleteFailure({ReviewField.amount}),
      isNot(ImportIncompleteFailure({ReviewField.date})),
    );
    expect(
      ProbableDuplicateFailure(finding),
      ProbableDuplicateFailure(finding),
    );
  });
}
