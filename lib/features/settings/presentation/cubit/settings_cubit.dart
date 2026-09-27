import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/device/device_locale_provider.dart';
import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/glass_appearance.dart';
import '../../domain/entities/glass_level.dart';
import '../../domain/usecases/change_glass_appearance.dart';
import '../../domain/usecases/change_language.dart';
import '../../domain/usecases/change_theme_mode.dart';
import '../../domain/usecases/get_glass_appearance_preference.dart';
import '../../domain/usecases/get_language_preference.dart';
import '../../domain/usecases/get_theme_mode_preference.dart';
import 'settings_state.dart';

/// Root-scoped (constitution research.md Decision 2) — provided once above
/// `MaterialApp.router` rather than per-screen, so the whole app can react
/// to `state.language`/`state.themeMode`/`state.glassAppearance` live
/// (FR-004).
@lazySingleton
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(
    this._getLanguagePreference,
    this._changeLanguage,
    this._deviceLocaleProvider,
    this._getThemeModePreference,
    this._changeThemeMode,
    this._getGlassAppearancePreference,
    this._changeGlassAppearance,
  ) : super(const SettingsState());

  final GetLanguagePreference _getLanguagePreference;
  final ChangeLanguage _changeLanguage;
  final DeviceLocaleProvider _deviceLocaleProvider;
  final GetThemeModePreference _getThemeModePreference;
  final ChangeThemeMode _changeThemeMode;
  final GetGlassAppearancePreference _getGlassAppearancePreference;
  final ChangeGlassAppearance _changeGlassAppearance;

  /// Resolves the initial language, theme mode and glass appearance: the
  /// persisted preference if one exists for each, otherwise their
  /// respective first-launch defaults (FR-009 for language: the device's
  /// system language when it's Arabic or English, else English; FR-011 for
  /// theme: `AppThemeMode.system`, no device I/O required — research.md
  /// Decision 5; 020 for glass: `GlassAppearance.defaults`, also on a
  /// failed read). All three land in a single emit. Must complete before
  /// the app's first frame (T025, `main.dart`) so that frame already
  /// reflects the right language/theme rather than this Cubit's hardcoded
  /// initial state.
  Future<void> initialize() async {
    final languageResult = await _getLanguagePreference();
    final persistedLanguage = languageResult.getOrElse((_) => null);
    final themeResult = await _getThemeModePreference();
    final persistedThemeMode = themeResult.getOrElse((_) => null);
    final glassResult = await _getGlassAppearancePreference();
    final persistedGlass = glassResult.getOrElse((_) => null);
    emit(
      state.copyWith(
        language: persistedLanguage ?? _firstLaunchLanguageDefault(),
        themeMode: persistedThemeMode ?? AppThemeMode.system,
        glassAppearance: persistedGlass ?? GlassAppearance.defaults,
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

  /// Turns Liquid Glass on or off. Disabling keeps the transparency and
  /// intensity choices, so re-enabling restores them (020 data-model.md).
  Future<void> setGlassEnabled(bool enabled) =>
      _changeGlass(state.glassAppearance.copyWith(enabled: enabled));

  Future<void> setGlassTransparency(GlassLevel level) =>
      _changeGlass(state.glassAppearance.copyWith(transparency: level));

  Future<void> setGlassIntensity(GlassLevel level) =>
      _changeGlass(state.glassAppearance.copyWith(intensity: level));

  /// Emits [next] immediately so the change is live with no restart, then
  /// persists the whole snapshot via [ChangeGlassAppearance], which owns
  /// the retry-once policy. A value equal to the current one is a no-op:
  /// nothing is emitted and nothing is written.
  /// [SettingsState.isGlassPersistFailing] is only set once the retried
  /// write has also failed; the session's glass choice is never rolled
  /// back.
  Future<void> _changeGlass(GlassAppearance next) async {
    if (next == state.glassAppearance) {
      return;
    }
    emit(state.copyWith(glassAppearance: next, isGlassPersistFailing: false));
    final persisted = await _changeGlassAppearance(next);
    if (!persisted) {
      emit(state.copyWith(isGlassPersistFailing: true));
    }
  }
}
