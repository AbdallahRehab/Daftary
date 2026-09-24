import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/notification_preference.dart';
import '../../domain/usecases/request_notification_permission.dart';
import '../../domain/usecases/set_notification_preferences.dart';
import 'notification_settings_state.dart';

/// Drives the notification settings screen (US3, FR-009–FR-013).
@injectable
class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit(this._setPreferences, this._requestPermission)
    : super(const NotificationSettingsState());

  final SetNotificationPreferences _setPreferences;
  final RequestNotificationPermission _requestPermission;

  /// The quiet-hours window offered when the user first turns quiet hours
  /// on (spec.md Assumptions "Quiet hours default"): 22:00–08:00 local.
  /// Only a starting suggestion — both ends are editable, and nothing is
  /// stored until the user switches quiet hours on.
  static const int suggestedQuietHoursStart = 22 * 60;
  static const int suggestedQuietHoursEnd = 8 * 60;

  /// Loads the stored preference, refreshing the permission flag from a
  /// live OS check first (FR-012) — never prompting.
  Future<void> load() async {
    final result = await _requestPermission.refresh();
    result.fold(
      (_) =>
          emit(state.copyWith(status: NotificationSettingsStatus.loadFailure)),
      (preference) => emit(
        state.copyWith(
          status: NotificationSettingsStatus.ready,
          preference: preference,
        ),
      ),
    );
  }

  /// Re-checks the OS permission without prompting — e.g. when the app
  /// resumes after the user visited device settings.
  Future<void> refreshPermission() async {
    if (state.status != NotificationSettingsStatus.ready) return;
    final result = await _requestPermission.refresh();
    result.fold(
      (_) {},
      (preference) => emit(state.copyWith(preference: preference)),
    );
  }

  /// Turns the whole feature on or off (FR-009, FR-018).
  ///
  /// Enabling without OS permission is the one moment the OS prompt is
  /// shown (FR-011). A denial still leaves the feature enabled: the choice
  /// is kept and the permission-denied banner explains that nothing can be
  /// delivered until permission is granted (FR-012).
  Future<void> setEnabled(bool enabled) async {
    if (state.status != NotificationSettingsStatus.ready ||
        state.isRequestingPermission) {
      return;
    }
    if (enabled && !state.preference.osPermissionGranted) {
      emit(state.copyWith(isRequestingPermission: true, isSaveFailing: false));
      final permission = await _requestPermission();
      final preference = permission.getRight().toNullable();
      emit(
        state.copyWith(
          isRequestingPermission: false,
          preference: preference ?? state.preference,
        ),
      );
    }
    await _save(
      NotificationPreferenceSettings.fromPreference(
        state.preference.copyWith(isEnabled: enabled),
      ),
    );
  }

  Future<void> setBudgetWarningsEnabled(bool enabled) => _save(
    NotificationPreferenceSettings.fromPreference(
      state.preference.copyWith(budgetWarningsEnabled: enabled),
    ),
  );

  Future<void> setSavingsCheckInsEnabled(bool enabled) => _save(
    NotificationPreferenceSettings.fromPreference(
      state.preference.copyWith(savingsCheckInsEnabled: enabled),
    ),
  );

  /// Turns quiet hours on with the suggested window, or off entirely.
  Future<void> setQuietHoursEnabled(bool enabled) {
    if (!enabled) return clearQuietHours();
    if (state.preference.hasQuietHours) return Future.value();
    return setQuietHours(
      start: suggestedQuietHoursStart,
      end: suggestedQuietHoursEnd,
    );
  }

  /// Stores a quiet-hours window, in minutes since local midnight (FR-013).
  Future<void> setQuietHours({required int start, required int end}) {
    final current = NotificationPreferenceSettings.fromPreference(
      state.preference,
    );
    return _save(
      NotificationPreferenceSettings(
        isEnabled: current.isEnabled,
        budgetWarningsEnabled: current.budgetWarningsEnabled,
        savingsCheckInsEnabled: current.savingsCheckInsEnabled,
        quietHoursStart: start,
        quietHoursEnd: end,
      ),
    );
  }

  Future<void> clearQuietHours() => _save(
    NotificationPreferenceSettings.fromPreference(
      state.preference.copyWith(clearQuietHours: true),
    ),
  );

  Future<void> _save(NotificationPreferenceSettings settings) async {
    if (state.status != NotificationSettingsStatus.ready) return;
    if (state.isSaveFailing) emit(state.copyWith(isSaveFailing: false));
    final result = await _setPreferences(settings);
    result.fold(
      (_) => emit(state.copyWith(isSaveFailing: true)),
      (NotificationPreference saved) => emit(state.copyWith(preference: saved)),
    );
  }
}
