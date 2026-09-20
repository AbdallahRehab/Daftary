import 'package:equatable/equatable.dart';

import '../../domain/entities/app_language.dart';

/// Immutable state for [SettingsCubit] (constitution Principle IV).
class SettingsState extends Equatable {
  const SettingsState({
    this.language = AppLanguage.english,
    this.isPersistFailing = false,
  });

  final AppLanguage language;

  /// `true` only once the FR-008 retry-once policy has also failed on the
  /// second attempt — surfaced as a small non-blocking notice, never
  /// blocking the user from using the app in their chosen language.
  final bool isPersistFailing;

  SettingsState copyWith({AppLanguage? language, bool? isPersistFailing}) {
    return SettingsState(
      language: language ?? this.language,
      isPersistFailing: isPersistFailing ?? this.isPersistFailing,
    );
  }

  @override
  List<Object?> get props => [language, isPersistFailing];
}
