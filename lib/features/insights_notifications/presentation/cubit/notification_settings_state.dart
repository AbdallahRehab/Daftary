import 'package:equatable/equatable.dart';

import '../../domain/entities/notification_preference.dart';

enum NotificationSettingsStatus { loading, ready, loadFailure }

/// Immutable state for `NotificationSettingsCubit` (constitution
/// Principle IV).
class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.status = NotificationSettingsStatus.loading,
    this.preference = NotificationPreference.defaults,
    this.isRequestingPermission = false,
    this.isSaveFailing = false,
  });

  final NotificationSettingsStatus status;

  /// The preference as last persisted (never an unsaved optimistic copy).
  final NotificationPreference preference;

  /// `true` while the OS permission prompt is on screen — the master
  /// switch is disabled meanwhile so a second tap cannot stack prompts.
  final bool isRequestingPermission;

  /// `true` once the latest change failed to persist; surfaced as a
  /// non-blocking snackbar. Reset at the start of every change.
  final bool isSaveFailing;

  /// The feature is on but the OS will not deliver anything (FR-012). The
  /// switch stays on — the user's choice is kept, so granting permission
  /// later in device settings starts delivery without re-enabling — while
  /// the banner states plainly that nothing can be delivered.
  bool get showPermissionDeniedBanner =>
      status == NotificationSettingsStatus.ready &&
      preference.isEnabled &&
      !preference.osPermissionGranted;

  NotificationSettingsState copyWith({
    NotificationSettingsStatus? status,
    NotificationPreference? preference,
    bool? isRequestingPermission,
    bool? isSaveFailing,
  }) {
    return NotificationSettingsState(
      status: status ?? this.status,
      preference: preference ?? this.preference,
      isRequestingPermission:
          isRequestingPermission ?? this.isRequestingPermission,
      isSaveFailing: isSaveFailing ?? this.isSaveFailing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    preference,
    isRequestingPermission,
    isSaveFailing,
  ];
}
