import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_locale_provider.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/usecases/change_language.dart';
import '../../domain/usecases/get_language_preference.dart';
import 'settings_state.dart';

/// Root-scoped (constitution research.md Decision 2) — provided once above
/// `MaterialApp.router` rather than per-screen, so the whole app can react
/// to `state.language` live (FR-004).
@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getLanguagePreference,
    this._changeLanguage,
    this._deviceLocaleProvider,
  ) : super(const SettingsState());

  final GetLanguagePreference _getLanguagePreference;
  final ChangeLanguage _changeLanguage;
  final DeviceLocaleProvider _deviceLocaleProvider;

  /// Resolves the initial language: the persisted preference if one
  /// exists, otherwise the FR-009 first-launch default — the device's
  /// system language when it's Arabic or English, else English. Must
  /// complete before the app's first frame (T025, `main.dart`) so that
  /// frame already reflects the right language rather than this Cubit's
  /// hardcoded `AppLanguage.english` initial state.
  Future<void> initialize() async {
    final result = await _getLanguagePreference();
    final persisted = result.getOrElse((_) => null);
    if (persisted != null) {
      emit(state.copyWith(language: persisted));
      return;
    }
    emit(state.copyWith(language: _firstLaunchDefault()));
  }

  AppLanguage _firstLaunchDefault() {
    final deviceLanguageCode = _deviceLocaleProvider
        .currentLocale()
        .languageCode;
    for (final language in AppLanguage.values) {
      if (language.code == deviceLanguageCode) {
        return language;
      }
    }
    return AppLanguage.english;
  }

  /// Emits the new language immediately so the switch is live (FR-004),
  /// then persists it via [ChangeLanguage], which owns the FR-008
  /// retry-once policy. [SettingsState.isPersistFailing] is only set once
  /// the retried write has also failed.
  Future<void> changeLanguage(AppLanguage language) async {
    emit(state.copyWith(language: language, isPersistFailing: false));
    final persisted = await _changeLanguage(language);
    if (!persisted) {
      emit(state.copyWith(isPersistFailing: true));
    }
  }
}
