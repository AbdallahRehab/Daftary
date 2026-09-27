import 'package:equatable/equatable.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';
import '../../domain/entities/glass_appearance.dart';

/// Immutable state for [SettingsCubit] (constitution Principle IV).
class SettingsState extends Equatable {
  const SettingsState({
    this.language = AppLanguage.english,
    this.isPersistFailing = false,
    this.themeMode = AppThemeMode.system,
    this.isThemeModePersistFailing = false,
    this.glassAppearance = GlassAppearance.defaults,
    this.isGlassPersistFailing = false,
  });

  final AppLanguage language;

  /// `true` only once the FR-008 retry-once policy has also failed on the
  /// second attempt — surfaced as a small non-blocking notice, never
  /// blocking the user from using the app in their chosen language.
  final bool isPersistFailing;

  final AppThemeMode themeMode;

  /// `true` only once the retried theme-mode persistence write has also
  /// failed (research.md Decision 9) — scoped separately from
  /// [isPersistFailing], which stays language-only.
  final bool isThemeModePersistFailing;

  /// The live Liquid Glass preference; drives `AppGlassScope` at the root
  /// (020 data-model.md).
  final GlassAppearance glassAppearance;

  /// `true` only once the retried glass persistence write has also failed —
  /// set only after the retried write fails; scoped separately from the
  /// language/theme flags. The session's glass choice is never rolled back.
  final bool isGlassPersistFailing;

  SettingsState copyWith({
    AppLanguage? language,
    bool? isPersistFailing,
    AppThemeMode? themeMode,
    bool? isThemeModePersistFailing,
    GlassAppearance? glassAppearance,
    bool? isGlassPersistFailing,
  }) {
    return SettingsState(
      language: language ?? this.language,
      isPersistFailing: isPersistFailing ?? this.isPersistFailing,
      themeMode: themeMode ?? this.themeMode,
      isThemeModePersistFailing:
          isThemeModePersistFailing ?? this.isThemeModePersistFailing,
      glassAppearance: glassAppearance ?? this.glassAppearance,
      isGlassPersistFailing:
          isGlassPersistFailing ?? this.isGlassPersistFailing,
    );
  }

  @override
  List<Object?> get props => [
    language,
    isPersistFailing,
    themeMode,
    isThemeModePersistFailing,
    glassAppearance,
    isGlassPersistFailing,
  ];
}
