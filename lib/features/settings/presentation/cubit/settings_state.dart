import 'package:equatable/equatable.dart';

import '../../domain/entities/app_language.dart';
import '../../domain/entities/app_theme_mode.dart';

/// Immutable state for [SettingsCubit] (constitution Principle IV).
class SettingsState extends Equatable {
  const SettingsState({
    this.language = AppLanguage.english,
    this.isPersistFailing = false,
    this.themeMode = AppThemeMode.system,
    this.isThemeModePersistFailing = false,
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

  SettingsState copyWith({
    AppLanguage? language,
    bool? isPersistFailing,
    AppThemeMode? themeMode,
    bool? isThemeModePersistFailing,
  }) {
    return SettingsState(
      language: language ?? this.language,
      isPersistFailing: isPersistFailing ?? this.isPersistFailing,
      themeMode: themeMode ?? this.themeMode,
      isThemeModePersistFailing:
          isThemeModePersistFailing ?? this.isThemeModePersistFailing,
    );
  }

  @override
  List<Object?> get props => [
    language,
    isPersistFailing,
    themeMode,
    isThemeModePersistFailing,
  ];
}
