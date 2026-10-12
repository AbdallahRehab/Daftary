import 'package:equatable/equatable.dart';

import 'sms_import_enums.dart';

/// Feature settings, scan cursor and content-free counters (data-model
/// §3.5). One singleton row; every default below is the state of a fresh
/// install.
class SmsImportSettings extends Equatable {
  const SmsImportSettings({
    this.isEnabled = false,
    this.onboardingDismissed = false,
    this.scanWindow = ScanWindow.days30,
    this.cursorDate,
    this.cursorId,
    this.lastScanAt,
    this.lastCatchUpAt,
    this.countCashWithdrawals = false,
    this.permissionRequested = false,
    this.scannedCount = 0,
    this.recognizedCount = 0,
    this.addedCount = 0,
    this.ignoredCount = 0,
    this.expiredNoticeSeenAt,
    this.rulesSeen = const {},
  });

  /// Off by default (FR-004).
  final bool isEnabled;

  /// "Dismissed permanently" (FR-004).
  final bool onboardingDismissed;
  final ScanWindow scanWindow;

  /// Highest processed `(date, id)` pair, advanced after each page commit.
  final DateTime? cursorDate;
  final int? cursorId;
  final DateTime? lastScanAt;

  /// Drives the 60-second catch-up debounce.
  final DateTime? lastCatchUpAt;

  /// FR-051b.
  final bool countCashWithdrawals;

  /// Written at request time; feeds `permanentlyDenied` classification.
  final bool permissionRequested;

  /// FR-102 content-free counters; monotonic.
  final int scannedCount;
  final int recognizedCount;
  final int addedCount;
  final int ignoredCount;

  /// Last time the user saw the "N suggestions expired" notice (FR-025).
  final DateTime? expiredNoticeSeenAt;

  /// Last rule versions evaluated, `{profileId: version}` (Decision 8).
  final Map<String, int> rulesSeen;

  /// [clearCursor] resets the scan cursor (an explicit scan restarts from
  /// its window).
  SmsImportSettings copyWith({
    bool? isEnabled,
    bool? onboardingDismissed,
    ScanWindow? scanWindow,
    DateTime? cursorDate,
    int? cursorId,
    bool clearCursor = false,
    DateTime? lastScanAt,
    DateTime? lastCatchUpAt,
    bool? countCashWithdrawals,
    bool? permissionRequested,
    int? scannedCount,
    int? recognizedCount,
    int? addedCount,
    int? ignoredCount,
    DateTime? expiredNoticeSeenAt,
    Map<String, int>? rulesSeen,
  }) {
    return SmsImportSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      onboardingDismissed: onboardingDismissed ?? this.onboardingDismissed,
      scanWindow: scanWindow ?? this.scanWindow,
      cursorDate: clearCursor ? null : (cursorDate ?? this.cursorDate),
      cursorId: clearCursor ? null : (cursorId ?? this.cursorId),
      lastScanAt: lastScanAt ?? this.lastScanAt,
      lastCatchUpAt: lastCatchUpAt ?? this.lastCatchUpAt,
      countCashWithdrawals: countCashWithdrawals ?? this.countCashWithdrawals,
      permissionRequested: permissionRequested ?? this.permissionRequested,
      scannedCount: scannedCount ?? this.scannedCount,
      recognizedCount: recognizedCount ?? this.recognizedCount,
      addedCount: addedCount ?? this.addedCount,
      ignoredCount: ignoredCount ?? this.ignoredCount,
      expiredNoticeSeenAt: expiredNoticeSeenAt ?? this.expiredNoticeSeenAt,
      rulesSeen: rulesSeen ?? this.rulesSeen,
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    onboardingDismissed,
    scanWindow,
    cursorDate,
    cursorId,
    lastScanAt,
    lastCatchUpAt,
    countCashWithdrawals,
    permissionRequested,
    scannedCount,
    recognizedCount,
    addedCount,
    ignoredCount,
    expiredNoticeSeenAt,
    rulesSeen,
  ];
}
