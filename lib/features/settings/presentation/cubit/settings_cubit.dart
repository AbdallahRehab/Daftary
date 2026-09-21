import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_locale_provider.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/usecases/change_language.dart';
import '../../domain/usecases/change_theme_mode.dart';
import '../../domain/usecases/get_language_preference.dart';
import '../../domain/usecases/get_theme_mode_preference.dart';
import 'settings_state.dart';

/// Root-scoped (constitution research.md Decision 2) — provided once above
/// `MaterialApp.router` rather than per-screen, so the whole app can react
/// to `state.language`/`state.themeMode` live (FR-004).
@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getLanguagePreference,
    this._changeLanguage,
    this._deviceLocaleProvider,
    this._getThemeModePreference,
    this._changeThemeMode,
  ) : super(const SettingsState());

  final GetLanguagePreference _getLanguagePreference;
  final ChangeLanguage _changeLanguage;
  final DeviceLocaleProvider _deviceLocaleProvider;
  final GetThemeModePreference _getThemeModePreference;
  final ChangeThemeMode _changeThemeMode;

  /// Resolves the initial language and theme mode: the persisted preference
  /// if one exists for each, otherwise their respective first-launch
  /// defaults (FR-009 for language: the device's system language when it's
  /// Arabic or English, else English; FR-011 for theme: `AppThemeMode.system`,
  /// no device I/O required — research.md Decision 5). Must complete before
  /// the app's first frame (T025, `main.dart`) so that frame already
  /// reflects the right language/theme rather than this Cubit's hardcoded
  /// initial state.
  Future<void> initialize() async {
    final languageResult = await _getLanguagePreference();
    final persistedLanguage = languageResult.getOrElse((_) => null);
    final themeResult = await _getThemeModePreference();
    final persistedThemeMode = themeResult.getOrElse((_) => null);
    emit(
      state.copyWith(
        language: persistedLanguage ?? _firstLaunchLanguageDefault(),
        themeMode: persistedThemeMode ?? AppThemeMode.system,
      ),
    );
  }

  AppLanguage _firstLaunchLanguageDefault() {
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

  /// Emits the new theme mode immediately so the switch is live with no
  /// restart (FR-004), then persists it via [ChangeThemeMode], which owns
  /// the retry-once policy (research.md Decision 9).
  /// [SettingsState.isThemeModePersistFailing] is only set once the
  /// retried write has also failed; the session's theme choice is never
  /// rolled back.
  Future<void> changeThemeMode(AppThemeMode mode) async {
    emit(state.copyWith(themeMode: mode, isThemeModePersistFailing: false));
    final persisted = await _changeThemeMode(mode);
    if (!persisted) {
      emit(state.copyWith(isThemeModePersistFailing: true));
    }
  }
}
