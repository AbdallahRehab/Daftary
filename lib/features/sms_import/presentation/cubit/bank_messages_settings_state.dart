import 'package:equatable/equatable.dart';

import '../../../../core/error/failure.dart';
import '../../domain/entities/sms_import_settings.dart';
import '../../domain/entities/sms_permission_status.dart';
import '../../domain/entities/sms_value_types.dart';

/// The Settings -> Bank messages phases (ui-contract §3.1).
enum BankMessagesSettingsStatus { initial, loading, ready, error }

/// The control being saved; the others stay usable (ui-contract §3.1
/// "submitting").
enum BankMessagesSettingsControl { window, countCash, turnOff }

/// The status chip (ui-contract §3.1).
enum SmsImportStatusLabel { off, on, permissionOff, blocked }

/// Immutable state of `BankMessagesSettingsCubit`. Flags, the window,
/// timestamps and counts only; never message content.
class BankMessagesSettingsState extends Equatable {
  const BankMessagesSettingsState({
    this.status = BankMessagesSettingsStatus.initial,
    this.capabilityAvailable = false,
    this.permission = SmsPermissionStatus.unavailable,
    this.settings = const SmsImportSettings(),
    this.counts = const SmsImportCounts(),
    this.submitting,
    this.failure,
    this.saveFailed = false,
    this.turnedOff = false,
    this.deletedPendingCount,
  });

  final BankMessagesSettingsStatus status;

  /// `SmsCapability.available`: the SMS rows are rendered only when true
  /// (CHK013, CHK036).
  final bool capabilityAvailable;
  final SmsPermissionStatus permission;
  final SmsImportSettings settings;
  final SmsImportCounts counts;
  final BankMessagesSettingsControl? submitting;

  /// The load failure (error state).
  final Failure? failure;

  /// The last write failed; the page shows a message once.
  final bool saveFailed;

  /// One-shot: Turn off succeeded; the page announces it and calls
  /// `turnedOffShown` (FR-078).
  final bool turnedOff;

  /// With [turnedOff]: how many pending items were deleted, or `null`
  /// when the user kept them.
  final int? deletedPendingCount;

  bool get isEnabled => settings.isEnabled;

  /// The chip of the Status section.
  SmsImportStatusLabel get statusLabel {
    if (!settings.isEnabled) {
      return switch (permission) {
        SmsPermissionStatus.permanentlyDenied ||
        SmsPermissionStatus.restrictedBlocked => SmsImportStatusLabel.blocked,
        _ => SmsImportStatusLabel.off,
      };
    }
    return switch (permission) {
      SmsPermissionStatus.granted => SmsImportStatusLabel.on,
      SmsPermissionStatus.restrictedBlocked => SmsImportStatusLabel.blocked,
      _ => SmsImportStatusLabel.permissionOff,
    };
  }

  /// Scan rows (window, Scan now, last scan, counts): capability, on and
  /// granted.
  bool get showScanSection =>
      capabilityAvailable &&
      settings.isEnabled &&
      permission == SmsPermissionStatus.granted;

  BankMessagesSettingsState copyWith({
    BankMessagesSettingsStatus? status,
    bool? capabilityAvailable,
    SmsPermissionStatus? permission,
    SmsImportSettings? settings,
    SmsImportCounts? counts,
    BankMessagesSettingsControl? submitting,
    bool clearSubmitting = false,
    Failure? failure,
    bool clearFailure = false,
    bool? saveFailed,
    bool? turnedOff,
    int? deletedPendingCount,
    bool clearDeletedPendingCount = false,
  }) {
    return BankMessagesSettingsState(
      status: status ?? this.status,
      capabilityAvailable: capabilityAvailable ?? this.capabilityAvailable,
      permission: permission ?? this.permission,
      settings: settings ?? this.settings,
      counts: counts ?? this.counts,
      submitting: clearSubmitting ? null : (submitting ?? this.submitting),
      failure: clearFailure ? null : (failure ?? this.failure),
      saveFailed: saveFailed ?? this.saveFailed,
      turnedOff: turnedOff ?? this.turnedOff,
      deletedPendingCount: clearDeletedPendingCount
          ? null
          : (deletedPendingCount ?? this.deletedPendingCount),
    );
  }

  @override
  List<Object?> get props => [
    status,
    capabilityAvailable,
    permission,
    settings,
    counts,
    submitting,
    failure,
    saveFailed,
    turnedOff,
    deletedPendingCount,
  ];

  @override
  String toString() =>
      'BankMessagesSettingsState(status: ${status.name}, '
      'capability: $capabilityAvailable, permission: ${permission.name}, '
      'enabled: ${settings.isEnabled}, submitting: ${submitting?.name})';
}
