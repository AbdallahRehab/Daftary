import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/failure.dart';
import '../entities/notification_preference.dart';
import '../repositories/notification_preference_repository.dart';

/// The user-editable part of a [NotificationPreference] (FR-009, FR-013).
///
/// Deliberately excludes `osPermissionGranted`: that flag reflects the OS,
/// not a user choice, and is owned by `RequestNotificationPermission`. It
/// also carries no pairing assert, so a malformed (one-sided) quiet-hours
/// window can reach [SetNotificationPreferences] and be rejected as a typed
/// [ValidationFailure] rather than crashing in debug builds.
class NotificationPreferenceSettings extends Equatable {
  const NotificationPreferenceSettings({
    required this.isEnabled,
    required this.budgetWarningsEnabled,
    required this.savingsCheckInsEnabled,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  factory NotificationPreferenceSettings.fromPreference(
    NotificationPreference preference,
  ) {
    return NotificationPreferenceSettings(
      isEnabled: preference.isEnabled,
      budgetWarningsEnabled: preference.budgetWarningsEnabled,
      savingsCheckInsEnabled: preference.savingsCheckInsEnabled,
      quietHoursStart: preference.quietHoursStart,
      quietHoursEnd: preference.quietHoursEnd,
    );
  }

  final bool isEnabled;
  final bool budgetWarningsEnabled;
  final bool savingsCheckInsEnabled;

  /// Minutes since local midnight (0–1439); paired with [quietHoursEnd].
  final int? quietHoursStart;

  /// Minutes since local midnight (0–1439); paired with [quietHoursStart].
  final int? quietHoursEnd;

  @override
  List<Object?> get props => [
    isEnabled,
    budgetWarningsEnabled,
    savingsCheckInsEnabled,
    quietHoursStart,
    quietHoursEnd,
  ];
}

/// Persists the user's notification settings (US3): the master switch, the
/// two independent category toggles, and the quiet-hours window.
///
/// The stored `osPermissionGranted` flag is preserved as-is — it is read
/// from the repository rather than taken from the caller, so a stale UI
/// copy can never overwrite the last-known OS permission state.
@injectable
class SetNotificationPreferences {
  const SetNotificationPreferences(this._repository);

  final NotificationPreferenceRepository _repository;

  static const int _minutesPerDay = 24 * 60;

  Future<Either<Failure, NotificationPreference>> call(
    NotificationPreferenceSettings settings,
  ) async {
    final validationError = _validate(settings);
    if (validationError != null) {
      return Left(ValidationFailure(validationError));
    }

    final current = await _repository.getPreference();
    return current.fold(
      (failure) async => Left(failure),
      (stored) => _repository.savePreference(
        NotificationPreference(
          isEnabled: settings.isEnabled,
          budgetWarningsEnabled: settings.budgetWarningsEnabled,
          savingsCheckInsEnabled: settings.savingsCheckInsEnabled,
          osPermissionGranted: stored.osPermissionGranted,
          quietHoursStart: settings.quietHoursStart,
          quietHoursEnd: settings.quietHoursEnd,
        ),
      ),
    );
  }

  /// data-model.md: quiet hours are both set or both null, each a valid
  /// minute of the day, and a window must have non-zero length.
  String? _validate(NotificationPreferenceSettings settings) {
    final start = settings.quietHoursStart;
    final end = settings.quietHoursEnd;
    if ((start == null) != (end == null)) {
      return 'Quiet hours need both a start and an end time.';
    }
    if (start == null || end == null) return null;
    if (!_isMinuteOfDay(start) || !_isMinuteOfDay(end)) {
      return 'Quiet hours must be times within a single day.';
    }
    if (start == end) {
      return 'Quiet hours must start and end at different times.';
    }
    return null;
  }

  bool _isMinuteOfDay(int minutes) => minutes >= 0 && minutes < _minutesPerDay;
}
