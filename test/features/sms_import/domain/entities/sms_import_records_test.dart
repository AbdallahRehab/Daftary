import 'package:daftary/features/finance/domain/entities/finance_entry_type.dart';
import 'package:daftary/features/sms_import/domain/entities/merchant_category_mapping.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_enums.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_settings.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_import_tombstone.dart';
import 'package:daftary/features/sms_import/domain/entities/sms_sender_mute.dart';
import 'package:flutter_test/flutter_test.dart';

/// 023 T023: tombstone, sender mute, learned mapping and settings.
void main() {
  final created = DateTime(2026, 3, 4, 10);

  group('SmsImportTombstone', () {
    SmsImportTombstone tombstone({DateTime? purgeAfter, String? refHash}) =>
        SmsImportTombstone(
          fingerprint: 'fp-1',
          outcome: TombstoneOutcome.ignored,
          bankId: 'nbe',
          createdAt: created,
          purgeAfter:
              purgeAfter ?? SmsImportTombstone.minimumPurgeAfter(created),
          refHash: refHash,
        );

    test('equality', () {
      expect(tombstone(), tombstone());
      expect(tombstone(), isNot(tombstone(refHash: 'r')));
    });

    test('"purge_after >= created_at + 97 days"', () {
      expect(
        SmsImportTombstone.minimumPurgeAfter(created),
        created.add(const Duration(days: 97)),
      );
      expect(tombstone().meetsRetention, isTrue);
      expect(
        tombstone(
          purgeAfter: created.add(const Duration(days: 120)),
        ).meetsRetention,
        isTrue,
      );
      expect(
        () => tombstone(purgeAfter: created.add(const Duration(days: 96))),
        throwsA(isA<AssertionError>()),
      );
    });

    test('toString prints no hash', () {
      expect(
        tombstone(refHash: 'deadbeef').toString(),
        isNot(contains('dead')),
      );
    });
  });

  group('SmsSenderMute', () {
    test('sender id is canonical upper-case with no spaces', () {
      final mute = SmsSenderMute(senderId: ' bank x\t', createdAt: created);
      expect(mute.senderId, 'BANKX');
      expect(canonicalSmsSenderId('Nbe'), 'NBE');
    });

    test('two spellings of one sender are one mute', () {
      expect(
        SmsSenderMute(senderId: 'nbe', createdAt: created),
        SmsSenderMute(senderId: 'NBE', createdAt: created),
      );
    });
  });

  group('MerchantCategoryMapping', () {
    MerchantCategoryMapping mapping({
      FinanceEntryType type = FinanceEntryType.expense,
    }) => MerchantCategoryMapping(
      merchantKey: 'example cafe',
      entryType: type,
      categoryId: 'cat-1',
      updatedAt: created,
    );

    test('equality includes the entry type', () {
      expect(mapping(), mapping());
      expect(mapping(), isNot(mapping(type: FinanceEntryType.income)));
    });

    test('toString does not print the merchant key', () {
      expect(mapping().toString(), isNot(contains('cafe')));
    });
  });

  group('SmsImportSettings', () {
    test('data-model §3.5 defaults', () {
      const settings = SmsImportSettings();
      expect(settings.isEnabled, isFalse);
      expect(settings.onboardingDismissed, isFalse);
      expect(settings.scanWindow, ScanWindow.days30);
      expect(settings.scanWindow.days, 30);
      expect(settings.countCashWithdrawals, isFalse);
      expect(settings.permissionRequested, isFalse);
      expect(settings.rulesSeen, isEmpty);
      expect(settings.cursorDate, isNull);
      expect(settings.cursorId, isNull);
      expect(settings.lastScanAt, isNull);
      expect(settings.lastCatchUpAt, isNull);
      expect(settings.expiredNoticeSeenAt, isNull);
      expect(settings.scannedCount, 0);
      expect(settings.recognizedCount, 0);
      expect(settings.addedCount, 0);
      expect(settings.ignoredCount, 0);
    });

    test('equality', () {
      expect(const SmsImportSettings(), const SmsImportSettings());
      expect(
        const SmsImportSettings(),
        isNot(const SmsImportSettings(isEnabled: true)),
      );
      expect(
        const SmsImportSettings(rulesSeen: {'nbe': 1}),
        const SmsImportSettings(rulesSeen: {'nbe': 1}),
      );
    });
  });
}
