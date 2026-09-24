import 'package:equatable/equatable.dart';

/// The device-level configuration for this feature (data-model.md). There is
/// only ever one — it is not a list.
class NotificationPreference extends Equatable {
  const NotificationPreference({
    required this.isEnabled,
    required this.budgetWarningsEnabled,
    required this.savingsCheckInsEnabled,
    required this.osPermissionGranted,
    this.quietHoursStart,
    this.quietHoursEnd,
  }) : assert(
         (quietHoursStart == null) == (quietHoursEnd == null),
         'quietHoursStart and quietHoursEnd are both set or both null',
       );

  /// What a device that has never opened the notification settings gets:
  /// the feature is off (FR-010), both categories are on so the first
  /// enable delivers both, and no quiet hours are configured.
  static const NotificationPreference defaults = NotificationPreference(
    isEnabled: false,
    budgetWarningsEnabled: true,
    savingsCheckInsEnabled: true,
    osPermissionGranted: false,
  );

  /// Whether the feature is on at all (FR-010, FR-018).
  final bool isEnabled;

  /// Budget-limit warnings, independently toggleable (FR-009).
  final bool budgetWarningsEnabled;

  /// Savings-goal check-ins, independently toggleable (FR-009).
  final bool savingsCheckInsEnabled;

  /// Start of the quiet-hours window, in minutes since local midnight
  /// (0–1439). Paired with [quietHoursEnd]: both null or both set. Kept as
  /// a plain `int` rather than Flutter's `TimeOfDay` so the Domain layer
  /// stays free of Flutter imports.
  final int? quietHoursStart;

  /// End of the quiet-hours window, in minutes since local midnight. May be
  /// earlier than [quietHoursStart] for a window that crosses midnight
  /// (e.g. 22:00–08:00).
  final int? quietHoursEnd;

  /// Last-known OS permission state (FR-012). Drives the settings banner
  /// only — delivery always re-checks the OS live.
  final bool osPermissionGranted;

  bool get hasQuietHours => quietHoursStart != null && quietHoursEnd != null;

  /// [clearQuietHours] removes the window; it wins over
  /// [quietHoursStart]/[quietHoursEnd] when both are passed.
  NotificationPreference copyWith({
    bool? isEnabled,
    bool? budgetWarningsEnabled,
    bool? savingsCheckInsEnabled,
    int? quietHoursStart,
    int? quietHoursEnd,
    bool clearQuietHours = false,
    bool? osPermissionGranted,
  }) {
    return NotificationPreference(
      isEnabled: isEnabled ?? this.isEnabled,
      budgetWarningsEnabled:
          budgetWarningsEnabled ?? this.budgetWarningsEnabled,
      savingsCheckInsEnabled:
          savingsCheckInsEnabled ?? this.savingsCheckInsEnabled,
      quietHoursStart: clearQuietHours
          ? null
          : quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: clearQuietHours
          ? null
          : quietHoursEnd ?? this.quietHoursEnd,
      osPermissionGranted: osPermissionGranted ?? this.osPermissionGranted,
    );
  }

  @override
  List<Object?> get props => [
    isEnabled,
    budgetWarningsEnabled,
    savingsCheckInsEnabled,
    quietHoursStart,
    quietHoursEnd,
    osPermissionGranted,
  ];
}
