import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_sms_import.dart';
import '../../domain/entities/sms_import_enums.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/entities/sms_value_types.dart';

/// The pending list's phases (ui-contract §3.3).
enum BankMessagesStatus { initial, loading, ready, empty, error }

/// Immutable state of `BankMessagesCubit`: the list (T079) and the scan
/// with its permission state (T120), and multi-select with batch Ignore
/// (T132).
class BankMessagesState extends Equatable {
  BankMessagesState({
    this.status = BankMessagesStatus.initial,
    List<PendingSmsImport> items = const [],
    this.expiredNoticeCount = 0,
    this.failure,
    this.scanAvailable = false,
    this.isEnabled = false,
    this.permission = SmsPermissionStatus.unavailable,
    this.scanWindow = ScanWindow.defaultWindow,
    this.scanning = false,
    this.scanProcessed = 0,
    this.scanSummary,
    this.scanFailure,
    this.selectionMode = false,
    Set<String> selectedIds = const {},
    this.ignoring = false,
    this.ignoredCount,
    this.ignoreFailure,
  }) : items = List.unmodifiable(items),
       selectedIds = Set.unmodifiable(selectedIds);

  final BankMessagesStatus status;

  /// In review order: low confidence first, then oldest first (FR-042).
  final List<PendingSmsImport> items;

  /// "N suggestions expired" (FR-025); 0 hides the notice.
  final int expiredNoticeCount;
  final Failure? failure;

  // --- US2 scan (T120) ---

  /// `SmsCapability.available`: scan rows and banners exist only then
  /// (CHK013, CHK036). Paste-only platforms keep the list.
  final bool scanAvailable;
  final bool isEnabled;

  /// Prompt-free status; drives the banner (ui-contract §3.7).
  final SmsPermissionStatus permission;
  final ScanWindow scanWindow;
  final bool scanning;

  /// Messages processed by the running scan.
  final int scanProcessed;

  /// The last scan's content-free summary and Skipped list, in memory
  /// only (CHK003, FR-024, FR-097).
  final ScanSummary? scanSummary;

  /// The last scan failed (partial results kept).
  final Failure? scanFailure;

  // --- US6 selection and batch Ignore (T132) ---

  /// Multi-select is on (long-press or "Select"). Its only action is
  /// Ignore: there is no batch Add (FR-046).
  final bool selectionMode;

  /// Ids of the selected pending items.
  final Set<String> selectedIds;

  /// A batch Ignore is running; the selected rows are disabled.
  final bool ignoring;

  /// One-shot: how many items the last batch Ignore ignored, for the
  /// "N ignored" announcement. The page calls `consumeIgnoredCount`.
  final int? ignoredCount;

  /// The last batch Ignore failed; nothing was ignored (all or nothing).
  final Failure? ignoreFailure;

  bool get showExpiredNotice => expiredNoticeCount > 0;

  /// "Scan now": capability, enabled and granted.
  bool get canScan =>
      scanAvailable && isEnabled && permission == SmsPermissionStatus.granted;

  /// The banner status, or `null` for none (ui-contract §3.7). When the
  /// feature is off the "Turn on" card is shown instead, except when the
  /// permission is blocked.
  SmsPermissionStatus? get bannerStatus {
    if (!scanAvailable) return null;
    if (permission == SmsPermissionStatus.granted ||
        permission == SmsPermissionStatus.unavailable) {
      return null;
    }
    if (isEnabled) return permission;
    return switch (permission) {
      SmsPermissionStatus.permanentlyDenied ||
      SmsPermissionStatus.restrictedBlocked => permission,
      _ => null,
    };
  }

  /// The "Turn on" card: capability, off, and no blocking banner.
  bool get showTurnOn => scanAvailable && !isEnabled && bannerStatus == null;

  BankMessagesState copyWith({
    BankMessagesStatus? status,
    List<PendingSmsImport>? items,
    int? expiredNoticeCount,
    Failure? failure,
    bool clearFailure = false,
    bool? scanAvailable,
    bool? isEnabled,
    SmsPermissionStatus? permission,
    ScanWindow? scanWindow,
    bool? scanning,
    int? scanProcessed,
    ScanSummary? scanSummary,
    bool clearScanSummary = false,
    Failure? scanFailure,
    bool clearScanFailure = false,
    bool? selectionMode,
    Set<String>? selectedIds,
    bool? ignoring,
    int? ignoredCount,
    bool clearIgnoredCount = false,
    Failure? ignoreFailure,
    bool clearIgnoreFailure = false,
  }) {
    return BankMessagesState(
      status: status ?? this.status,
      items: items ?? this.items,
      expiredNoticeCount: expiredNoticeCount ?? this.expiredNoticeCount,
      failure: clearFailure ? null : (failure ?? this.failure),
      scanAvailable: scanAvailable ?? this.scanAvailable,
      isEnabled: isEnabled ?? this.isEnabled,
      permission: permission ?? this.permission,
      scanWindow: scanWindow ?? this.scanWindow,
      scanning: scanning ?? this.scanning,
      scanProcessed: scanProcessed ?? this.scanProcessed,
      scanSummary: clearScanSummary ? null : (scanSummary ?? this.scanSummary),
      scanFailure: clearScanFailure ? null : (scanFailure ?? this.scanFailure),
      selectionMode: selectionMode ?? this.selectionMode,
      selectedIds: selectedIds ?? this.selectedIds,
      ignoring: ignoring ?? this.ignoring,
      ignoredCount: clearIgnoredCount
          ? null
          : (ignoredCount ?? this.ignoredCount),
      ignoreFailure: clearIgnoreFailure
          ? null
          : (ignoreFailure ?? this.ignoreFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    expiredNoticeCount,
    failure,
    scanAvailable,
    isEnabled,
    permission,
    scanWindow,
    scanning,
    scanProcessed,
    scanSummary,
    scanFailure,
    selectionMode,
    selectedIds,
    ignoring,
    ignoredCount,
    ignoreFailure,
  ];

  /// Redacted: counts and codes only, never an item's content (FR-097).
  @override
  String toString() =>
      'BankMessagesState(status: ${status.name}, items: ${items.length}, '
      'expired: $expiredNoticeCount, failure: ${failure.runtimeType}, '
      'scanAvailable: $scanAvailable, enabled: $isEnabled, '
      'permission: ${permission.name}, scanning: $scanning, '
      'processed: $scanProcessed, selection: $selectionMode, '
      'selected: ${selectedIds.length}, ignoring: $ignoring)';
}
