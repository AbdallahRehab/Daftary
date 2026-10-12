import 'package:daftary/core/error/failure.dart';
import 'package:daftary/core/l10n/app_localizations.dart';
import 'package:daftary/core/l10n/failure_message.dart';
import 'package:daftary/core/money/money.dart';
import 'package:daftary/features/sms_import/domain/entities/review_draft.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_failures.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_permission_status.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_value_types.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// T066 — every `SmsImportFailure` maps to its own `smsImportError*`
/// copy in both languages, never to the generic fallback.
void main() {
  final failures = <SmsImportFailure, String Function(AppLocalizations)>{
    const SmsCapabilityUnavailableFailure(): (l) =>
        l.smsImportErrorCapabilityUnavailable,
    const SmsPermissionFailure(SmsPermissionStatus.denied): (l) =>
        l.smsImportErrorPermissionDenied,
    const SmsPermissionFailure(SmsPermissionStatus.permanentlyDenied): (l) =>
        l.smsImportErrorPermissionBlocked,
    const SmsPermissionFailure(SmsPermissionStatus.restrictedBlocked): (l) =>
        l.smsImportErrorPermissionBlocked,
    const SmsPermissionFailure(SmsPermissionStatus.revoked): (l) =>
        l.smsImportErrorPermissionRevoked,
    const SmsPermissionFailure(SmsPermissionStatus.unavailable): (l) =>
        l.smsImportErrorCapabilityUnavailable,
    const SmsInboxQueryFailure(): (l) => l.smsImportErrorInboxQuery,
    const InputTooLargeFailure(InputLimit.characters): (l) =>
        l.smsImportErrorTooLongCharacters,
    const InputTooLargeFailure(InputLimit.messages): (l) =>
        l.smsImportErrorTooManyMessages,
    const NotRecognizedFailure(): (l) => l.smsImportErrorNotRecognized,
    const ImportAlreadyDecidedFailure(SmsImportStatus.added): (l) =>
        l.smsImportErrorAlreadyDecided,
    ImportIncompleteFailure({ReviewField.amount}): (l) =>
        l.smsImportErrorIncomplete,
    const ProbableDuplicateFailure(DuplicateFinding.none): (l) =>
        l.smsImportErrorProbableDuplicate,
    const OriginalUnavailableFailure(): (l) =>
        l.smsImportErrorOriginalUnavailable,
    const ScanNotAllowedFailure(ScanBlockReason.alreadyRunning): (l) =>
        l.smsImportErrorScanAlreadyRunning,
    const ScanNotAllowedFailure(ScanBlockReason.capabilityOff): (l) =>
        l.smsImportErrorCapabilityUnavailable,
    const ScanNotAllowedFailure(ScanBlockReason.noPermission): (l) =>
        l.smsImportErrorPermissionDenied,
    const ScanNotAllowedFailure(ScanBlockReason.locked): (l) =>
        l.smsImportErrorScanNotAllowed,
  };

  for (final locale in const [Locale('en'), Locale('ar')]) {
    group(locale.languageCode, () {
      final l10n = lookupAppLocalizations(locale);

      test('each failure has its own copy', () {
        for (final entry in failures.entries) {
          final text = l10n.messageFor(entry.key);
          expect(text, entry.value(l10n), reason: '${entry.key}');
          expect(text, isNot(l10n.errorUnknown), reason: '${entry.key}');
          expect(text.trim(), isNotEmpty);
        }
      });

      test('every scan-block reason maps to feature copy', () {
        for (final reason in ScanBlockReason.values) {
          final text = l10n.messageFor(ScanNotAllowedFailure(reason));
          expect(text, isNot(l10n.errorUnknown), reason: reason.name);
        }
      });

      test('the interrupted-scan plural renders every count', () {
        for (final count in [0, 1, 2, 3, 11, 100]) {
          final text = l10n.smsImportErrorScanInterrupted(count);
          expect(text.trim(), isNotEmpty);
          if (count > 2) expect(text, contains('$count'));
        }
      });

      test('existing mappings are unchanged', () {
        expect(
          l10n.messageFor(RatesMissingFailure(const [Currency.usd])),
          l10n.rateNeededMessage('USD'),
        );
        expect(l10n.messageFor(null), l10n.errorUnknown);
      });
    });
  }
}
