import 'dart:convert';

import '../../../../core/database/app_database.dart' as db;
import '../../../finance/domain/entities/finance_entry_type.dart';
import '../../domain/entities/merchant_category_mapping.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_import_settings.dart';
import '../../domain/entities/sms_sender_mute.dart';

/// Maps the settings singleton, mutes and learned mappings (data-model
/// §3.3-§3.5, §4.3-§4.5). Every decode is total and never throws.
extension SmsImportSettingsRowMapper on db.SmsImportSettingsRow {
  SmsImportSettings toDomain() => SmsImportSettings(
    isEnabled: isEnabled,
    onboardingDismissed: onboardingDismissed,
    // Checked in code, not SQL: any stored value other than 7/30/90 reads
    // as the default window.
    scanWindow: ScanWindow.fromDays(scanWindowDays),
    cursorDate: _date(cursorDate),
    cursorId: cursorId,
    lastScanAt: _date(lastScanAt),
    lastCatchUpAt: _date(lastCatchUpAt),
    countCashWithdrawals: countCashWithdrawals,
    permissionRequested: permissionRequested,
    scannedCount: scannedCount,
    recognizedCount: recognizedCount,
    addedCount: addedCount,
    ignoredCount: ignoredCount,
    expiredNoticeSeenAt: _date(expiredNoticeSeenAt),
    rulesSeen: decodeRulesSeen(rulesSeen),
  );
}

extension SmsSenderMuteRowMapper on db.SmsSenderMuteRow {
  SmsSenderMute toDomain() => SmsSenderMute(
    senderId: senderId,
    createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
  );
}

extension SmsMerchantCategoryMappingRowMapper
    on db.SmsMerchantCategoryMappingRow {
  /// `null` for a row whose entry type is neither `expense` nor `income`.
  MerchantCategoryMapping? toDomain() {
    final type = switch (entryType) {
      'expense' => FinanceEntryType.expense,
      'income' => FinanceEntryType.income,
      _ => null,
    };
    if (type == null) return null;
    return MerchantCategoryMapping(
      merchantKey: merchantKey,
      entryType: type,
      categoryId: categoryId,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
    );
  }
}

/// `{profileId: version}` as JSON (data-model §3.5).
String encodeRulesSeen(Map<String, int> versions) =>
    jsonEncode(Map<String, int>.of(versions));

/// Total decode: non-integer values are dropped; malformed JSON is empty.
Map<String, int> decodeRulesSeen(String? json) {
  if (json == null || json.isEmpty) return const {};
  try {
    final decoded = jsonDecode(json);
    if (decoded is! Map) return const {};
    return Map.unmodifiable({
      for (final entry in decoded.entries)
        if (entry.key is String && entry.value is int)
          entry.key as String: entry.value as int,
    });
  } on FormatException {
    return const {};
  }
}

DateTime? _date(int? millis) =>
    millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
